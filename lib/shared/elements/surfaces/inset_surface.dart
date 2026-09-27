import 'package:flutter/material.dart';
import 'surface_mode.dart';

class CentrodeInsetPainter extends CustomPainter {
  final double cornerRadius;
  final bool isDark;
  final double depth;
  final bool enabled;
  final double focusProgress;
  final Color? accentColor;
  final Gradient? cardGradient;

  const CentrodeInsetPainter({
    required this.cornerRadius,
    required this.isDark,
    this.depth = 1.2,
    this.enabled = true,
    this.focusProgress = 0.0,
    this.accentColor,
    this.cardGradient,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(cornerRadius));
    final accent = accentColor ?? const Color(0xFF388E81);
    final effectiveDepth = (enabled ? depth : (depth * 0.75)).clamp(0.4, 2.5);

    if (isDark) {
      final floorPaint = Paint()
        ..color = enabled
            ? const Color(0xFF000000).withValues(alpha: 0.55)
            : const Color(0xFF000000).withValues(alpha: 0.75);
      canvas.drawRRect(rrect, floorPaint);
    } else {
      final baseDiffusionPaint = Paint()
        ..color = const Color(0xFFEFE8DE).withValues(alpha: enabled ? 0.40 : 0.55);
      canvas.drawRRect(rrect, baseDiffusionPaint);

      final debossWashPaint = Paint()
        ..color = const Color(0xFF423024).withValues(alpha: enabled ? 0.09 : 0.14);
      canvas.drawRRect(rrect, debossWashPaint);
    }

    canvas.save();
    canvas.clipRRect(rrect);

    final shadowPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(rect.inflate(16.0))
      ..addRRect(rrect);

    final darkOffset = Offset(effectiveDepth * 0.9, effectiveDepth * 1.2);
    final darkStepPaint = Paint()
      ..color = isDark
          ? Colors.black.withValues(alpha: enabled ? 0.72 : 0.40)
          : const Color(0xFF423024).withValues(alpha: enabled ? 0.44 : 0.22)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, effectiveDepth * 2.6);

    canvas.save();
    canvas.translate(darkOffset.dx, darkOffset.dy);
    canvas.drawPath(shadowPath, darkStepPaint);
    canvas.restore();

    final creasePaint = Paint()
      ..color = isDark
          ? Colors.black.withValues(alpha: enabled ? 0.78 : 0.44)
          : const Color(0xFF2E1F15).withValues(alpha: enabled ? 0.42 : 0.22)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, effectiveDepth * 0.9);

    canvas.save();
    canvas.translate(darkOffset.dx * 0.5, darkOffset.dy * 0.5);
    canvas.drawPath(shadowPath, creasePaint);
    canvas.restore();

    final lightOffset = Offset(-effectiveDepth * 0.5, -effectiveDepth * 0.65);
    final lightStepPaint = Paint()
      ..color = isDark
          ? Colors.white.withValues(alpha: enabled ? 0.16 : 0.08)
          : Colors.white.withValues(alpha: enabled ? 0.60 : 0.30)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, effectiveDepth * 1.4);

    canvas.save();
    canvas.translate(lightOffset.dx, lightOffset.dy);
    canvas.drawPath(shadowPath, lightStepPaint);
    canvas.restore();

    canvas.restore();

    if (focusProgress > 0) {
      final borderGlow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = accent.withValues(alpha: (isDark ? 0.55 : 0.42) * focusProgress)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);
      canvas.drawRRect(rrect, borderGlow);

      final rimPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.3
        ..color = accent.withValues(alpha: (isDark ? 0.90 : 0.85) * focusProgress);
      canvas.drawRRect(rrect, rimPaint);
    } else {
      final rimPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  Colors.black.withValues(alpha: enabled ? 0.50 : 0.30),
                  Colors.white.withValues(alpha: enabled ? 0.05 : 0.02),
                  Colors.white.withValues(alpha: enabled ? 0.16 : 0.08),
                ]
              : [
                  const Color(0xFF4A382C).withValues(alpha: enabled ? 0.26 : 0.14),
                  Colors.white.withValues(alpha: enabled ? 0.30 : 0.15),
                  Colors.white.withValues(alpha: enabled ? 0.80 : 0.45),
                ],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(rect);
      canvas.drawRRect(rrect, rimPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CentrodeInsetPainter oldDelegate) {
    return oldDelegate.cornerRadius != cornerRadius ||
        oldDelegate.isDark != isDark ||
        oldDelegate.depth != depth ||
        oldDelegate.enabled != enabled ||
        oldDelegate.focusProgress != focusProgress ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.cardGradient != cardGradient;
  }
}

