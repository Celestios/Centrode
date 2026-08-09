// lib/features/graph/state/states/auto_pan_manager.dart
part of '../base_interaction_state.dart';

/// Logger for AutoPanManager telemetry
final Logger _autoPanLog = Logger('AutoPanManager');

/// Manages continuous camera auto-panning during node dragging when pointer is near viewport edges.
class AutoPanManager {
  Timer? _timer;
  Offset? _lastScreenPos;

  static const double edgeMargin = 60.0;
  static const double maxSpeed = 16.0;

  /// Calculates screen translation delta for camera auto-pan based on screen position and viewport size.
  static Offset calculatePanDelta(Offset screenPos, Size viewportSize) {
    if (viewportSize.width <= 0 || viewportSize.height <= 0) return Offset.zero;

    double dx = 0.0;
    double dy = 0.0;

    // Left edge
    if (screenPos.dx < edgeMargin) {
      final dist = (edgeMargin - screenPos.dx).clamp(0.0, edgeMargin * 2.0);
      final ratio = dist / edgeMargin;
      dx = ratio * ratio * maxSpeed;
    }
    // Right edge
    else if (screenPos.dx > viewportSize.width - edgeMargin) {
      final dist = (screenPos.dx - (viewportSize.width - edgeMargin)).clamp(0.0, edgeMargin * 2.0);
      final ratio = dist / edgeMargin;
      dx = -ratio * ratio * maxSpeed;
    }

    // Top edge
    if (screenPos.dy < edgeMargin) {
      final dist = (edgeMargin - screenPos.dy).clamp(0.0, edgeMargin * 2.0);
      final ratio = dist / edgeMargin;
      dy = ratio * ratio * maxSpeed;
    }
    // Bottom edge
    else if (screenPos.dy > viewportSize.height - edgeMargin) {
      final dist = (screenPos.dy - (viewportSize.height - edgeMargin)).clamp(0.0, edgeMargin * 2.0);
      final ratio = dist / edgeMargin;
      dy = -ratio * ratio * maxSpeed;
    }

    return Offset(dx, dy);
  }

  /// Updates auto-pan state with the latest screen position.
  /// If inside edge margin, starts or maintains periodic camera panning and fires [onTick].
  void update(
    Offset screenPos,
    ViewportCapability ctx,
    void Function(Offset pCanvas) onTick,
  ) {
    _lastScreenPos = screenPos;
    final delta = calculatePanDelta(screenPos, ctx.viewportSize);

    if (delta == Offset.zero) {
      stop();
      return;
    }

    if (_timer == null || !_timer!.isActive) {
      _autoPanLog.finest('Starting auto-pan timer for drag at $screenPos');
      _timer = Timer.periodic(const Duration(milliseconds: 16), (_) {
        if (_lastScreenPos == null) return;
        final currentDelta = calculatePanDelta(_lastScreenPos!, ctx.viewportSize);
        if (currentDelta == Offset.zero) {
          stop();
          return;
        }
        ctx.panViewport(currentDelta);
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
    }
  }
}
