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
  /// Convert Content to plain text string.
  /// Derives text from all blocks and inline nodes.
  String toPlainText() {
    final buffer = StringBuffer();
    for (final block in blocks) {
      for (final inline in block.content) {
        buffer.write(inline.text);
      }
      buffer.writeln();
    }
    // Remove trailing newline
    final result = buffer.toString();
    if (result.endsWith('\n')) {
      return result.substring(0, result.length - 1);
    }
    return result;
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

/// Factory methods for creating common Content patterns.
class ContentFactory {
  /// Create Content from plain text (single paragraph).
  static Content fromText(String text) {
    if (text.isEmpty) {
      return const Content(text: '', blocks: []);
    }
    return ContentBuilder().paragraph(text).build();
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