class CentrodeInsetSurface extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double cornerRadius;
  final double depth;
  final bool enabled;
  final double focusProgress;
  final Color? accentColor;

  const CentrodeInsetSurface({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.cornerRadius = 14.0,
    this.depth = 1.5,
    this.enabled = true,
    this.focusProgress = 0.0,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scope = CentrodeSurfaceScope.maybeOf(context);

    return CustomPaint(
      painter: CentrodeInsetPainter(
        cornerRadius: cornerRadius,
        isDark: isDark,
        depth: depth,
        enabled: enabled,
        focusProgress: focusProgress,
        accentColor: accentColor ?? scope?.accentColor,
        cardGradient: scope?.partialColorGradient,
      ),
      child: Container(
        width: width,
        height: height,
        padding: padding,
        child: child,
      ),
    );
  }
}

class CentrodeDebossedField extends StatefulWidget {
  final String hintText;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool isPassword;
  final bool enabled;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final double depth;
  final double height;
  final double cornerRadius;
  final Color? accentColor;

  const CentrodeDebossedField({
    super.key,
    required this.hintText,
    this.prefixIcon,
    this.suffix,
    this.isPassword = false,
    this.enabled = true,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.depth = 1.0,
    this.height = 44.0,
    this.cornerRadius = 14.0,
    this.accentColor,
  });

  @override
  State<CentrodeDebossedField> createState() => _CentrodeDebossedFieldState();
}

class _CentrodeDebossedFieldState extends State<CentrodeDebossedField>
    with SingleTickerProviderStateMixin {
  late final FocusNode _focusNode;
  late final AnimationController _focusController;
  late final TextEditingController _controller;
  bool _internalController = false;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _controller = TextEditingController();
      _internalController = true;
    } else {
      _controller = widget.controller!;
    }

    _focusNode = FocusNode();
    _focusController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      _focusController.forward();
    } else {
      _focusController.reverse();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _focusController.dispose();
    if (_internalController) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scope = CentrodeSurfaceScope.maybeOf(context);
    final accent = widget.accentColor ?? scope?.accentColor ?? Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: _focusController,
      builder: (context, child) {
        final focusT = _focusController.value;

        return MouseRegion(
          cursor: widget.enabled ? SystemMouseCursors.text : SystemMouseCursors.forbidden,
          child: SizedBox(
            height: widget.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: CentrodeInsetPainter(
                    cornerRadius: widget.cornerRadius,
                    isDark: isDark,
                    depth: widget.depth,
                    enabled: widget.enabled,
                    focusProgress: focusT,
                    accentColor: accent,
                    cardGradient: scope?.partialColorGradient,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0),
                  child: Row(
                    children: [
                      if (widget.prefixIcon != null) ...[
                        Icon(
                          widget.prefixIcon,
                          size: 18.0,
                          color: isDark
                              ? Colors.white.withValues(alpha: widget.enabled ? 0.60 : 0.30)
                              : const Color(0xFF4A382C).withValues(alpha: widget.enabled ? 0.65 : 0.35),
                        ),
                        const SizedBox(width: 10.0),
                      ],
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          enabled: widget.enabled,
                          obscureText: widget.isPassword,
                          onChanged: widget.onChanged,
                          onSubmitted: widget.onSubmitted,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFFF1F5F9) : const Color(0xFF1E252B),
                          ),
                          decoration: InputDecoration(
                            hintText: widget.hintText,
                            hintStyle: TextStyle(
                              fontSize: 13.5,
                              color: isDark
                                  ? const Color(0xFF94A3B8).withValues(alpha: 0.60)
                                  : const Color(0xFF75818D).withValues(alpha: 0.70),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      if (widget.suffix != null) widget.suffix!,
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
