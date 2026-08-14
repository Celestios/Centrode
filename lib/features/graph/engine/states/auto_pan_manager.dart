// lib/features/graph/state/states/auto_pan_manager.dart
part of '../base_interaction_state.dart';

/// Logger for AutoPanManager telemetry
final Logger _autoPanLog = Logger('AutoPanManager');

/// Manages continuous camera auto-panning and scale zoom during node dragging when pointer is near viewport edges.
class AutoPanManager {
  Timer? _timer;
  DateTime? _lastTickTime;
  Offset? _lastScreenPos;

  static const double edgeMargin = 60.0;
  static const double maxPanSpeed = 1000.0; // Pixels per second
  static const double zoomSpeedPerSecond = 0.5; // Scale units per second

  /// Calculates screen translation delta for camera auto-pan based on screen position, viewport size, and dt.
  static Offset calculatePanDelta(Offset screenPos, Size viewportSize, [double dt = 0.016]) {
    if (viewportSize.width <= 0 || viewportSize.height <= 0) return Offset.zero;

    double dx = 0.0;
    double dy = 0.0;

    // Left edge
    if (screenPos.dx < edgeMargin) {
      final dist = (edgeMargin - screenPos.dx).clamp(0.0, edgeMargin * 2.0);
      final ratio = dist / edgeMargin;
      dx = ratio * ratio * maxPanSpeed * dt;
    }
    // Right edge
    else if (screenPos.dx > viewportSize.width - edgeMargin) {
      final dist = (screenPos.dx - (viewportSize.width - edgeMargin)).clamp(0.0, edgeMargin * 2.0);
      final ratio = dist / edgeMargin;
      dx = -ratio * ratio * maxPanSpeed * dt;
    }

    // Top edge
    if (screenPos.dy < edgeMargin) {
      final dist = (edgeMargin - screenPos.dy).clamp(0.0, edgeMargin * 2.0);
      final ratio = dist / edgeMargin;
      dy = ratio * ratio * maxPanSpeed * dt;
    }
    // Bottom edge
    else if (screenPos.dy > viewportSize.height - edgeMargin) {
      final dist = (screenPos.dy - (viewportSize.height - edgeMargin)).clamp(0.0, edgeMargin * 2.0);
      final ratio = dist / edgeMargin;
      dy = -ratio * ratio * maxPanSpeed * dt;
    }

    return Offset(dx, dy);
  }

  /// Updates auto-pan state with the latest screen position.
  /// If inside edge margin or perimeter zoom region, starts or maintains periodic camera panning and fires [onTick].
  void update(
    Offset screenPos,
    ViewportCapability ctx,
    void Function(Offset pCanvas) onTick, {
    bool isNearContainerPerimeter = false,
  }) {
    _lastScreenPos = screenPos;

    if (_timer == null || !_timer!.isActive) {
      _autoPanLog.finest('Starting auto-pan timer for drag at $screenPos');
      _lastTickTime = DateTime.now();
      _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        final now = DateTime.now();
        final dt = (_lastTickTime != null ? now.difference(_lastTickTime!).inMicroseconds : 16000) / 1000000.0;
        _lastTickTime = now;

        if (_lastScreenPos == null) return;
        final currentPanDelta = calculatePanDelta(_lastScreenPos!, ctx.viewportSize, dt);

        if (currentPanDelta != Offset.zero) {
          ctx.panViewport(currentPanDelta);
        }

        if (isNearContainerPerimeter && ctx.currentScale > 0.15) {
          final newScale = ctx.currentScale * (1.0 - (zoomSpeedPerSecond * dt));
          ctx.updateScale(newScale);
        }

        final newPCanvas = ctx.screenToCanvas(_lastScreenPos!);
        onTick(newPCanvas);
      });
    }
  }

  /// Stops any running auto-pan timer.
  void stop() {
    if (_timer != null) {
      _autoPanLog.finest('Stopping auto-pan timer');
      _timer!.cancel();
      _timer = null;
      _lastTickTime = null;
      _lastScreenPos = null;
    }
  }
}
