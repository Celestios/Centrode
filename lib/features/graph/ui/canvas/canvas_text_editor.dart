import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';

import '../../presentation/node_render_state.dart';
import '../../models/models.dart';
import 'content_text_editing_controller.dart';

class CanvasTextEditor extends StatefulWidget {
  final String entityId;
  final Content content;
  final TextStyle textStyle;
  final int? maxLines;

  const CanvasTextEditor({
    super.key,
    required this.entityId,
    required this.content,
    required this.textStyle,
    this.maxLines,
  });

  @override
  State<CanvasTextEditor> createState() => _CanvasTextEditorState();
}

class _CanvasTextEditorState extends State<CanvasTextEditor> {
  late final ContentTextEditingController _controller;
  late final FocusNode _focusNode;
  final Logger _log = Logger('CanvasTextEditor');
  bool _isCommitted = false;
  bool _isAborted = false;

  // Cache dependencies to survive unmount lookups
  late NodeRenderState _renderState;

  // Track the last value to detect pure selection drags
  TextEditingValue _lastValue = TextEditingValue.empty;

  @override
  void initState() {
    super.initState();
    _controller = ContentTextEditingController();
    _controller.loadFromContent(widget.content);
    _lastValue = _controller.value;

    _controller.addListener(_onControllerChanged);
    _focusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );

      _renderState.applyFormatCallback = (type, {url}) {
        _controller.toggleFormat(type as TextFormatType, url: url);
      };
      _renderState.toggleHeadingCallback = (type) {
        _controller.toggleHeading(type as TextFormatType);
      };
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _renderState = context.watch<NodeRenderState>();
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);

    if (!_isCommitted && !_isAborted) {
      _log.info('Committing final edit on dispose for: ${widget.entityId}');
      try {
        _renderState.commitEntityText(
          widget.entityId,
          _controller.buildContent(),
          originalTextOrContent: widget.content,
        );
      } catch (e) {
        _log.severe('Failed to commit text on dispose: $e');
      }
    }

    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onControllerChanged() {
    final currentValue = _controller.value;
    final selectionChanged = currentValue.selection != _lastValue.selection;

    if (selectionChanged) {
      _renderState.updateActiveTextSelection(currentValue.selection);
    }

    // Only update live if the text actually changed (skips mouse drags/highlighting)
    final onlySelectionChanged =
        (currentValue.text == _lastValue.text) &&
        (currentValue.composing == _lastValue.composing) &&
        selectionChanged;

    if (!onlySelectionChanged) {
      _renderState.updateEntityTextLive(
        widget.entityId,
        _controller.buildContent(),
      );
    }

    _lastValue = currentValue;
  }

  void _submit() {
    if (_isCommitted) return;
    _isCommitted = true;
    _log.info('Committing internal edit for: ${widget.entityId}');
    _renderState.cancelActiveEdit();
    _renderState.commitEntityText(
      widget.entityId,
      _controller.buildContent(),
      originalTextOrContent: widget.content,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFieldTapRegion(
      child: Focus(
        canRequestFocus: false,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.enter &&
                !HardwareKeyboard.instance.isShiftPressed) {
              _submit();
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.escape) {
              _isAborted = true;
              _renderState.cancelActiveEdit();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: const Color(0xFF2196F3).withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          child: Theme(
            data: Theme.of(context).copyWith(
              textSelectionTheme: const TextSelectionThemeData(
                selectionColor: Color(0x602196F3), // Highly visible selection highlight
                selectionHandleColor: Color(0xFF2196F3),
                cursorColor: Color(0xFF2196F3),
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                maxLines: widget.maxLines,
                minLines: widget.maxLines == null ? 1 : null,
                expands: false,
                textAlign: TextAlign.center,
                textAlignVertical: TextAlignVertical.center,
                autofocus: true,
                cursorColor: const Color(0xFF2196F3),
                style: widget.textStyle,
                strutStyle: StrutStyle.fromTextStyle(
                  widget.textStyle,
                  forceStrutHeight: true,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
                onTapOutside: (event) {
                  // Intercepted to prevent automatic focus loss
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
