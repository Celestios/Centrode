import 'dart:math' as math;
import 'package:flutter/foundation.dart' show clampDouble;
import 'package:flutter/painting.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4, Quad, Vector3;

/// Pure mathematical and geometric utilities for viewport transformations.
class CanvasGeometryUtils {
  CanvasGeometryUtils._();

  /// Returns the closest point to the given point on the given line segment.
  static Vector3 getNearestPointOnLine(Vector3 point, Vector3 l1, Vector3 l2) {
    final double lengthSquared =
        math.pow(l2.x - l1.x, 2.0).toDouble() +
        math.pow(l2.y - l1.y, 2.0).toDouble();

    if (lengthSquared == 0) {
      return l1;
    }

    final Vector3 l1P = point - l1;
    final Vector3 l1L2 = l2 - l1;
    final double fraction = clampDouble(
      l1P.dot(l1L2) / lengthSquared,
      0.0,
      1.0,
    );
    return l1 + l1L2 * fraction;
  }

  /// Given a quad, return its axis aligned bounding box.
  static Quad getAxisAlignedBoundingBox(Quad quad) {
    final double minX = math.min(
      quad.point0.x,
      math.min(quad.point1.x, math.min(quad.point2.x, quad.point3.x)),
    );
    final double minY = math.min(
      quad.point0.y,
      math.min(quad.point1.y, math.min(quad.point2.y, quad.point3.y)),
    );
    final double maxX = math.max(
      quad.point0.x,
      math.max(quad.point1.x, math.max(quad.point2.x, quad.point3.x)),
    );
    final double maxY = math.max(
      quad.point0.y,
      math.max(quad.point1.y, math.max(quad.point2.y, quad.point3.y)),
    );
    return Quad.points(
      Vector3(minX, minY, 0),
      Vector3(maxX, minY, 0),
      Vector3(maxX, maxY, 0),
      Vector3(minX, maxY, 0),
    );
  }

  /// Returns true iff the point is inside the rectangle given by the Quad, inclusively.
  static bool pointIsInside(Vector3 point, Quad quad) {
    final Vector3 aM = point - quad.point0;
    final Vector3 aB = quad.point1 - quad.point0;
    final Vector3 aD = quad.point3 - quad.point0;

    final double aMAB = aM.dot(aB);
    final double aBAB = aB.dot(aB);
    final double aMAD = aM.dot(aD);
    final double aDAD = aD.dot(aD);

    return 0 <= aMAB && aMAB <= aBAB && 0 <= aMAD && aMAD <= aDAD;
  }

  /// Get the point inside (inclusively) the given Quad that is nearest to the given Vector3.
  static Vector3 getNearestPointInside(Vector3 point, Quad quad) {
    if (pointIsInside(point, quad)) {
      return point;
    }

    final List<Vector3> closestPoints = <Vector3>[
      getNearestPointOnLine(point, quad.point0, quad.point1),
      getNearestPointOnLine(point, quad.point1, quad.point2),
      getNearestPointOnLine(point, quad.point2, quad.point3),
      getNearestPointOnLine(point, quad.point3, quad.point0),
    ];
    double minDistance = double.infinity;
    late Vector3 closestOverall;
    for (final Vector3 closePoint in closestPoints) {
      final double distance = math.sqrt(
        math.pow(point.x - closePoint.x, 2) +
            math.pow(point.y - closePoint.y, 2),
      );
      if (distance < minDistance) {
        minDistance = distance;
        closestOverall = closePoint;
      }
    }
    return closestOverall;
  }

  /// Transform the four corners of the viewport by the inverse of the given matrix.
  static Quad transformViewport(Matrix4 matrix, Rect viewport) {
    final Matrix4 inverseMatrix = matrix.clone()..invert();
    return Quad.points(
      inverseMatrix.transform3(
        Vector3(viewport.topLeft.dx, viewport.topLeft.dy, 0.0),
      ),
      inverseMatrix.transform3(
        Vector3(viewport.topRight.dx, viewport.topRight.dy, 0.0),
      ),
      inverseMatrix.transform3(
        Vector3(viewport.bottomRight.dx, viewport.bottomRight.dy, 0.0),
      ),
      inverseMatrix.transform3(
        Vector3(viewport.bottomLeft.dx, viewport.bottomLeft.dy, 0.0),
      ),
    );
  }

  /// Round the output values to prevent precision jitter.
  static Offset roundOffset(Offset offset) {
    return Offset(
      double.parse(offset.dx.toStringAsFixed(9)),
      double.parse(offset.dy.toStringAsFixed(9)),
    );
  }

  /// Align the given offset to the given axis by allowing movement only in the axis direction.
  static Offset alignAxis(Offset offset, Axis axis) {
    return switch (axis) {
      Axis.horizontal => Offset(offset.dx, 0.0),
      Axis.vertical => Offset(0.0, offset.dy),
    };
  }
}
