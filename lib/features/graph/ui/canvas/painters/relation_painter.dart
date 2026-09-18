import 'package:flutter/material.dart';
import 'package:centrode/shared/elements/elements.dart';
import 'relation_painter_dto.dart';
import '../../../../../presentation/theme/app_theme_manager.dart';

class RelationPainter extends CustomPainter {
  final List<RelationPaintDto> paintDtos;
  final ThemeData theme;

  final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  final Paint _labelBgPaint = Paint()..style = PaintingStyle.fill;
  final Paint _labelBorderPaint = Paint()..style = PaintingStyle.stroke;
  final Paint _handlePaint = Paint()..style = PaintingStyle.fill;
  final Paint _handleBorderPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.0;
  final Paint _segmentPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;
  final Paint _shapePaint = Paint()..strokeWidth = 2.0;

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
      fontSize: CanvasPainterTokens.relationLabelFontSize,
      fontWeight: FontWeight.w500,
    );
    final textSpan = TextSpan(text: text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final double paddingX = CanvasPainterTokens.relationLabelPaddingX;
    final double paddingY = CanvasPainterTokens.relationLabelPaddingY;
    final rect = Rect.fromCenter(
      center: pos,
      width: textPainter.width + paddingX * 2,
      height: textPainter.height + paddingY * 2,
    );

    _labelBgPaint.color = theme.colorScheme.surface;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect,
        const Radius.circular(CanvasPainterTokens.relationLabelRadius),
      ),
      _labelBgPaint,
    );

    _labelBorderPaint
      ..color = strokeColor.withValues(alpha: 0.3)
      ..strokeWidth = strokeWidth * 0.5;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect,
        const Radius.circular(CanvasPainterTokens.relationLabelRadius),
      ),
      _labelBorderPaint,
    );

    final textOffset = Offset(
      pos.dx - textPainter.width / 2,
      pos.dy - textPainter.height / 2,
    );
    textPainter.paint(canvas, textOffset);
    textPainter.dispose();
  }

  Path _verticesToPath(List<Offset> points, {bool close = false}) {
    final path = Path();
    if (points.isEmpty) return path;
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }
    if (close) path.close();
    return path;
  }

  Path _createPatternedPath(List<Offset> points, String pattern) {
    final double dashLen = pattern == 'dashed'
        ? CanvasPainterTokens.relationDashWidth
        : CanvasPainterTokens.relationDotWidth;
    final double gapLen = pattern == 'dashed'
        ? CanvasPainterTokens.relationDashSpace
        : CanvasPainterTokens.relationDotSpace;

    final source = _verticesToPath(points);
    return PaintGeometry.createDashedPath(source, dashLen, gapLen);
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
      _segmentPaint
        ..color = color
        ..strokeWidth = w;
      canvas.drawLine(p1, p2, _segmentPaint);
    }
  }

  void _drawShape(
    Canvas canvas,
    List<Offset> vertices,
    Color color,
    bool filled,
  ) {
    if (vertices.length < 2) return;
    _shapePaint
      ..color = color
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke;
    if (filled) {
      final path = _verticesToPath(vertices, close: true);
      canvas.drawPath(path, _shapePaint);
    } else {
      final tip = vertices.first;
      for (int i = 1; i < vertices.length; i++) {
        canvas.drawLine(tip, vertices[i], _shapePaint);
      }
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final dto in paintDtos) {
      _strokePaint
        ..color = dto.color
        ..strokeWidth = dto.strokeWidth;

      if (dto.isVariableWidth) {
        _drawVariableWidthPoints(canvas, dto.bodyPoints, dto.widths, _strokePaint.color);
      } else if (dto.strokePattern == 'dashed' || dto.strokePattern == 'dotted') {
        final decoratedPath = _createPatternedPath(dto.bodyPoints, dto.strokePattern);
        canvas.drawPath(decoratedPath, _strokePaint);
      } else {
        final bodyPath = _verticesToPath(dto.bodyPoints);
        canvas.drawPath(bodyPath, _strokePaint);
      }

      _drawShape(canvas, dto.startShapeVertices, dto.color, dto.startShapeFilled);
      _drawShape(canvas, dto.endShapeVertices, dto.color, dto.endShapeFilled);

      if (dto.isSelected && !dto.isDragging) {
        _drawSelectionHandles(canvas, dto.startHandlePos, dto.endHandlePos);
      }

      if (dto.verb.isNotEmpty) {
        _drawText(canvas, dto.verb, dto.labelPos, _strokePaint.color, _strokePaint.strokeWidth);
      }
    }
  }

  void _drawSelectionHandles(Canvas canvas, Offset start, Offset end) {
    _handlePaint.color = AppThemeManager.instance.currentTheme.canvasAccentColor;
    _handleBorderPaint.color = Colors.white;

    canvas.drawCircle(start, 6.0, _handleBorderPaint);
    canvas.drawCircle(start, 5.0, _handlePaint);
    canvas.drawCircle(end, 6.0, _handleBorderPaint);
    canvas.drawCircle(end, 5.0, _handlePaint);
  }

  @override
  bool shouldRepaint(covariant RelationPainter oldDelegate) {
    if (oldDelegate.theme != theme) {
      return true;
    }
    if (oldDelegate.paintDtos.length != paintDtos.length) {
      return true;
    }
    for (int i = 0; i < paintDtos.length; i++) {
      if (oldDelegate.paintDtos[i] != paintDtos[i]) {
        return true;
      }
    }
    return false;
  }
}
