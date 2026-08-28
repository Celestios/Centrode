import 'package:flutter/material.dart';
import 'showcase_painters.dart';

/// Live Relation Showcase Object rendering in real-time.
class RelationShowcaseCard extends StatelessWidget {
  final String labelShape;
  final String labelFill;
  final double padding;
  final double cornerRadius;
  final String font;
  final double fontSize;
  final String routingStrategy;
  final double curveTension;
  final String strokePattern;
  final double strokeWidth;
  final String startCap;
  final String endCap;
  final String crossingStrategy;
  final Color accentColor;

  const RelationShowcaseCard({
    super.key,
    required this.labelShape,
    required this.labelFill,
    required this.padding,
    required this.cornerRadius,
    required this.font,
    required this.fontSize,
    required this.routingStrategy,
    required this.curveTension,
    required this.strokePattern,
    required this.strokeWidth,
    required this.startCap,
    required this.endCap,
    required this.crossingStrategy,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    String? effectiveFontFamily;
    if (font == 'mono') {
      effectiveFontFamily = 'monospace';
    } else if (font == 'outfit') {
      effectiveFontFamily = 'Outfit';
    } else {
      effectiveFontFamily = null;
    }

    BorderRadius labelRadius;
    if (labelShape == 'capsule') {
      labelRadius = BorderRadius.circular(20);
    } else if (labelShape == 'sharp') {
      labelRadius = BorderRadius.zero;
    } else {
      labelRadius = BorderRadius.circular(cornerRadius.clamp(0, 16));
    }

    Color labelBg;
    if (labelFill == 'solid') {
      labelBg = accentColor.withValues(alpha: 0.9);
    } else if (labelFill == 'glass') {
      labelBg = Colors.black.withValues(alpha: 0.65);
    } else {
      labelBg = Colors.transparent;
    }

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
          Positioned.fill(
            child: CustomPaint(
              painter: RelationPathPainter(
                routingStrategy: routingStrategy,
                curveTension: curveTension,
                strokePattern: strokePattern,
                strokeWidth: strokeWidth,
                startCap: startCap,
                endCap: endCap,
                color: accentColor,
              ),
            ),
          ),
          if (labelShape != 'none')
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.symmetric(
                horizontal: padding.clamp(4.0, 14.0),
                vertical: (padding * 0.35).clamp(2.0, 6.0),
              ),
              decoration: BoxDecoration(
                color: labelBg,
                borderRadius: labelRadius,
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.85),
                  width: 0.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                'relates_to',
                style: TextStyle(
                  fontFamily: effectiveFontFamily,
                  fontSize: (fontSize * 0.8).clamp(8.0, 12.0),
                  fontWeight: FontWeight.w700,
                  color: labelFill == 'solid' ? Colors.black87 : Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class RelationPathPainter extends CustomPainter {
  final String routingStrategy;
  final double curveTension;
  final String strokePattern;
  final double strokeWidth;
  final String startCap;
  final String endCap;
  final Color color;

  RelationPathPainter({
    required this.routingStrategy,
    required this.curveTension,
    required this.strokePattern,
    required this.strokeWidth,
    required this.startCap,
    required this.endCap,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final inset = (size.width * 0.12).clamp(8.0, 24.0);
    final start = Offset(inset, size.height / 2);
    final end = Offset(size.width - inset, size.height / 2);

    final path = Path();
    path.moveTo(start.dx, start.dy);

    if (routingStrategy == 'straight') {
      path.lineTo(end.dx, end.dy);
    } else if (routingStrategy == 'curved') {
      final dx = end.dx - start.dx;
      final cx1 = start.dx + dx * 0.35;
      final cy1 = start.dy - 18.0 * curveTension;
      final cx2 = start.dx + dx * 0.65;
      final cy2 = end.dy + 18.0 * curveTension;
      path.cubicTo(cx1, cy1, cx2, cy2, end.dx, end.dy);
    } else if (routingStrategy == 'orthogonal') {
      final midX = (start.dx + end.dx) / 2;
      path.lineTo(midX, start.dy - 12);
      path.lineTo(midX, end.dy + 12);
      path.lineTo(end.dx, end.dy);
    } else if (routingStrategy == 'step') {
      final midX = (start.dx + end.dx) / 2;
      path.lineTo(midX, start.dy);
      path.lineTo(midX, end.dy);
      path.lineTo(end.dx, end.dy);
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    if (strokePattern == 'solid') {
      canvas.drawPath(path, paint);
    } else {
      drawDashedPath(canvas, path, paint, borderStyle: strokePattern);
    }

    // Start Cap
    if (startCap == 'circle') {
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawCircle(start, (strokeWidth + 2.0).clamp(2.5, 5.5), dotPaint);
    }

    // End Cap
    if (endCap == 'arrow') {
      final arrowPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      final arrowPath = Path();
      final arrowSize = (strokeWidth * 2.0 + 4).clamp(6.0, 12.0);
      arrowPath.moveTo(end.dx, end.dy);
      arrowPath.lineTo(end.dx - arrowSize, end.dy - arrowSize * 0.55);
      arrowPath.lineTo(end.dx - arrowSize * 0.7, end.dy);
      arrowPath.lineTo(end.dx - arrowSize, end.dy + arrowSize * 0.55);
      arrowPath.close();
      canvas.drawPath(arrowPath, arrowPaint);
    } else if (endCap == 'diamond') {
      final diamondPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      final dPath = Path();
      final dSize = (strokeWidth * 1.8 + 4).clamp(5.0, 10.0);
      dPath.moveTo(end.dx, end.dy);
      dPath.lineTo(end.dx - dSize * 0.6, end.dy - dSize * 0.45);
      dPath.lineTo(end.dx - dSize * 1.2, end.dy);
      dPath.lineTo(end.dx - dSize * 0.6, end.dy + dSize * 0.45);
      dPath.close();
      canvas.drawPath(dPath, diamondPaint);
    }
  }

  @override
  bool shouldRepaint(covariant RelationPathPainter oldDelegate) {
    return oldDelegate.routingStrategy != routingStrategy ||
        oldDelegate.curveTension != curveTension ||
        oldDelegate.strokePattern != strokePattern ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.startCap != startCap ||
        oldDelegate.endCap != endCap ||
        oldDelegate.color != color;
  }
}
