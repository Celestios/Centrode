import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:flutter/material.dart';

/// Clean sub-block container within a section shell.
/// The reset button only appears when hovering over the subsection.
class SubBlockShell extends StatefulWidget {
  final String title;
  final Widget child;
  final Color accentColor;
  final VoidCallback? onReset;

  const SubBlockShell({
    super.key,
    required this.title,
    required this.child,
    required this.accentColor,
    this.onReset,
  });

  @override
  State<SubBlockShell> createState() => _SubBlockShellState();
}

class _SubBlockShellState extends State<SubBlockShell> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayTitle = widget.title.isNotEmpty
        ? '${widget.title[0].toUpperCase()}${widget.title.substring(1)}'
        : widget.title;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header outside of box with title on left and refresh on right (inset 14px from right scrollbar)
            Padding(
              padding: const EdgeInsets.only(left: 2.0, right: 14.0, bottom: 5.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    displayTitle,
                    style: TextStyle(
                      fontSize: UiFont.compact,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.04,
                      color: widget.accentColor.withValues(alpha: 0.88),
                    ),
                  ),
                  if (widget.onReset != null)
                    AnimatedOpacity(
                      duration: UiMotion.fast,
                      curve: Curves.easeOut,
                      opacity: _isHovered ? 1.0 : 0.0,
                      child: IgnorePointer(
                        ignoring: !_isHovered,
                        child: Tooltip(
                          message: 'Reset $displayTitle formatting',
                          child: MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: widget.onReset,
                              child: Container(
                                padding: UiInsets.tight,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(UiRadius.control),
                                  color: Colors.transparent,
                                ),
                                child: Icon(
                                  Icons.refresh_rounded,
                                  size: 15,
                                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.55) ?? Colors.white54,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Sub-block glass container
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(UiRadius.card),
                border: Border.all(
                  color: widget.accentColor.withValues(alpha: 0.14),
                  width: 0.6,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
              child: widget.child,
            ),
          ],
        ),
      ),
    );
  }
}
