import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../../../core/config/app_config.dart';
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
