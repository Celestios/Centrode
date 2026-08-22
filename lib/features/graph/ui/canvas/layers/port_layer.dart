import 'dart:async';
import 'package:flutter/material.dart';
import 'package:centrode/features/graph/models/port.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/store/graph_data_query.dart';
import 'package:centrode/features/graph/presentation/drag_state.dart';
import 'package:centrode/features/graph/presentation/view_state.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import '../../../engine/base_interaction_state.dart';
import '../../../engine/config.dart';
import '../../../../../presentation/theme/app_theme_manager.dart';
import '../../../presentation/viewport_state.dart';

class PortLayer extends StatefulWidget {
  final Map<RawUuid, NodeViewState> nodeViewStates;
  final ValueNotifier<RawUuid?> hoveredNodeNotifier;
  final ValueNotifier<Port?> hoveredPortNotifier;
  final ValueNotifier<CanvasInteractionState> interactionState;
  final DragState dragState;
  final GraphDataQuery? queryController;
  final ViewportController? viewportController;

  const PortLayer({
    super.key,
    required this.nodeViewStates,
    required this.hoveredNodeNotifier,
    required this.hoveredPortNotifier,
    required this.interactionState,
    required this.dragState,
    this.queryController,
    this.viewportController,
  });

  @override
  State<PortLayer> createState() => _PortLayerState();
}

