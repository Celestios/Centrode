import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/features/graph/models/content_builder.dart';
import 'package:centrode/src/rust/domain/contents.dart';

void main() {
  group('ContentBuilder', () {
    test('creates empty content', () {
      final builder = ContentBuilder();
      expect(builder.isEmpty, isTrue);
      expect(builder.length, 0);

      final content = builder.build();
      expect(content.blocks, isEmpty);
      expect(content.text, isEmpty);
    });

    test('builds single paragraph', () {
      final content = ContentBuilder().paragraph('Hello World').build();

      expect(content.blocks.length, 1);
      expect(content.blocks.first.blockType, BlockType.paragraph);
      expect(content.blocks.first.content.first.text, 'Hello World');
      expect(content.text, 'Hello World');
    });

    test('builds multiple paragraphs', () {
      final content = ContentBuilder()
          .paragraph('First paragraph')
          .paragraph('Second paragraph')
          .build();

      expect(content.blocks.length, 2);
      expect(content.text, 'First paragraph\nSecond paragraph');
    });

    test('builds heading with correct level', () {
      final content = ContentBuilder().heading('My Title', level: 2).build();

      expect(content.blocks.length, 1);
      expect(content.blocks.first.blockType, BlockType.heading);
      expect(content.blocks.first.attrs?.level, 2);
      expect(content.text, 'My Title');
    });

    test('builds complex content with formatting', () {
      final content = ContentBuilder()
          .heading('Title', level: 1)
          .paragraphSegments([
            InlineElement(inlineType: InlineType.text, text: 'Normal text '),
            InlineElement(
              inlineType: InlineType.text,
              text: 'bold text',
              marks: [TextMark(markType: MarkType.bold)],
            ),
          ])
          .build();

      expect(content.blocks.length, 2);
      expect(content.blocks[0].blockType, BlockType.heading);
      expect(content.blocks[1].blockType, BlockType.paragraph);
      expect(content.text, 'Title\nNormal text bold text');
    });

    test('clear resets builder state', () {
      final builder = ContentBuilder().paragraph('Test');
      expect(builder.isNotEmpty, isTrue);

      builder.clear();
      expect(builder.isEmpty, isTrue);
      expect(builder.length, 0);
    });
  });

  group('ContentFactory', () {
    test('fromText creates single paragraph content', () {
      final content = ContentFactory.fromText('Quick text');
      expect(content.blocks.length, 1);
      expect(content.text, 'Quick text');
    });

    test('fromText handles empty string', () {
      final content = ContentFactory.fromText('');
      expect(content.blocks, isEmpty);
      expect(content.text, isEmpty);
    });

    test('heading creates heading content', () {
      final content = ContentFactory.heading('Header', level: 3);
      expect(content.blocks.length, 1);
      expect(content.blocks.first.blockType, BlockType.heading);
      expect(content.blocks.first.attrs?.level, 3);
    });

    test('fromParagraphs creates multiple blocks', () {
      final content = ContentFactory.fromParagraphs(['One', 'Two', 'Three']);
      expect(content.blocks.length, 3);
      expect(content.text, 'One\nTwo\nThree');
    });
  });

  group('ContentExtensions', () {
    test('toPlainText generates correct string', () {
      final content = ContentFactory.fromParagraphs(['Line 1', 'Line 2']);
      expect(content.toPlainText(), 'Line 1\nLine 2');
    });

    test('isEmptyContent correctly identifies empty states', () {
      expect(ContentFactory.empty().isEmptyContent, isTrue);
      expect(ContentFactory.fromText('').isEmptyContent, isTrue);
      expect(ContentFactory.fromText('   ').isEmptyContent, isFalse);
    });

    test('preview truncates long text', () {
      final longText = List.filled(150, 'A').join('');
      final content = ContentFactory.fromText(longText);

      final preview = content.preview;
      expect(preview.length, 103); // 100 + '...'
      expect(preview.endsWith('...'), isTrue);
    });
  });

  group('ContentFactory.toMarkdown', () {
    test('converts headings of various levels', () {
      final h1 = ContentFactory.heading('Header 1', level: 1);
      expect(ContentFactory.toMarkdown(h1), '# Header 1');

      final h2 = ContentFactory.heading('Header 2', level: 2);
      expect(ContentFactory.toMarkdown(h2), '## Header 2');

      final h3 = ContentFactory.heading('Header 3', level: 3);
      expect(ContentFactory.toMarkdown(h3), '### Header 3');
    });

    test('converts formatted inline marks to markdown', () {
      final content = Content(
        text: 'bold italic code link',
        blocks: [
          ContentBlock(
            blockType: BlockType.paragraph,
            content: [
              InlineElement(
                inlineType: InlineType.text,
                text: 'bold',
                marks: [TextMark(markType: MarkType.bold)],
              ),
              InlineElement(inlineType: InlineType.text, text: ' '),
              InlineElement(
                inlineType: InlineType.text,
                text: 'italic',
                marks: [TextMark(markType: MarkType.italic)],
              ),
              InlineElement(inlineType: InlineType.text, text: ' '),
              InlineElement(
                inlineType: InlineType.text,
                text: 'code',
                marks: [TextMark(markType: MarkType.code)],
              ),
              InlineElement(inlineType: InlineType.text, text: ' '),
              InlineElement(
                inlineType: InlineType.text,
                text: 'link',
                marks: [
                  TextMark(
                    markType: MarkType.link,
                    attrs: const MarkAttrs(href: 'https://centrode.io'),
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final md = ContentFactory.toMarkdown(content);
      expect(md, '**bold** *italic* `code` [link](https://centrode.io)');
    });

    test('converts blockquote, bulletList, and codeBlock', () {
      final bq = Content(
        text: 'Quote',
        blocks: [
          ContentBlock(
            blockType: BlockType.blockquote,
            content: [InlineElement(inlineType: InlineType.text, text: 'Quote')],
          ),
        ],
      );
      expect(ContentFactory.toMarkdown(bq), '> Quote');

      final list = Content(
        text: 'Item',
        blocks: [
          ContentBlock(
            blockType: BlockType.bulletList,
            content: [InlineElement(inlineType: InlineType.text, text: 'Item')],
          ),
        ],
      );
      expect(ContentFactory.toMarkdown(list), '- Item');

      final code = Content(
        text: 'var x = 1;',
        blocks: [
          ContentBlock(
            blockType: BlockType.codeBlock,
            attrs: const BlockAttrs(language: 'dart'),
            content: [
              InlineElement(inlineType: InlineType.text, text: 'var x = 1;'),
            ],
          ),
        ],
      );
      expect(ContentFactory.toMarkdown(code), '```dart\nvar x = 1;\n```');
    });
  });

  group('ContentFactory.parseInline', () {
    test('parses plain text without marks', () {
      final elements = ContentFactory.parseInline('Hello World');
      expect(elements.length, 1);
      expect(elements.first.text, 'Hello World');
      expect(elements.first.marks, isNull);
    });

    test('parses bold delimiter', () {
      final elements = ContentFactory.parseInline('A **bold text** B');
      expect(elements.length, 3);
      expect(elements[0].text, 'A ');
      expect(elements[1].text, 'bold text');
      expect(elements[1].marks?.any((m) => m.markType == MarkType.bold), isTrue);
      expect(elements[2].text, ' B');
    });

    test('parses italic delimiter', () {
      final elements = ContentFactory.parseInline('A *italic text* B');
      expect(elements.length, 3);
      expect(elements[1].text, 'italic text');
      expect(elements[1].marks?.any((m) => m.markType == MarkType.italic), isTrue);
    });

    test('parses bold+italic delimiter', () {
      final elements = ContentFactory.parseInline('***bold and italic***');
      expect(elements.length, 1);
      expect(elements.first.text, 'bold and italic');
      expect(elements.first.marks?.any((m) => m.markType == MarkType.bold), isTrue);
      expect(elements.first.marks?.any((m) => m.markType == MarkType.italic), isTrue);
    });

    test('parses inline code delimiter', () {
      final elements = ContentFactory.parseInline('Run `cargo test` now');
      expect(elements.length, 3);
      expect(elements[1].text, 'cargo test');
      expect(elements[1].marks?.any((m) => m.markType == MarkType.code), isTrue);
    });

    test('parses markdown hyperlinks', () {
      final elements = ContentFactory.parseInline('Click [Centrode](https://centrode.io) here');
      expect(elements.length, 3);
      expect(elements[1].text, 'Centrode');
      expect(elements[1].marks?.first.markType, MarkType.link);
      expect(elements[1].marks?.first.attrs?.href, 'https://centrode.io');
    });

    test('parses strikethrough and underline', () {
      final strike = ContentFactory.parseInline('~~deleted~~');
      expect(strike.first.text, 'deleted');
      expect(strike.first.marks?.any((m) => m.markType == MarkType.strikethrough), isTrue);

      final under = ContentFactory.parseInline('<u>underlined</u>');
      expect(under.first.text, 'underlined');
      expect(under.first.marks?.any((m) => m.markType == MarkType.underline), isTrue);
    });
  });

  group('ContentTransformExtensions', () {
    test('toggleMark adds and removes text marks', () {
      final initial = ContentFactory.fromText('Important note');
      final withBold = initial.toggleMark(MarkType.bold);

      expect(
        withBold.blocks.first.content.first.marks?.any((m) => m.markType == MarkType.bold),
        isTrue,
      );

      final withoutBold = withBold.toggleMark(MarkType.bold);
      expect(
        withoutBold.blocks.first.content.first.marks?.any((m) => m.markType == MarkType.bold) ?? false,
        isFalse,
      );
    });

    test('setTextAlign updates block text alignment attribute', () {
      final content = ContentFactory.fromText('Aligned text');
      final centered = content.setTextAlign('center');
      expect(centered.blocks.first.attrs?.textAlign, 'center');

      final rightAligned = centered.setTextAlign('right');
      expect(rightAligned.blocks.first.attrs?.textAlign, 'right');
    });

    test('transformLetterCase modifies casing across text elements', () {
      final content = ContentFactory.fromText('hello world');
      final upper = content.transformLetterCase('uppercase');
      expect(upper.text, 'HELLO WORLD');
      expect(upper.blocks.first.content.first.text, 'HELLO WORLD');

      final lower = upper.transformLetterCase('lowercase');
      expect(lower.text, 'hello world');
      expect(lower.blocks.first.content.first.text, 'hello world');
    });

    test('setHighlightColor applies and clears highlight color mark', () {
      final content = ContentFactory.fromText('Highlighted text');
      final highlighted = content.setHighlightColor(0xFFFFEB3B);
      final mark = highlighted.blocks.first.content.first.marks?.firstWhere(
        (m) => m.markType == MarkType.highlight,
      );
      expect(mark, isNotNull);
      expect(mark?.attrs?.color, 0xFFFFEB3B);

      final cleared = highlighted.setHighlightColor(null);
      expect(
        cleared.blocks.first.content.first.marks?.any((m) => m.markType == MarkType.highlight) ?? false,
        isFalse,
      );
    });

    test('resetFormatting strips all marks and restores default paragraph', () {
      final styled = Content(
        text: 'Custom Styled',
        blocks: [
          ContentBlock(
            blockType: BlockType.heading,
            attrs: const BlockAttrs(level: 1, textAlign: 'left'),
            content: [
              InlineElement(
                inlineType: InlineType.text,
                text: 'Custom Styled',
                marks: [
                  TextMark(markType: MarkType.bold),
                  TextMark(markType: MarkType.italic),
                ],
              ),
            ],
          ),
        ],
      );

      final reset = styled.resetFormatting();
      expect(reset.blocks.first.blockType, BlockType.paragraph);
      expect(reset.blocks.first.attrs?.textAlign, 'center');
      expect(reset.blocks.first.content.first.marks, isNull);
    });
  });
}
