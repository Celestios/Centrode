import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';
import '../../store/graph_data_controller.dart';
import '../../presentation/node_render_state.dart';

class CanvasTextEditor extends StatefulWidget {
  final String entityId;
  final String initialText;
  final TextStyle textStyle;
  final int? maxLines;

  const CanvasTextEditor({
    super.key,
    required this.entityId,
    required this.initialText,
    required this.textStyle,
    this.maxLines,
  });

  @override
  State<CanvasTextEditor> createState() => _CanvasTextEditorState();
}

class _CanvasTextEditorState extends State<CanvasTextEditor> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  final Logger _log = Logger('CanvasTextEditor');

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    _controller.addListener(_onTextChanged);
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
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    context.read<GraphDataController>().updateEntityTextLive(
      widget.entityId,
      _controller.text,
    );
  }

  void _submit() {
    _log.info('Committing internal edit for: ${widget.entityId}');
    context.read<GraphDataController>().commitEntityText(
      widget.entityId,
      _controller.text,
      originalText: widget.initialText,
    );
    context.read<NodeRenderState>().cancelActiveEdit();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.enter &&
              !HardwareKeyboard.instance.isShiftPressed) {
            _submit();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            _log.info('Aborted edit via Escape key.');
            context.read<NodeRenderState>().cancelActiveEdit();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Material(
        type: MaterialType.transparency,
        child: TextField(
          controller: _controller,
          focusNode: _focusNode,
          maxLines: widget.maxLines,
          textAlign: TextAlign.center,
          autofocus: true,
          cursorColor: Colors.black54,
          style: widget.textStyle,
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
          onTapOutside: (_) => _submit(),
        ),
      ),
    );
  }
}
