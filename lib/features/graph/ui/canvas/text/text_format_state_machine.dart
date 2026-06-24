import 'package:flutter/material.dart';
import '../../../engine/config.dart';
import 'text_format_models.dart';
import 'text_ast_serializer.dart';

class TextFormatStateMachine {
  List<FormattingSpan> formattingSpans;
  final ValueNotifier<TextAlign> textAlignNotifier;
  final VoidCallback notifyListeners;
  final String Function() getText;
  final void Function(TextEditingValue) setValue;
  final TextSelection Function() getSelection;

  TextFormatStateMachine({
    required this.formattingSpans,
    required this.textAlignNotifier,
    required this.notifyListeners,
    required this.getText,
    required this.setValue,
    required this.getSelection,
  });

  void _replaceSpans(List<FormattingSpan> newSpans) {
    formattingSpans
      ..clear()
      ..addAll(newSpans);
  }

  void toggleFormat(TextFormatType type, {String? url}) {
    final selection = getSelection();
    if (selection.isCollapsed) return;

    final int start = selection.start;
    final int end = selection.end;

    final bool isAttributeType = (type == TextFormatType.highlight ||
        type == TextFormatType.textColor ||
        type == TextFormatType.fontFamily);

    if (isAttributeType) {
      final updatedSpans = <FormattingSpan>[];
      for (final span in formattingSpans) {
        if (span.type != type) {
          updatedSpans.add(span);
          continue;
        }

        if (span.end <= start || span.start >= end) {
          updatedSpans.add(span);
        } else {
          if (span.start < start) {
            updatedSpans.add(FormattingSpan(start: span.start, end: start, type: type, url: span.url));
          }
          if (span.end > end) {
            updatedSpans.add(FormattingSpan(start: end, end: span.end, type: type, url: span.url));
          }
        }
      }
      _replaceSpans(updatedSpans);

      if (url != null) {
        formattingSpans.add(FormattingSpan(start: start, end: end, type: type, url: url));
        _replaceSpans(mergeAdjacentSpans(formattingSpans));
      }
    } else {
      bool hasFormat = true;
      for (int i = start; i < end; i++) {
        bool indexCovered = false;
        for (final span in formattingSpans) {
          if (span.type == type && span.start <= i && span.end > i) {
            indexCovered = true;
            break;
          }
        }
        if (!indexCovered) {
          hasFormat = false;
          break;
        }
      }

      if (hasFormat) {
        final updatedSpans = <FormattingSpan>[];
        for (final span in formattingSpans) {
          if (span.type != type) {
            updatedSpans.add(span);
            continue;
          }

          if (span.end <= start || span.start >= end) {
            updatedSpans.add(span);
          } else {
            if (span.start < start) {
              updatedSpans.add(FormattingSpan(start: span.start, end: start, type: type, url: span.url));
            }
            if (span.end > end) {
              updatedSpans.add(FormattingSpan(start: end, end: span.end, type: type, url: span.url));
            }
          }
        }
        _replaceSpans(updatedSpans);
      } else {
        formattingSpans.add(FormattingSpan(start: start, end: end, type: type, url: url));
        _replaceSpans(mergeAdjacentSpans(formattingSpans));
      }
    }

    notifyListeners();
  }

  void cycleFontFamily() {
    final selection = getSelection();
    if (selection.isCollapsed) return;

    String? currentFont;
    for (final span in formattingSpans) {
      if (span.type == TextFormatType.fontFamily &&
          span.start <= selection.start &&
          span.end > selection.start) {
        currentFont = span.url;
        break;
      }
    }

    final fonts = AppConfig.visuals.availableFonts;
    final currentIndex = currentFont == null ? 0 : fonts.indexOf(currentFont);
    final nextIndex = (currentIndex + 1) % fonts.length;
    final nextFont = fonts[nextIndex];

    if (nextFont == 'System') {
      toggleFormat(TextFormatType.fontFamily, url: null);
    } else {
      toggleFormat(TextFormatType.fontFamily, url: nextFont);
    }
  }

