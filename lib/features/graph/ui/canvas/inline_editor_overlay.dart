import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import '../../state/graph_data_controller.dart';
import '../../state/graph_ui_controller.dart';
import '../../../../core/config/app_config.dart';

/// A specialized portal overlay for editing relation labels.
///
/// This component handles only relation labels, positioning itself at the
/// midpoint between the connected nodes' ports. It masks the underlying
/// CustomPainter text with a white background to prevent visual "mixing".
///
/// The overlay listens to [MovementNotifier] for drift compensation during
/// node drags, ensuring spatial integrity during movement.
class InlineEditorOverlay extends StatefulWidget {
  final String entityId;
  final String initialText;

  const InlineEditorOverlay({
    super.key,
    required this.entityId,
    required this.initialText,
  });

  @override
  State<InlineEditorOverlay> createState() => _InlineEditorOverlayState();
}

class _InlineEditorOverlayState extends State<InlineEditorOverlay> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  final Logger _log = Logger('InlineEditorOverlay');

  @override
  void initState() {
    super.initState();
    _log.fine('Mounting editor overlay for relation: ${widget.entityId}');
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode();
    // High-priority selection for immediate editing
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _log.fine('Unmounting editor overlay for relation: ${widget.entityId}');
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataController = context.read<GraphDataController>();
    final uiController = context.read<GraphUIController>();

    // Early return for non-relation entities
    final rel = dataController.relations
        .where((r) => r.id == widget.entityId)
        .firstOrNull;
    if (rel == null) {
      _log.warning(
        'Entity ${widget.entityId} is not a relation, returning empty widget',
      );
      return const SizedBox.shrink();
    }

    return ListenableBuilder(
      listenable: dataController.movementNotifier,
      builder: (context, _) {
        // Get view states for the connected nodes
        final fromVs = dataController.allNodeViewStates[rel.fromNodeId];
        final toVs = dataController.allNodeViewStates[rel.toNodeId];

        if (fromVs == null || toVs == null) {
          _log.warning(
            'Attempted to render overlay for orphaned relation: ${rel.id}',
          );
          return const SizedBox.shrink();
        }

        // Calculate midpoint between ports
        final start = fromVs.rightPort;
        final end = toVs.leftPort;
        final mid = Offset((start.dx + end.dx) / 2, (start.dy + end.dy) / 2);

        // Position the editor with fixed width
        final width = AppConfig.graph.relation.editorMinWidth;
        final position =
            mid -
            Offset(width / 2, AppConfig.graph.relation.editorVerticalOffset);

        return Positioned(
          left: position.dx,
          top: position.dy,
          child: Container(
            width: width,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            decoration: BoxDecoration(
              color: AppConfig.graph.relation.editorBgColor,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: AppConfig.graph.visual.selectionAccent,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.enter &&
                      !HardwareKeyboard.instance.isShiftPressed) {
                    dataController.commitEntityText(
                      widget.entityId,
                      _controller.text,
                    );
                    uiController.cancelActiveEdit();
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.escape) {
                    uiController.cancelActiveEdit();
                    return KeyEventResult.handled;
                  }
                }
                return KeyEventResult.ignored;
              },
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppConfig.graph.editor.fontSizeRelation,
                  color: Colors.black,
                  fontWeight: FontWeight.w500,
                  height: 1.2,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onTapOutside: (_) {
                  dataController.commitEntityText(
                    widget.entityId,
                    _controller.text,
                  );
                  uiController.cancelActiveEdit();
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
