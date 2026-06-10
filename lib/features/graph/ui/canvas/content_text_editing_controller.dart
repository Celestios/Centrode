import 'package:flutter/material.dart';
import '../../models/models.dart';

enum TextFormatType {
  bold,
  italic,
  underline,
  heading1,
  heading2,
  heading3,
  link
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
      final int blockStart = buffer.length;

      // Add block prefix/prefix markers to text if needed, but we edit plain text
      for (final inline in block.content) {
        if (inline.inlineType == InlineType.hardBreak) {
          buffer.write('\n');
          continue;
        }

        final int inlineStart = buffer.length;
        buffer.write(inline.text);
        final int inlineEnd = buffer.length;

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

      // Map block type to heading format spans
      if (block.blockType == BlockType.heading) {
        final level = block.attrs?.level ?? 1;
        final type = level == 1
            ? TextFormatType.heading1
            : (level == 2 ? TextFormatType.heading2 : TextFormatType.heading3);
        newSpans.add(FormattingSpan(start: blockStart, end: blockEnd, type: type));
      }

      if (i < content.blocks.length - 1) {
        buffer.write('\n');
      }
    }

    formattingSpans = _mergeAdjacentSpans(newSpans);
    text = buffer.toString();
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

      // Determine if this line/block is a heading
      BlockType blockType = BlockType.paragraph;
      BlockAttrs? blockAttrs;

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
          }
        }
      }

      // If line is empty, add an empty paragraph block
      if (line.isEmpty) {
        blocks.add(ContentBlock(blockType: blockType, content: [], attrs: blockAttrs));
        currentOffset += 1; // accounting for \n
        continue;
      }

      // Find all marks/formatting ranges that overlap with this line
      final inlineElements = <InlineElement>[];
      int localOffset = 0;

      while (localOffset < line.length) {
        final int globalIdx = lineStart + localOffset;

        // Find the next span boundary or end of line
        int nextBoundary = line.length;
        final activeMarks = <TextMark>[];

        for (final span in formattingSpans) {
          if (span.type == TextFormatType.heading1 ||
              span.type == TextFormatType.heading2 ||
              span.type == TextFormatType.heading3) {
            continue; // Headings are block-level, not inline marks
          }

          if (span.start <= globalIdx && span.end > globalIdx) {
            // Span is active at globalIdx
            nextBoundary = nextBoundary < (span.end - lineStart)
                ? nextBoundary
                : (span.end - lineStart);
            
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
              default:
                break;
            }
            if (markType != null) {
              activeMarks.add(TextMark(markType: markType, attrs: attrs));
            }
          } else if (span.start > globalIdx && span.start < lineEnd) {
            // Span starts later on this line
            nextBoundary = nextBoundary < (span.start - lineStart)
                ? nextBoundary
                : (span.start - lineStart);
          }
        }

        final segmentText = line.substring(localOffset, nextBoundary);
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

    // Check if format is already fully present on selection
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
    } else {
      // Add formatting: merge overlapping spans of same type
      formattingSpans.add(FormattingSpan(start: start, end: end, type: type, url: url));
      formattingSpans = _mergeAdjacentSpans(formattingSpans);
    }

    notifyListeners();
  }

  /// Sets the block level heading for the line containing the current cursor.
  void toggleHeading(TextFormatType headingType) {
    final int cursor = selection.baseOffset;
    if (cursor < 0) return;

    // Find line boundaries containing cursor
    final plainText = text;
    int lineStart = 0;
    int lineEnd = plainText.length;

    final lines = plainText.split('\n');
    int currentOffset = 0;
    for (final line in lines) {
      final int start = currentOffset;
      final int end = start + line.length;
      if (cursor >= start && cursor <= end + 1) {
        lineStart = start;
        lineEnd = end;
        break;
      }
      currentOffset += line.length + 1;
    }

    // Check if the current line already has the heading type
    bool hasHeading = false;
    final updatedSpans = <FormattingSpan>[];
    for (final span in formattingSpans) {
      if (span.type == TextFormatType.heading1 ||
          span.type == TextFormatType.heading2 ||
          span.type == TextFormatType.heading3) {
        if (span.start == lineStart && span.end == lineEnd && span.type == headingType) {
          hasHeading = true;
          continue; // Remove it
        }
        if (span.start == lineStart && span.end == lineEnd) {
          continue; // Remove other heading types on same line
        }
      }
      updatedSpans.add(span);
    }

    if (!hasHeading) {
      updatedSpans.add(FormattingSpan(start: lineStart, end: lineEnd, type: headingType));
    }

    formattingSpans = updatedSpans;
    notifyListeners();
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
        }
      }

      children.add(TextSpan(text: textSegment, style: segmentStyle));
      localOffset = nextBoundary;
    }

    return TextSpan(children: children, style: style);
  }
}