  void setFontFamily(String fontFamily) {
    final selection = getSelection();
    if (selection.isCollapsed) return;
    if (fontFamily == 'System') {
      toggleFormat(TextFormatType.fontFamily, url: null);
    } else {
      toggleFormat(TextFormatType.fontFamily, url: fontFamily);
    }
  }

  void cycleTextAlign() {
    final selection = getSelection();
    final int cursor = selection.baseOffset;
    if (cursor < 0) return;

    final plainText = getText();
    final lines = plainText.split('\n');

    final int selStart = selection.isCollapsed ? cursor : selection.start;
    final int selEnd = selection.isCollapsed ? cursor : selection.end;

    final selectedLineBounds = <(int, int)>[];
    int currentOffset = 0;
    for (final line in lines) {
      final int start = currentOffset;
      final int end = start + line.length;
      if (end >= selStart && start <= selEnd) {
        selectedLineBounds.add((start, end));
      }
      currentOffset += line.length + 1;
    }

    if (selectedLineBounds.isEmpty) return;

    final firstLine = selectedLineBounds.first;
    String? currentAlign;
    for (final span in formattingSpans) {
      if (span.type == TextFormatType.textAlign &&
          span.start <= firstLine.$2 && span.end >= firstLine.$1) {
        currentAlign = span.url;
        break;
      }
    }

    final alignments = [null, 'left', 'center', 'right'];
    final currentIndex = currentAlign == null ? 0 : alignments.indexOf(currentAlign);
    final nextIndex = (currentIndex + 1) % alignments.length;
    final nextAlign = alignments[nextIndex];

    final selRangeStart = selectedLineBounds.first.$1;
    final selRangeEnd = selectedLineBounds.last.$2;

    final updatedSpans = <FormattingSpan>[];
    for (final span in formattingSpans) {
      if (span.type == TextFormatType.textAlign &&
          span.start <= selRangeEnd && span.end >= selRangeStart) {
        if (span.start < selRangeStart) {
          updatedSpans.add(FormattingSpan(start: span.start, end: selRangeStart, type: span.type, url: span.url));
        }
        if (span.end > selRangeEnd) {
          updatedSpans.add(FormattingSpan(start: selRangeEnd, end: span.end, type: span.type, url: span.url));
        }
      } else {
        updatedSpans.add(span);
      }
    }
    _replaceSpans(updatedSpans);

    if (nextAlign != null) {
      for (final (lStart, lEnd) in selectedLineBounds) {
        formattingSpans.add(FormattingSpan(start: lStart, end: lEnd, type: TextFormatType.textAlign, url: nextAlign));
      }
    }

    switch (nextAlign) {
      case 'left':
        textAlignNotifier.value = TextAlign.left;
        break;
      case 'center':
        textAlignNotifier.value = TextAlign.center;
        break;
      case 'right':
        textAlignNotifier.value = TextAlign.right;
        break;
      default:
        textAlignNotifier.value = TextAlign.center;
        break;
    }

    notifyListeners();
  }

  void cycleTextColor() {
    final selection = getSelection();
    if (selection.isCollapsed) return;

    int? currentColor;
    for (final span in formattingSpans) {
      if (span.type == TextFormatType.textColor &&
          span.start <= selection.start &&
          span.end > selection.start) {
        if (span.url != null) {
          currentColor = int.tryParse(span.url!);
        }
        break;
      }
    }

    final colors = [
      null,
      0xFFE53935,
      0xFF1E88E5,
      0xFF43A047,
      0xFFFB8C00,
      0xFF8E24AA,
    ];

    final currentIndex = currentColor == null ? 0 : colors.indexOf(currentColor);
    final nextIndex = (currentIndex + 1) % colors.length;
    final nextColor = colors[nextIndex];

    if (nextColor == null) {
      toggleFormat(TextFormatType.textColor, url: null);
    } else {
      toggleFormat(TextFormatType.textColor, url: nextColor.toString());
    }
  }

