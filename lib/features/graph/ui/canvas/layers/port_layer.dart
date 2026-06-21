import 'package:flutter/material.dart';
import 'package:mycelium/features/graph/models/port.dart';
import 'package:mycelium/features/graph/presentation/drag_state.dart';
import 'package:mycelium/features/graph/presentation/view_state.dart';

class PortLayer extends StatefulWidget {
  final Map<String, NodeViewState> nodeViewStates;
  final ValueNotifier<String?> hoveredNodeNotifier;
  final DragState dragState;
  final void Function(String nodeId, Port port)? onPortTapped;

  const PortLayer({
    super.key,
    required this.nodeViewStates,
    required this.hoveredNodeNotifier,
    required this.dragState,
    this.onPortTapped,
  });

  @override
  State<PortLayer> createState() => _PortLayerState();
}

class _PortLayerState extends State<PortLayer> {
  String? _activeNodeId;
  Offset? _mousePosition;

  @override
  void initState() {
    super.initState();
    widget.hoveredNodeNotifier.addListener(_onHoverChanged);
    widget.dragState.addListener(_onDragChanged);
  }

  @override
  void didUpdateWidget(covariant PortLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hoveredNodeNotifier != widget.hoveredNodeNotifier) {
      oldWidget.hoveredNodeNotifier.removeListener(_onHoverChanged);
      widget.hoveredNodeNotifier.addListener(_onHoverChanged);
    }
    if (oldWidget.dragState != widget.dragState) {
      oldWidget.dragState.removeListener(_onDragChanged);
      widget.dragState.addListener(_onDragChanged);
    }
  }

  @override
  void dispose() {
    widget.hoveredNodeNotifier.removeListener(_onHoverChanged);
    widget.dragState.removeListener(_onDragChanged);
    super.dispose();
  }

  void _onDragChanged() {
    if (widget.dragState.draggingNodes.isNotEmpty) {
      setState(() {
        _activeNodeId = null;
        _mousePosition = null;
      });
    }
  }

  void _onHoverChanged() {
    final hoveredId = widget.hoveredNodeNotifier.value;
    if (hoveredId != null) {
      setState(() => _activeNodeId = hoveredId);
    } else if (_activeNodeId != null) {
      _checkShouldHide();
    }
  }

  void _checkShouldHide() {
    if (_activeNodeId == null || _mousePosition == null) {
      setState(() => _activeNodeId = null);
      return;
    }

    final vs = widget.nodeViewStates[_activeNodeId];
    if (vs == null) {
      setState(() => _activeNodeId = null);
      return;
    }

    final nodePos = vs.positionNotifier.value;
    final scale = vs.currentScale;
    final portOffset = 8.0 * scale;

    for (final port in vs.ports.allPorts) {
      final offsetPos = _getOffsetPortPosition(port, nodePos, portOffset);
      if ((_mousePosition! - offsetPos).distance < 16.0) {
        return;
      }
    }

    setState(() => _activeNodeId = null);
  }

  Offset _getOffsetPortPosition(Port port, Offset nodePos, double d) {
    if (port.isCorner) {
      final isLeft = port.position.dx <= nodePos.dx;
      final isTop = port.position.dy <= nodePos.dy;
      return port.position + Offset(isLeft ? -d : d, isTop ? -d : d);
    }
    switch (port.side) {
      case PortSide.top:
        return port.position + Offset(0, -d);
      case PortSide.bottom:
        return port.position + Offset(0, d);
      case PortSide.left:
        return port.position + Offset(-d, 0);
      case PortSide.right:
        return port.position + Offset(d, 0);
    }
  }

  Port? _findPortAtPosition(Offset position) {
    if (_activeNodeId == null) return null;
    final vs = widget.nodeViewStates[_activeNodeId];
    if (vs == null) return null;

    final nodePos = vs.positionNotifier.value;
    final scale = vs.currentScale;
    final portOffset = 8.0 * scale;

    for (final port in vs.ports.allPorts) {
      final offsetPos = _getOffsetPortPosition(port, nodePos, portOffset);
      if ((position - offsetPos).distance < 12.0) {
        return port;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final nodeId = _activeNodeId;
    if (nodeId == null) return const SizedBox.shrink();

    final vs = widget.nodeViewStates[nodeId];
    if (vs == null) return const SizedBox.shrink();

    final scale = vs.currentScale;

    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      opaque: false,
      onHover: (event) {
        setState(() => _mousePosition = event.localPosition);
      },
      onExit: (_) {
        setState(() {
          _mousePosition = null;
          _activeNodeId = null;
        });
      },
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: (details) {
          final port = _findPortAtPosition(details.localPosition);
          if (port != null && widget.onPortTapped != null) {
            widget.onPortTapped!(nodeId, port);
          }
        },
        child: CustomPaint(
          painter: PortPainter(
            ports: vs.ports.allPorts,
            mousePosition: _mousePosition,
            scale: scale,
            nodeSize: vs.sizeNotifier.value,
            nodePosition: vs.positionNotifier.value,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class PortPainter extends CustomPainter {
  final List<Port> ports;
  final Offset? mousePosition;
  final double scale;
  final Size nodeSize;
  final Offset nodePosition;

  PortPainter({
    required this.ports,
    this.mousePosition,
    this.scale = 1.0,
    required this.nodeSize,
    required this.nodePosition,
  });

  static const double _portOffset = 8.0;
  static const double _portHitRadius = 12.0;

  double get _portRadius => 3.0 * scale;

  @override
  void paint(Canvas canvas, Size size) {
    for (final port in ports) {
      final offsetPos = _offsetPosition(port);

      final isHovered = mousePosition != null &&
          (mousePosition! - offsetPos).distance < _portHitRadius;

      final paint = Paint()
        ..color = isHovered
            ? Colors.blue.withValues(alpha: 0.9)
            : Colors.grey.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(offsetPos, _portRadius, paint);
    }
  }

  Offset _offsetPosition(Port port) {
    final d = _portOffset * scale;
    if (port.isCorner) {
      final isLeft = port.position.dx <= nodePosition.dx;
      final isTop = port.position.dy <= nodePosition.dy;
      return port.position + Offset(isLeft ? -d : d, isTop ? -d : d);
    }
    switch (port.side) {
      case PortSide.top:
        return port.position + Offset(0, -d);
      case PortSide.bottom:
        return port.position + Offset(0, d);
      case PortSide.left:
        return port.position + Offset(-d, 0);
      case PortSide.right:
        return port.position + Offset(d, 0);
    }
  }

  @override
  bool shouldRepaint(covariant PortPainter oldDelegate) {
    return ports != oldDelegate.ports ||
        mousePosition != oldDelegate.mousePosition ||
        scale != oldDelegate.scale ||
        nodeSize != oldDelegate.nodeSize ||
        nodePosition != oldDelegate.nodePosition;
  }
}
