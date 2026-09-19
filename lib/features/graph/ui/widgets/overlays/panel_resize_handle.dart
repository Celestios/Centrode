import 'package:flutter/material.dart';
import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';

class PanelResizeHandle extends StatefulWidget {
  final double width;
  final double height;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<DragUpdateDetails> onDragUpdate;
  final ValueChanged<DragEndDetails> onDragEnd;
  final Widget child;

  const PanelResizeHandle({
    super.key,
    required this.width,
    required this.height,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.child,
  });

  @override
  State<PanelResizeHandle> createState() => _PanelResizeHandleState();
}

class _PanelResizeHandleState extends State<PanelResizeHandle> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onToggleExpanded,
        onHorizontalDragUpdate: widget.onDragUpdate,
        onHorizontalDragEnd: widget.onDragEnd,
        behavior: HitTestBehavior.opaque,
        child: GlassPanel(
          width: widget.width,
          height: widget.height,
          borderRadius: UiRadius.panel,
          blur: 12.0,
          child: AnimatedContainer(
            duration: UiMotion.fast,
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
            decoration: BoxDecoration(
              color: _isHovered
                  ? primaryColor.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(UiRadius.panel),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
