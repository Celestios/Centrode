import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/config/app_config.dart';
import '../../domain/models.dart';
import '../../state/theme_controller.dart';
import '../../state/graph_ui_controller.dart';
import '../../state/graph_data_controller.dart';
import '../../domain/styling.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

/// A passive node widget that renders exactly what the domain instructs.
///
/// This widget is purely presentational - all interaction handling
/// is delegated to the InteractionController via the Listener in GraphCanvas.
///
/// [REFACTORED]: Converted to StatelessWidget with domain-driven geometry.
/// Size is now determined synchronously from the UiNode domain model,
/// eliminating asynchronous UI measurement and layout observers.
///
/// [NEW]: Dynamic node sizing with headless TextPainter for O(1) layout.
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
    final themeController = context.watch<ThemeController>();
    final uiController = context.watch<GraphUIController>();

    // THE FIX: Reactively select the canonical node from the central store.
    // This prevents the widget from rendering stale aesthetics (like old width)
    // when the FSM drops the volatile drag state before the parent layer rebuilds.
    final liveNode = context.select<GraphDataController, UiNode>(
      (c) => c.nodeLookup[node.id] ?? node,
    );

    final isSelected = uiController.selectedEntities.contains(liveNode.id);
    final isEditing = uiController.activeEditId == liveNode.id;

    final resolvedStyle =
        themeController.activeTheme?.resolveStyle(
          liveNode.type.name.capitalize(),
          liveNode.aesthetics,
        ) ??
        StyleProfile();

    // [NEW] We merge the notifiers so the widget repaints when position, size, or expanded state changes
    return ListenableBuilder(
      listenable: Listenable.merge([
        viewState.positionNotifier,
        viewState.sizeNotifier,
        viewState.isExpandedNotifier,
        viewState.dragWidthNotifier,
      ]),
      builder: (context, _) {
        final pos = viewState.positionNotifier.value;

        // Mathematical fallback: Use drag width if active, else aesthetic width, else 150
        final activeWidth =
            viewState.dragWidthNotifier.value ?? resolvedStyle.width;

        // Execute headless geometry logic safely before render phase
        viewState.recalculateSize(
          node.text,
          activeWidth,
          resolvedStyle.fontFamily,
        );

        final size = viewState.sizeNotifier.value;

        return Transform.translate(
          offset: pos,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Main Visual Body - strictly constrained by domain size
              Container(
                width: size.width,
                height: size.height,
                decoration: BoxDecoration(
                  color: resolvedStyle.bgColor,
                  borderRadius: resolvedStyle.shape == 'circle'
                      ? BorderRadius.circular(size.width / 2)
                      : BorderRadius.circular(8.0),
                  border: Border.all(
                    // Selection highlighting: Use consistent blue accent when selected
                    color: isSelected
                        ? AppConfig.graph.visual.selectionAccent
                        : resolvedStyle.strokeColor,
                    width: isSelected ? 2.5 : resolvedStyle.strokeWidth,
                  ),
                  boxShadow: isSelected
                      ? [
                          // Selection glow shadow
                          const BoxShadow(
                            color: Color(0x4442A5F5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : [
                          // Default shadow
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4,
                            offset: const Offset(2, 2),
                          ),
                        ],
                ),
                padding: const EdgeInsets.all(8.0),
                child: isEditing
                    ? _NodeInternalEditor(
                        nodeId: liveNode.id,
                        initialText: liveNode.text,
                        style: resolvedStyle,
                      )
                    : _buildNodeContent(context, liveNode, resolvedStyle),
              ),

              // [NEW] Resize Handle Visual (Right Edge)
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: AppConfig.graph.node.resizeHandleVisualWidth,
                  decoration: BoxDecoration(
                    // THE FIX: Force the rendering engine to paint this container.
                    // Colors.transparent is skipped by the hit-tester in a Stack.
                    // 1% opacity black is invisible to the eye but opaque to the pointer.
                    color: Colors.black.withValues(alpha: 0.01),
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(8.0),
                    ),
                  ),
                ),
              ),

              // REMOVED: Floating Toolbar (_NodeToolbar) - now handled by GraphCanvas stack

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

  Widget _buildNodeContent(
    BuildContext context,
    UiNode liveNode,
    StyleProfile style,
  ) {
    // [REFACTORED]: Simplified to static rendering only.
    // Editing is now handled by the top-level InlineEditorOverlay.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            liveNode.text.isEmpty ? "Empty Node" : liveNode.text,
            style: TextStyle(fontSize: 12, fontFamily: style.fontFamily),
            overflow: TextOverflow.fade,
            // [NEW] Enforce line limit visually based on expanded state
            maxLines: viewState.isExpandedNotifier.value
                ? null
                : AppConfig.graph.node.collapsedLineLimit,
          ),
        ),

        // [NEW] Expand/Collapse Toggle Button
        if (viewState.lineCount > 3)
          Container(
            margin: const EdgeInsets.only(top: 4.0),
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            child: Text(
              viewState.isExpandedNotifier.value ? "Show Less" : "Show More",
              style: const TextStyle(
                fontSize: 10,
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

        // Task Node state badge
        if (liveNode is TaskUiNode)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              (liveNode).state,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}

/// Internal editor widget for in-place node text editing.
///
/// This widget renders a TextField directly within the node's container,
/// inheriting the node's background and font styles for aesthetic alignment
/// and "zero-drift" movement during editing.
class _NodeInternalEditor extends StatefulWidget {
  final String nodeId;
  final String initialText;
  final StyleProfile style;

  const _NodeInternalEditor({
    required this.nodeId,
    required this.initialText,
    required this.style,
  });

  @override
  State<_NodeInternalEditor> createState() => _NodeInternalEditorState();
}

class _NodeInternalEditorState extends State<_NodeInternalEditor> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode();

    // Request focus and select all text after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<GraphDataController>().commitEntityText(
      widget.nodeId,
      _controller.text,
    );
    context.read<GraphUIController>().cancelActiveEdit();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          // Enter without Shift: submit and close
          if (event.logicalKey == LogicalKeyboardKey.enter &&
              !HardwareKeyboard.instance.isShiftPressed) {
            _submit();
            return KeyEventResult.handled;
          }
          // Escape: cancel edit without saving
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            context.read<GraphUIController>().cancelActiveEdit();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLines: null,
        textAlign: TextAlign.center,
        autofocus: true,
        cursorColor: Colors.black54,
        style: TextStyle(fontSize: 12, fontFamily: widget.style.fontFamily),
        decoration: const InputDecoration(
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onTapOutside: (_) => _submit(),
      ),
    );
  }
}
