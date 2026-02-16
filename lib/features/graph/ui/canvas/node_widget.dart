import 'package:flutter/material.dart';
import '../../domain/models.dart';

/// A passive node widget that renders exactly what the domain instructs.
///
/// This widget is purely presentational - all interaction handling
/// is delegated to the InteractionController via the Listener in GraphCanvas.
/// 
/// [REFACTORED]: Converted to StatelessWidget with domain-driven geometry.
/// Size is now determined synchronously from the UiNode domain model,
/// eliminating asynchronous UI measurement and layout observers.
class NodeWidget extends StatelessWidget {
  final UiNode node;
  final NodeViewState viewState;
  final bool isDeleteMenuVisible;
  final VoidCallback onDelete;

  const NodeWidget({
    super.key,
    required this.node,
    required this.viewState,
    required this.isDeleteMenuVisible,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Offset>(
      valueListenable: viewState.positionNotifier,
      builder: (context, pos, _) {
        return Transform.translate(
          offset: pos,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main Visual Body - strictly constrained by domain size
              Container(
                width: node.size.width,
                height: node.size.height,
                decoration: BoxDecoration(
                  color: node.color,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: node.isSelected
                        ? Colors.blueAccent
                        : Colors.black87,
                    width: node.isSelected ? 2.0 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(8.0),
                child: _buildNodeContent(context),
              ),
              
              // Port Visual (aligned with portRect schema in InteractionController)
              // Positioned at right center, matching the 30x30 hit-test rect
              Positioned(
                right: -15,
                top: (node.size.height / 2) - 15,
                child: const IgnorePointer(
                  child: Icon(
                    Icons.add_circle,
                    size: 30,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              
              // Delete Overlay (Topmost)
              if (isDeleteMenuVisible)
                Positioned(
                  top: -20,
                  right: -20,
                  child: GestureDetector(
                    onTap: onDelete,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 4)
                        ],
                      ),
                      child: const Icon(Icons.delete, color: Colors.white, size: 20),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNodeContent(BuildContext context) {
    // [REFACTORED]: Simplified to static rendering only. 
    // Editing is now handled by the top-level InlineEditorOverlay.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getIconForType(node.type),
              size: 14,
              color: Colors.black54,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                node.id.startsWith("temp")
                    ? "Saving..."
                    : node.id.substring(0, node.id.length.clamp(0, 5)),
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
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              (node as TaskUiNode).state,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          )
      ],
    );
  }

  IconData _getIconForType(UiNodeType type) {
    switch (type) {
      case UiNodeType.task:
        return Icons.check_circle_outline;
      case UiNodeType.inter:
        return Icons.link;
      case UiNodeType.info:
        return Icons.sticky_note_2_outlined;
    }
  }
}
