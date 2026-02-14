import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/graph_controller.dart';
import '../../domain/models.dart';
import 'node_widget.dart';
import 'relation_painter.dart';

class GraphCanvas extends StatefulWidget {
  const GraphCanvas({super.key});

  @override
  State<GraphCanvas> createState() => _GraphCanvasState();
}

class _GraphCanvasState extends State<GraphCanvas> {
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GraphController>();

    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(1000),
      minScale: 0.1,
      maxScale: 5.0,
      child: GestureDetector(
        // Double-click to add node
        onDoubleTapDown: (details) {
          controller.addNode(UiNodeType.info, details.localPosition);
        },
        // Tap empty space to dismiss menus
        onTap: () {
          controller.hideDeleteMenu();
        },
        child: SizedBox(
          width: 2000,
          height: 2000,
          child: Stack(
            children: [
              // 0. The Relations Layer
              Positioned.fill(
                child: CustomPaint(
                  painter: RelationPainter(
                    controller.relations,
                    controller.nodeLookup,
                  ),
                ),
              ),

              // 1. The Nodes Layer
              ...controller.nodes.map((node) {
                return Positioned(
                  left: node.position.dx,
                  top: node.position.dy,
                  child: NodeWidget(
                    node: node,
                    isDeleteMenuVisible: controller.nodeShowingDeleteMenu == node.id,
                    onTap: () {
                      // Handled inside NodeWidget or left empty if not needed
                    },
                    onSecondaryTap: () => controller.showDeleteMenu(node.id),
                    onDelete: () => controller.deleteNode(node.id),
                    onDrag: (delta) {
                      final newPosition = node.position + delta;
                      controller.updateNodePosition(node.id, newPosition);
                    },
                    onRelationPanStart: (pos) => controller.startRelationDrag(node.id, pos),
                    onRelationPanUpdate: (delta) {
                      final current = controller.draggingRelationCurrentPosition ?? Offset.zero;
                      controller.updateRelationDrag(current + delta);
                    },
                    onRelationPanEnd: () => controller.endRelationDrag(),
                  ),
                );
              }),

              // 2. Temporary Relation Drag Line
              if (controller.draggingRelationSourceNode != null &&
                  controller.draggingRelationCurrentPosition != null)
                 Positioned.fill(
                   child: CustomPaint(
                     painter: _TempRelationPainter(
                       start: controller.nodeLookup[controller.draggingRelationSourceNode]?.position ?? Offset.zero,
                       startSize: controller.nodeLookup[controller.draggingRelationSourceNode]?.size ?? Size.zero,
                       end: controller.draggingRelationCurrentPosition!,
                     ),
                   ),
                 ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TempRelationPainter extends CustomPainter {
  final Offset start;
  final Size startSize;
  final Offset end;

  _TempRelationPainter({required this.start, required this.startSize, required this.end});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blueAccent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final startCenter = start + Offset(startSize.width / 2, startSize.height / 2);

    // Draw dashed line or solid
    canvas.drawLine(startCenter, end, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}