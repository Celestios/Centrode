import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import '../../../../../core/config/app_config.dart';
import '../../../state/graph_data_controller.dart';
import '../../../state/graph_ui_controller.dart';
import '../relation_painter.dart';

class RelationLayer extends StatelessWidget {
  const RelationLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final dataController = context.watch<GraphDataController>();
    final uiController = context.watch<GraphUIController>();

    return Positioned.fill(
      child: RepaintBoundary(
        child: ListenableBuilder(
          listenable: dataController.movementNotifier,
          builder: (context, _) {
            // Find if a relation is currently being edited
            final activeEditId = uiController.activeEditId;
            final editedRel = activeEditId != null
                ? dataController.relations
                      .where((r) => r.id == activeEditId)
                      .firstOrNull
                : null;

            Widget? editorWidget;
            if (editedRel != null) {
              final fromVs =
                  dataController.allNodeViewStates[editedRel.fromNodeId];
              final toVs = dataController.allNodeViewStates[editedRel.toNodeId];

              if (fromVs != null && toVs != null) {
                final start = fromVs.rightPort;
                final end = toVs.leftPort;
                final mid = Offset(
                  (start.dx + end.dx) / 2,
                  (start.dy + end.dy) / 2,
                );

                final width = AppConfig.graph.relation.editorMinWidth;
                final position =
                    mid -
                    Offset(
                      width / 2,
                      AppConfig.graph.relation.editorVerticalOffset,
                    );

                editorWidget = Positioned(
                  left: position.dx,
                  top: position.dy,
                  child: _RelationInternalEditor(
                    relationId: editedRel.id,
                    initialText: editedRel.label,
                  ),
                );
              }
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Base Painter
                Positioned.fill(
                  child: CustomPaint(
                    painter: RelationPainter(
                      dataController.relations.toList(),
                      dataController.allNodeViewStates,
                      uiController.selectedEntities,
                    ),
                  ),
                ),
                // Transient Inline Editor
                if (editorWidget != null) editorWidget,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RelationInternalEditor extends StatefulWidget {
  final String relationId;
  final String initialText;

  const _RelationInternalEditor({
    required this.relationId,
    required this.initialText,
  });

  @override
  State<_RelationInternalEditor> createState() =>
      _RelationInternalEditorState();
}

class _RelationInternalEditorState extends State<_RelationInternalEditor> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  final Logger _log = Logger('RelationInternalEditor');

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _focusNode = FocusNode();

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
    _log.info('Committing internal relation edit for: ${widget.relationId}');
    context.read<GraphDataController>().commitEntityText(
      widget.relationId,
      _controller.text,
    );
    context.read<GraphUIController>().cancelActiveEdit();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppConfig.graph.relation.editorMinWidth,
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
              _submit();
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              _log.info('Aborted relation edit via Escape.');
              context.read<GraphUIController>().cancelActiveEdit();
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
          onTapOutside: (_) => _submit(),
        ),
      ),
    );
  }
}
