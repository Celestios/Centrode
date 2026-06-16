import 'package:flutter/material.dart';
import '../../models/models.dart';

enum TextFormatType {
  bold,
  italic,
  underline,
  heading1,
  heading2,
  heading3,
  link,
  blockquote,
  codeBlock,
  bulletList,
  orderedList,
  highlight,
  textColor,
  fontFamily
}

class FormattingSpan {
  int start;
  int end;
  final TextFormatType type;
  final String? url;

  FormattingSpan({
    required this.start,
    required this.end,
    required this.type,
    this.url,
  });

  FormattingSpan copyWith({int? start, int? end, String? url}) {
    return FormattingSpan(
      start: start ?? this.start,
      end: end ?? this.end,
      type: type,
      url: url ?? this.url,
    );
  }

  @override
  String toString() => 'FormattingSpan($type, $start-$end)';
}

class ContentTextEditingController extends TextEditingController {
  List<FormattingSpan> formattingSpans = [];

  ContentTextEditingController();

  /// Loads content from the AST structure into plain text and sets up styling spans.
  void loadFromContent(Content content) {
    final buffer = StringBuffer();
    final newSpans = <FormattingSpan>[];

    for (int i = 0; i < content.blocks.length; i++) {
      final block = content.blocks[i];
      
      String prefix = '';
      if (block.blockType == BlockType.bulletList) {
        prefix = '• ';
      } else if (block.blockType == BlockType.orderedList) {
        prefix = '${i + 1}. ';
      } else if (block.blockType == BlockType.blockquote) {
        prefix = '> ';
      }

      final int blockStart = buffer.length;
      buffer.write(prefix);

      final int contentStart = blockStart + prefix.length;
      int localOffset = contentStart;

      for (final inline in block.content) {
        if (inline.inlineType == InlineType.hardBreak) {
          buffer.write('\n');
          localOffset += 1;
          continue;
        }

        final int inlineStart = localOffset;
        buffer.write(inline.text);
        final int inlineEnd = localOffset + inline.text.length;
        localOffset = inlineEnd;

        if (inline.marks != null) {
          for (final mark in inline.marks!) {
            TextFormatType? formatType;
            String? href;
            switch (mark.markType) {
              case MarkType.bold:
                formatType = TextFormatType.bold;
                break;
              case MarkType.italic:
                formatType = TextFormatType.italic;
                break;
              case MarkType.underline:
                formatType = TextFormatType.underline;
                break;
              case MarkType.link:
                formatType = TextFormatType.link;
                href = mark.attrs?.href;
                break;
              case MarkType.highlight:
                formatType = TextFormatType.highlight;
                href = mark.attrs?.color?.toString();
                break;
              case MarkType.textColor:
                formatType = TextFormatType.textColor;
                href = mark.attrs?.color?.toString();
                break;
              case MarkType.fontFamily:
                formatType = TextFormatType.fontFamily;
                href = mark.attrs?.fontFamily;
                break;
              default:
                break;
            }
            if (formatType != null) {
              newSpans.add(
                FormattingSpan(
                  start: inlineStart,
                  end: inlineEnd,
                  type: formatType,
                  url: href,
                ),
              );
            }
          }
        }
      }

      final int blockEnd = buffer.length;

      // Map block type to heading/block format spans
      if (block.blockType == BlockType.heading) {
        final level = block.attrs?.level ?? 1;
        final type = level == 1
            ? TextFormatType.heading1
            : (level == 2 ? TextFormatType.heading2 : TextFormatType.heading3);
        newSpans.add(FormattingSpan(start: blockStart, end: blockEnd, type: type));
      } else if (block.blockType == BlockType.blockquote) {
        newSpans.add(FormattingSpan(start: blockStart, end: blockEnd, type: TextFormatType.blockquote));
      } else if (block.blockType == BlockType.codeBlock) {
        newSpans.add(FormattingSpan(start: blockStart, end: blockEnd, type: TextFormatType.codeBlock));
      } else if (block.blockType == BlockType.bulletList) {
        newSpans.add(FormattingSpan(start: blockStart, end: blockEnd, type: TextFormatType.bulletList));
      } else if (block.blockType == BlockType.orderedList) {
        newSpans.add(FormattingSpan(start: blockStart, end: blockEnd, type: TextFormatType.orderedList));
      }

      if (i < content.blocks.length - 1) {
        buffer.write('\n');
      }
    }

    formattingSpans = _mergeAdjacentSpans(newSpans);
    super.value = TextEditingValue(
      text: buffer.toString(),
      selection: const TextSelection.collapsed(offset: -1),
    );
  }

