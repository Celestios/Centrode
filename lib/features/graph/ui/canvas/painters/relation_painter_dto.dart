import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:mycelium/src/rust/domain/styles.dart';

class RelationPaintDto {
  final String id;
  final Path path;
  final List<Offset> points;
  final List<double> widths;
  final bool isVariableWidth;
  final Color color;
  final double strokeWidth;
  final String strokePattern;
  final EndpointShape? startShape;
  final EndpointShape? endShape;
  final double arrowSize;
  final Offset startArrowCenter;
  final Offset endArrowCenter;
  final double startArrowDirection;
  final double endArrowDirection;
  final double startArrowMargin;
  final double endArrowMargin;
  final bool isSelected;
  final Offset startPoint;
  final Offset endPoint;
  final String verb;
  final Offset labelPos;

  const RelationPaintDto({
    required this.id,
    required this.path,
    required this.points,
    required this.widths,
    required this.isVariableWidth,
    required this.color,
    required this.strokeWidth,
    required this.strokePattern,
    this.startShape,
    this.endShape,
    required this.arrowSize,
    required this.startArrowCenter,
    required this.endArrowCenter,
    required this.startArrowDirection,
    required this.endArrowDirection,
    required this.startArrowMargin,
    required this.endArrowMargin,
    required this.isSelected,
    required this.startPoint,
    required this.endPoint,
    required this.verb,
    required this.labelPos,
  });
}
