import 'package:flutter/material.dart';
import 'package:mycelium/features/graph/models/port.dart';
import 'package:mycelium/features/graph/presentation/drag_state.dart';
import 'package:mycelium/features/graph/presentation/view_state.dart';

class PortLayer extends StatelessWidget {
  final Map<String, NodeViewState> nodeViewStates;
  final ValueNotifier<String?> hoveredNodeNotifier;
  final DragState dragState;

  const PortLayer({
    super.key,
    required this.nodeViewStates,
    required this.hoveredNodeNotifier,
    required this.dragState,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([dragState, hoveredNodeNotifier, _PortHighlight.instance]),
      builder: (context, _) {
        // Hide ports while any node is being dragged
        if (dragState.draggingNodes.isNotEmpty) {
          _PortHighlight.instance.reset();
          return const SizedBox.shrink();
        }

        final highlight = _PortHighlight.instance;
        final hoveredNodeId = hoveredNodeNotifier.value;

        // Show ports if: hovering over node OR keeping ports visible after hover
        final nodeId = hoveredNodeId ?? highlight.currentNodeId;
        if (nodeId == null) {
          _PortHighlight.instance.reset();
          return const SizedBox.shrink();
        }

        final vs = nodeViewStates[nodeId];
        if (vs == null) return const SizedBox.shrink();

        final scale = vs.currentScale;

        return MouseRegion(
          opaque: false,
          onHover: (event) {
            _PortHighlight.instance.update(nodeId, event.localPosition);
          },
          onExit: (_) {
            // Only reset if not hovering over a port
            if (!_PortHighlight.instance.isPortHovered) {
              _PortHighlight.instance.reset();
            }
          },
          child: CustomPaint(
            painter: PortPainter(
              ports: vs.ports.allPorts,
              mousePosition: highlight.position,
              scale: scale,
              nodeSize: vs.sizeNotifier.value,
              nodePosition: vs.positionNotifier.value,
            ),
            size: Size.infinite,
          ),
        );
      },
    );
  }
}

class _PortHighlight extends ChangeNotifier {
  static final instance = _PortHighlight._();
  _PortHighlight._();

  String? currentNodeId;
  Offset? position;
  bool isPortHovered = false;

  void update(String? newNodeId, Offset? newPosition) {
    currentNodeId = newNodeId;
    position = newPosition;
    isPortHovered = false;
    notifyListeners();
  }

  void setPortHovered() {
    isPortHovered = true;
    notifyListeners();
  }

  void reset() {
    currentNodeId = null;
    position = null;
    isPortHovered = false;
    notifyListeners();
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

      // Check if mouse is near this port
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
