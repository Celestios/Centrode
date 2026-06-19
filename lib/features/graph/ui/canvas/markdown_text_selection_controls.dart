import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import 'content_text_editing_controller.dart';

final _log = Logger('MarkdownTextSelectionControls');

class MarkdownTextSelectionControls extends TextSelectionControls {
  ContentTextEditingController? controller;

  int get contextMenuButtonCount => 4;

  @override
  Size getHandleSize(double textLineHeight) => const Size(22.0, 22.0);

  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ValueListenable<ClipboardStatus>? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    return TextSelectionToolbar(
      anchorAbove: selectionMidpoint,
      anchorBelow: selectionMidpoint,
      children: [
        TextSelectionToolbarTextButton(
          onPressed: () {
            _handleCopyAsMarkdown(delegate);
          },
          padding: const EdgeInsets.symmetric(horizontal: 14.5, vertical: 9.5),
          child: const Text('Copy'),
        ),
        TextSelectionToolbarTextButton(
          onPressed: () {
            _handleCopyAsPlainText(delegate);
          },
          padding: const EdgeInsets.symmetric(horizontal: 14.5, vertical: 9.5),
          child: const Text('Copy as Plain Text'),
        ),
        TextSelectionToolbarTextButton(
          onPressed: () {
            _handlePaste(delegate);
          },
          padding: const EdgeInsets.symmetric(horizontal: 14.5, vertical: 9.5),
          child: const Text('Paste'),
        ),
        TextSelectionToolbarTextButton(
          onPressed: () {
            handleSelectAll(delegate);
          },
          padding: const EdgeInsets.symmetric(horizontal: 14.5, vertical: 9.5),
          child: const Text('Select All'),
        ),
      ],
    );
  }

  void _handleCopyAsMarkdown(TextSelectionDelegate delegate) {
    final ctrl = controller;
    if (ctrl == null) {
      delegate.copySelection(SelectionChangedCause.toolbar);
      return;
    }
    final markdown = ctrl.selectedTextAsMarkdown();
    Clipboard.setData(ClipboardData(text: markdown));
    delegate.hideToolbar();
    _log.fine('Copied as markdown: ${markdown.length} chars');
  }

  void _handleCopyAsPlainText(TextSelectionDelegate delegate) {
    final text = delegate.textEditingValue.text;
    final selection = delegate.textEditingValue.selection;
    if (!selection.isCollapsed && selection.start >= 0 && selection.end >= 0) {
      final selectedText = text.substring(selection.start, selection.end);
      Clipboard.setData(ClipboardData(text: selectedText));
    }
    delegate.hideToolbar();
  }

  void _handlePaste(TextSelectionDelegate delegate) async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text == null || data!.text!.isEmpty) {
      delegate.hideToolbar();
      return;
    }

    final clipboardText = data.text!;
    final ctrl = controller;
    if (ctrl != null) {
      ctrl.insertMarkdownSpans(clipboardText);
    } else {
      final current = delegate.textEditingValue;
      delegate.userUpdateTextEditingValue(
        TextEditingValue(
          text: current.text.replaceRange(
            current.selection.start,
            current.selection.extentOffset,
            clipboardText,
          ),
          selection: TextSelection.collapsed(
            offset: current.selection.start + clipboardText.length,
          ),
        ),
        SelectionChangedCause.toolbar,
      );
    }
    delegate.hideToolbar();
    _log.fine('Pasted markdown: ${clipboardText.length} chars');
  }

  @override
  Widget buildHandle(
    BuildContext context,
    TextSelectionHandleType type,
    double textLineHeight, [
    VoidCallback? onTap,
  ]) {
    final Widget handle = SizedBox.square(
      dimension: 22.0,
      child: GestureDetector(onTap: onTap, behavior: HitTestBehavior.translucent),
    );

    return switch (type) {
      TextSelectionHandleType.left => Transform.rotate(
        angle: 3.14159265 / 2.0,
        child: handle,
      ),
      TextSelectionHandleType.right => handle,
      TextSelectionHandleType.collapsed => Transform.rotate(
        angle: 3.14159265 / 4.0,
        child: handle,
      ),
    };
  }

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    return switch (type) {
      TextSelectionHandleType.collapsed => const Offset(11.0, -4.0),
      TextSelectionHandleType.left => const Offset(22.0, 0),
      TextSelectionHandleType.right => Offset.zero,
    };
  }

  @override
  bool canCopy(TextSelectionDelegate delegate) => true;

  @override
  bool canCut(TextSelectionDelegate delegate) => true;

  @override
  bool canPaste(TextSelectionDelegate delegate) => true;

  @override
  bool canSelectAll(TextSelectionDelegate delegate) => true;

  @override
  void handleCopy(TextSelectionDelegate delegate) {
    _handleCopyAsMarkdown(delegate);
  }

  @override
  void handleCut(TextSelectionDelegate delegate) {
    final ctrl = controller;
    if (ctrl != null) {
      final markdown = ctrl.selectedTextAsMarkdown();
      Clipboard.setData(ClipboardData(text: markdown));
    }
    delegate.cutSelection(SelectionChangedCause.toolbar);
  }

  @override
  Future<void> handlePaste(TextSelectionDelegate delegate) async {
    _handlePaste(delegate);
  }

  @override
  void handleSelectAll(TextSelectionDelegate delegate) {
    delegate.selectAll(SelectionChangedCause.toolbar);
  }
}
