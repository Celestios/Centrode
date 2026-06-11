/// Fluent builder for constructing Content with blocks.
/// Provides a convenient API for creating formatted document content.
///
/// Example:
/// ```dart
/// final content = ContentBuilder()
///   .heading('Meeting Notes', level: 2)
///   .paragraph('Discussed ')
///   .paragraph('important', marks: [TextMark.bold()])
///   .paragraph(' topics.')
///   .build();
/// ```
library;

import 'package:mycelium/src/rust/domain/contents.dart';

/// Fluent builder for constructing Content with blocks.
class ContentBuilder {
  final List<ContentBlock> _blocks = [];

  /// Add a paragraph with optional formatting marks.
  ContentBuilder paragraph(String text, {List<TextMark>? marks}) {
    _blocks.add(
      ContentBlock(
        blockType: BlockType.paragraph,
        content: [
          InlineElement(inlineType: InlineType.text, text: text, marks: marks),
        ],
      ),
    );
    return this;
  }

  /// Add a paragraph with multiple inline segments.
  /// Each segment can have different formatting.
  ContentBuilder paragraphSegments(List<InlineElement> segments) {
    _blocks.add(
      ContentBlock(blockType: BlockType.paragraph, content: segments),
    );
    return this;
  }

  /// Add a heading with the specified level (1-6).
  ContentBuilder heading(String text, {required int level}) {
    _blocks.add(
      ContentBlock(
        blockType: BlockType.heading,
        content: [InlineElement(inlineType: InlineType.text, text: text)],
        attrs: BlockAttrs(level: level),
      ),
    );
    return this;
  }

  /// Add a bullet list item.
  ContentBuilder bulletList(String text, {List<TextMark>? marks}) {
    _blocks.add(
      ContentBlock(
        blockType: BlockType.bulletList,
        content: [
          InlineElement(inlineType: InlineType.text, text: text, marks: marks),
        ],
      ),
    );
    return this;
  }

  /// Add an ordered list item.
  ContentBuilder orderedList(String text, {List<TextMark>? marks}) {
    _blocks.add(
      ContentBlock(
        blockType: BlockType.orderedList,
        content: [
          InlineElement(inlineType: InlineType.text, text: text, marks: marks),
        ],
      ),
    );
    return this;
  }

  /// Add a code block with optional language specification.
  ContentBuilder codeBlock(String text, {String? language}) {
    _blocks.add(
      ContentBlock(
        blockType: BlockType.codeBlock,
        content: [InlineElement(inlineType: InlineType.text, text: text)],
        attrs: BlockAttrs(language: language),
      ),
    );
    return this;
  }

  /// Add a blockquote.
  ContentBuilder blockquote(String text, {List<TextMark>? marks}) {
    _blocks.add(
      ContentBlock(
        blockType: BlockType.blockquote,
        content: [
          InlineElement(inlineType: InlineType.text, text: text, marks: marks),
        ],
      ),
    );
    return this;
  }

  /// Add a hard break (line break within a block).
  ContentBuilder hardBreak() {
    // Hard breaks are typically added within existing blocks
    // This is a convenience method for standalone use
    _blocks.add(
      ContentBlock(
        blockType: BlockType.paragraph,
        content: [InlineElement(inlineType: InlineType.hardBreak, text: '')],
      ),
    );
    return this;
  }

  /// Add a pre-built block node directly.
  ContentBuilder block(ContentBlock block) {
    _blocks.add(block);
    return this;
  }

  /// Build the Content object.
  Content build() {
    final text = _computePlainText(_blocks);
    return Content(text: text, blocks: _blocks);
  }

  static String _computePlainText(List<ContentBlock> blocks) {
    return ContentExtensions.computePlainText(blocks);
  }

  /// Clear all blocks and start fresh.
  void clear() {
    _blocks.clear();
  }

  /// Get the current number of blocks.
  int get length => _blocks.length;

  /// Check if there are any blocks.
  bool get isEmpty => _blocks.isEmpty;

  /// Check if there are any blocks.
  bool get isNotEmpty => _blocks.isNotEmpty;
}

/// Extension methods for Content to provide additional functionality.
extension ContentExtensions on Content {
  /// Helper to convert a list of blocks to plain text.
  static String computePlainText(List<ContentBlock> blocks) {
    final buffer = StringBuffer();
    for (final block in blocks) {
      for (final inline in block.content) {
        buffer.write(inline.text);
      }
      buffer.writeln();
    }
    final result = buffer.toString();
    return result.endsWith('\n')
        ? result.substring(0, result.length - 1)
        : result;
  }

  /// Convert Content to plain text string.
  /// Derives text from all blocks and inline nodes.
  String toPlainText() {
    return computePlainText(blocks);
  }

