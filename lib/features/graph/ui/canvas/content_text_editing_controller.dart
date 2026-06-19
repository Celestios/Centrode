import 'package:flutter/material.dart';
import '../../models/models.dart';
import 'text_format_models.dart';
import 'text_ast_serializer.dart' as serializer;
import 'text_format_state_machine.dart';

export 'text_format_models.dart' show TextFormatType, FormattingSpan, isBlockFormatType;

class ContentTextEditingController extends TextEditingController {
  List<FormattingSpan> formattingSpans = [];
  final ValueNotifier<TextAlign> textAlignNotifier = ValueNotifier(TextAlign.center);
  late final TextFormatStateMachine _stateMachine;

  ContentTextEditingController() {
    _stateMachine = TextFormatStateMachine(
      formattingSpans: formattingSpans,
      textAlignNotifier: textAlignNotifier,
      notifyListeners: () => notifyListeners(),
      getText: () => text,
      setValue: (v) => value = v,
      getSelection: () => selection,
    );
  }

  void loadFromContent(Content content) {
    final result = serializer.loadFromContent(content);
    formattingSpans = result.$2;
    _stateMachine.formattingSpans = formattingSpans;
    textAlignNotifier.value = result.$3;

    super.value = TextEditingValue(
      text: result.$1,
      selection: const TextSelection.collapsed(offset: -1),
    );
  }

  Content buildContent() => serializer.buildContent(text, formattingSpans);

  void toggleFormat(TextFormatType type, {String? url}) =>
      _stateMachine.toggleFormat(type, url: url);

  void cycleFontFamily() => _stateMachine.cycleFontFamily();

  void setFontFamily(String fontFamily) => _stateMachine.setFontFamily(fontFamily);

  void cycleTextAlign() => _stateMachine.cycleTextAlign();

  void cycleTextColor() => _stateMachine.cycleTextColor();

  void toggleHighlight({String? colorUrl}) => _stateMachine.toggleHighlight(colorUrl: colorUrl);

  void cycleHighlightColor() => _stateMachine.cycleHighlightColor();

  void toggleHeading(TextFormatType headingType) => _stateMachine.toggleHeading(headingType);

  void toggleBlockFormat(TextFormatType blockType) => _stateMachine.toggleBlockFormat(blockType);

  void clearBlockFormat() => _stateMachine.clearBlockFormat();

