import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mycelium/features/graph/ui/canvas/text/text_format_state_machine.dart';
import 'package:mycelium/features/graph/ui/canvas/text/text_format_models.dart';

void main() {
  group('TextFormatStateMachine', () {
    late TextFormatStateMachine stateMachine;
    late List<FormattingSpan> spans;
    late ValueNotifier<TextAlign> alignNotifier;
    late String text;
    late TextSelection selection;

    setUp(() {
      spans = [];
      alignNotifier = ValueNotifier(TextAlign.center);
      text = 'Line 1\nLine 2\nLine 3';
      selection = const TextSelection(baseOffset: 0, extentOffset: 6);

      stateMachine = TextFormatStateMachine(
        formattingSpans: spans,
        textAlignNotifier: alignNotifier,
        notifyListeners: () {},
        getText: () => text,
        setValue: (val) {
          text = val.text;
          selection = val.selection;
        },
        getSelection: () => selection,
      );
    });

    test('toggleFormat adds bold formatting span', () {
      stateMachine.toggleFormat(TextFormatType.bold);
      expect(spans.length, equals(1));
      expect(spans.first.type, equals(TextFormatType.bold));
      expect(spans.first.start, equals(0));
      expect(spans.first.end, equals(6));
    });

    test('toggleBlockFormat adds bullet list prefix to target line', () {
      selection = const TextSelection(baseOffset: 2, extentOffset: 2);
      stateMachine.toggleBlockFormat(TextFormatType.bulletList);

      expect(text, startsWith('• Line 1'));
    });
  });
}
