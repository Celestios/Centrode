import 'package:flutter/material.dart';
import 'package:mycelium/features/graph/models/port.dart';
import 'package:mycelium/features/graph/presentation/view_state.dart';

class PortLayer extends StatelessWidget {
  final Map<String, NodeViewState> nodeViewStates;
  final ValueNotifier<String?> hoveredNodeNotifier;

  const PortLayer({
    super.key,
    required this.nodeViewStates,
    required this.hoveredNodeNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: hoveredNodeNotifier,
      builder: (context, hoveredNodeId, _) {
        if (hoveredNodeId == null) return const SizedBox.shrink();

        final vs = nodeViewStates[hoveredNodeId];
        if (vs == null) return const SizedBox.shrink();

        return MouseRegion(
          onHover: (event) {
            // Store cursor position for port highlighting
            _PortHighlight.instance.position.value = event.localPosition;
          },
          onExit: (_) {
            _PortHighlight.instance.position.value = null;
          },
          child: ValueListenableBuilder<Offset?>(
            valueListenable: _PortHighlight.instance.position,
            builder: (context, mousePos, _) {
              return CustomPaint(
                painter: PortPainter(
                  ports: vs.ports.allPorts,
                  mousePosition: mousePos,
                ),
                size: Size.infinite,
              );
            },
          ),
        );
      },
    );
  }
}

class _PortHighlight {
  static final instance = _PortHighlight._();
  _PortHighlight._();
  final ValueNotifier<Offset?> position = ValueNotifier(null);
}

class PortPainter extends CustomPainter {
  final List<Port> ports;
  final Offset? mousePosition;

  PortPainter({required this.ports, this.mousePosition});

  static const double _portOffset = 8.0;
  static const double _portRadius = 4.0;

  @override
  void paint(Canvas canvas, Size size) {
    for (final port in ports) {
      final offsetPos = _offsetPosition(port);

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

  Offset _offsetPosition(Port port) {
    switch (port.side) {
      case PortSide.top:
        return port.position + const Offset(0, -_portOffset);
      case PortSide.bottom:
        return port.position + const Offset(0, _portOffset);
      case PortSide.left:
        return port.position + const Offset(-_portOffset, 0);
      case PortSide.right:
        return port.position + const Offset(_portOffset, 0);
    }
  }

  @override
  bool shouldRepaint(covariant PortPainter oldDelegate) {
    return ports != oldDelegate.ports || mousePosition != oldDelegate.mousePosition;
  }
}