  /// Check if content is empty (no blocks or all blocks are empty).
  bool get isEmptyContent {
    if (blocks.isEmpty) return true;
    return blocks.every(
      (block) =>
          block.content.isEmpty ||
          block.content.every((inline) => inline.text.isEmpty),
    );
  }

  /// Get the first text segment (useful for previews).
  String? get firstText {
    for (final block in blocks) {
      for (final inline in block.content) {
        if (inline.text.isNotEmpty) {
          return inline.text;
        }
      }
    }
    return null;
  }

  /// Get a preview string (first 100 characters).
  String get preview {
    final plainText = toPlainText();
    if (plainText.length <= 100) return plainText;
    return '${plainText.substring(0, 100)}...';
  }
}

/// Factory methods for creating common Content patterns and serialization.
class ContentFactory {
  /// Parses inline elements from a line of text, identifying bold, italic,
  /// underline, strikethrough, code, and hyperlinks.
  static List<InlineElement> parseInline(String text, [List<TextMark>? activeMarks]) {
    final marks = activeMarks ?? [];
    
    int firstIdx = -1;
    String matchType = '';
    Match? bestMatch;
    
    final linkReg = RegExp(r'\[([^\]]*)\]\(([^)]+)\)');
    final boldReg = RegExp(r'\*\*([^*]+)\*\*');
    final italicReg = RegExp(r'\*([^*]+)\*');
    final underlineReg = RegExp(r'<u>([^<]+)</u>');
    final strikeReg = RegExp(r'~~([^~]+)~~');
    final codeReg = RegExp(r'`([^`]+)`');
    
    final regexes = {
      'link': linkReg,
      'bold': boldReg,
      'italic': italicReg,
      'underline': underlineReg,
      'strike': strikeReg,
      'code': codeReg,
    };
    
    for (final entry in regexes.entries) {
      final m = entry.value.firstMatch(text);
      if (m != null) {
        if (firstIdx == -1 || m.start < firstIdx) {
          firstIdx = m.start;
          matchType = entry.key;
          bestMatch = m;
        }
      }
    }
    
    if (bestMatch == null) {
      return [
        InlineElement(
          inlineType: InlineType.text,
          text: text,
          marks: marks.isEmpty ? null : List.from(marks),
        )
      ];
    }
    
    final list = <InlineElement>[];
    // 1. Text before match
    if (bestMatch.start > 0) {
      list.addAll(parseInline(text.substring(0, bestMatch.start), marks));
    }
    
    // 2. The match itself
    final matchText = bestMatch.group(1) ?? '';
    final nextMarks = List<TextMark>.from(marks);
    
    if (matchType == 'bold') {
      nextMarks.add(const TextMark(markType: MarkType.bold));
      list.addAll(parseInline(matchText, nextMarks));
    } else if (matchType == 'italic') {
      nextMarks.add(const TextMark(markType: MarkType.italic));
      list.addAll(parseInline(matchText, nextMarks));
    } else if (matchType == 'underline') {
      nextMarks.add(const TextMark(markType: MarkType.underline));
      list.addAll(parseInline(matchText, nextMarks));
    } else if (matchType == 'strike') {
      nextMarks.add(const TextMark(markType: MarkType.strikethrough));
      list.addAll(parseInline(matchText, nextMarks));
    } else if (matchType == 'code') {
      nextMarks.add(const TextMark(markType: MarkType.code));
      list.addAll(parseInline(matchText, nextMarks));
    } else if (matchType == 'link') {
      final url = bestMatch.group(2) ?? '';
      nextMarks.add(TextMark(markType: MarkType.link, attrs: MarkAttrs(href: url)));
      list.addAll(parseInline(matchText, nextMarks));
    }
    
    // 3. Text after match
    if (bestMatch.end < text.length) {
      list.addAll(parseInline(text.substring(bestMatch.end), marks));
    }
    
    return list;
  }

