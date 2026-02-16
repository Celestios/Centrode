import 'package:flutter/material.dart';
import '../../domain/models.dart';

/// A passive node widget that reports its size for hit-testing.
///
/// This widget is purely presentational - all interaction handling
/// is delegated to the InteractionController via the Listener in GraphCanvas.
/// The widget reports its rendered size to the NodeViewState for accurate
/// hit-testing in canvas space.
class NodeWidget extends StatefulWidget {
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
  State<NodeWidget> createState() => _NodeWidgetState();
}

class _NodeWidgetState extends State<NodeWidget> {
  final GlobalKey _childKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Measure-Observer: Report size after first layout
    WidgetsBinding.instance.addPostFrameCallback((_) => _reportSize());
  }

  @override
  void didUpdateWidget(NodeWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-report size if node dimensions change
    if (oldWidget.node.size != widget.node.size) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _reportSize());
    }
  }

  void _reportSize() {
    final context = _childKey.currentContext;
    if (context != null) {
      final renderBox = context.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) {
        widget.viewState.updateSize(renderBox.size);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Offset>(
      valueListenable: widget.viewState.positionNotifier,
      builder: (context, pos, _) {
        return Transform.translate(
          offset: pos,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main Visual Body
              Container(
                key: _childKey,
                width: widget.node.size.width,
                height: widget.node.size.height,
                decoration: BoxDecoration(
                  color: widget.node.color,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: widget.node.isSelected
                        ? Colors.blueAccent
                        : Colors.black87,
                    width: widget.node.isSelected ? 2.0 : 1.0,
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
                child: _buildNodeContent(),
              ),
              
              // Port Visual (aligned with portRect schema in InteractionController)
              // Positioned at right center, matching the 30x30 hit-test rect
              Positioned(
                right: -15,
                top: (widget.node.size.height / 2) - 15,
                child: const IgnorePointer(
                  child: Icon(
                    Icons.add_circle,
                    size: 30,
                    color: Colors.blueAccent,
                  ),
                ),
              ),
              
              // Delete Overlay (Topmost)
              if (widget.isDeleteMenuVisible)
                Positioned(
                  top: -20,
                  right: -20,
                  child: GestureDetector(
                    onTap: widget.onDelete,
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

  Widget _buildNodeContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              _getIconForType(widget.node.type),
              size: 14,
              color: Colors.black54,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                widget.node.id.startsWith("temp")
                    ? "Saving..."
                    : widget.node.id.substring(0, widget.node.id.length.clamp(0, 5)),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const Divider(height: 8, thickness: 0.5),
        Expanded(
          child: Text(
            widget.node.text.isEmpty ? "Empty Node" : widget.node.text,
            style: const TextStyle(fontSize: 12),
            overflow: TextOverflow.fade,
          ),
        ),
        if (widget.node is TaskUiNode)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              (widget.node as TaskUiNode).state,
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
