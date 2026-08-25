import 'dart:math' as math;
import 'package:flutter/physics.dart';
import 'package:centrode/shared/widgets/canvas_camera_physics.dart';

/// Physics calculations for canvas deceleration, springs, and friction.
class CanvasViewportPhysics {
  CanvasViewportPhysics._();

  // Coefficient of friction in inertial translation.
  static const double defaultDrag = 0.0000135;

  /// Given a velocity and drag, calculate the time at which motion will come to a stop.
  static double getFinalTime(
    double velocity,
    double drag, {
    double effectivelyMotionless = 10,
  }) {
    if (velocity <= 0 || drag <= 0) return 0.0;
    return math.log(effectivelyMotionless / velocity) / math.log(drag / 100);
  }

  /// Calculates rubber-band overscroll resistance for an overflow delta.
  static double calculateRubberBand(double overflow, double resistance) {
    return CanvasCameraPhysics.rubberBand(overflow, resistance);
  }
}