  void toggleHighlight({String? colorUrl}) {
    final selection = getSelection();
    if (selection.isCollapsed) return;

    final int start = selection.start;
    final int end = selection.end;

    bool hasHighlight = true;
    for (int i = start; i < end; i++) {
      bool indexCovered = false;
      for (final span in formattingSpans) {
        if (span.type == TextFormatType.highlight && span.start <= i && span.end > i) {
          indexCovered = true;
          break;
        }
      }
      if (!indexCovered) {
        hasHighlight = false;
        break;
      }
    }

    if (hasHighlight) {
      toggleFormat(TextFormatType.highlight, url: null);
    } else {
      final colorToApply = colorUrl ?? '0xFFFFF200';
      toggleFormat(TextFormatType.highlight, url: colorToApply);
    }
  }

  void cycleHighlightColor() {
    final selection = getSelection();
    if (selection.isCollapsed) return;

    int? currentColor;
    for (final span in formattingSpans) {
      if (span.type == TextFormatType.highlight &&
          span.start <= selection.start &&
          span.end > selection.start) {
        if (span.url != null) {
          currentColor = int.tryParse(span.url!);
        }
        break;
      }
    }

    final colors = [
      0xFFFFF200,
      0xFFFFB300,
      0xFF81C784,
      0xFF64B5F6,
      0xFFE1BEE7,
      0xFFFF8A80,
    ];

    final currentIndex = currentColor == null ? 0 : colors.indexOf(currentColor);
    final nextIndex = (currentIndex + 1) % colors.length;
    final nextColor = colors[nextIndex];

    toggleFormat(TextFormatType.highlight, url: nextColor.toString());
  }

  void toggleHeading(TextFormatType headingType) {
    toggleBlockFormat(headingType);
  }

  void toggleBlockFormat(TextFormatType blockType) {
    final selection = getSelection();
    final int cursor = selection.baseOffset;
    if (cursor < 0) return;

    final plainText = getText();
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

    TextFormatType? oldBlockType;
    for (final span in formattingSpans) {
      if (isBlockFormatType(span.type) && span.type != TextFormatType.textAlign) {
        if (span.start <= lineEnd && span.end >= lineStart) {
          oldBlockType = span.type;
          break;
        }
      }
    }

    final bool isRemoving = oldBlockType == blockType;
    final TextFormatType? newBlockType = isRemoving ? null : blockType;

    final updatedSpans = <FormattingSpan>[];
    for (final span in formattingSpans) {
      if (isBlockFormatType(span.type) && span.type != TextFormatType.textAlign) {
        if (span.start <= lineEnd && span.end >= lineStart) {
          continue;
        }
      }
      updatedSpans.add(span);
    }
    _replaceSpans(updatedSpans);

    if (newBlockType != null) {
      formattingSpans.add(FormattingSpan(start: lineStart, end: lineEnd, type: newBlockType));
    }

    _updateLinePrefix(lineStart, lineEnd, oldBlockType, newBlockType);
    notifyListeners();
  }

  void clearBlockFormat() {
    final selection = getSelection();
    final int cursor = selection.baseOffset;
    if (cursor < 0) return;

    final plainText = getText();
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

    TextFormatType? oldBlockType;
    for (final span in formattingSpans) {
      if (isBlockFormatType(span.type) && span.type != TextFormatType.textAlign) {
        if (span.start <= lineEnd && span.end >= lineStart) {
          oldBlockType = span.type;
          break;
        }
      }
    }

    if (oldBlockType == null) return;

    final updatedSpans = <FormattingSpan>[];
    for (final span in formattingSpans) {
      if (isBlockFormatType(span.type) && span.type != TextFormatType.textAlign) {
        if (span.start <= lineEnd && span.end >= lineStart) {
          continue;
        }
      }
      updatedSpans.add(span);
    }
    _replaceSpans(updatedSpans);

    _updateLinePrefix(lineStart, lineEnd, oldBlockType, null);
    notifyListeners();
  }

