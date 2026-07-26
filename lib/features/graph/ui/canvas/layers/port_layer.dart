import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mycelium/features/graph/models/port.dart';
import 'package:mycelium/features/graph/presentation/drag_state.dart';
import 'package:mycelium/features/graph/presentation/view_state.dart';
import 'package:mycelium/shared/domain/raw_uuid.dart';
import '../../../engine/base_interaction_state.dart';
import '../../../engine/config.dart';

class PortLayer extends StatefulWidget {
  final Map<RawUuid, NodeViewState> nodeViewStates;
  final ValueNotifier<RawUuid?> hoveredNodeNotifier;
  final ValueNotifier<Port?> hoveredPortNotifier;
  final ValueNotifier<CanvasInteractionState> interactionState;
  final DragState dragState;

  const PortLayer({
    super.key,
    required this.nodeViewStates,
    required this.hoveredNodeNotifier,
    required this.hoveredPortNotifier,
    required this.interactionState,
    required this.dragState,
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
  }

  @override
  void didUpdateWidget(covariant PortLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hoveredNodeNotifier != widget.hoveredNodeNotifier) {
      oldWidget.hoveredNodeNotifier.removeListener(_onHoverChanged);
      widget.hoveredNodeNotifier.addListener(_onHoverChanged);
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
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.hoveredNodeNotifier.removeListener(_onHoverChanged);
    widget.hoveredPortNotifier.removeListener(_onPortHoverChanged);
    widget.interactionState.removeListener(_onInteractionChanged);
    widget.dragState.removeListener(_onDragStateChanged);
    super.dispose();
  }

  void _onInteractionChanged() {
    final interaction = widget.interactionState.value;
    final isDrawing = interaction is RelationDrawing;
    if (isDrawing || interaction is RelationTipDragging) {
      _hideTimer?.cancel();
      _hideTimer = null;
      final hoveredId = widget.hoveredNodeNotifier.value;
      if (hoveredId != _activeNodeId) {
        setState(() => _activeNodeId = hoveredId);
      } else if (isDrawing) {
        setState(() {});
      }
    } else {
      final hoveredId = widget.hoveredNodeNotifier.value;
      if (hoveredId != _activeNodeId) {
        setState(() => _activeNodeId = hoveredId);
      }
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
    final nodeId = _activeNodeId;
    if (nodeId == null) return const SizedBox.shrink();

    final vs = widget.nodeViewStates[nodeId];
    if (vs == null) return const SizedBox.shrink();

    if (widget.dragState.isNodeDragging(nodeId)) {
      return const SizedBox.shrink();
    }

    final interaction = widget.interactionState.value;
    final drawing = interaction is RelationDrawing ? interaction : null;

    if (drawing != null && drawing.sourceNodeIds.contains(nodeId)) {
      return const SizedBox.shrink();
    }

    final ports = vs.ports.allPorts;
    if (ports.isEmpty) return const SizedBox.shrink();

    final snappedTarget = drawing?.snappedTargetPort;
    final hoveredPort = widget.hoveredPortNotifier.value;

    return IgnorePointer(
      child: CustomPaint(
        painter: PortPainter(
          ports: ports,
          scale: vs.currentScale,
          snappedTargetPort: snappedTarget,
          hoveredPort: hoveredPort,
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

  PortPainter({
    required this.ports,
    this.scale = 1.0,
    this.snappedTargetPort,
    this.hoveredPort,
  });

  double get _portRadius => AppConfig.port.drawRadius * scale;
  double get _hoveredPortRadius => AppConfig.port.drawRadius * 1.5 * scale;

  @override
  void paint(Canvas canvas, Size size) {
    final hoverColor = AppConfig.visuals.hoverAccent;
    final selectColor = AppConfig.visuals.selectionAccent;

    for (final port in ports) {
      final isSnapped = snappedTargetPort != null && port == snappedTargetPort;
      final isHovered = !isSnapped && hoveredPort != null && port == hoveredPort;

      final paint = Paint()
        ..color = isSnapped || isHovered
            ? selectColor.withValues(alpha: 0.9)
            : hoverColor.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;

      final radius = isSnapped || isHovered ? _hoveredPortRadius : _portRadius;

      canvas.drawCircle(port.position, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant PortPainter oldDelegate) {
    return ports != oldDelegate.ports ||
        scale != oldDelegate.scale ||
        snappedTargetPort != oldDelegate.snappedTargetPort ||
        hoveredPort != oldDelegate.hoveredPort;
  }
}
