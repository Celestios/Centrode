import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:centrode/features/graph/models/port.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/store/graph_data_query.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/features/graph/engine/interaction_engine.dart';
import 'package:centrode/features/graph/engine/base_interaction_state.dart';
import 'package:centrode/features/graph/engine/config.dart';
import 'package:centrode/presentation/theme/app_theme_manager.dart';
import 'package:centrode/features/graph/presentation/viewport_state.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

/// Canvas layer rendering connection ports for hovered and connecting nodes.
class PortLayer extends StatelessWidget {
  const PortLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final renderState = context.watch<NodeRenderState>();
    final queryController = context.watch<GraphDataQuery>();
    final interactionController = context.watch<InteractionController>();
    final viewportController = context.watch<ViewportController>();

    return ValueListenableBuilder<CanvasInteractionState>(
      valueListenable: interactionController.state,
      builder: (context, interaction, _) {
        return ListenableBuilder(
          listenable: Listenable.merge([
            renderState.hoveredNodeNotifier,
            renderState.hoveredPortNotifier,
            renderState.dragState,
            viewportController.activeScopeNotifier,
            viewportController.isTransitioningNotifier,
          ]),
          builder: (context, _) {
            final drawing = interaction is RelationDrawing ? interaction : null;
            final tipDrag = interaction is RelationTipDragging ? interaction : null;

            final RawUuid? activeId = renderState.hoveredNodeNotifier.value ??
                (tipDrag?.snappedTargetNodeId) ??
                (drawing?.snappedTargetNodeId);

            if (activeId == null) return const SizedBox.shrink();
            final nodeId = activeId;

            final vs = renderState.viewStates[nodeId];
            if (vs == null) return const SizedBox.shrink();

            final node = queryController.nodeLookup[nodeId];
            if (node != null) {
              final activeScope = viewportController.activeScopeNotifier.value;
              if (!queryController.isNodeInScope(nodeId, activeScope)) {
                return const SizedBox.shrink();
              }
              if (activeScope is RootViewportScope && node is ContainerUiNode) {
                final isTransitioning = viewportController.isTransitioningNotifier.value;
                final screenWidth = (vs.sizeNotifier.value.width > 0 ? vs.sizeNotifier.value.width : node.size.width) * vs.currentScale;
                if (!node.isClosed || isTransitioning || screenWidth >= 180.0) {
                  return const SizedBox.shrink();
                }
              }
            }

            if (renderState.dragState.isNodeDragging(nodeId)) {
              return const SizedBox.shrink();
            }

            if (drawing != null && drawing.sourceNodeIds.contains(nodeId)) {
              return const SizedBox.shrink();
            }

            if (tipDrag != null) {
              final rel = queryController.relationLookup[tipDrag.relationId];
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
                ? renderState.hoveredPortNotifier.value
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
          },
        );
      },
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