  /// Merges adjacent spans of the same style type to clean up the span list.
  List<FormattingSpan> _mergeAdjacentSpans(List<FormattingSpan> spans) {
    if (spans.isEmpty) return [];
    spans.sort((a, b) => a.start.compareTo(b.start));

    final merged = <FormattingSpan>[];
    for (final span in spans) {
      if (merged.isEmpty) {
        merged.add(span);
        continue;
      }
      final last = merged.last;
      if (last.type == span.type && last.url == span.url && last.end >= span.start) {
        last.end = last.end > span.end ? last.end : span.end;
      } else {
        merged.add(span);
      }
    }
    return merged;
  }

  /// Builds a structured AST Content object from the current plain text and styling spans.
  Content buildContent() {
    final String plainText = text;
    if (plainText.isEmpty) {
      return const Content(text: '', blocks: []);
    }

    final lines = plainText.split('\n');
    final blocks = <ContentBlock>[];
    int currentOffset = 0;

    for (final line in lines) {
      final int lineStart = currentOffset;
      final int lineEnd = lineStart + line.length;

      // Determine block type
      BlockType blockType = BlockType.paragraph;
      BlockAttrs? blockAttrs;
      String contentLine = line;
      int prefixLength = 0;

      for (final span in formattingSpans) {
        if (span.start <= lineStart && span.end >= lineEnd) {
          if (span.type == TextFormatType.heading1) {
            blockType = BlockType.heading;
            blockAttrs = const BlockAttrs(level: 1);
            break;
          } else if (span.type == TextFormatType.heading2) {
            blockType = BlockType.heading;
            blockAttrs = const BlockAttrs(level: 2);
            break;
          } else if (span.type == TextFormatType.heading3) {
            blockType = BlockType.heading;
            blockAttrs = const BlockAttrs(level: 3);
            break;
          } else if (span.type == TextFormatType.blockquote) {
            blockType = BlockType.blockquote;
            if (line.startsWith('> ')) {
              contentLine = line.substring(2);
              prefixLength = 2;
            }
            break;
          } else if (span.type == TextFormatType.codeBlock) {
            blockType = BlockType.codeBlock;
            break;
          } else if (span.type == TextFormatType.bulletList) {
            blockType = BlockType.bulletList;
            if (line.startsWith('• ')) {
              contentLine = line.substring(2);
              prefixLength = 2;
            }
            break;
          } else if (span.type == TextFormatType.orderedList) {
            blockType = BlockType.orderedList;
            final match = RegExp(r'^\d+\.\s+').firstMatch(line);
            if (match != null) {
              contentLine = line.substring(match.end);
              prefixLength = match.end;
            }
            break;
          }
        }
      }

      // If line is empty (or prefix only), add an empty block
      if (contentLine.isEmpty) {
        blocks.add(ContentBlock(blockType: blockType, content: [], attrs: blockAttrs));
        currentOffset += line.length + 1; // accounting for \n
        continue;
      }

      // Find all marks/formatting ranges that overlap with this line content
      final inlineElements = <InlineElement>[];
      int localOffset = 0;

      while (localOffset < contentLine.length) {
        final int globalIdx = lineStart + prefixLength + localOffset;

        // Find the next span boundary or end of line content
        int nextBoundary = contentLine.length;
        final activeMarks = <TextMark>[];

        for (final span in formattingSpans) {
          if (span.type == TextFormatType.heading1 ||
              span.type == TextFormatType.heading2 ||
              span.type == TextFormatType.heading3 ||
              span.type == TextFormatType.blockquote ||
              span.type == TextFormatType.codeBlock ||
              span.type == TextFormatType.bulletList ||
              span.type == TextFormatType.orderedList) {
            continue; // Block-level, not inline marks
          }

          if (span.start <= globalIdx && span.end > globalIdx) {
            // Span is active at globalIdx
            final int relativeEnd = span.end - lineStart - prefixLength;
            nextBoundary = nextBoundary < relativeEnd ? nextBoundary : relativeEnd;
            
            // Map type to MarkType
            MarkType? markType;
            MarkAttrs? attrs;
            switch (span.type) {
              case TextFormatType.bold:
                markType = MarkType.bold;
                break;
              case TextFormatType.italic:
                markType = MarkType.italic;
                break;
              case TextFormatType.underline:
                markType = MarkType.underline;
                break;
              case TextFormatType.link:
                markType = MarkType.link;
                attrs = MarkAttrs(href: span.url ?? '');
                break;
              case TextFormatType.highlight:
                markType = MarkType.highlight;
                if (span.url != null) {
                  attrs = MarkAttrs(color: int.tryParse(span.url!));
                }
                break;
              case TextFormatType.textColor:
                markType = MarkType.textColor;
                if (span.url != null) {
                  attrs = MarkAttrs(color: int.tryParse(span.url!));
                }
                break;
              case TextFormatType.fontFamily:
                markType = MarkType.fontFamily;
                attrs = MarkAttrs(fontFamily: span.url);
                break;
              default:
                break;
            }
            if (markType != null) {
              activeMarks.add(TextMark(markType: markType, attrs: attrs));
            }
          } else if (span.start > globalIdx && span.start < (lineStart + prefixLength + contentLine.length)) {
            // Span starts later on this line content
            final int relativeStart = span.start - lineStart - prefixLength;
            nextBoundary = nextBoundary < relativeStart ? nextBoundary : relativeStart;
          }
        }

        final segmentText = contentLine.substring(localOffset, nextBoundary);
        if (segmentText.isNotEmpty) {
          inlineElements.add(
            InlineElement(
              inlineType: InlineType.text,
              text: segmentText,
              marks: activeMarks.isEmpty ? null : activeMarks,
            ),
          );
        }
        localOffset = nextBoundary;
      }

      blocks.add(
        ContentBlock(
          blockType: blockType,
          content: inlineElements,
          attrs: blockAttrs,
        ),
      );

      currentOffset += line.length + 1; // line text + \n
    }

    return Content(text: plainText, blocks: blocks);
  }

