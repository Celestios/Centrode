import 'package:flutter/material.dart';
import '../../domain/models.dart';

class NodeWidget extends StatelessWidget {
  final UiNode node;
  final bool isDeleteMenuVisible;
  final VoidCallback onTap;
  final VoidCallback onSecondaryTap;
  final VoidCallback onDelete;
  final Function(Offset delta) onDrag;

  // Relation Drag Callbacks (Positions in Canvas Space)
  final Function(Offset startPos) onRelationPanStart;
  final Function(Offset delta) onRelationPanUpdate;
  final VoidCallback onRelationPanEnd;

  const NodeWidget({
    super.key,
    required this.node,
    required this.isDeleteMenuVisible,
    required this.onTap,
    required this.onSecondaryTap,
    required this.onDelete,
    required this.onDrag,
    required this.onRelationPanStart,
    required this.onRelationPanUpdate,
    required this.onRelationPanEnd,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      onSecondaryTap: onSecondaryTap, // Right-click / Long press
      onPanUpdate: (details) {
        onDrag(details.delta);
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 1. The Main Node Content
          Container(
            width: node.size.width,
            height: node.size.height,
            decoration: BoxDecoration(
              color: node.color,
              borderRadius: BorderRadius.circular(8.0),
              border: Border.all(
                color: node.isSelected ? Colors.blueAccent : Colors.black87,
                width: node.isSelected ? 2.0 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(),
                  blurRadius: 4,
                  offset: const Offset(2, 2),
                )
              ],
            ),
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(_getIconForType(node.type), size: 14, color: Colors.black54),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        node.id.startsWith("temp") ? "Saving..." : node.id.substring(0, 5),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 8, thickness: 0.5),
                Expanded(
                  child: Text(
                    node.text.isEmpty ? "Empty Node" : node.text,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.fade,
                  ),
                ),
                if (node is TaskUiNode)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      (node as TaskUiNode).state,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  )
              ],
            ),
          ),

          // 2. Drag Handles (4 sides)
          _buildDragHandle(Alignment.topCenter, Offset(node.size.width / 2, 0)),
          _buildDragHandle(Alignment.centerRight, Offset(node.size.width, node.size.height / 2)),
          _buildDragHandle(Alignment.bottomCenter, Offset(node.size.width / 2, node.size.height)),
          _buildDragHandle(Alignment.centerLeft, Offset(0, node.size.height / 2)),

          // 3. Delete Overlay (Topmost)
          if (isDeleteMenuVisible)
            GestureDetector(
              onTap: onDelete,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: const Icon(Icons.delete, color: Colors.white, size: 20),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDragHandle(Alignment alignment, Offset localOffset) {
    return Positioned(
      left: localOffset.dx - 20, 
      top: localOffset.dy - 20,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) {
          // Calculate global start pos for the line
          final globalStart = node.position + localOffset;
          onRelationPanStart(globalStart);
        },
        onPanUpdate: (details) => onRelationPanUpdate(details.delta),
        onPanEnd: (_) => onRelationPanEnd(),
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: const Icon(Icons.add, size: 8, color: Colors.white),
        ),
      ),
    );
  }

  IconData _getIconForType(UiNodeType type) {
    switch (type) {
      case UiNodeType.task: return Icons.check_circle_outline;
      case UiNodeType.inter: return Icons.link;
      case UiNodeType.info: return Icons.sticky_note_2_outlined;
    }
  }
}