import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../../../core/config/app_config.dart';
import '../../../src/rust/domain/base_models.dart' show BoundingBox;
import 'graph_ui_controller.dart';

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
/// and viewport boundary math. Disconnected from the widget tree lifecycle.
class ViewportController {
  final Logger _log = Logger('ViewportController');
  final GraphUIController _uiController;
  final TransformationController transformController =
      TransformationController();

  Rect _overscanBuffer = Rect.zero;
  Size _currentViewportSize = Size.zero;

  ViewportController(this._uiController) {
    _log.info(
      'Initializing ViewportController and tracking transform mutations.',
    );
    transformController.addListener(_handleTransform);
  }

  /// Guarded dimension update injected by the Passive View's LayoutBuilder.
  /// Guarantees O(1) performance by rejecting identical subsequent layouts.
  void updateViewportSize(Size size) {
    if (size == _currentViewportSize) return;

    _log.fine('Viewport dimensions updated: $size');
    _currentViewportSize = size;
    _recalculate();
  }

  /// Mutates the Transformation Matrix to center the camera on the provided bounds.
  void focusOnBounds(BoundingBox bounds) {
    if (_currentViewportSize == Size.zero) return;

    // Detect the Rust fallback empty bounds (-2500 to 2500)
    final bool isEmpty = bounds.minX == -2500 && bounds.maxX == 2500;

    // Calculate the mathematical center of the nodes
    final double centerX = isEmpty ? 0.0 : (bounds.minX + bounds.maxX) / 2.0;
    final double centerY = isEmpty ? 0.0 : (bounds.minY + bounds.maxY) / 2.0;

    // Calculate translation required to place the center point in the middle of the screen
    final double dx = (_currentViewportSize.width / 2) - centerX;
    final double dy = (_currentViewportSize.height / 2) - centerY;

    _log.info('Translating Camera Matrix to center: ($centerX, $centerY)');
    transformController.value = Matrix4.identity()..translate(dx, dy);
  }

  void _handleTransform() {
    _recalculate();
  }

  void _recalculate() {
    // Prevent math execution before initial layout constraints are fed
    if (_currentViewportSize == Size.zero) return;

    final viewport = _calculateCanvasViewport();
    if (viewport == Rect.zero) return;

    // Viewport Hysteresis Logic
    if (!_overscanBuffer.containsRect(viewport)) {
      _overscanBuffer = viewport.inflate(
        viewport.width * AppConfig.graph.canvas.overscanRatio,
      );
      _uiController.updateVisibleSet(_overscanBuffer);
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
    transformController.dispose();
  }
}