  /// Toggles the formatting style on the selected text range.
  void toggleFormat(TextFormatType type, {String? url}) {
    if (selection.isCollapsed) return;

    final int start = selection.start;
    final int end = selection.end;

    final bool isAttributeType = (type == TextFormatType.highlight ||
        type == TextFormatType.textColor ||
        type == TextFormatType.fontFamily);

    // If it's an attribute type, we always clear any existing overlapping spans of this type first
    // so we can apply the new attribute value cleanly.
    if (isAttributeType) {
      final updatedSpans = <FormattingSpan>[];
      for (final span in formattingSpans) {
        if (span.type != type) {
          updatedSpans.add(span);
          continue;
        }

        // Split or shrink the span
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
      formattingSpans = updatedSpans;

      // If url is not null, apply the new formatting span
      if (url != null) {
        formattingSpans.add(FormattingSpan(start: start, end: end, type: type, url: url));
        formattingSpans = _mergeAdjacentSpans(formattingSpans);
      }
    } else {
      // Normal toggling logic (bold, italic, etc.)
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
        // Remove formatting from the selection range
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
        formattingSpans = updatedSpans;
      } else {
        // Add formatting: merge overlapping spans of same type
        formattingSpans.add(FormattingSpan(start: start, end: end, type: type, url: url));
        formattingSpans = _mergeAdjacentSpans(formattingSpans);
      }
    }

    notifyListeners();
  }

