import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'graph_metrics.dart';
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

  /// Notifier exposing the set of node IDs currently residing inside the overscan buffer.
  final ValueNotifier<Set<String>> visibleNodeIds = ValueNotifier({});

  final ValueNotifier<ViewportStateGrid> viewportStateNotifier = ValueNotifier(
    ViewportStateGrid(
      visibleRect: Rect.zero,
      scale: 1.0,
      viewportSize: Size.zero,
    ),
  );

  /// Notifier exposing the calculated elastic margins for CanvasInteractiveViewer.
  final ValueNotifier<EdgeInsets> elasticMargins = ValueNotifier(EdgeInsets.zero);

  StreamSubscription<GraphEntityUpdate>? _updateSubscription;

  ViewportController(this._dataController) {
    _log.info(
      'Initializing ViewportController and tracking transform mutations.',
    );
    transformController.addListener(_handleTransform);
    _dataController.canvasBounds.addListener(_onCanvasBoundsChanged);
    _updateSubscription = _dataController.onEntityUpdate.listen(_handleEntityUpdate);
  }

  void _onCanvasBoundsChanged() {
    recalculateElasticMargins();
  }

  void _handleEntityUpdate(GraphEntityUpdate update) {
    switch (update.type) {
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
    transformController.value = Matrix4.identity()..translate(dx, dy);
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
    final bounds = _dataController.canvasBounds.value;
    final padding = AppConfig.canvas.boundaryMargin;
    final minScale = AppConfig.canvas.minScale;
    
    final effectiveViewportWidth = _currentViewportSize.width / minScale;
    final effectiveViewportHeight = _currentViewportSize.height / minScale;

    // 1. Calculate boundaries based on graph node coordinates
    final nodeLeftBound = -bounds.minX.toDouble() + padding;
    final nodeTopBound = -bounds.minY.toDouble() + padding;
    final nodeRightBound = bounds.maxX.toDouble() + padding;
    final nodeBottomBound = bounds.maxY.toDouble() + padding;

    // 2. Adjust boundaries to guarantee they enclose the current camera viewport
    // to prevent sudden snap backs when the nodes boundary shrinks.
    final leftBound = math.max(
      math.max(effectiveViewportWidth, nodeLeftBound),
      viewport != Rect.zero ? -viewport.left : 0.0,
    );
    final topBound = math.max(
      math.max(effectiveViewportHeight, nodeTopBound),
      viewport != Rect.zero ? -viewport.top : 0.0,
    );
    final rightBound = math.max(
      math.max(effectiveViewportWidth, nodeRightBound),
      viewport != Rect.zero ? viewport.right - _currentViewportSize.width : 0.0,
    );
    final bottomBound = math.max(
      math.max(effectiveViewportHeight, nodeBottomBound),
      viewport != Rect.zero ? viewport.bottom - _currentViewportSize.height : 0.0,
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
    final newVisible = _dataController.spatialGrid.queryRect(bufferRect);
    _log.finest(
      'updateVisibleSet: Spatial index returned ${newVisible.length} visible nodes.',
    );
    if (!setEquals(visibleNodeIds.value, newVisible)) {
      visibleNodeIds.value = newVisible;
    }
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

  void dispose() {
    _log.fine('Disposing ViewportController.');
    transformController.removeListener(_handleTransform);
    _dataController.canvasBounds.removeListener(_onCanvasBoundsChanged);
    _updateSubscription?.cancel();
    transformController.dispose();
    viewportStateNotifier.dispose();
    visibleNodeIds.dispose();
    elasticMargins.dispose();
  }
}
