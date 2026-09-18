import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import '../models/models.dart';
import 'strategies/node_layout_strategy.dart';
import 'strategies/container_zoom_strategy.dart';
import 'shared/view_constants.dart';

class ViewportTransformMath {
  const ViewportTransformMath._();

  static Offset screenToCanvas(Matrix4 transform, Offset screenPos) {
    if (transform.determinant() == 0.0) return screenPos;
    return MatrixUtils.transformPoint(Matrix4.inverted(transform), screenPos);
  }

  static Offset projectCanvasToScreen(Matrix4 transform, Offset canvasPos) {
    if (transform.determinant() == 0.0) return canvasPos;
    return MatrixUtils.transformPoint(transform, canvasPos);
  }

  static Rect projectCanvasRectToScreen(Matrix4 transform, Rect canvasRect) {
    final topLeft = projectCanvasToScreen(transform, canvasRect.topLeft);
    final bottomRight = projectCanvasToScreen(transform, canvasRect.bottomRight);
    return Rect.fromPoints(topLeft, bottomRight);
  }

  static Rect calculateCanvasViewport(Matrix4 transform, Size viewportSize) {
    if (transform.determinant() == 0.0) return Rect.zero;

    final Matrix4 inverse = Matrix4.inverted(transform);
    final Offset topLeft = MatrixUtils.transformPoint(inverse, Offset.zero);
    final Offset bottomRight = MatrixUtils.transformPoint(
      inverse,
      Offset(viewportSize.width, viewportSize.height),
    );

    return Rect.fromPoints(topLeft, bottomRight);
  }

  static Offset computeCenterOnBounds(
    BoundingBox bounds,
    Size viewportSize,
  ) {
    final double centerX = (bounds.minX + bounds.maxX) / 2.0;
    final double centerY = (bounds.minY + bounds.maxY) / 2.0;
    final double dx = (viewportSize.width / 2) - centerX;
    final double dy = (viewportSize.height / 2) - centerY;
    return Offset(dx, dy);
  }

  static Offset computeCenterOnPoint(
    Offset canvasPoint,
    Size viewportSize,
    double currentScale,
  ) {
    final double dx =
        (viewportSize.width / 2) - (canvasPoint.dx * currentScale);
    final double dy =
        (viewportSize.height / 2) - (canvasPoint.dy * currentScale);
    return Offset(dx, dy);
  }

  static Matrix4 buildCenterOnPointMatrix(
    Offset canvasPoint,
    Size viewportSize,
    double currentScale,
  ) {
    final offset = computeCenterOnPoint(canvasPoint, viewportSize, currentScale);
    return Matrix4.identity()
      ..translateByDouble(offset.dx, offset.dy, 0, 1)
      ..scaleByDouble(currentScale, currentScale, currentScale, 1);
  }

  static Matrix4 buildScaleAtCenterMatrix(
    double newScale,
    Offset canvasCenter,
    Size viewportSize,
  ) {
    final dx = (viewportSize.width / 2) - (canvasCenter.dx * newScale);
    final dy = (viewportSize.height / 2) - (canvasCenter.dy * newScale);
    return Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(newScale, newScale, newScale, 1);
  }

  static Matrix4 buildPanMatrix(
    Matrix4 currentMatrix,
    Offset deltaScreen,
  ) {
    final currentScale = currentMatrix.getMaxScaleOnAxis();
    final translation = currentMatrix.getTranslation();
    return Matrix4.identity()
      ..translateByDouble(
        translation.x + deltaScreen.dx,
        translation.y + deltaScreen.dy,
        0,
        1,
      )
      ..scaleByDouble(currentScale, currentScale, currentScale, 1);
  }

  static ContainerZoomResult calculateContainerZoomResult(
    ContainerUiNode node,
    Size viewportSize,
    Map<RawUuid, UiNode> nodeLookup,
  ) {
    const layoutStrategy = DefaultNodeLayoutStrategy();
    final worldPos = node.getAbsoluteWorldPosition(nodeLookup);
    final nodeSize = layoutStrategy.calculateSize(node).size;
    final availW = viewportSize.width > 0 ? viewportSize.width - 160.0 : 800.0;
    final availH = viewportSize.height > 0 ? viewportSize.height - 160.0 : 600.0;
    final nodeCenter =
        worldPos + Offset(nodeSize.width / 2.0, nodeSize.height / 2.0);
    final targetScale =
        math.min(availW / nodeSize.width, availH / nodeSize.height)
            .clamp(1.0, 50.0);
    final targetDx = (viewportSize.width / 2.0) - (nodeCenter.dx * targetScale);
    final targetDy = (viewportSize.height / 2.0) - (nodeCenter.dy * targetScale);
    final targetMatrix = Matrix4.identity()
      ..translateByDouble(targetDx, targetDy, 0, 1)
      ..scaleByDouble(targetScale, targetScale, targetScale, 1);

    final aspectRatio =
        nodeSize.height / (nodeSize.width > 0 ? nodeSize.width : 1.0);
    final internalW = kInternalContainerWidth;
    final internalH = 1600.0 * aspectRatio;
    final containerInitScale =
        math.min(availW / internalW, availH / internalH).clamp(0.2, 5.0);

    return ContainerZoomResult(
      targetMatrix: targetMatrix,
      nodeSize: nodeSize,
      containerInitScale: containerInitScale,
      internalSize: Size(internalW, internalH),
    );
  }

  static Matrix4 buildContainerOpenMatrix(
    Size internalSize,
    double containerInitScale,
    Size viewportSize,
  ) {
    final containerDx =
        (viewportSize.width / 2.0) - ((internalSize.width / 2.0) * containerInitScale);
    final containerDy =
        (viewportSize.height / 2.0) - ((internalSize.height / 2.0) * containerInitScale);
    return Matrix4.identity()
      ..translateByDouble(containerDx, containerDy, 0, 1)
      ..scaleByDouble(
          containerInitScale, containerInitScale, containerInitScale, 1);
  }

  static double computeContainerExitScale(
    Size nodeSize,
    Size viewportSize,
  ) {
    final availW = viewportSize.width > 0 ? viewportSize.width - 160.0 : 800.0;
    final availH = viewportSize.height > 0 ? viewportSize.height - 160.0 : 600.0;
    return math.min(availW / nodeSize.width, availH / nodeSize.height)
        .clamp(1.0, 50.0);
  }

  static Matrix4 buildContainerExitStartMatrix(
    Offset nodeCenter,
    double targetScale,
    Size viewportSize,
  ) {
    final targetDx = (viewportSize.width / 2.0) - (nodeCenter.dx * targetScale);
    final targetDy = (viewportSize.height / 2.0) - (nodeCenter.dy * targetScale);
    return Matrix4.identity()
      ..translateByDouble(targetDx, targetDy, 0, 1)
      ..scaleByDouble(targetScale, targetScale, targetScale, 1);
  }

  static Rect computeContentBounds(
    BoundingBox bounds,
    double padding,
    double initialPadding,
  ) {
    final effectivePadding = math.max(padding, initialPadding);
    final minX = bounds.minX.toDouble() - effectivePadding;
    final minY = bounds.minY.toDouble() - effectivePadding;
    final maxX = bounds.maxX.toDouble() + effectivePadding;
    final maxY = bounds.maxY.toDouble() + effectivePadding;
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  static EdgeInsets computeElasticMargins(
    Rect contentBounds,
    Size viewportSize,
  ) {
    return EdgeInsets.fromLTRB(
      -contentBounds.left,
      -contentBounds.top,
      contentBounds.right - viewportSize.width,
      contentBounds.bottom - viewportSize.height,
    );
  }
}
