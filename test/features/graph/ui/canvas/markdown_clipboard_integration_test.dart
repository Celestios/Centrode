import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mycelium/features/graph/ui/canvas/content_text_editing_controller.dart';
import 'package:mycelium/features/graph/models/content_builder.dart';
import 'package:mycelium/features/graph/models/models.dart';

void main() {
  group('Markdown clipboard round-trip', () {
    test('markdown → insert → buildContent → toMarkdown preserves structure', () {
      final controller = ContentTextEditingController();
      controller.value = TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );

      const markdown = '# Title\n\n**Bold** and *italic*\n\n- Item 1\n- Item 2';
      controller.insertMarkdownSpans(markdown);

      final content = controller.buildContent();
      final result = ContentFactory.toMarkdown(content);

      expect(result, contains('# Title'));
      expect(result, contains('**Bold**'));
      expect(result, contains('*italic*'));
      expect(result, contains('- Item 1'));
      expect(result, contains('- Item 2'));
    });

    test('selection markdown output matches input', () {
      final controller = ContentTextEditingController();
      const input = '# Heading\n\nSome **bold** text';
      final content = ContentFactory.fromText(input);
      controller.loadFromContent(content);

      controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.text.length);
      final output = controller.selectedTextAsMarkdown();

      final reparsed = ContentFactory.fromText(output);
      expect(reparsed.blocks.length, content.blocks.length);
      expect(reparsed.blocks.first.blockType, BlockType.heading);
    });
  });
}
