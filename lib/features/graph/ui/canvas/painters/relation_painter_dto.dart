import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mycelium/shared/domain/raw_uuid.dart';

class RelationPaintDto {
  final RawUuid id;
  final List<Offset> bodyPoints;
  final List<Offset> startShapeVertices;
  final List<Offset> endShapeVertices;
  final bool startShapeFilled;
  final bool endShapeFilled;
  final Color color;
  final double strokeWidth;
  final String strokePattern;
  final bool isSelected;
  final Offset startPoint;
  final Offset endPoint;
  final Offset startHandlePos;
  final Offset endHandlePos;
  final bool isDragging;
  final String verb;
  final Offset labelPos;
  final List<double> widths;
  final bool isVariableWidth;

  const RelationPaintDto({
    required this.id,
    required this.bodyPoints,
    required this.startShapeVertices,
    required this.endShapeVertices,
    required this.startShapeFilled,
    required this.endShapeFilled,
    required this.color,
    required this.strokeWidth,
    required this.strokePattern,
    required this.isSelected,
    required this.startPoint,
    required this.endPoint,
    required this.startHandlePos,
    required this.endHandlePos,
    required this.isDragging,
    required this.verb,
    required this.labelPos,
    required this.widths,
    required this.isVariableWidth,
  });
}
