import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mycelium/features/graph/ui/canvas/content_text_editing_controller.dart';
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
}
