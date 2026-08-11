import 'package:flutter/material.dart';

/// A reusable widget that encapsulates mouse hover detection, tap highlight tracking,
/// animated scaling, and optional tooltips to unify premium micro-animations across
/// interactive widgets in the codebase.
class HoverScaleButton extends StatefulWidget {
  final Widget? child;
  final Widget Function(BuildContext context, bool isHovered, bool isPressed)?
  builder;
  final VoidCallback? onTap;
  final double hoverScale;
  final double pressScale;
  final Duration duration;
  final bool isEnabled;
  final String? tooltip;
  final BorderRadius? borderRadius;
  final ValueChanged<bool>? onHoverChanged;

  const HoverScaleButton({
    super.key,
    this.child,
    this.builder,
    this.onTap,
    this.hoverScale = 1.05,
    this.pressScale = 0.95,
    this.duration = const Duration(milliseconds: 100),
    this.isEnabled = true,
    this.tooltip,
    this.borderRadius,
    this.onHoverChanged,
  }) : assert(
         child != null || builder != null,
         'Either child or builder must be provided',
       );

  @override
  State<HoverScaleButton> createState() => _HoverScaleButtonState();
}

class _HoverScaleButtonState extends State<HoverScaleButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  void _updateHover(bool hovered) {
    if (!widget.isEnabled) return;
    if (_isHovered != hovered) {
      setState(() => _isHovered = hovered);
      widget.onHoverChanged?.call(hovered);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.isEnabled && widget.onTap != null;
    double scale = 1.0;
    if (enabled) {
      if (_isPressed) {
        scale = widget.pressScale;
      } else if (_isHovered) {
        scale = widget.hoverScale;
      }
    }

    final content = widget.builder != null
        ? widget.builder!(context, _isHovered, _isPressed)
        : widget.child!;

    Widget result = MouseRegion(
      onEnter: (_) => _updateHover(true),
      onExit: (_) {
        _updateHover(false);
        if (_isPressed) setState(() => _isPressed = false);
      },
      child: AnimatedScale(
        scale: scale,
        duration: widget.duration,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: widget.borderRadius,
            onTap: enabled ? widget.onTap : null,
            onHighlightChanged: enabled
                ? (highlighted) => setState(() => _isPressed = highlighted)
                : null,
            child: content,
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      result = Tooltip(message: widget.tooltip!, child: result);
    }

    return result;
  }
}
