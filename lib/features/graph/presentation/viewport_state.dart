import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mycelium/shared/logging.dart';
import 'package:mycelium/shared/domain/raw_uuid.dart';
import '../engine/config.dart';
import '../../../src/rust/domain/base_models.dart' show BoundingBox;
import '../store/graph_data_query.dart';

class ViewportStateGrid {
  final Rect visibleRect;
  final double scale;
  final Size viewportSize;

  const ViewportStateGrid({
    required this.visibleRect,
    required this.scale,
    required this.viewportSize,
  });
}

/// Extension on Rect to check if one rect fully contains another.
/// Extracted from GraphCanvas for Viewport Math.
extension RectExtension on Rect {
  bool containsRect(Rect other) =>
      left <= other.left &&
      right >= other.right &&
      top <= other.top &&
      bottom >= other.bottom;
}

/// Sole arbiter of coordinate transformations, hysteresis overscan buffering,
/// viewport boundary math, and visible node culling.
class ViewportController {
  final Logger _log = Logger('ViewportController');
  final GraphDataQuery _dataController;
  final TransformationController transformController =
      TransformationController();

  Rect _overscanBuffer = Rect.zero;
  Size _currentViewportSize = Size.zero;
  bool _isDisposed = false;

  AnimationController? _viewportAnimationController;

  /// Notifier exposing the set of node IDs currently residing inside the overscan buffer.
  final ValueNotifier<Set<RawUuid>> visibleNodeIds = ValueNotifier({});

  final ValueNotifier<ViewportStateGrid> viewportStateNotifier = ValueNotifier(
    ViewportStateGrid(
      visibleRect: Rect.zero,
      scale: 1.0,
      viewportSize: Size.zero,
    ),
  );

  /// Notifier exposing the calculated elastic margins for CanvasInteractiveViewer.
  final ValueNotifier<EdgeInsets> elasticMargins = ValueNotifier(
    EdgeInsets.zero,
  );

  StreamSubscription<GraphEntityUpdate>? _updateSubscription;

  ViewportController(this._dataController) {
    _log.info(
      'Initializing ViewportController and tracking transform mutations.',
    );
    transformController.addListener(_handleTransform);
    _updateSubscription = _dataController.onEntityUpdate.listen(
      _handleEntityUpdate,
    );
  }

  void _onCanvasBoundsChanged() {
    recalculateElasticMargins();
  }

  void _handleEntityUpdate(GraphEntityUpdate update) {
    switch (update.type) {
      case GraphUpdateType.boundary:
        _onCanvasBoundsChanged();
        break;
      case GraphUpdateType.position:
      case GraphUpdateType.size:
      case GraphUpdateType.nodeAdded:
      case GraphUpdateType.nodeDeleted:
      case GraphUpdateType.reset:
        if (_overscanBuffer != Rect.zero) {
          updateVisibleSet(_overscanBuffer);
        }
        break;
      default:
        break;
    }
  }

  /// Guarded dimension update injected by the Passive View's LayoutBuilder.
  /// Guarantees O(1) performance by rejecting identical subsequent layouts.
  void updateViewportSize(Size size) {
    if (size == _currentViewportSize) return;

    _log.fine('Viewport dimensions updated: $size');
    _currentViewportSize = size;
    _recalculate();
    recalculateElasticMargins();
  }

  /// Mutates the Transformation Matrix to center the camera on the provided bounds.
  void focusOnBounds(BoundingBox bounds) {
    if (_currentViewportSize == Size.zero) return;

    // Calculate the mathematical center of the nodes
    final double centerX = (bounds.minX + bounds.maxX) / 2.0;
    final double centerY = (bounds.minY + bounds.maxY) / 2.0;

    // Calculate translation required to place the center point in the middle of the InteractiveViewer widget
    final double dx = (_currentViewportSize.width / 2) - centerX;
    final double dy = (_currentViewportSize.height / 2) - centerY;

    _log.info('Translating Camera Matrix to center: ($centerX, $centerY)');
    transformController.value = Matrix4.identity()..translateByDouble(dx, dy, 0, 1);
    recalculateElasticMargins();
  }

  /// Updates the zoom scale while preserving the current camera translation.
  void updateScale(double newScale) {
    final currentMatrix = transformController.value;
    final translation = currentMatrix.getTranslation();
    transformController.value = Matrix4.identity()
      ..translateByDouble(translation.x, translation.y, 0, 1)
      ..scaleByDouble(newScale, newScale, newScale, 1);
    recalculateElasticMargins();
  }

  void _handleTransform() {
    _recalculate();
  }

  void _recalculate() {
    // Prevent math execution before initial layout constraints are fed
    if (_currentViewportSize == Size.zero) return;

    final viewport = _calculateCanvasViewport();
    if (viewport == Rect.zero) return;

    final scale = transformController.value.getMaxScaleOnAxis();
    viewportStateNotifier.value = ViewportStateGrid(
      visibleRect: viewport,
      scale: scale,
      viewportSize: _currentViewportSize,
    );

    // Viewport Hysteresis Logic
    if (!_overscanBuffer.containsRect(viewport)) {
      final inflatedBuffer = viewport.inflate(
        viewport.width * AppConfig.canvas.overscanRatio,
      );
      updateVisibleSet(inflatedBuffer);
    }
  }

