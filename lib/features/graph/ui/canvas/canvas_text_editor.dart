import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:logging/logging.dart';

import '../../presentation/node_render_state.dart';
import '../../models/models.dart';
import 'content_text_editing_controller.dart';
import 'markdown_text_selection_controls.dart';

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

  final _gestureDelegate = _CanvasGestureDelegate();
  late final TextSelectionGestureDetectorBuilder _gestureBuilder;

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
    _gestureBuilder = TextSelectionGestureDetectorBuilder(delegate: _gestureDelegate);

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
      _renderState.clearBlockFormatCallback = () {
        _controller.clearBlockFormat();
      };
      _renderState.cycleFontFamilyCallback = () {
        _controller.cycleFontFamily();
      };
      _renderState.setFontFamilyCallback = (fontFamily) {
        _controller.setFontFamily(fontFamily);
      };
      _renderState.cycleTextColorCallback = () {
        _controller.cycleTextColor();
      };
      _renderState.toggleHighlightCallback = ({colorUrl}) {
        _controller.toggleHighlight(colorUrl: colorUrl);
      };
      _renderState.cycleHighlightColorCallback = () {
        _controller.cycleHighlightColor();
      };
      _renderState.cycleTextAlignCallback = () {
        _controller.cycleTextAlign();
        _syncCurrentTextAlign(_controller.value);
      };

      _syncCurrentTextAlign(_controller.value);
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
    _renderState.clearBlockFormatCallback = null;
    _renderState.cycleFontFamilyCallback = null;
    _renderState.cycleTextColorCallback = null;
    _renderState.toggleHighlightCallback = null;
    _renderState.cycleHighlightColorCallback = null;

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
      _syncCurrentTextAlign(currentValue);
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

  void _syncCurrentTextAlign(TextEditingValue value) {
    final cursor = value.selection.baseOffset;
    if (cursor < 0) return;

    final plainText = value.text;
    int lineStart = 0;
    int lineEnd = plainText.length;

    final lines = plainText.split('\n');
    int currentOffset = 0;
    for (final line in lines) {
      final int start = currentOffset;
      final int end = start + line.length;
      if (cursor >= start && cursor <= end) {
        lineStart = start;
        lineEnd = end;
        break;
      }
      currentOffset += line.length + 1;
    }

    TextAlign found = TextAlign.center;
    for (final span in _controller.formattingSpans) {
      if (span.type == TextFormatType.textAlign &&
          span.start <= lineEnd && span.end >= lineStart) {
        switch (span.url) {
          case 'left':
            found = TextAlign.left;
            break;
          case 'center':
            found = TextAlign.center;
            break;
          case 'right':
            found = TextAlign.right;
            break;
        }
        break;
      }
    }

    _renderState.currentTextAlignNotifier.value = found;
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

  void _insertTab() {
    final textVal = _controller.value;
    final text = textVal.text;
    final selection = textVal.selection;

    final int start = selection.start;
    final int end = selection.end;

    if (start < 0) return;

    final newText = text.replaceRange(start, end, '    ');
    final newSelection = TextSelection.collapsed(offset: start + 4);

    _controller.value = TextEditingValue(
      text: newText,
      selection: newSelection,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ValueListenableBuilder<TextAlign>(
      valueListenable: _controller.textAlignNotifier,
      builder: (context, textAlign, _) {
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
                if (event.logicalKey == LogicalKeyboardKey.tab) {
                  _insertTab();
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
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              child: Theme(
                data: Theme.of(context).copyWith(
                  textSelectionTheme: const TextSelectionThemeData(
                    selectionColor: Color(0x602196F3),
                    selectionHandleColor: Color(0xFF2196F3),
                    cursorColor: Color(0xFF2196F3),
                  ),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  child: _gestureBuilder.buildGestureDetector(
                    behavior: HitTestBehavior.translucent,
                    child: EditableText(
                      key: _gestureDelegate.editableTextKey,
                      controller: _controller,
                      focusNode: _focusNode,
                      maxLines: widget.maxLines,
                      minLines: widget.maxLines == null ? 1 : null,
                      expands: false,
                      textAlign: textAlign,
                      textDirection: TextDirection.ltr,
                      autofocus: true,
                      cursorColor: const Color(0xFF2196F3),
                      backgroundCursorColor: Colors.grey,
                      selectionColor: const Color(0x602196F3),
                      style: widget.textStyle,
                      strutStyle: StrutStyle.disabled,
                      selectionControls: MarkdownTextSelectionControls(),
                      showSelectionHandles: false,
                      magnifierConfiguration: TextMagnifierConfiguration.disabled,
                      onTapOutside: (event) {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CanvasGestureDelegate implements TextSelectionGestureDetectorBuilderDelegate {
  @override
  final GlobalKey<EditableTextState> editableTextKey = GlobalKey<EditableTextState>();

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => true;
}
