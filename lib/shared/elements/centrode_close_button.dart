import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class CentrodeCloseButton extends StatefulWidget {
  final VoidCallback? onTap;
  final double size;

  const CentrodeCloseButton({
    super.key,
    this.onTap,
    this.size = 34.0,
  });

  @override
  State<CentrodeCloseButton> createState() => _CentrodeCloseButtonState();
}

class _CentrodeCloseButtonState extends State<CentrodeCloseButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap ?? () => Navigator.of(context).maybePop(),
        child: AnimatedContainer(
          duration: UiMotion.fast,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isHovered ? const Color(0xFFFF5252) : const Color(0xFFE53935),
            boxShadow: [
              BoxShadow(
                color: (_isHovered ? const Color(0xFFFF5252) : const Color(0xFFE53935))
                    .withValues(alpha: 0.35),
                blurRadius: _isHovered ? 8.0 : 4.0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.close_rounded,
              size: widget.size * (18.0 / 34.0),
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
