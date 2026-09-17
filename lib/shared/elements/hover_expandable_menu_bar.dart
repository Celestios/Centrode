import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:centrode/shared/widgets/context_menu_overlay.dart';
import 'dart:async';

import 'package:flutter/material.dart';

class CentrodeMenuSection {
  final String title;
  final List<ContextMenuItem> items;

  const CentrodeMenuSection({
    required this.title,
    required this.items,
  });
}

class HoverExpandableMenuBar extends StatefulWidget {
  final List<CentrodeMenuSection>? sections;
  final List<Widget> Function(BuildContext context, ButtonStyle menuButtonStyle)?
      menuBuilder;
  final VoidCallback? onClose;

  const HoverExpandableMenuBar({
    super.key,
    this.sections,
    this.menuBuilder,
    this.onClose,
  });

  @override
  State<HoverExpandableMenuBar> createState() => _HoverExpandableMenuBarState();
}

class _HoverExpandableMenuBarState extends State<HoverExpandableMenuBar> {
  bool _isExpanded = false;
  Timer? _closeTimer;
  OverlayEntry? _openMenuEntry;
  String? _activeSectionTitle;

  void _openMenu() {
    _closeTimer?.cancel();
    if (!_isExpanded) {
      setState(() => _isExpanded = true);
    }
  }

  void _scheduleCloseMenu() {
    _closeTimer = Timer(const Duration(milliseconds: 300), () {
      if (_isExpanded && _activeSectionTitle == null) {
        setState(() => _isExpanded = false);
      }
    });
  }

  void _closeMenu() {
    _closeTimer?.cancel();
    _openMenuEntry?.remove();
    _openMenuEntry = null;
    if (_isExpanded) {
      setState(() {
        _isExpanded = false;
        _activeSectionTitle = null;
      });
    }
    widget.onClose?.call();
  }

  void _openSectionMenu(BuildContext btnContext, CentrodeMenuSection section) {
    _openMenuEntry?.remove();
    _openMenuEntry = null;

    final renderBox = btnContext.findRenderObject() as RenderBox;
    final rect = renderBox.localToGlobal(Offset.zero) & renderBox.size;

    setState(() => _activeSectionTitle = section.title);

    _openMenuEntry = CentrodeContextMenu.showAt(
      context: btnContext,
      targetRect: rect,
      items: section.items,
      onDismissed: () {
        if (mounted) {
          setState(() => _activeSectionTitle = null);
        }
        _openMenuEntry = null;
      },
    );
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _openMenuEntry?.remove();
    _openMenuEntry = null;
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
          duration: UiMotion.standard,
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: Container(
            padding: UiInsets.tight,
            child: Icon(
              Icons.menu_rounded,
              size: UiIconSize.standard,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
            ),
          ),
          secondChild: SizedBox(
            height: UiControlSize.standard,
            child: widget.sections != null
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final section in widget.sections!)
                        _SectionHeaderButton(
                          section: section,
                          isActive: _activeSectionTitle == section.title,
                          onPressed: (btnContext) =>
                              _openSectionMenu(btnContext, section),
                          onHover: (btnContext) {
                            if (_activeSectionTitle != null &&
                                _activeSectionTitle != section.title) {
                              _openSectionMenu(btnContext, section);
                            }
                          },
                        ),
                    ],
                  )
                : Theme(
                    data: theme.copyWith(
                      hoverColor:
                          theme.colorScheme.primary.withValues(alpha: 0.1),
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

class _SectionHeaderButton extends StatefulWidget {
  final CentrodeMenuSection section;
  final bool isActive;
  final void Function(BuildContext) onPressed;
  final void Function(BuildContext) onHover;

  const _SectionHeaderButton({
    required this.section,
    required this.isActive,
    required this.onPressed,
    required this.onHover,
  });

  @override
  State<_SectionHeaderButton> createState() => _SectionHeaderButtonState();
}

class _SectionHeaderButtonState extends State<_SectionHeaderButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isHighlighted = widget.isActive || _isHovered;

    final hoverBg = widget.isActive
        ? theme.colorScheme.primary.withValues(alpha: 0.18)
        : (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onHover(context);
      },
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => widget.onPressed(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
          decoration: BoxDecoration(
            color: isHighlighted ? hoverBg : Colors.transparent,
            borderRadius: BorderRadius.circular(UiRadius.control),
          ),
          child: Text(
            widget.section.title,
            style: TextStyle(
              fontSize: UiFont.standard,
              fontWeight: FontWeight.w500,
              color: widget.isActive
                  ? theme.colorScheme.primary
                  : (theme.textTheme.bodyMedium?.color ?? Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
