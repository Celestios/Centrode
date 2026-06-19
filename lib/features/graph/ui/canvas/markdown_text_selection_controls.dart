import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

import 'content_text_editing_controller.dart';

final _log = Logger('MarkdownTextSelectionControls');

class MarkdownTextSelectionControls extends MaterialTextSelectionControls {
  ContentTextEditingController? controller;

  MarkdownTextSelectionControls({this.controller});

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
  void handleCopy(TextSelectionDelegate delegate) {
    _handleCopyAsMarkdown(delegate);
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