  void _updateLinePrefix(int lineStart, int lineEnd, TextFormatType? oldType, TextFormatType? newType) {
    final plainText = getText();
    String lineText = plainText.substring(lineStart, lineEnd);

    String contentText = lineText;
    if (oldType == TextFormatType.bulletList && lineText.startsWith('• ')) {
      contentText = lineText.substring(2);
    } else if (oldType == TextFormatType.blockquote && lineText.startsWith('> ')) {
      contentText = lineText.substring(2);
    } else if (oldType == TextFormatType.orderedList) {
      final match = RegExp(r'^\d+\.\s+').firstMatch(lineText);
      if (match != null) {
        contentText = lineText.substring(match.end);
      }
    }

    String newPrefix = '';
    if (newType == TextFormatType.bulletList) {
      newPrefix = '• ';
    } else if (newType == TextFormatType.blockquote) {
      newPrefix = '> ';
    } else if (newType == TextFormatType.orderedList) {
      final lines = plainText.substring(0, lineStart).split('\n');
      final lineIdx = lines.length;
      newPrefix = '$lineIdx. ';
    }

    final newLineText = newPrefix + contentText;
    final diff = newLineText.length - lineText.length;

    final newFullText = plainText.replaceRange(lineStart, lineEnd, newLineText);

    final oldSelection = getSelection();

    setValue(TextEditingValue(
      text: newFullText,
      selection: TextSelection(
        baseOffset: oldSelection.baseOffset == lineEnd ? lineEnd + diff : oldSelection.baseOffset.clamp(0, newFullText.length),
        extentOffset: oldSelection.extentOffset == lineEnd ? lineEnd + diff : oldSelection.extentOffset.clamp(0, newFullText.length),
      ),
    ));
  }

  void alignBlockSpans(String plainText) {
    final lines = plainText.split('\n');
    final lineBounds = <(int, int)>[];
    int currentOffset = 0;
    for (final line in lines) {
      lineBounds.add((currentOffset, currentOffset + line.length));
      currentOffset += line.length + 1;
    }

    final updatedSpans = <FormattingSpan>[];
    final occupiedLines = <int>{};

    for (final span in formattingSpans) {
      if (isBlockFormatType(span.type)) {
        int targetLineIdx = -1;
        for (int i = 0; i < lineBounds.length; i++) {
          final (lStart, lEnd) = lineBounds[i];
          if (span.start >= lStart && span.start <= lEnd) {
            targetLineIdx = i;
            break;
          }
        }

        if (targetLineIdx == -1) {
          targetLineIdx = 0;
        }

        if (occupiedLines.contains(targetLineIdx)) {
          continue;
        }

        final lineText = lines[targetLineIdx];
        bool shouldKeep = true;
        if (span.type == TextFormatType.bulletList && !lineText.startsWith('• ')) {
          shouldKeep = false;
        } else if (span.type == TextFormatType.orderedList && !RegExp(r'^\d+\.\s+').hasMatch(lineText)) {
          shouldKeep = false;
        } else if (span.type == TextFormatType.blockquote && !lineText.startsWith('> ')) {
          shouldKeep = false;
        }

        if (shouldKeep) {
          occupiedLines.add(targetLineIdx);
          final (lStart, lEnd) = lineBounds[targetLineIdx];
          updatedSpans.add(span.copyWith(start: lStart, end: lEnd));
        }
      } else {
        final clampedStart = span.start.clamp(0, plainText.length);
        final clampedEnd = span.end.clamp(0, plainText.length);
        if (clampedStart < clampedEnd) {
          updatedSpans.add(span.copyWith(start: clampedStart, end: clampedEnd));
        }
      }
    }

    for (int i = 0; i < lineBounds.length; i++) {
      if (occupiedLines.contains(i)) continue;

      final lineText = lines[i];
      final (lStart, lEnd) = lineBounds[i];

      if (lineText.startsWith('• ')) {
        occupiedLines.add(i);
        updatedSpans.add(FormattingSpan(start: lStart, end: lEnd, type: TextFormatType.bulletList));
      } else if (RegExp(r'^\d+\.\s+').hasMatch(lineText)) {
        occupiedLines.add(i);
        updatedSpans.add(FormattingSpan(start: lStart, end: lEnd, type: TextFormatType.orderedList));
      } else if (lineText.startsWith('> ')) {
        occupiedLines.add(i);
        updatedSpans.add(FormattingSpan(start: lStart, end: lEnd, type: TextFormatType.blockquote));
      }
    }

    _replaceSpans(updatedSpans);
  }
}
