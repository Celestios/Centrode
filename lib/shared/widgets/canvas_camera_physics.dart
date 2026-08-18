import 'dart:ui';
import 'package:centrode/features/graph/engine/config.dart';

/// Pure mathematical model for bounded canvas camera and rubber-band elasticity.
class CanvasCameraPhysics {
  const CanvasCameraPhysics._();

  /// Nonlinear rubber-band compression function in screen pixels.
  static double rubberBand(double displacement, double resistance) {
    if (displacement == 0) return 0;
    final sign = displacement.sign;
    final magnitude = displacement.abs();
    final compressed = magnitude / (1.0 + magnitude / resistance);
    return sign * compressed;
  }
}

/// Critically damped spring simulation for elastic snap-back.
class DampedSpring {
  Offset position = Offset.zero;
  Offset velocity = Offset.zero;

  final double stiffness;
  final double damping;

  DampedSpring({
    double? stiffness,
    double? damping,
  })  : stiffness = stiffness ?? AppConfig.canvas.springStiffness,
        damping = damping ?? AppConfig.canvas.springDamping;

  bool get settled => position.distance < 0.1 && velocity.distance < 0.1;

  void reset(Offset initialPosition) {
    position = initialPosition;
    velocity = Offset.zero;
  }

  void update(double dt) {
    final acceleration = (-position * stiffness) - (velocity * damping);
    velocity += acceleration * dt;
    position += velocity * dt;

    if (settled) {
      position = Offset.zero;
      velocity = Offset.zero;
    }
  }
}
