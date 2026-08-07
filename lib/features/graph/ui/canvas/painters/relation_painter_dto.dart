import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';


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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RelationPaintDto &&
        other.id == id &&
        listEquals(other.bodyPoints, bodyPoints) &&
        listEquals(other.startShapeVertices, startShapeVertices) &&
        listEquals(other.endShapeVertices, endShapeVertices) &&
        other.startShapeFilled == startShapeFilled &&
        other.endShapeFilled == endShapeFilled &&
        other.color == color &&
        other.strokeWidth == strokeWidth &&
        other.strokePattern == strokePattern &&
        other.isSelected == isSelected &&
        other.startPoint == startPoint &&
        other.endPoint == endPoint &&
        other.startHandlePos == startHandlePos &&
        other.endHandlePos == endHandlePos &&
        other.isDragging == isDragging &&
        other.verb == verb &&
        other.labelPos == labelPos &&
        listEquals(other.widths, widths) &&
        other.isVariableWidth == isVariableWidth;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      id,
      Object.hashAll(bodyPoints),
      Object.hashAll(startShapeVertices),
      Object.hashAll(endShapeVertices),
      startShapeFilled,
      endShapeFilled,
      color,
      strokeWidth,
      strokePattern,
      isSelected,
      startPoint,
      endPoint,
      startHandlePos,
      endHandlePos,
      isDragging,
      verb,
      labelPos,
      Object.hashAll(widths),
      isVariableWidth,
    ]);
  }
}

