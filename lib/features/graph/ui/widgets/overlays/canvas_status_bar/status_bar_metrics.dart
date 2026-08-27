import 'dart:io';
import 'package:flutter/foundation.dart';

/// Centralized responsive metrics and platform visibility logic for canvas overlays.
class CanvasStatusBarMetrics {
  static bool isAndroidPlatform() => !kIsWeb && Platform.isAndroid;

  /// Dynamic dimension for the square minimap based on available viewport height.
  static double computeMiniMapDimension(double screenHeight) {
    if (screenHeight >= 850) {
      return 200.0;
    } else if (screenHeight <= 450) {
      return 100.0;
    } else {
      return 100.0 + (screenHeight - 450.0) / 400.0 * 100.0;
    }
  }

  /// Whether the minimap should be rendered given platform and viewport dimensions.
  static bool shouldShowMiniMap({
    required double maxWidth,
    required double maxHeight,
  }) {
    if (isAndroidPlatform()) return false;
    return maxWidth >= 700 && maxHeight >= 380;
  }

  /// Whether the graph metrics status bar section should be visible.
  static bool shouldShowMetrics(double maxWidth) {
    if (isAndroidPlatform()) return false;
    return maxWidth >= 500;
  }

  /// Whether the zoom slider is enabled.
  static bool shouldShowZoom() {
    return !isAndroidPlatform();
  }

  /// Whether the graph manual / conventions legend is visible.
  static bool shouldShowManual(double maxWidth) {
    return maxWidth >= 300;
  }

  /// Calculates dynamic bottom offset for the Right Property Panel to align with overlays.
  static double rightPanelBottomOffset({
    required double screenHeight,
    required double maxWidth,
    required double maxHeight,
    required double bottomPadding,
    required bool isBottomPanelVisible,
  }) {
    if (isAndroidPlatform()) {
      return bottomPadding + 68.0;
    }
    if (!isBottomPanelVisible) {
      return 16.0;
    }
    if (shouldShowMiniMap(maxWidth: maxWidth, maxHeight: maxHeight)) {
      return computeMiniMapDimension(screenHeight) + 24.0;
    }
    return 64.0;
  }
}
