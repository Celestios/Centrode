import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'content_text_editing_controller.dart';

class MarkdownTextSelectionControls extends MaterialTextSelectionControls {
  final ContentTextEditingController controller;

  MarkdownTextSelectionControls({required this.controller});

  @override
  // ignore: deprecated_member_use
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
    return const SizedBox.shrink();
  }

  @override
  void handleSelectAll(TextSelectionDelegate delegate) {
    delegate.selectAll(SelectionChangedCause.toolbar);
  }
}