  /// Create Content from markdown-like text, parsing structure and formatting.
  static Content fromText(String text) {
    if (text.isEmpty) {
      return const Content(text: '', blocks: []);
    }
    
    final lines = text.split('\n');
    final blocks = <ContentBlock>[];
    
    bool inCodeBlock = false;
    String? codeBlockLanguage;
    final codeBlockBuffer = StringBuffer();
    
    for (final line in lines) {
      if (inCodeBlock) {
        if (line.trimRight() == '```') {
          inCodeBlock = false;
          blocks.add(
            ContentBlock(
              blockType: BlockType.codeBlock,
              content: [InlineElement(inlineType: InlineType.text, text: codeBlockBuffer.toString().trimRight())],
              attrs: BlockAttrs(language: codeBlockLanguage),
            ),
          );
          codeBlockBuffer.clear();
        } else {
          codeBlockBuffer.writeln(line);
        }
        continue;
      }
      
      // Check for code block start
      if (line.startsWith('```')) {
        inCodeBlock = true;
        final lang = line.substring(3).trim();
        codeBlockLanguage = lang.isEmpty ? null : lang;
        continue;
      }
      
      // Heading: starts with #
      final headingMatch = RegExp(r'^(#{1,6})\s+(.*)$').firstMatch(line);
      if (headingMatch != null) {
        final level = headingMatch.group(1)!.length;
        final contentText = headingMatch.group(2)!;
        blocks.add(
          ContentBlock(
            blockType: BlockType.heading,
            content: parseInline(contentText),
            attrs: BlockAttrs(level: level),
          ),
        );
        continue;
      }
      
      // Blockquote: starts with >
      if (line.startsWith('>') && (line.length == 1 || line[1] == ' ')) {
        final contentText = line.length == 1 ? '' : line.substring(2);
        blocks.add(
          ContentBlock(
            blockType: BlockType.blockquote,
            content: parseInline(contentText),
          ),
        );
        continue;
      }
      
      // Bullet List: starts with - , * , or +
      final bulletMatch = RegExp(r'^[-*+]\s+(.*)$').firstMatch(line);
      if (bulletMatch != null) {
        final contentText = bulletMatch.group(1)!;
        blocks.add(
          ContentBlock(
            blockType: BlockType.bulletList,
            content: parseInline(contentText),
          ),
        );
        continue;
      }
      
      // Ordered List: starts with 1. or 2. etc.
      final orderedMatch = RegExp(r'^(\d+)\.\s+(.*)$').firstMatch(line);
      if (orderedMatch != null) {
        final contentText = orderedMatch.group(2)!;
        blocks.add(
          ContentBlock(
            blockType: BlockType.orderedList,
            content: parseInline(contentText),
          ),
        );
        continue;
      }
      
      // Otherwise, it's a paragraph
      blocks.add(
        ContentBlock(
          blockType: BlockType.paragraph,
          content: parseInline(line),
        ),
      );
    }
    
    // Handle unclosed code block
    if (inCodeBlock) {
      blocks.add(
        ContentBlock(
          blockType: BlockType.codeBlock,
          content: [InlineElement(inlineType: InlineType.text, text: codeBlockBuffer.toString().trimRight())],
          attrs: BlockAttrs(language: codeBlockLanguage),
        ),
      );
    }
    
    // Compute the plain text representation
    final plainText = ContentBuilder._computePlainText(blocks);
    return Content(text: plainText, blocks: blocks);
  }

  /// Converts a Content object back into its markdown-like representation.
  static String toMarkdown(Content content) {
    final buffer = StringBuffer();
    for (final block in content.blocks) {
      if (block.blockType == BlockType.heading) {
        final level = block.attrs?.level ?? 1;
        buffer.write('${"#" * level} ');
      } else if (block.blockType == BlockType.blockquote) {
        buffer.write('> ');
      } else if (block.blockType == BlockType.bulletList) {
        buffer.write('- ');
      } else if (block.blockType == BlockType.orderedList) {
        buffer.write('1. ');
      } else if (block.blockType == BlockType.codeBlock) {
        final lang = block.attrs?.language ?? '';
        buffer.writeln('```$lang');
      }
      
      for (final inline in block.content) {
        if (inline.inlineType == InlineType.hardBreak) {
          buffer.write('\n');
          continue;
        }
        
        var text = inline.text;
        if (inline.marks != null && block.blockType != BlockType.codeBlock) {
          // Apply marks in order
          for (final mark in inline.marks!) {
            if (mark.markType == MarkType.bold) {
              text = '**$text**';
            } else if (mark.markType == MarkType.italic) {
              text = '*$text*';
            } else if (mark.markType == MarkType.underline) {
              text = '<u>$text</u>';
            } else if (mark.markType == MarkType.strikethrough) {
              text = '~~$text~~';
            } else if (mark.markType == MarkType.code) {
              text = '`$text`';
            } else if (mark.markType == MarkType.link) {
              final href = mark.attrs?.href ?? '';
              text = '[$text]($href)';
            }
          }
        }
        buffer.write(text);
      }
      
      if (block.blockType == BlockType.codeBlock) {
        buffer.write('\n```');
      }
      buffer.writeln();
    }
    
    final result = buffer.toString();
    return result.endsWith('\n')
        ? result.substring(0, result.length - 1)
        : result;
  }

  /// Create Content with a single heading.
  static Content heading(String text, {int level = 1}) {
    return ContentBuilder().heading(text, level: level).build();
  }

  /// Create Content from a list of strings (each becomes a paragraph).
  static Content fromParagraphs(List<String> paragraphs) {
    final builder = ContentBuilder();
    for (final p in paragraphs) {
      builder.paragraph(p);
    }
    return builder.build();
  }

  /// Create empty Content.
  static Content empty() {
    return const Content(text: '', blocks: []);
  }
}
