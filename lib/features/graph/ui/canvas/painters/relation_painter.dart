import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import 'package:mycelium/src/rust/domain/enums.dart';
import 'relation_painter_dto.dart';
import '../../../engine/config.dart';

class RelationPainter extends CustomPainter {
  final List<RelationPaintDto> paintDtos;
  final ThemeData theme;

  RelationPainter({
    required this.paintDtos,
    required this.theme,
  });

  void _drawText(
    Canvas canvas,
    String text,
    Offset pos,
    Color strokeColor,
    double strokeWidth,
  ) {
    final textStyle = TextStyle(
      color: theme.colorScheme.onSurface,
      fontSize: 10,
      fontWeight: FontWeight.w500,
    );
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    const double paddingX = 8.0;
    const double paddingY = 4.0;
    final double w = textPainter.width + paddingX * 2;
    final double h = textPainter.height + paddingY * 2;

    final rect = Rect.fromCenter(center: pos, width: w, height: h);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8.0));

    final fillPaint = Paint()
      ..color = theme.scaffoldBackgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, fillPaint);

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawRRect(rrect, strokePaint);

    textPainter.paint(
      canvas,
      pos - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  Path _createPatternedPath(Path source, String pattern) {
    final Path dest = Path();
    final double dashLen = pattern == 'dashed' ? 8.0 : 2.0;
    final double gapLen = pattern == 'dashed' ? 6.0 : 4.0;

    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = draw ? dashLen : gapLen;
        if (draw) {
          dest.addPath(
            metric.extractPath(
              distance,
              (distance + len).clamp(0.0, metric.length),
            ),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  void _drawVariableWidthPoints(
    Canvas canvas,
    List<Offset> points,
    List<double> widths,
    Color color,
  ) {
    if (points.length < 2) return;
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];
      final w = i < widths.length ? widths[i] : (widths.isNotEmpty ? widths.last : 2.0);
      final segmentPaint = Paint()
        ..color = color
        ..strokeWidth = w
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(p1, p2, segmentPaint);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke;

    for (final dto in paintDtos) {
      paint.color = dto.color;
      paint.strokeWidth = dto.strokeWidth;

      if (dto.isVariableWidth) {
        _drawVariableWidthPoints(canvas, dto.points, dto.widths, paint.color);
      } else {
        if (dto.strokePattern == 'dashed' || dto.strokePattern == 'dotted') {
          final decoratedPath = _createPatternedPath(dto.path, dto.strokePattern);
          canvas.drawPath(decoratedPath, paint);
        } else {
          canvas.drawPath(dto.path, paint);
        }
      }

      if (dto.startShape != null && dto.startShape != EndpointShape.none) {
        _drawEndpointShape(
          canvas,
          dto.startArrowCenter,
          dto.startArrowDirection,
          dto.startShape!,
          dto.color.withAlpha(255),
          dto.startArrowMargin,
        );
      }
      if (dto.endShape != null && dto.endShape != EndpointShape.none) {
        _drawEndpointShape(
          canvas,
          dto.endArrowCenter,
          dto.endArrowDirection,
          dto.endShape!,
          dto.color.withAlpha(255),
          dto.endArrowMargin,
        );
      }

      if (dto.isSelected) {
        _drawSelectionHandles(canvas, dto.startPoint, dto.endPoint);
      }

      if (dto.verb.isNotEmpty) {
        _drawText(canvas, dto.verb, dto.labelPos, paint.color, paint.strokeWidth);
      }
    }
  }

  void _drawSelectionHandles(Canvas canvas, Offset start, Offset end) {
    final handlePaint = Paint()
      ..color = AppConfig.visuals.selectionAccent
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawCircle(start, 6.0, borderPaint);
    canvas.drawCircle(start, 5.0, handlePaint);
    canvas.drawCircle(end, 6.0, borderPaint);
    canvas.drawCircle(end, 5.0, handlePaint);
  }

  void _drawEndpointShape(
    Canvas canvas,
    Offset position,
    double direction,
    EndpointShape shape,
    Color color,
    double size,
  ) {
    final half = size / 2;
    final opaqueColor = color.withAlpha(255);
    final fillPaint = Paint()
      ..color = opaqueColor
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = opaqueColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.save();
    canvas.translate(position.dx, position.dy);
    canvas.rotate(direction);

    switch (shape) {
      case EndpointShape.none:
        break;
      case EndpointShape.arrow:
        final path = Path();
        path.moveTo(half, 0);
        path.lineTo(-half, -half);
        path.lineTo(-half, half);
        path.close();
        canvas.drawPath(path, fillPaint);
        break;
      case EndpointShape.openArrow:
        final path = Path();
        path.moveTo(half, 0);
        path.lineTo(-half, -half);
        path.moveTo(half, 0);
        path.lineTo(-half, half);
        canvas.drawPath(path, strokePaint);
        break;
      case EndpointShape.circle:
        canvas.drawCircle(Offset.zero, half, fillPaint);
        break;
      case EndpointShape.diamond:
        final path = Path();
        path.moveTo(0, -half);
        path.lineTo(half, 0);
        path.lineTo(0, half);
        path.lineTo(-half, 0);
        path.close();
        canvas.drawPath(path, fillPaint);
        break;
      case EndpointShape.square:
        final rect = Rect.fromCenter(center: Offset.zero, width: size, height: size);
        canvas.drawRect(rect, fillPaint);
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant RelationPainter oldDelegate) {
    if (oldDelegate.theme != theme) return true;
    if (oldDelegate.paintDtos.length != paintDtos.length) return true;
    for (int i = 0; i < paintDtos.length; i++) {
      if (oldDelegate.paintDtos[i] != paintDtos[i]) return true;
    }
    return false;
  }
}
