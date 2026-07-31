import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/features/graph/models/content_builder.dart';
import 'package:centrode/src/rust/domain/contents.dart';

void main() {
  group('ContentFactory.fromText', () {
    test('CRLF heading is parsed correctly', () {
      final c = ContentFactory.fromText('# Heading\r\nParagraph');
      expect(c.blocks.length, equals(2));
      expect(c.blocks[0].blockType, equals(BlockType.heading));
      expect(c.blocks[0].attrs?.level, equals(1));
      expect(c.blocks[1].blockType, equals(BlockType.paragraph));
    });

    test('triple emphasis with nested underline', () {
      final c = ContentFactory.fromText('***<u>because</u>***');
      expect(c.blocks.length, equals(1));
      final inline = c.blocks[0].content.first;
      expect(inline.text, equals('because'));
      expect(inline.marks, isNotNull);
      final markTypes = inline.marks!.map((m) => m.markType).toList();
      expect(markTypes, contains(MarkType.bold));
      expect(markTypes, contains(MarkType.italic));
      expect(markTypes, contains(MarkType.underline));
    });

    test('heading level is extracted from hashes', () {
      final c = ContentFactory.fromText('## Level Two');
      expect(c.blocks.length, equals(1));
      expect(c.blocks[0].blockType, equals(BlockType.heading));
      expect(c.blocks[0].attrs?.level, equals(2));
    });

    test('code block is parsed', () {
      final c = ContentFactory.fromText('```\nconst x = 1;\n```');
      expect(c.blocks.length, equals(1));
      expect(c.blocks[0].blockType, equals(BlockType.codeBlock));
      expect(c.blocks[0].content.first.text, contains('const x = 1;'));
    });

    test('code block with language', () {
      final c = ContentFactory.fromText('```dart\nvoid main() {}\n```');
      expect(c.blocks.length, equals(1));
      expect(c.blocks[0].blockType, equals(BlockType.codeBlock));
      expect(c.blocks[0].attrs?.language, equals('dart'));
    });

    test('bullet list items', () {
      final c = ContentFactory.fromText('- Item 1\n- Item 2\n- Item 3');
      expect(c.blocks.length, equals(3));
      for (final block in c.blocks) {
        expect(block.blockType, equals(BlockType.bulletList));
      }
      expect(c.blocks[0].content.first.text, equals('Item 1'));
      expect(c.blocks[2].content.first.text, equals('Item 3'));
    });

    test('ordered list items', () {
      final c = ContentFactory.fromText('1. First\n2. Second');
      expect(c.blocks.length, equals(2));
      expect(c.blocks[0].blockType, equals(BlockType.orderedList));
      expect(c.blocks[1].blockType, equals(BlockType.orderedList));
    });

    test('blockquote', () {
      final c = ContentFactory.fromText('> quoted text');
      expect(c.blocks.length, equals(1));
      expect(c.blocks[0].blockType, equals(BlockType.blockquote));
      expect(c.blocks[0].content.first.text, equals('quoted text'));
    });

    test('bold text', () {
      final c = ContentFactory.fromText('**bold**');
      expect(c.blocks.length, equals(1));
      final marks = c.blocks[0].content.first.marks;
      expect(marks, isNotNull);
      expect(marks!.any((m) => m.markType == MarkType.bold), isTrue);
    });

    test('italic text', () {
      final c = ContentFactory.fromText('*italic*');
      expect(c.blocks.length, equals(1));
      final marks = c.blocks[0].content.first.marks;
      expect(marks, isNotNull);
      expect(marks!.any((m) => m.markType == MarkType.italic), isTrue);
    });

    test('strikethrough text', () {
      final c = ContentFactory.fromText('~~struck~~');
      expect(c.blocks.length, equals(1));
      final marks = c.blocks[0].content.first.marks;
      expect(marks, isNotNull);
      expect(marks!.any((m) => m.markType == MarkType.strikethrough), isTrue);
    });

    test('inline code', () {
      final c = ContentFactory.fromText('use `dart`');
      expect(c.blocks.length, equals(1));
      expect(c.blocks[0].content.length, greaterThanOrEqualTo(2));
      final codeSegment = c.blocks[0].content.firstWhere(
        (i) => i.text == 'dart',
        orElse: () => c.blocks[0].content.first,
      );
      expect(codeSegment.marks, isNotNull);
      expect(
        codeSegment.marks!.any((m) => m.markType == MarkType.code),
        isTrue,
      );
    });

    test('link', () {
      final c = ContentFactory.fromText('[click](https://example.com)');
      expect(c.blocks.length, equals(1));
      final marks = c.blocks[0].content.first.marks;
      expect(marks, isNotNull);
      final linkMark = marks!.firstWhere((m) => m.markType == MarkType.link);
      expect(linkMark.attrs?.href, equals('https://example.com'));
    });

    test('empty text produces no blocks', () {
      final c = ContentFactory.fromText('');
      expect(c.blocks, isEmpty);
    });

    test('unclosed code block is handled gracefully', () {
      final c = ContentFactory.fromText('```\nunclosed code');
      expect(c.blocks.length, equals(1));
      expect(c.blocks[0].blockType, equals(BlockType.codeBlock));
      expect(c.blocks[0].content.first.text, contains('unclosed code'));
    });
  });

  group('ContentFactory.toMarkdown', () {
    test('heading round-trips', () {
      final original = '# Title\n\nParagraph';
      final c = ContentFactory.fromText(original);
      final result = ContentFactory.toMarkdown(c);
      expect(result, contains('# Title'));
      expect(result, contains('Paragraph'));
    });

    test('code block round-trips', () {
      final original = '```\ncode here\n```';
      final c = ContentFactory.fromText(original);
      final result = ContentFactory.toMarkdown(c);
      expect(result, contains('```'));
      expect(result, contains('code here'));
    });

    test('bold round-trips', () {
      final c = ContentFactory.fromText('**bold text**');
      final result = ContentFactory.toMarkdown(c);
      expect(result, contains('**bold text**'));
    });

    test('italic round-trips', () {
      final c = ContentFactory.fromText('*italic text*');
      final result = ContentFactory.toMarkdown(c);
      expect(result, contains('*italic text*'));
    });

    test('link round-trips', () {
      final c = ContentFactory.fromText('[text](https://example.com)');
      final result = ContentFactory.toMarkdown(c);
      expect(result, contains('[text](https://example.com)'));
    });

    test('bullet list round-trips', () {
      final c = ContentFactory.fromText('- Item 1\n- Item 2');
      final result = ContentFactory.toMarkdown(c);
      expect(result, contains('- Item 1'));
      expect(result, contains('- Item 2'));
    });

    test('blockquote round-trips', () {
      final c = ContentFactory.fromText('> quoted');
      final result = ContentFactory.toMarkdown(c);
      expect(result, contains('> quoted'));
    });

    test('full user markdown round-trips structure', () {
      final md =
          '# Heading\n\n```\nCode block\n```\n\n**bold** and *italic* and <u>underline</u>\n\n***<u>because</u>*** is important\n\n[text](https://example.com)';
      final c = ContentFactory.fromText(md);
      final result = ContentFactory.toMarkdown(c);

      expect(result, contains('# Heading'));
      expect(result, contains('```'));
      expect(result, contains('Code block'));
      expect(result, contains('**bold**'));
      expect(result, contains('*italic*'));
      expect(result, contains('<u>underline</u>'));
      expect(result, contains('[text](https://example.com)'));
    });
  });

  group('Complex markdown scenarios', () {
    test('mixed headings, code, emphasis, and links', () {
      final md =
          '# The standard Lorem Ipsum passage, used since 1966\n<u>"Lorem ipsum dolor sit amet."</u>\n\n## Section 1.10.32\n\n```\n"Sed ut perspiciatis unde omnis."\n```\n\n### 1914 translation by H. Rackham';
      final c = ContentFactory.fromText(md);

      final headings = c.blocks
          .where((b) => b.blockType == BlockType.heading)
          .toList();
      expect(headings.length, equals(3));
      expect(headings[0].attrs?.level, equals(1));
      expect(headings[1].attrs?.level, equals(2));
      expect(headings[2].attrs?.level, equals(3));

      final codeBlocks = c.blocks
          .where((b) => b.blockType == BlockType.codeBlock)
          .toList();
      expect(codeBlocks.length, equals(1));

      final underlined = c.blocks[1].content.first.marks;
      expect(underlined, isNotNull);
      expect(underlined!.any((m) => m.markType == MarkType.underline), isTrue);
    });

    test('nested emphasis in long text', () {
      final c = ContentFactory.fromText('***<u>because</u>*** is important');
      expect(c.blocks.length, equals(1));
      final firstInline = c.blocks[0].content.first;
      expect(firstInline.text, equals('because'));
      final markTypes = firstInline.marks!.map((m) => m.markType).toList();
      expect(markTypes, contains(MarkType.bold));
      expect(markTypes, contains(MarkType.italic));
      expect(markTypes, contains(MarkType.underline));
    });
  });
}
