import 'dart:async';

import 'package:flutter/material.dart';

class HoverExpandableMenuBar extends StatefulWidget {
  final List<Widget> Function(BuildContext context, ButtonStyle menuButtonStyle)?
      menuBuilder;
  final VoidCallback? onClose;

  const HoverExpandableMenuBar({
    super.key,
    this.menuBuilder,
    this.onClose,
  });

  @override
  State<HoverExpandableMenuBar> createState() => _HoverExpandableMenuBarState();
}

class _HoverExpandableMenuBarState extends State<HoverExpandableMenuBar> {
  bool _isExpanded = false;
  Timer? _closeTimer;

  void _openMenu() {
    _closeTimer?.cancel();
    if (!_isExpanded) {
      setState(() => _isExpanded = true);
    }
  }

  void _scheduleCloseMenu() {
    _closeTimer = Timer(const Duration(milliseconds: 300), () {
      if (_isExpanded) {
        setState(() => _isExpanded = false);
      }
    });
  }

  void _closeMenu() {
    _closeTimer?.cancel();
    if (_isExpanded) {
      setState(() => _isExpanded = false);
    }
    widget.onClose?.call();
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final menuButtonStyle = ButtonStyle(
      minimumSize: WidgetStateProperty.all(Size.zero),
      padding: WidgetStateProperty.all(
        const EdgeInsets.only(left: 10, right: 10, top: 8, bottom: 12),
      ),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );

    return TapRegion(
      groupId: 'menu_bar_group',
      onTapOutside: (_) => _closeMenu(),
      child: MouseRegion(
        onEnter: (_) => _openMenu(),
        onExit: (_) => _scheduleCloseMenu(),
        child: AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Container(
            padding: const EdgeInsets.all(4),
            child: Icon(
              Icons.menu_rounded,
              size: 18,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
          secondChild: SizedBox(
            height: 32,
            child: Theme(
              data: theme.copyWith(
                hoverColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              ),
              child: MenuBar(
                style: MenuStyle(
                  backgroundColor: WidgetStateProperty.all(
                    Colors.transparent,
                  ),
                  elevation: WidgetStateProperty.all(0),
                  padding: WidgetStateProperty.all(EdgeInsets.zero),
                ),
                children: [
                  if (widget.menuBuilder != null)
                    ...widget.menuBuilder!(context, menuButtonStyle),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