  void cycleFontFamily() {
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

    final fonts = ['System', 'Inter', 'Roboto', 'Consolas'];
    final currentIndex = currentFont == null ? 0 : fonts.indexOf(currentFont);
    final nextIndex = (currentIndex + 1) % fonts.length;
    final nextFont = fonts[nextIndex];

    if (nextFont == 'System') {
      toggleFormat(TextFormatType.fontFamily, url: null);
    } else {
      toggleFormat(TextFormatType.fontFamily, url: nextFont);
    }
  }

  void cycleTextColor() {
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
      null, // Default
      0xFFE53935, // Red
      0xFF1E88E5, // Blue
      0xFF43A047, // Green
      0xFFFB8C00, // Orange
      0xFF8E24AA, // Purple
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
      0xFFFFF200, // Yellow
      0xFFFFB300, // Amber
      0xFF81C784, // Light Green
      0xFF64B5F6, // Light Blue
      0xFFE1BEE7, // Lavender
      0xFFFF8A80, // Soft Red
    ];

    final currentIndex = currentColor == null ? 0 : colors.indexOf(currentColor);
    final nextIndex = (currentIndex + 1) % colors.length;
    final nextColor = colors[nextIndex];

    toggleFormat(TextFormatType.highlight, url: nextColor.toString());
  }

  /// Sets the block level heading for the line containing the current cursor.
  void toggleHeading(TextFormatType headingType) {
    toggleBlockFormat(headingType);
  }

  /// Toggles block-level formatting for the line containing the current cursor.
  void toggleBlockFormat(TextFormatType blockType) {
    final int cursor = selection.baseOffset;
    if (cursor < 0) return;

    final plainText = text;
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

    // Check if the current line already has a block type
    TextFormatType? oldBlockType;
    for (final span in formattingSpans) {
      if (span.type == TextFormatType.heading1 ||
          span.type == TextFormatType.heading2 ||
          span.type == TextFormatType.heading3 ||
          span.type == TextFormatType.blockquote ||
          span.type == TextFormatType.codeBlock ||
          span.type == TextFormatType.bulletList ||
          span.type == TextFormatType.orderedList) {
        if (span.start <= lineEnd && span.end >= lineStart) {
          oldBlockType = span.type;
          break;
        }
      }
    }

    final bool isRemoving = oldBlockType == blockType;
    final TextFormatType? newBlockType = isRemoving ? null : blockType;

    // Remove old block formatting spans on this line
    final updatedSpans = <FormattingSpan>[];
    for (final span in formattingSpans) {
      if (span.type == TextFormatType.heading1 ||
          span.type == TextFormatType.heading2 ||
          span.type == TextFormatType.heading3 ||
          span.type == TextFormatType.blockquote ||
          span.type == TextFormatType.codeBlock ||
          span.type == TextFormatType.bulletList ||
          span.type == TextFormatType.orderedList) {
        if (span.start <= lineEnd && span.end >= lineStart) {
          continue; // Remove it
        }
      }
      updatedSpans.add(span);
    }
    formattingSpans = updatedSpans;

    if (newBlockType != null) {
      formattingSpans.add(FormattingSpan(start: lineStart, end: lineEnd, type: newBlockType));
    }

    // Update prefix and adjust text
    _updateLinePrefix(lineStart, lineEnd, oldBlockType, newBlockType);
    notifyListeners();
  }

  /// Clears block-level formatting on the line containing the current cursor, converting it to a normal paragraph.
  void clearBlockFormat() {
    final int cursor = selection.baseOffset;
    if (cursor < 0) return;

    final plainText = text;
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

    // Find if the current line has a block type
    TextFormatType? oldBlockType;
    for (final span in formattingSpans) {
      if (span.type == TextFormatType.heading1 ||
          span.type == TextFormatType.heading2 ||
          span.type == TextFormatType.heading3 ||
          span.type == TextFormatType.blockquote ||
          span.type == TextFormatType.codeBlock ||
          span.type == TextFormatType.bulletList ||
          span.type == TextFormatType.orderedList) {
        if (span.start <= lineEnd && span.end >= lineStart) {
          oldBlockType = span.type;
          break;
        }
      }
    }

    if (oldBlockType == null) return; // Already normal text

    // Remove old block formatting spans on this line
    final updatedSpans = <FormattingSpan>[];
    for (final span in formattingSpans) {
      if (span.type == TextFormatType.heading1 ||
          span.type == TextFormatType.heading2 ||
          span.type == TextFormatType.heading3 ||
          span.type == TextFormatType.blockquote ||
          span.type == TextFormatType.codeBlock ||
          span.type == TextFormatType.bulletList ||
          span.type == TextFormatType.orderedList) {
        if (span.start <= lineEnd && span.end >= lineStart) {
          continue; // Remove it
        }
      }
      updatedSpans.add(span);
    }
    formattingSpans = updatedSpans;

    // Update prefix and adjust text
    _updateLinePrefix(lineStart, lineEnd, oldBlockType, null);
    notifyListeners();
  }

  void _updateLinePrefix(int lineStart, int lineEnd, TextFormatType? oldType, TextFormatType? newType) {
    final plainText = text;
    String lineText = plainText.substring(lineStart, lineEnd);

    // 1. Strip old prefix if any
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

    // 2. Prepend new prefix
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

    // Replace in full text
    final newFullText = plainText.replaceRange(lineStart, lineEnd, newLineText);

    final oldSelection = selection;

    // Update value (triggers setter which shifts other spans and aligns them)
    value = TextEditingValue(
      text: newFullText,
      selection: TextSelection(
        baseOffset: oldSelection.baseOffset == lineEnd ? lineEnd + diff : oldSelection.baseOffset.clamp(0, newFullText.length),
        extentOffset: oldSelection.extentOffset == lineEnd ? lineEnd + diff : oldSelection.extentOffset.clamp(0, newFullText.length),
      ),
    );
  }

  void _alignBlockSpans(String plainText) {
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
      if (span.type == TextFormatType.heading1 ||
          span.type == TextFormatType.heading2 ||
          span.type == TextFormatType.heading3 ||
          span.type == TextFormatType.blockquote ||
          span.type == TextFormatType.codeBlock ||
          span.type == TextFormatType.bulletList ||
          span.type == TextFormatType.orderedList) {

        // Find which line contains the span's start
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
          continue; // Clear duplicates/conflicts
        }

        // Check if the prefix has been deleted for prefix-based blocks
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
        // Inline spans
        final clampedStart = span.start.clamp(0, plainText.length);
        final clampedEnd = span.end.clamp(0, plainText.length);
        if (clampedStart < clampedEnd) {
          updatedSpans.add(span.copyWith(start: clampedStart, end: clampedEnd));
        }
      }
    }

    // Auto-detect typed prefixes on lines that do not have any block span
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

    formattingSpans = updatedSpans;
  }

  @override
  set value(TextEditingValue newValue) {
    final oldText = text;
    final newText = newValue.text;

    if (oldText != newText) {
      // Compute text delta
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
          // Unchanged span before edit
          updatedSpans.add(span);
        } else if (span.start >= firstDiff + deletedCount) {
          // Span after edit, shift position
          updatedSpans.add(
            span.copyWith(
              start: span.start + diff,
              end: span.end + diff,
            ),
          );
        } else {
          // Overlapping span
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
      formattingSpans = _mergeAdjacentSpans(updatedSpans);
      _alignBlockSpans(newText);
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
            break;
        }
      }

      children.add(TextSpan(text: textSegment, style: segmentStyle));
      localOffset = nextBoundary;
    }

    return TextSpan(children: children, style: style);
  }
}
