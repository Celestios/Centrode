import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mycelium/features/graph/ui/canvas/content_text_editing_controller.dart';
import 'package:mycelium/features/graph/ui/canvas/text_ast_serializer.dart' as serializer;
import 'package:mycelium/features/graph/models/models.dart';

void main() {
  group('ContentTextEditingController', () {
    test('loadFromContent sets up correct formatting spans and text', () {
      final controller = ContentTextEditingController();
      final content = Content(
        text: 'Hello World\n• Bullet\n> Quote',
        blocks: [
          const ContentBlock(
            blockType: BlockType.heading,
            attrs: BlockAttrs(level: 1),
            content: [InlineElement(inlineType: InlineType.text, text: 'Hello World')],
          ),
          const ContentBlock(
            blockType: BlockType.bulletList,
            content: [InlineElement(inlineType: InlineType.text, text: 'Bullet')],
          ),
          const ContentBlock(
            blockType: BlockType.blockquote,
            content: [InlineElement(inlineType: InlineType.text, text: 'Quote')],
          ),
        ],
      );

      controller.loadFromContent(content);

      expect(controller.text, equals('Hello World\n• Bullet\n> Quote'));
      expect(controller.formattingSpans.length, equals(3));
      
      // Verify first span is heading1
      expect(controller.formattingSpans[0].type, equals(TextFormatType.heading1));
      expect(controller.formattingSpans[0].start, equals(0));
      expect(controller.formattingSpans[0].end, equals(11));

      // Verify second span is bulletList
      expect(controller.formattingSpans[1].type, equals(TextFormatType.bulletList));
      expect(controller.formattingSpans[1].start, equals(12));
      expect(controller.formattingSpans[1].end, equals(20));

      // Verify third span is blockquote
      expect(controller.formattingSpans[2].type, equals(TextFormatType.blockquote));
      expect(controller.formattingSpans[2].start, equals(21));
      expect(controller.formattingSpans[2].end, equals(28));
    });

    test('Block formatting spans align exactly to lines after text editing', () {
      final controller = ContentTextEditingController();
      final content = Content(
        text: 'Heading',
        blocks: [
          const ContentBlock(
            blockType: BlockType.heading,
            attrs: BlockAttrs(level: 1),
            content: [InlineElement(inlineType: InlineType.text, text: 'Heading')],
          ),
        ],
      );

      controller.loadFromContent(content);

      // Typing at the end of the heading
      controller.value = const TextEditingValue(
        text: 'Heading!',
        selection: TextSelection.collapsed(offset: 8),
      );

      // Verify that the heading1 span expanded to cover the new text exactly
      expect(controller.formattingSpans.length, equals(1));
      expect(controller.formattingSpans[0].type, equals(TextFormatType.heading1));
      expect(controller.formattingSpans[0].start, equals(0));
      expect(controller.formattingSpans[0].end, equals(8));

      // Typing at the start of the heading
      controller.value = const TextEditingValue(
        text: 'A Heading!',
        selection: TextSelection.collapsed(offset: 2),
      );

      // Verify that the heading1 span expanded to cover the start too
      expect(controller.formattingSpans[0].start, equals(0));
      expect(controller.formattingSpans[0].end, equals(10));
    });

    test('toggleHeading correctly toggles block format and updates prefix', () {
      final controller = ContentTextEditingController();
      final content = Content(
        text: '• Hello',
        blocks: [
          const ContentBlock(
            blockType: BlockType.bulletList,
            content: [InlineElement(inlineType: InlineType.text, text: 'Hello')],
          ),
        ],
      );

      controller.loadFromContent(content);
      controller.selection = const TextSelection.collapsed(offset: 4);

      // Toggle Heading 1
      controller.toggleHeading(TextFormatType.heading1);

      // Bullet prefix should be stripped, and heading1 span should cover the whole text
      expect(controller.text, equals('Hello'));
      expect(controller.formattingSpans.length, equals(1));
      expect(controller.formattingSpans[0].type, equals(TextFormatType.heading1));
      expect(controller.formattingSpans[0].start, equals(0));
      expect(controller.formattingSpans[0].end, equals(5));
    });

    test('Auto-detects typed list and blockquote prefixes', () {
      final controller = ContentTextEditingController();
      controller.text = 'Normal line';
      
      // Type bullet prefix
      controller.value = const TextEditingValue(
        text: '• Normal line',
        selection: TextSelection.collapsed(offset: 13),
      );

      expect(controller.formattingSpans.length, equals(1));
      expect(controller.formattingSpans[0].type, equals(TextFormatType.bulletList));
      expect(controller.formattingSpans[0].start, equals(0));
      expect(controller.formattingSpans[0].end, equals(13));

      // Backspace prefix
      controller.value = const TextEditingValue(
        text: 'Normal line',
        selection: TextSelection.collapsed(offset: 11),
      );

      expect(controller.formattingSpans.isEmpty, isTrue);
    });

    test('clearBlockFormat clears block level format, strips prefix, and notifies listeners', () {
      final controller = ContentTextEditingController();
      final content = Content(
        text: '• Hello',
        blocks: [
          const ContentBlock(
            blockType: BlockType.bulletList,
            content: [InlineElement(inlineType: InlineType.text, text: 'Hello')],
          ),
        ],
      );

      controller.loadFromContent(content);
      controller.selection = const TextSelection.collapsed(offset: 4);

      int notifyCount = 0;
      controller.addListener(() {
        notifyCount++;
      });

      // Clear block format
      controller.clearBlockFormat();

      expect(controller.text, equals('Hello'));
      expect(controller.formattingSpans.isEmpty, isTrue);
      expect(notifyCount, greaterThan(0));
    });

    test('toggleBlockFormat toggle lists and quote formats correctly and notifies listeners', () {
      final controller = ContentTextEditingController();
      controller.text = 'Hello';
      controller.selection = const TextSelection.collapsed(offset: 3);

      int notifyCount = 0;
      controller.addListener(() {
        notifyCount++;
      });

      // Toggle blockquote
      controller.toggleBlockFormat(TextFormatType.blockquote);
      expect(controller.text, equals('> Hello'));
      expect(controller.formattingSpans[0].type, equals(TextFormatType.blockquote));
      expect(notifyCount, greaterThan(0));

      // Reset count
      notifyCount = 0;

      // Toggle bullet list (clears blockquote and sets bullet list)
      controller.toggleBlockFormat(TextFormatType.bulletList);
      expect(controller.text, equals('• Hello'));
      expect(controller.formattingSpans[0].type, equals(TextFormatType.bulletList));
      expect(notifyCount, greaterThan(0));
    });
  });

  group('ContentTextEditingController.insertMarkdownSpans', () {
    test('inserts bold markdown at cursor position', () {
      final controller = ContentTextEditingController();
      controller.value = const TextEditingValue(
        text: 'Hello world',
        selection: TextSelection.collapsed(offset: 6),
      );

      controller.insertMarkdownSpans('**bold**');

      expect(controller.text, contains('bold'));
      expect(controller.formattingSpans, isNotEmpty);
      final boldSpans = controller.formattingSpans
          .where((s) => s.type == TextFormatType.bold)
          .toList();
      expect(boldSpans, isNotEmpty);
    });

    test('parses heading markdown', () {
      final controller = ContentTextEditingController();
      controller.value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );

      controller.insertMarkdownSpans('# Heading');

      expect(controller.text, contains('Heading'));
      final headingSpans = controller.formattingSpans
          .where((s) => s.type == TextFormatType.heading1)
          .toList();
      expect(headingSpans, isNotEmpty);
    });

    test('parses list markdown', () {
      final controller = ContentTextEditingController();
      controller.value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );

      controller.insertMarkdownSpans('- Item 1\n- Item 2');

      expect(controller.text, contains('Item 1'));
      expect(controller.text, contains('Item 2'));
      final listSpans = controller.formattingSpans
          .where((s) => s.type == TextFormatType.bulletList)
          .toList();
      expect(listSpans.length, 2);
    });

    test('inserts plain text when no markdown detected', () {
      final controller = ContentTextEditingController();
      controller.value = const TextEditingValue(
        text: 'Hello',
        selection: TextSelection.collapsed(offset: 5),
      );

      controller.insertMarkdownSpans(' world');

      expect(controller.text, 'Hello world');
    });
  });

  group('ContentTextEditingController.selectedTextAsMarkdown', () {
    test('converts selected bold text to markdown', () {
      final controller = ContentTextEditingController();
      controller.loadFromContent(
        const Content(
          text: 'Hello bold world',
          blocks: [
            ContentBlock(
              blockType: BlockType.paragraph,
              content: [
                InlineElement(inlineType: InlineType.text, text: 'Hello '),
                InlineElement(
                  inlineType: InlineType.text,
                  text: 'bold',
                  marks: [TextMark(markType: MarkType.bold)],
                ),
                InlineElement(inlineType: InlineType.text, text: ' world'),
              ],
            ),
          ],
        ),
      );

      controller.selection = const TextSelection(baseOffset: 6, extentOffset: 10);
      final md = controller.selectedTextAsMarkdown();
      expect(md, '**bold**');
    });

    test('returns plain text for unformatted selection', () {
      final controller = ContentTextEditingController();
      controller.loadFromContent(
        const Content(
          text: 'Hello world',
          blocks: [
            ContentBlock(
              blockType: BlockType.paragraph,
              content: [
                InlineElement(inlineType: InlineType.text, text: 'Hello world'),
              ],
            ),
          ],
        ),
      );

      controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
      final md = controller.selectedTextAsMarkdown();
      expect(md, 'Hello');
    });

    test('converts heading to markdown', () {
      final controller = ContentTextEditingController();
      controller.loadFromContent(
        const Content(
          text: 'Title',
          blocks: [
            ContentBlock(
              blockType: BlockType.heading,
              content: [
                InlineElement(inlineType: InlineType.text, text: 'Title'),
              ],
              attrs: BlockAttrs(level: 1),
            ),
          ],
        ),
      );

      controller.selection = const TextSelection(baseOffset: 0, extentOffset: 5);
      final md = controller.selectedTextAsMarkdown();
      expect(md, '# Title');
    });

    test('preserves code block in toMarkdown', () {
      final controller = ContentTextEditingController();
      controller.loadFromContent(
        const Content(
          text: 'Some text\nCode here\nMore text',
          blocks: [
            ContentBlock(
              blockType: BlockType.paragraph,
              content: [InlineElement(inlineType: InlineType.text, text: 'Some text')],
            ),
            ContentBlock(
              blockType: BlockType.codeBlock,
              content: [InlineElement(inlineType: InlineType.text, text: 'Code here')],
            ),
            ContentBlock(
              blockType: BlockType.paragraph,
              content: [InlineElement(inlineType: InlineType.text, text: 'More text')],
            ),
          ],
        ),
      );

      controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
      final md = controller.selectedTextAsMarkdown();
      expect(md, contains('```'));
      expect(md, contains('Code here'));
    });

    test('preserves link in toMarkdown', () {
      final controller = ContentTextEditingController();
      controller.loadFromContent(
        const Content(
          text: 'Click here',
          blocks: [
            ContentBlock(
              blockType: BlockType.paragraph,
              content: [
                InlineElement(
                  inlineType: InlineType.text,
                  text: 'Click here',
                  marks: [TextMark(markType: MarkType.link, attrs: MarkAttrs(href: 'https://example.com'))],
                ),
              ],
            ),
          ],
        ),
      );

      controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
      final md = controller.selectedTextAsMarkdown();
      expect(md, contains('[Click here](https://example.com)'));
    });

    test('preserves nested bold+italic+underline in toMarkdown', () {
      final controller = ContentTextEditingController();
      controller.loadFromContent(
        const Content(
          text: 'because',
          blocks: [
            ContentBlock(
              blockType: BlockType.paragraph,
              content: [
                InlineElement(
                  inlineType: InlineType.text,
                  text: 'because',
                  marks: [
                    TextMark(markType: MarkType.bold),
                    TextMark(markType: MarkType.italic),
                    TextMark(markType: MarkType.underline),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
      final md = controller.selectedTextAsMarkdown();
      expect(md, contains('**'));
      expect(md, contains('*'));
      expect(md, contains('<u>'));
    });

    test('preserves partial bold in toMarkdown', () {
      final controller = ContentTextEditingController();
      controller.loadFromContent(
        const Content(
          text: 'undertakes',
          blocks: [
            ContentBlock(
              blockType: BlockType.paragraph,
              content: [
                InlineElement(
                  inlineType: InlineType.text,
                  text: 'undertak',
                  marks: [TextMark(markType: MarkType.bold)],
                ),
                InlineElement(inlineType: InlineType.text, text: 'es'),
              ],
            ),
          ],
        ),
      );

      controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
      final md = controller.selectedTextAsMarkdown();
      expect(md, contains('**undertak**'));
      expect(md, contains('es'));
    });

    test('full round-trip: markdown -> fromText -> loadFromContent -> selectedTextAsMarkdown', () {
      final originalMarkdown = '```\nCode here\n```\n\n**bold** and *italic*\n\n[text](https://example.com)';
      final content = ContentFactory.fromText(originalMarkdown);
      final controller = ContentTextEditingController();
      controller.loadFromContent(content);

      controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
      final result = controller.selectedTextAsMarkdown();

      expect(result, contains('```'));
      expect(result, contains('**bold**'));
      expect(result, contains('*italic*'));
      expect(result, contains('[text](https://example.com)'));
    });

    test('full round-trip with nested marks', () {
      final originalMarkdown = '***<u>because</u>*** is important';
      final content = ContentFactory.fromText(originalMarkdown);
      final controller = ContentTextEditingController();
      controller.loadFromContent(content);

      controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
      final result = controller.selectedTextAsMarkdown();

      expect(result, contains('**'));
      expect(result, contains('<u>'));
    });

    test('loadFromContent preserves code block spans for buildContent round-trip', () {
      final content = ContentFactory.fromText('Text\n```\nCode\n```\nMore');
      final (text, spans, _) = serializer.loadFromContent(content);

      expect(text, contains('Code'));

      final codeSpans = spans.where((s) => s.type == TextFormatType.codeBlock).toList();
      expect(codeSpans, isNotEmpty, reason: 'loadFromContent should produce codeBlock spans');

      final rebuilt = serializer.buildContent(text, spans);
      final codeBlocks = rebuilt.blocks.where((b) => b.blockType == BlockType.codeBlock).toList();
      expect(codeBlocks, isNotEmpty, reason: 'buildContent should recreate codeBlock blocks from spans');
    });

    test('buildContent preserves link marks from loadFromContent spans', () {
      final content = ContentFactory.fromText('[click](https://example.com)');
      final (text, spans, _) = serializer.loadFromContent(content);

      final linkSpans = spans.where((s) => s.type == TextFormatType.link).toList();
      expect(linkSpans, isNotEmpty, reason: 'loadFromContent should produce link spans');

      final rebuilt = serializer.buildContent(text, spans);
      final linkMarks = rebuilt.blocks.expand((b) => b.content).expand((i) => i.marks ?? []).where((m) => m.markType == MarkType.link).toList();
      expect(linkMarks, isNotEmpty, reason: 'buildContent should recreate link marks');
    });

    test('user workflow: paste markdown then copy as markdown preserves all formatting', () {
      final controller = ContentTextEditingController();
      controller.value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );

      final markdown = '# Heading\n\n```\nCode block\n```\n\n**bold** and *italic* and <u>underline</u>\n\n***<u>nested</u>***\n\n**partial**bold\n\n[text](https://example.com)\n\n- list item';
      controller.insertMarkdownSpans(markdown);

      controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
      final result = controller.selectedTextAsMarkdown();

      expect(result, contains('# Heading'));
      expect(result, contains('```'));
      expect(result, contains('**bold**'));
      expect(result, contains('*italic*'));
      expect(result, contains('<u>underline</u>'));
      expect(result, contains('**partial**'));
      expect(result, contains('[text](https://example.com)'));
      expect(result, contains('- list item'));
    });

    test('selection starting mid-text preserves block formatting', () {
      final controller = ContentTextEditingController();
      controller.value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );

      final markdown = 'Before\n\n# Heading\n\n```\nCode\n```\n\n**bold** text';
      controller.insertMarkdownSpans(markdown);

      final codeStart = controller.text.indexOf('Code');
      final codeEnd = codeStart + 4;
      controller.selection = TextSelection(baseOffset: codeStart, extentOffset: codeEnd);
      final result = controller.selectedTextAsMarkdown();
      expect(result, contains('Code'));

      final boldStart = controller.text.indexOf('bold');
      final boldEnd = boldStart + 4;
      controller.selection = TextSelection(baseOffset: boldStart, extentOffset: boldEnd);
      final resultBold = controller.selectedTextAsMarkdown();
      expect(resultBold, '**bold**');
    });

    test('full node copy captures all blocks', () {
      final controller = ContentTextEditingController();
      controller.value = const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );

      final markdown = 'Intro text\n\n```\nCode block here\n```\n\nParagraph with **bold** and [link](https://x.com)\n\n### Sub heading';
      controller.insertMarkdownSpans(markdown);

      controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
      final result = controller.selectedTextAsMarkdown();

      // ignore: avoid_print
      print('FULL RESULT: $result');
      expect(result, contains('```'));
      expect(result, contains('Code block here'));
      expect(result, contains('**bold**'));
      expect(result, contains('[link](https://x.com)'));
      expect(result, contains('### Sub heading'));
    });
  });
}
