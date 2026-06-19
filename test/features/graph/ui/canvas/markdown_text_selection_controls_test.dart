import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mycelium/features/graph/ui/canvas/markdown_text_selection_controls.dart';

void main() {
  group('MarkdownTextSelectionControls', () {
    late MarkdownTextSelectionControls controls;

    setUp(() {
      controls = MarkdownTextSelectionControls();
    });

    test('can be instantiated', () {
      expect(controls, isA<TextSelectionControls>());
    });

    test('getHandleSize returns correct size', () {
      final size = controls.getHandleSize(20.0);
      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));
    });

    test('canCopy returns true', () {
      expect(controls.canCopy(_FakeDelegate()), isTrue);
    });

    test('canCut returns true', () {
      expect(controls.canCut(_FakeDelegate()), isTrue);
    });

    test('canPaste returns true', () {
      expect(controls.canPaste(_FakeDelegate()), isTrue);
    });

    test('canSelectAll returns true', () {
      expect(controls.canSelectAll(_FakeDelegate()), isTrue);
    });

    test('controller defaults to null', () {
      expect(controls.controller, isNull);
    });
  });
}

class _FakeDelegate with TextSelectionDelegate {
  @override
  TextEditingValue get textEditingValue => const TextEditingValue();

  @override
  void userUpdateTextEditingValue(TextEditingValue value, SelectionChangedCause cause) {}

  @override
  void hideToolbar([bool hideHandles = true]) {}

  @override
  void bringIntoView(TextPosition position) {}

  @override
  void cutSelection(SelectionChangedCause cause) {}

  @override
  Future<void> pasteText(SelectionChangedCause cause) async {}

  @override
  void selectAll(SelectionChangedCause cause) {}

  @override
  void copySelection(SelectionChangedCause cause) {}
}