  /// Calculates and updates the elastic margins boundaries.
  /// Decoupled from the high-frequency transform controller tick to prevent
  /// layout rebuild jitter during active panning/scaling.
  void recalculateElasticMargins() {
    if (_currentViewportSize == Size.zero) return;

    final viewport = _calculateCanvasViewport();
    if (viewport == Rect.zero) return;

    // Scale-Aware Geometric Decoupling & Elastic Margin calculation.
    final bounds = _dataController.canvasBounds;
    final padding = AppConfig.canvas.boundaryMargin;
    final initialPadding = AppConfig.canvas.initialBoundaryMargin;

    // 1. Calculate boundaries based on graph node coordinates
    final nodeLeftBound = -bounds.minX.toDouble() + padding;
    final nodeTopBound = -bounds.minY.toDouble() + padding;
    final nodeRightBound = bounds.maxX.toDouble() + padding;
    final nodeBottomBound = bounds.maxY.toDouble() + padding;

    // 2. Adjust boundaries to guarantee they enclose the current camera viewport
    // to prevent sudden snap backs when the nodes boundary shrinks.
    final leftBound = math.max(
      math.max(initialPadding, nodeLeftBound),
      viewport != Rect.zero ? -viewport.left : 0.0,
    );
    final topBound = math.max(
      math.max(initialPadding, nodeTopBound),
      viewport != Rect.zero ? -viewport.top : 0.0,
    );
    final rightBound = math.max(
      math.max(initialPadding, nodeRightBound),
      viewport != Rect.zero ? viewport.right - _currentViewportSize.width : 0.0,
    );
    final bottomBound = math.max(
      math.max(initialPadding, nodeBottomBound),
      viewport != Rect.zero
          ? viewport.bottom - _currentViewportSize.height
          : 0.0,
    );

    final calculatedMargins = EdgeInsets.fromLTRB(
      leftBound,
      topBound,
      rightBound,
      bottomBound,
    );

    if (elasticMargins.value != calculatedMargins) {
      elasticMargins.value = calculatedMargins;
    }
  }

  void updateVisibleSet(Rect bufferRect) {
    _overscanBuffer = bufferRect;
    final currentOverscan = bufferRect;

    // Dispatch the spatial grid query asynchronously on the event loop
    Future(() {
      if (_isDisposed) return;
      if (_overscanBuffer != currentOverscan) return;
      final newVisible = _dataController.spatialGrid.queryRect(currentOverscan);
      if (_isDisposed) return;
      if (_overscanBuffer == currentOverscan) {
        _log.finest(
          'updateVisibleSet: Spatial index returned ${newVisible.length} visible nodes.',
        );
        if (!setEquals(visibleNodeIds.value, newVisible)) {
          visibleNodeIds.value = newVisible;
        }
      }
    });
  }

  Rect _calculateCanvasViewport() {
    final Matrix4 transform = transformController.value;

    // Guard against singular matrix to prevent unhandled render exceptions
    if (transform.determinant() == 0.0) {
      _log.severe(
        'Singular matrix detected in canvas transform (Scale = 0). Aborting viewport calculation.',
      );
      return Rect.zero;
    }

    final Matrix4 inverse = Matrix4.inverted(transform);
    final Offset topLeft = MatrixUtils.transformPoint(inverse, Offset.zero);
    final Offset bottomRight = MatrixUtils.transformPoint(
      inverse,
      Offset(_currentViewportSize.width, _currentViewportSize.height),
    );

    return Rect.fromPoints(topLeft, bottomRight);
  }

  /// Animates the viewport translation and scale dynamically using a [vsync] ticker.
  void animateViewportTo(
    Matrix4 targetMatrix,
    TickerProvider vsync, {
    Duration duration = const Duration(milliseconds: 600),
  }) {
    _viewportAnimationController?.stop();
    _viewportAnimationController?.dispose();

    final startMatrix = transformController.value;
    final startTranslation = startMatrix.getTranslation();
    final targetTranslation = targetMatrix.getTranslation();
    final startScale = startMatrix.getMaxScaleOnAxis();
    final targetScale = targetMatrix.getMaxScaleOnAxis();

    _viewportAnimationController = AnimationController(
      vsync: vsync,
      duration: duration,
    );

    _viewportAnimationController!.addListener(() {
      final t = _viewportAnimationController!.value;
      final interpTranslation = Offset.lerp(
        Offset(startTranslation.x, startTranslation.y),
        Offset(targetTranslation.x, targetTranslation.y),
        t,
      )!;
      final interpScale = startScale + (targetScale - startScale) * t;

      transformController.value = Matrix4.identity()
        ..translateByDouble(interpTranslation.dx, interpTranslation.dy, 0, 1)
        ..scaleByDouble(interpScale, interpScale, interpScale, 1);

      if (t == 1.0) {
        recalculateElasticMargins();
        final controllerToDispose = _viewportAnimationController;
        Future.microtask(() {
          if (controllerToDispose == _viewportAnimationController) {
            _viewportAnimationController?.dispose();
            _viewportAnimationController = null;
          }
        });
      }
    });
    _viewportAnimationController!.forward();
  }

  /// Projects canvas coordinates to screen-space coordinates.
  Offset projectCanvasToScreen(Offset canvasPos) {
    final Matrix4 transform = transformController.value;
    if (transform.determinant() == 0.0) return canvasPos;
    return MatrixUtils.transformPoint(transform, canvasPos);
  }

  /// Projects a canvas Rect to a screen-space Rect.
  Rect projectCanvasRectToScreen(Rect canvasRect) {
    final topLeft = projectCanvasToScreen(canvasRect.topLeft);
    final bottomRight = projectCanvasToScreen(canvasRect.bottomRight);
    return Rect.fromPoints(topLeft, bottomRight);
  }

  void dispose() {
    _log.fine('Disposing ViewportController.');
    _isDisposed = true;
    _viewportAnimationController?.stop();
    _viewportAnimationController?.dispose();
    transformController.removeListener(_handleTransform);
    _updateSubscription?.cancel();
    transformController.dispose();
    viewportStateNotifier.dispose();
    visibleNodeIds.dispose();
    elasticMargins.dispose();
  }
}