class _PortLayerState extends State<PortLayer> {
  RawUuid? _activeNodeId;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    widget.hoveredNodeNotifier.addListener(_onHoverChanged);
    widget.hoveredPortNotifier.addListener(_onPortHoverChanged);
    widget.interactionState.addListener(_onInteractionChanged);
    widget.dragState.addListener(_onDragStateChanged);
    widget.viewportController?.activeScopeNotifier.addListener(_onScopeChanged);
    _activeNodeId = widget.hoveredNodeNotifier.value;
  }

  @override
  void didUpdateWidget(covariant PortLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hoveredNodeNotifier != widget.hoveredNodeNotifier) {
      oldWidget.hoveredNodeNotifier.removeListener(_onHoverChanged);
      widget.hoveredNodeNotifier.addListener(_onHoverChanged);
      _activeNodeId = widget.hoveredNodeNotifier.value;
    }
    if (oldWidget.hoveredPortNotifier != widget.hoveredPortNotifier) {
      oldWidget.hoveredPortNotifier.removeListener(_onPortHoverChanged);
      widget.hoveredPortNotifier.addListener(_onPortHoverChanged);
    }
    if (oldWidget.interactionState != widget.interactionState) {
      oldWidget.interactionState.removeListener(_onInteractionChanged);
      widget.interactionState.addListener(_onInteractionChanged);
    }
    if (oldWidget.dragState != widget.dragState) {
      oldWidget.dragState.removeListener(_onDragStateChanged);
      widget.dragState.addListener(_onDragStateChanged);
    }
    if (oldWidget.viewportController != widget.viewportController) {
      oldWidget.viewportController?.activeScopeNotifier.removeListener(_onScopeChanged);
      widget.viewportController?.activeScopeNotifier.addListener(_onScopeChanged);
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.hoveredNodeNotifier.removeListener(_onHoverChanged);
    widget.hoveredPortNotifier.removeListener(_onPortHoverChanged);
    widget.interactionState.removeListener(_onInteractionChanged);
    widget.dragState.removeListener(_onDragStateChanged);
    widget.viewportController?.activeScopeNotifier.removeListener(_onScopeChanged);
    super.dispose();
  }

  void _onScopeChanged() {
    _hideTimer?.cancel();
    _hideTimer = null;
    _activeNodeId = null;
    if (mounted) setState(() {});
  }

  void _onInteractionChanged() {
    final interaction = widget.interactionState.value;
    if (interaction is RelationDrawing || interaction is RelationTipDragging) {
      _hideTimer?.cancel();
      _hideTimer = null;
    }
    final snappedId = interaction is RelationTipDragging
        ? interaction.snappedTargetNodeId
        : (interaction is RelationDrawing ? interaction.snappedTargetNodeId : null);
    final targetId = widget.hoveredNodeNotifier.value ?? snappedId;
    if (targetId != _activeNodeId) {
      setState(() => _activeNodeId = targetId);
    } else {
      setState(() {});
    }
  }

  void _onHoverChanged() {
    final hoveredId = widget.hoveredNodeNotifier.value;
    if (hoveredId != null) {
      _hideTimer?.cancel();
      _hideTimer = null;
      setState(() => _activeNodeId = hoveredId);
    } else if (_activeNodeId != null && _hideTimer == null) {
      _hideTimer = Timer(const Duration(milliseconds: 100), () {
        _hideTimer = null;
        if (mounted) {
          setState(() => _activeNodeId = widget.hoveredNodeNotifier.value);
        }
      });
    }
  }

  void _onPortHoverChanged() {
    if (_activeNodeId != null) {
      setState(() {});
    }
  }

  void _onDragStateChanged() {
    if (_activeNodeId == null) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final interaction = widget.interactionState.value;
    final drawing = interaction is RelationDrawing ? interaction : null;
    final tipDrag = interaction is RelationTipDragging ? interaction : null;

    final RawUuid? activeId = widget.hoveredNodeNotifier.value ??
        (tipDrag?.snappedTargetNodeId) ??
        (drawing?.snappedTargetNodeId) ??
        _activeNodeId;

    if (activeId == null) return const SizedBox.shrink();
    final nodeId = activeId;

    final vs = widget.nodeViewStates[nodeId];
    if (vs == null) return const SizedBox.shrink();

    final node = widget.queryController?.nodeLookup[nodeId];
    if (node != null) {
      final activeScope = widget.viewportController?.activeScopeNotifier.value ?? const RootViewportScope();
      if (!widget.queryController!.isNodeInScope(nodeId, activeScope)) {
        return const SizedBox.shrink();
      }
      if (activeScope is RootViewportScope && node is ContainerUiNode) {
        final isTransitioning = widget.viewportController?.isTransitioningNotifier.value ?? false;
        final screenWidth = (vs.sizeNotifier.value.width > 0 ? vs.sizeNotifier.value.width : node.size.width) * vs.currentScale;
        if (!node.isClosed || isTransitioning || screenWidth >= 180.0) {
          return const SizedBox.shrink();
        }
      }
    }

    if (widget.dragState.isNodeDragging(nodeId)) {
      return const SizedBox.shrink();
    }

    if (drawing != null && drawing.sourceNodeIds.contains(nodeId)) {
      return const SizedBox.shrink();
    }

    if (tipDrag != null) {
      final rel = widget.queryController?.relationLookup[tipDrag.relationId];
      final oppositeId = tipDrag.isStartTip ? rel?.toNodeId : rel?.fromNodeId;
      if (oppositeId != null && nodeId == oppositeId) {
        return const SizedBox.shrink();
      }
    }

    final ports = vs.ports.allPorts;
    if (ports.isEmpty) return const SizedBox.shrink();

    final snappedTarget = (drawing != null && drawing.snappedTargetNodeId == nodeId)
        ? drawing.snappedTargetPort
        : (tipDrag != null && tipDrag.snappedTargetNodeId == nodeId)
            ? tipDrag.snappedPort
            : null;
    final hoveredPort = interaction is CanvasIdle
        ? widget.hoveredPortNotifier.value
        : null;

    final canvasAccent = AppThemeManager.instance.currentTheme.canvasAccentColor;
    final hoverAccent = AppThemeManager.instance.currentTheme.hoverAccentColor;

    return IgnorePointer(
      child: CustomPaint(
        painter: PortPainter(
          ports: ports,
          scale: vs.currentScale,
          snappedTargetPort: snappedTarget,
          hoveredPort: hoveredPort,
          selectionColor: canvasAccent,
          hoverColor: hoverAccent,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class PortPainter extends CustomPainter {
  final List<Port> ports;
  final double scale;
  final Port? snappedTargetPort;
  final Port? hoveredPort;
  final Color selectionColor;
  final Color hoverColor;

  PortPainter({
    required this.ports,
    this.scale = 1.0,
    this.snappedTargetPort,
    this.hoveredPort,
    required this.selectionColor,
    required this.hoverColor,
  });

  double get _portRadius => AppConfig.port.drawRadius * scale;
  double get _hoveredPortRadius => AppConfig.port.drawRadius * 1.5 * scale;

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()..style = PaintingStyle.fill;
    final plusPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final port in ports) {
      final isSnapped = snappedTargetPort != null && port == snappedTargetPort;
      final isHovered =
          !isSnapped && hoveredPort != null && port == hoveredPort;

      fillPaint.color = isSnapped || isHovered ? selectionColor : hoverColor;

      final radius = isSnapped || isHovered ? _hoveredPortRadius : _portRadius;

      canvas.drawCircle(port.position, radius, fillPaint);

      plusPaint.strokeWidth = (isHovered || isSnapped ? 2.0 : 1.5) * scale;

      final armLength = radius * 0.5;
      canvas.drawLine(
        Offset(port.position.dx - armLength, port.position.dy),
        Offset(port.position.dx + armLength, port.position.dy),
        plusPaint,
      );
      canvas.drawLine(
        Offset(port.position.dx, port.position.dy - armLength),
        Offset(port.position.dx, port.position.dy + armLength),
        plusPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant PortPainter oldDelegate) {
    return ports != oldDelegate.ports ||
        scale != oldDelegate.scale ||
        snappedTargetPort != oldDelegate.snappedTargetPort ||
        hoveredPort != oldDelegate.hoveredPort ||
        selectionColor != oldDelegate.selectionColor ||
        hoverColor != oldDelegate.hoverColor;
  }
}
