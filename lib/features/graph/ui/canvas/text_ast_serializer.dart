import 'package:flutter/material.dart';
import '../../models/models.dart';
import 'text_format_models.dart';

/// Merges adjacent spans of the same style type to clean up the span list.
List<FormattingSpan> mergeAdjacentSpans(List<FormattingSpan> spans) {
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

/// Loads content from the AST structure into plain text and sets up styling spans.
/// Returns (plainText, spans, textAlign).
(String, List<FormattingSpan>, TextAlign) loadFromContent(Content content) {
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

    if (block.attrs?.textAlign != null) {
      newSpans.add(FormattingSpan(start: blockStart, end: blockEnd, type: TextFormatType.textAlign, url: block.attrs!.textAlign));
    }

    if (i < content.blocks.length - 1) {
      buffer.write('\n');
    }
  }

  final mergedSpans = mergeAdjacentSpans(newSpans);

  TextAlign textAlign = TextAlign.center;
  for (final span in mergedSpans) {
    if (span.type == TextFormatType.textAlign) {
      switch (span.url) {
        case 'left':
          textAlign = TextAlign.left;
          break;
        case 'center':
          textAlign = TextAlign.center;
          break;
        case 'right':
          textAlign = TextAlign.right;
          break;
      }
      break;
    }
  }

  return (buffer.toString(), mergedSpans, textAlign);
}

/// Builds a structured AST Content object from plain text and styling spans.
Content buildContent(String plainText, List<FormattingSpan> formattingSpans) {
  if (plainText.isEmpty) {
    return const Content(text: '', blocks: []);
  }

  final lines = plainText.split('\n');
  final blocks = <ContentBlock>[];
  int currentOffset = 0;

  for (final line in lines) {
    final int lineStart = currentOffset;
    final int lineEnd = lineStart + line.length;

    BlockType blockType = BlockType.paragraph;
    BlockAttrs? blockAttrs;
    String? textAlign;
    String contentLine = line;
    int prefixLength = 0;

    for (final span in formattingSpans) {
      if (span.start <= lineStart && span.end >= lineEnd) {
        if (span.type == TextFormatType.textAlign) {
          textAlign = span.url;
        }
      }
    }

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

    if (contentLine.isEmpty) {
      BlockAttrs? attrs;
      if (blockAttrs != null && textAlign != null) {
        attrs = BlockAttrs(level: blockAttrs.level, language: blockAttrs.language, textAlign: textAlign);
      } else {
        attrs = blockAttrs ?? (textAlign != null ? BlockAttrs(textAlign: textAlign) : null);
      }
      blocks.add(ContentBlock(blockType: blockType, content: [], attrs: attrs));
      currentOffset += line.length + 1;
      continue;
    }

    final inlineElements = <InlineElement>[];
    int localOffset = 0;

    while (localOffset < contentLine.length) {
      final int globalIdx = lineStart + prefixLength + localOffset;

      int nextBoundary = contentLine.length;
      final activeMarks = <TextMark>[];

      for (final span in formattingSpans) {
        if (isBlockFormatType(span.type)) {
          continue;
        }

        if (span.start <= globalIdx && span.end > globalIdx) {
          final int relativeEnd = span.end - lineStart - prefixLength;
          nextBoundary = nextBoundary < relativeEnd ? nextBoundary : relativeEnd;
          
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
        attrs: (() {
          if (blockAttrs != null && textAlign != null) {
            return BlockAttrs(level: blockAttrs.level, language: blockAttrs.language, textAlign: textAlign);
          }
          return blockAttrs ?? (textAlign != null ? BlockAttrs(textAlign: textAlign) : null);
        })(),
      ),
    );

    currentOffset += line.length + 1;
  }

  return Content(text: plainText, blocks: blocks);
}
