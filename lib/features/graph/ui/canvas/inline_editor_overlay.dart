import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import '../../state/graph_data_controller.dart';
import '../../state/graph_ui_controller.dart';

/// A unified transient overlay for inline text editing.
///
/// This component handles both node text and relation labels, positioning
/// itself dynamically based on the entity type. It manages its own ephemeral
/// editing state (TextEditingController, FocusNode) which are created on mount
/// and disposed on unmount - ensuring clean lifecycle management.
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
  final Logger _log = Logger('InlineEditorOverlay'); // [NEW]

  @override
  void initState() {
    super.initState();
    _log.fine(
      'Mounting editor overlay for entity: ${widget.entityId}',
    ); // [NEW]
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
    _log.fine(
      'Unmounting editor overlay for entity: ${widget.entityId}',
    ); // [NEW]
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dataController = context.read<GraphDataController>();
    final uiController = context.read<GraphUIController>();
    final rel = dataController.relations
        .where((r) => r.id == widget.entityId)
        .firstOrNull;
    final nodeVs = dataController.allNodeViewStates[widget.entityId];

    return ListenableBuilder(
      listenable: dataController.movementNotifier,
      builder: (context, _) {
        Offset position;
        double width = 120;

        if (rel != null) {
          final fromVs = dataController.allNodeViewStates[rel.fromNodeId];
          final toVs = dataController.allNodeViewStates[rel.toNodeId];
          if (fromVs == null || toVs == null) {
            _log.warning(
              'Attempted to render overlay for orphaned relation: ${rel.id}',
            );
            return const SizedBox.shrink();
          }

          // [REFACTORED]: Use DRY Geometry
          final start = fromVs.rightPort;
          final end = toVs.leftPort;
          position = Offset(
            (start.dx + end.dx) / 2 - (width / 2),
            (start.dy + end.dy) / 2 - 15,
          );
        } else if (nodeVs != null) {
          final double nodeWidth = nodeVs.sizeNotifier.value.width;
          // Defensive mathematical clamping for crash immunity
          width = nodeWidth > 16.0 ? nodeWidth - 16.0 : 84.0;
          position = nodeVs.positionNotifier.value + const Offset(8, 25);
        } else {
          return const SizedBox.shrink();
        }

        return Positioned(
          left: position.dx,
          top: position.dy,
          child: SizedBox(
            width: width,
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
                maxLines: null,
                textAlign: rel != null ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  fontSize: rel != null ? 10 : 12,
                  backgroundColor: Colors.white,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  border: rel != null
                      ? const OutlineInputBorder()
                      : InputBorder.none,
                  contentPadding: const EdgeInsets.all(2),
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
