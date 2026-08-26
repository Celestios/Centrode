import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Live Node Showcase Object rendering in real-time with subtle blueprint background.
class NodeShowcaseCard extends StatelessWidget {
  final String shape;
  final String fillStyle;
  final double opacity;
  final double cornerRadius;
  final String borderStyle;
  final double borderWidth;
  final double borderOpacity;
  final String fontFamily;
  final double fontSize;
  final String textAlign;
  final String highlightColor;
  final Color accentColor;

  const NodeShowcaseCard({
    super.key,
    required this.shape,
    required this.fillStyle,
    required this.opacity,
    required this.cornerRadius,
    required this.borderStyle,
    required this.borderWidth,
    required this.borderOpacity,
    required this.fontFamily,
    required this.fontSize,
    required this.textAlign,
    required this.highlightColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    BorderRadius effectiveRadius;
    if (shape == 'circle') {
      effectiveRadius = BorderRadius.circular(100);
    } else if (shape == 'capsule') {
      effectiveRadius = BorderRadius.circular(24);
    } else if (shape == 'sharp') {
      effectiveRadius = BorderRadius.zero;
    } else {
      effectiveRadius = BorderRadius.circular(cornerRadius.clamp(0, 24));
    }

    Color nodeBgColor;
    if (fillStyle == 'solid') {
      nodeBgColor = accentColor.withValues(alpha: (opacity / 100).clamp(0.05, 1.0));
    } else if (fillStyle == 'glass') {
      nodeBgColor = Colors.black.withValues(alpha: (0.45 * (opacity / 100)).clamp(0.05, 0.95));
    } else {
      nodeBgColor = Colors.transparent;
    }

    final borderColor = accentColor.withValues(alpha: (borderOpacity / 100).clamp(0.0, 1.0));

    return Container(
      height: 85,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 0.8,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: ShowcaseGridPainter(accentColor.withValues(alpha: 0.12)),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: shape == 'circle' ? 62 : 140,
            height: shape == 'circle' ? 62 : (shape == 'capsule' ? 36 : 46),
            decoration: BoxDecoration(
              color: nodeBgColor,
              borderRadius: effectiveRadius,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.15),
                  blurRadius: 10,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: CustomPaint(
              painter: BorderPainter(
                borderStyle: borderStyle,
                borderWidth: borderWidth,
                borderColor: borderColor,
                borderRadius: effectiveRadius,
                isCircle: shape == 'circle',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ShowcaseGridPainter extends CustomPainter {
  final Color dotColor;

  ShowcaseGridPainter(this.dotColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;

    const spacing = 16.0;
    for (double x = 8.0; x < size.width; x += spacing) {
      for (double y = 8.0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.7, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ShowcaseGridPainter oldDelegate) =>
      oldDelegate.dotColor != dotColor;
}

class BorderPainter extends CustomPainter {
  final String borderStyle;
  final double borderWidth;
  final Color borderColor;
  final BorderRadius borderRadius;
  final bool isCircle;

  BorderPainter({
    required this.borderStyle,
    required this.borderWidth,
    required this.borderColor,
    required this.borderRadius,
    required this.isCircle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (borderWidth <= 0 || borderColor.a <= 0) return;

    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    final rect = Offset.zero & size;
    final path = Path();

    if (isCircle) {
      path.addOval(rect.deflate(borderWidth / 2));
    } else {
      final rrect = borderRadius.toRRect(rect).deflate(borderWidth / 2);
      path.addRRect(rrect);
    }

    if (borderStyle == 'solid') {
      canvas.drawPath(path, paint);
    } else {
      final dashWidth = borderStyle == 'dashed' ? 6.0 : 2.0;
      final dashSpace = borderStyle == 'dashed' ? 4.0 : 3.0;

      for (final metric in path.computeMetrics()) {
        double distance = 0.0;
        while (distance < metric.length) {
          final len = math.min(dashWidth, metric.length - distance);
          final extract = metric.extractPath(distance, distance + len);
          canvas.drawPath(extract, paint);
          distance += dashWidth + dashSpace;
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant BorderPainter oldDelegate) {
    return oldDelegate.borderStyle != borderStyle ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.isCircle != isCircle;
  }
}
