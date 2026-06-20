import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:mycelium/features/graph/ui/canvas/markdown_text_selection_controls.dart';
import 'package:mycelium/features/graph/ui/canvas/content_text_editing_controller.dart';

void main() {
  group('MarkdownTextSelectionControls', () {
    late MarkdownTextSelectionControls controls;
    late ContentTextEditingController controller;

    setUp(() {
      controller = ContentTextEditingController();
      controls = MarkdownTextSelectionControls(controller: controller);
    });

    test('can be instantiated', () {
      expect(controls, isA<TextSelectionControls>());
    });

    test('getHandleSize returns correct size', () {
      final size = controls.getHandleSize(20.0);
      expect(size.width, greaterThan(0));
      expect(size.height, greaterThan(0));
    });

    test('canCopy with selection returns true', () {
      final delegate = _FakeDelegate(
        text: 'hello',
        selection: const TextSelection(baseOffset: 0, extentOffset: 5),
      );
      expect(controls.canCopy(delegate), isTrue);
    });

    test('canCut with selection returns true', () {
      final delegate = _FakeDelegate(
        text: 'hello',
        selection: const TextSelection(baseOffset: 0, extentOffset: 5),
      );
      expect(controls.canCut(delegate), isTrue);
    });

    test('canPaste returns true', () {
      expect(controls.canPaste(_FakeDelegate()), isTrue);
    });

    test('canSelectAll returns true with partial selection', () {
      final delegate = _FakeDelegate(
        text: 'hello',
        selection: const TextSelection(baseOffset: 0, extentOffset: 3),
      );
      expect(controls.canSelectAll(delegate), isTrue);
    });

    test('canSelectAll returns false when all text selected', () {
      final delegate = _FakeDelegate(
        text: 'hello',
        selection: const TextSelection(baseOffset: 0, extentOffset: 5),
      );
      expect(controls.canSelectAll(delegate), isFalse);
    });

    test('controller is final and non-null', () {
      expect(controls.controller, same(controller));
    });
  });
}

class _FakeDelegate with TextSelectionDelegate {
  final String _text;
  final TextSelection _selection;

  _FakeDelegate({String text = '', TextSelection? selection})
      : _text = text,
        _selection = selection ?? const TextSelection.collapsed(offset: 0);

  @override
  TextEditingValue get textEditingValue => TextEditingValue(
        text: _text,
        selection: _selection,
      );

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
