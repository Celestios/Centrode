import 'package:flutter/material.dart';

/// Semantic actions for dialogs, modals, and prompt bars.
enum DialogActionKind {
  confirm(label: 'CONFIRM', isDestructive: false, icon: Icons.check_rounded),
  cancel(label: 'CANCEL', isDestructive: false, icon: Icons.close_rounded),
  delete(label: 'DELETE', isDestructive: true, icon: Icons.delete_outline_rounded),
  save(label: 'SAVE', isDestructive: false, icon: Icons.bookmark_add_outlined),
  insert(label: 'INSERT', isDestructive: false, icon: Icons.add_link_rounded),
  retry(label: 'RETRY', isDestructive: false, icon: Icons.refresh_rounded),
  close(label: 'CLOSE', isDestructive: false, icon: Icons.close_rounded),
  apply(label: 'APPLY', isDestructive: false, icon: Icons.done_all_rounded);

  final String label;
  final bool isDestructive;
  final IconData icon;

  const DialogActionKind({
    required this.label,
    required this.isDestructive,
    required this.icon,
  });
}

/// Visual variants for standard Centrode buttons.
enum UiButtonVariant {
  primary,
  secondary,
  subtle,
  destructive,
  ghost,
}

/// Standardized text alignment enum replacing raw strings.
enum TextAlignmentKind {
  left(label: 'Left', icon: Icons.format_align_left_rounded, align: TextAlign.left),
  center(label: 'Center', icon: Icons.format_align_center_rounded, align: TextAlign.center),
  right(label: 'Right', icon: Icons.format_align_right_rounded, align: TextAlign.right),
  justify(label: 'Justify', icon: Icons.format_align_justify_rounded, align: TextAlign.justify);

  final String label;
  final IconData icon;
  final TextAlign align;

  const TextAlignmentKind({
    required this.label,
    required this.icon,
    required this.align,
  });
}

/// Standardized reading direction enum.
enum TextDirectionKind {
  ltr(label: 'LTR', direction: TextDirection.ltr),
  rtl(label: 'RTL', direction: TextDirection.rtl);

  final String label;
  final TextDirection direction;

  const TextDirectionKind({
    required this.label,
    required this.direction,
  });
}

/// Standardized font weight / formatting toggles.
enum TextFormatStyleKind {
  bold(label: 'B', tag: 'bold', tooltip: 'Bold (Ctrl+B)'),
  italic(label: 'I', tag: 'italic', tooltip: 'Italic (Ctrl+I)'),
  underline(label: 'U', tag: 'underline', tooltip: 'Underline (Ctrl+U)'),
  strikethrough(label: 'S', tag: 'strike', tooltip: 'Strikethrough (Ctrl+Shift+X)'),
  code(label: '</>', tag: 'code', tooltip: 'Inline Code (Ctrl+E)');

  final String label;
  final String tag;
  final String tooltip;

  const TextFormatStyleKind({
    required this.label,
    required this.tag,
    required this.tooltip,
  });
}
