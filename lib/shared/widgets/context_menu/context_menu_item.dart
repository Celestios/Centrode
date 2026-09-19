import 'package:flutter/widgets.dart';

class ContextMenuItem {
  final String label;
  final VoidCallback? onTap;
  final IconData? leadingIcon;
  final String? shortcut;
  final bool isDestructive;
  final bool isDivider;
  final bool isHeader;
  final bool visible;

  const ContextMenuItem({
    this.label = '',
    this.onTap,
    this.leadingIcon,
    this.shortcut,
    this.isDestructive = false,
    this.isDivider = false,
    this.isHeader = false,
    this.visible = true,
  });

  const ContextMenuItem.action({
    required this.label,
    required this.onTap,
    this.leadingIcon,
    this.shortcut,
    this.visible = true,
  })  : isDestructive = false,
        isDivider = false,
        isHeader = false;

  const ContextMenuItem.destructive({
    required this.label,
    required this.onTap,
    this.leadingIcon,
    this.shortcut,
    this.visible = true,
  })  : isDestructive = true,
        isDivider = false,
        isHeader = false;

  const ContextMenuItem.divider({this.visible = true})
      : label = '',
        onTap = null,
        leadingIcon = null,
        shortcut = null,
        isDestructive = false,
        isDivider = true,
        isHeader = false;

  const ContextMenuItem.header(this.label, {this.visible = true})
      : onTap = null,
        leadingIcon = null,
        shortcut = null,
        isDestructive = false,
        isDivider = false,
        isHeader = true;
}

typedef CentrodeMenuItem = ContextMenuItem;