  @override
  set value(TextEditingValue newValue) {
    final oldText = text;
    final newText = newValue.text;

    if (oldText != newText) {

      int firstDiff = 0;
      while (firstDiff < oldText.length &&
          firstDiff < newText.length &&
          oldText.codeUnitAt(firstDiff) == newText.codeUnitAt(firstDiff)) {
        firstDiff++;
      }

      int lastDiffOld = oldText.length - 1;
      int lastDiffNew = newText.length - 1;
      while (lastDiffOld >= firstDiff &&
          lastDiffNew >= firstDiff &&
          oldText.codeUnitAt(lastDiffOld) == newText.codeUnitAt(lastDiffNew)) {
        lastDiffOld--;
        lastDiffNew--;
      }

      final int deletedCount = (lastDiffOld - firstDiff + 1).clamp(0, oldText.length);
      final int insertedCount = (lastDiffNew - firstDiff + 1).clamp(0, newText.length);
      final int diff = insertedCount - deletedCount;

      final updatedSpans = <FormattingSpan>[];
      for (final span in formattingSpans) {
        if (span.end <= firstDiff) {
          updatedSpans.add(span);
        } else if (span.start >= firstDiff + deletedCount) {
          updatedSpans.add(
            span.copyWith(
              start: span.start + diff,
              end: span.end + diff,
            ),
          );
        } else {
          final newStart = span.start < firstDiff ? span.start : firstDiff;
          final newEnd = span.end > firstDiff + deletedCount
              ? span.end + diff
              : firstDiff + insertedCount;

          if (newStart < newEnd) {
            updatedSpans.add(
              span.copyWith(
                start: newStart.clamp(0, newText.length),
                end: newEnd.clamp(0, newText.length),
              ),
            );
          }
        }
      }
      formattingSpans
        ..clear()
        ..addAll(serializer.mergeAdjacentSpans(updatedSpans));
      _stateMachine.alignBlockSpans(newText);
    }

    super.value = newValue;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final String plainText = text;
    if (plainText.isEmpty) {
      return TextSpan(text: '', style: style);
    }

    final children = <TextSpan>[];
    int localOffset = 0;

    while (localOffset < plainText.length) {
      int nextBoundary = plainText.length;
      final activeTypes = <TextFormatType>[];

      for (final span in formattingSpans) {
        if (span.start <= localOffset && span.end > localOffset) {
          nextBoundary = nextBoundary < span.end ? nextBoundary : span.end;
          activeTypes.add(span.type);
        } else if (span.start > localOffset) {
          nextBoundary = nextBoundary < span.start ? nextBoundary : span.start;
        }
      }

      final textSegment = plainText.substring(localOffset, nextBoundary);
      TextStyle segmentStyle = style ?? const TextStyle();

      for (final type in activeTypes) {
        FormattingSpan? activeSpan;
        for (final span in formattingSpans) {
          if (span.type == type && span.start <= localOffset && span.end > localOffset) {
            activeSpan = span;
            break;
          }
        }

        switch (type) {
          case TextFormatType.bold:
            segmentStyle = segmentStyle.copyWith(fontWeight: FontWeight.bold);
            break;
          case TextFormatType.italic:
            segmentStyle = segmentStyle.copyWith(fontStyle: FontStyle.italic);
            break;
          case TextFormatType.underline:
            segmentStyle = segmentStyle.copyWith(decoration: TextDecoration.underline);
            break;
          case TextFormatType.heading1:
            segmentStyle = segmentStyle.copyWith(
              fontSize: (style?.fontSize ?? 12.0) * 1.4,
              fontWeight: FontWeight.bold,
            );
            break;
          case TextFormatType.heading2:
            segmentStyle = segmentStyle.copyWith(
              fontSize: (style?.fontSize ?? 12.0) * 1.25,
              fontWeight: FontWeight.bold,
            );
            break;
          case TextFormatType.heading3:
            segmentStyle = segmentStyle.copyWith(
              fontSize: (style?.fontSize ?? 12.0) * 1.15,
              fontWeight: FontWeight.bold,
            );
            break;
          case TextFormatType.link:
            segmentStyle = segmentStyle.copyWith(
              color: Colors.blueAccent,
              decoration: TextDecoration.underline,
            );
            break;
          case TextFormatType.blockquote:
            segmentStyle = segmentStyle.copyWith(
              fontStyle: FontStyle.italic,
              color: (style?.color ?? Colors.black).withValues(alpha: 0.85),
            );
            break;
          case TextFormatType.codeBlock:
            segmentStyle = segmentStyle.copyWith(
              fontFamily: 'Consolas',
              fontSize: (style?.fontSize ?? 12.0) * 0.9,
              color: (style?.color ?? Colors.black).withValues(alpha: 0.9),
            );
            break;
          case TextFormatType.highlight:
            final colorValStr = activeSpan?.url;
            final colorVal = colorValStr != null ? (int.tryParse(colorValStr) ?? 0xFFFFF200) : 0xFFFFF200;
            segmentStyle = segmentStyle.copyWith(
              backgroundColor: Color(colorVal),
            );
            break;
          case TextFormatType.textColor:
            final colorValStr = activeSpan?.url;
            final colorVal = colorValStr != null ? (int.tryParse(colorValStr) ?? 0xFF000000) : 0xFF000000;
            segmentStyle = segmentStyle.copyWith(
              color: Color(colorVal),
            );
            break;
          case TextFormatType.fontFamily:
            final fontFam = activeSpan?.url;
            if (fontFam != null && fontFam.isNotEmpty) {
              segmentStyle = segmentStyle.copyWith(
                fontFamily: fontFam == 'System' ? null : fontFam,
              );
            }
            break;
          case TextFormatType.bulletList:
          case TextFormatType.orderedList:
          case TextFormatType.textAlign:
            break;
        }
      }

      children.add(TextSpan(text: textSegment, style: segmentStyle));
      localOffset = nextBoundary;
    }

    return TextSpan(children: children, style: style);
  }
}
