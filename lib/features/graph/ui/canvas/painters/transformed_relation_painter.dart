import 'package:flutter/material.dart';
import 'relation_painter.dart';
import 'relation_painter_dto.dart';

class TransformedRelationPainter extends CustomPainter {
  final List<RelationPaintDto> paintDtos;
  final ThemeData theme;
  final double scaleX;
  final double scaleY;
  final Offset originOffset;

  TransformedRelationPainter({
    required this.paintDtos,
    required this.theme,
    required this.scaleX,
    required this.scaleY,
    required this.originOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (paintDtos.isEmpty) return;
    canvas.save();
    canvas.scale(scaleX, scaleY);
    canvas.translate(-originOffset.dx, -originOffset.dy);
    final painter = RelationPainter(paintDtos: paintDtos, theme: theme);
    painter.paint(canvas, size);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TransformedRelationPainter oldDelegate) {
    return oldDelegate.paintDtos != paintDtos ||
        oldDelegate.scaleX != scaleX ||
        oldDelegate.scaleY != scaleY ||
        oldDelegate.originOffset != originOffset ||
        oldDelegate.theme != theme;
  }
}
