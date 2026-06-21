import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mycelium/features/graph/models/port.dart';
import 'package:mycelium/features/graph/presentation/drag_state.dart';
import 'package:mycelium/features/graph/presentation/view_state.dart';
import '../../../engine/base_interaction_state.dart';

class PortLayer extends StatefulWidget {
  final Map<String, NodeViewState> nodeViewStates;
  final ValueNotifier<String?> hoveredNodeNotifier;
  final ValueNotifier<CanvasInteractionState> interactionState;
  final DragState dragState;

  const PortLayer({
    super.key,
    required this.nodeViewStates,
    required this.hoveredNodeNotifier,
    required this.interactionState,
    required this.dragState,
  });

  @override
  State<PortLayer> createState() => _PortLayerState();
}

class _PortLayerState extends State<PortLayer> {
  String? _activeNodeId;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    widget.hoveredNodeNotifier.addListener(_onHoverChanged);
    widget.interactionState.addListener(_onInteractionChanged);
  }

  @override
  void didUpdateWidget(covariant PortLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hoveredNodeNotifier != widget.hoveredNodeNotifier) {
      oldWidget.hoveredNodeNotifier.removeListener(_onHoverChanged);
      widget.hoveredNodeNotifier.addListener(_onHoverChanged);
    }
    if (oldWidget.interactionState != widget.interactionState) {
      oldWidget.interactionState.removeListener(_onInteractionChanged);
      widget.interactionState.addListener(_onInteractionChanged);
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.hoveredNodeNotifier.removeListener(_onHoverChanged);
    widget.interactionState.removeListener(_onInteractionChanged);
    super.dispose();
  }

  String? _computeActiveNodeId() {
    final interaction = widget.interactionState.value;
    if (interaction is RelationDrawing || interaction is RelationTipDragging) {
      return null;
    }

    final hoveredId = widget.hoveredNodeNotifier.value;
    return hoveredId;
  }

  void _onInteractionChanged() {
    final target = _computeActiveNodeId();
    if (target != null) {
      _hideTimer?.cancel();
      _hideTimer = null;
      if (target != _activeNodeId) {
        setState(() => _activeNodeId = target);
      }
    } else if (_activeNodeId != null && _hideTimer == null) {
      _hideTimer = Timer(const Duration(milliseconds: 100), () {
        _hideTimer = null;
        if (mounted) {
          final recheck = _computeActiveNodeId();
          setState(() => _activeNodeId = recheck);
        }
      });
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
          final recheck = _computeActiveNodeId();
          setState(() => _activeNodeId = recheck);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final nodeId = _activeNodeId;
    if (nodeId == null) return const SizedBox.shrink();

    final vs = widget.nodeViewStates[nodeId];
    if (vs == null) return const SizedBox.shrink();

    final scale = vs.currentScale;

    return IgnorePointer(
      child: CustomPaint(
        painter: PortPainter(
          ports: vs.ports.allPorts,
          scale: scale,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class PortPainter extends CustomPainter {
  final List<Port> ports;
  final double scale;

  PortPainter({
    required this.ports,
    this.scale = 1.0,
  });

  double get _portRadius => 3.0 * scale;

  @override
  void paint(Canvas canvas, Size size) {
    for (final port in ports) {
      final paint = Paint()
        ..color = Colors.grey.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(port.position, _portRadius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant PortPainter oldDelegate) {
    return ports != oldDelegate.ports || scale != oldDelegate.scale;
  }
}
