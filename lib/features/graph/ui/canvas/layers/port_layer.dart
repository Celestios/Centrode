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
      listenable: dragState,
      builder: (context, _) {
        // Hide ports while any node is being dragged
        if (dragState.draggingNodes.isNotEmpty) {
          _PortHighlight.instance.reset();
          return const SizedBox.shrink();
        }

        return ValueListenableBuilder<String?>(
          valueListenable: hoveredNodeNotifier,
          builder: (context, hoveredNodeId, _) {
            if (hoveredNodeId == null) {
              _PortHighlight.instance.reset();
              return const SizedBox.shrink();
            }

            final vs = nodeViewStates[hoveredNodeId];
            if (vs == null) return const SizedBox.shrink();

            final scale = vs.currentScale;

            return ListenableBuilder(
              listenable: _PortHighlight.instance,
              builder: (context, _) {
                final highlight = _PortHighlight.instance;

            if (highlight.isPortHovered && highlight.currentNodeId == hoveredNodeId) {
              return CustomPaint(
                painter: PortPainter(
                  ports: vs.ports.allPorts,
                  mousePosition: highlight.position,
                  scale: scale,
                  nodeSize: vs.sizeNotifier.value,
                ),
                size: Size.infinite,
              );
            }

            return MouseRegion(
              opaque: false,
              onHover: (event) {
                _PortHighlight.instance.update(hoveredNodeId, event.localPosition);
              },
              onExit: (_) {
                _PortHighlight.instance.reset();
              },
              child: CustomPaint(
                painter: PortPainter(
                  ports: vs.ports.allPorts,
                  mousePosition: null,
                  scale: scale,
                  nodeSize: vs.sizeNotifier.value,
                ),
                size: Size.infinite,
              ),
            );
              },
            );
          },
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

  PortPainter({
    required this.ports,
    this.mousePosition,
    this.scale = 1.0,
    required this.nodeSize,
  });

  static const double _portOffset = 8.0;

  double get _portRadius => 3.0 * scale;

  @override
  void paint(Canvas canvas, Size size) {
    for (final port in ports) {
      final offsetPos = _offsetPosition(port, nodeSize);

      // Check if mouse is near this port
      final isHovered = mousePosition != null &&
          (mousePosition! - offsetPos).distance < _portRadius + 4.0;

      final paint = Paint()
        ..color = isHovered
            ? Colors.blue.withValues(alpha: 0.9)
            : Colors.grey.withValues(alpha: 0.6)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(offsetPos, _portRadius, paint);
    }
  }

  Offset _offsetPosition(Port port, Size nodeSize) {
    final d = _portOffset * scale;
    if (port.isCorner) {
      // Use actual position to determine offset direction
      final isLeft = port.position.dx == 0;
      final isTop = port.position.dy == 0;
      return port.position + Offset(isLeft ? -d : d, isTop ? -d : d);
    }
    // Edge and middle ports offset perpendicular to side
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
        nodeSize != oldDelegate.nodeSize;
  }
}
