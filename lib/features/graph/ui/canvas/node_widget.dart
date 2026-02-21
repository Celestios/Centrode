import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/models.dart';
import '../../state/graph_controller.dart';
import '../../domain/styling.dart';

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
    final controller = context.watch<GraphController>();
    final resolvedStyle =
        controller.activeTheme?.resolveStyle(
          node.type.name.capitalize(),
          node.aesthetics,
        ) ??
        StyleProfile();

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
                  color: resolvedStyle.bgColor,
                  borderRadius: resolvedStyle.shape == 'circle'
                      ? BorderRadius.circular(node.size.width / 2)
                      : BorderRadius.circular(8.0),
                  border: Border.all(
                    color: node.isSelected
                        ? Colors.blueAccent
                        : resolvedStyle.strokeColor,
                    width: node.isSelected ? 2.0 : resolvedStyle.strokeWidth,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(8.0),
                child: _buildNodeContent(context, resolvedStyle),
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
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNodeContent(BuildContext context, StyleProfile style) {
    // [REFACTORED]: Simplified to static rendering only.
    // Editing is now handled by the top-level InlineEditorOverlay.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            node.text.isEmpty ? "Empty Node" : node.text,
            style: TextStyle(fontSize: 12, fontFamily: style.fontFamily),
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
          ),
      ],
    );
  }
}
