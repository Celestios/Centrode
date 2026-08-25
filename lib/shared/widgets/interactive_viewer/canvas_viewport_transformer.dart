import 'dart:math' as math;
import 'package:flutter/foundation.dart' show clampDouble;
import 'package:flutter/widgets.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4, Vector3;
import 'canvas_geometry_utils.dart';

/// Applies coordinate transformations, scaling, rotations, and boundary clamping to Matrix4.
class CanvasViewportTransformer {
  CanvasViewportTransformer._();

  /// Computes clamped translation matrix according to content boundaries.
  static Matrix4 matrixTranslate({
    required Matrix4 matrix,
    required Offset translation,
    required PanAxis panAxis,
    required Axis? currentAxis,
    required Rect contentBounds,
    required Size viewportSize,
  }) {
    if (translation == Offset.zero) {
      return matrix.clone();
    }

    final Offset alignedTranslation;
    if (currentAxis != null) {
      alignedTranslation = switch (panAxis) {
        PanAxis.horizontal => CanvasGeometryUtils.alignAxis(translation, Axis.horizontal),
        PanAxis.vertical => CanvasGeometryUtils.alignAxis(translation, Axis.vertical),
        PanAxis.aligned => CanvasGeometryUtils.alignAxis(translation, currentAxis),
        PanAxis.free => translation,
      };
    } else {
      alignedTranslation = translation;
    }

    final Matrix4 nextMatrix = matrix.clone()
      ..translateByDouble(alignedTranslation.dx, alignedTranslation.dy, 0, 1);

    if (contentBounds.isInfinite || viewportSize == Size.zero) {
      return nextMatrix;
    }

    final double zoom = nextMatrix.getMaxScaleOnAxis();
    final double maxTx = -contentBounds.left * zoom;
    final double minTx = viewportSize.width - contentBounds.right * zoom;
    final double maxTy = -contentBounds.top * zoom;
    final double minTy = viewportSize.height - contentBounds.bottom * zoom;

    final double lowX = math.min(minTx, maxTx);
    final double highX = math.max(minTx, maxTx);
    final double lowY = math.min(minTy, maxTy);
    final double highY = math.max(minTy, maxTy);

    final Vector3 nextT = nextMatrix.getTranslation();
    final double clampedTx = nextT.x.clamp(lowX, highX);
    final double clampedTy = nextT.y.clamp(lowY, highY);

    return nextMatrix.clone()
      ..setTranslation(Vector3(clampedTx, clampedTy, 0.0));
  }

  /// Scales matrix within minScale and maxScale bounds.
  static Matrix4 matrixScale({
    required Matrix4 matrix,
    required double scale,
    required double minScale,
    required double maxScale,
  }) {
    if (scale == 1.0) {
      return matrix.clone();
    }
    assert(scale != 0.0);

    final double currentScale = matrix.getMaxScaleOnAxis();
    final double totalScale = currentScale * scale;
    final double clampedTotalScale = clampDouble(
      totalScale,
      minScale,
      maxScale,
    );
    final double clampedScale = clampedTotalScale / currentScale;
    return matrix.clone()
      ..scaleByDouble(clampedScale, clampedScale, clampedScale, 1);
  }

  /// Rotates matrix around a given focal point in scene space.
  static Matrix4 matrixRotate({
    required Matrix4 matrix,
    required double rotation,
    required Offset focalPointScene,
  }) {
    if (rotation == 0) {
      return matrix.clone();
    }
    return matrix.clone()
      ..translateByDouble(focalPointScene.dx, focalPointScene.dy, 0, 1)
      ..rotateZ(-rotation)
      ..translateByDouble(-focalPointScene.dx, -focalPointScene.dy, 0, 1);
  }

  /// Computes clamped base translation and raw screen-space overflow deltas.
  static ({Offset baseTranslation, Offset overflow}) computePanClamp({
    required Offset desiredTranslation,
    required Rect contentBounds,
    required Size viewportSize,
    required double zoom,
  }) {
    if (contentBounds.isInfinite || viewportSize == Size.zero) {
      return (baseTranslation: desiredTranslation, overflow: Offset.zero);
    }

    final double maxTx = -contentBounds.left * zoom;
    final double minTx = viewportSize.width - contentBounds.right * zoom;
    final double maxTy = -contentBounds.top * zoom;
    final double minTy = viewportSize.height - contentBounds.bottom * zoom;

    final double lowX = math.min(minTx, maxTx);
    final double highX = math.max(minTx, maxTx);
    final double lowY = math.min(minTy, maxTy);
    final double highY = math.max(minTy, maxTy);

    final double clampedTx = desiredTranslation.dx.clamp(lowX, highX);
    final double clampedTy = desiredTranslation.dy.clamp(lowY, highY);

    final double overflowX = desiredTranslation.dx - clampedTx;
    final double overflowY = desiredTranslation.dy - clampedTy;

    return (
      baseTranslation: Offset(clampedTx, clampedTy),
      overflow: Offset(overflowX, overflowY),
    );
  }
}
