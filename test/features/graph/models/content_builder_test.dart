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
}
