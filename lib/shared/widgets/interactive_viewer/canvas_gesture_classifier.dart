import 'package:flutter/gestures.dart';

/// A classification of relevant user gestures.
enum CanvasGestureType {
  pan,
  scale,
  rotate,
}

/// Helper classifying gestures and determining supported interaction modes.
class CanvasGestureClassifier {
  CanvasGestureClassifier._();

  /// Decide which type of gesture this is by comparing scale and rotation amounts.
  static CanvasGestureType classifyGesture({
    required ScaleUpdateDetails details,
    required bool scaleEnabled,
    required bool rotateEnabled,
  }) {
    final double scale = !scaleEnabled ? 1.0 : details.scale;
    final double rotation = !rotateEnabled ? 0.0 : details.rotation;
    if ((scale - 1).abs() > rotation.abs()) {
      return CanvasGestureType.scale;
    } else if (rotation != 0.0) {
      return CanvasGestureType.rotate;
    } else {
      return CanvasGestureType.pan;
    }
  }

  /// Returns true iff the given gesture type is enabled.
  static bool isGestureSupported({
    required CanvasGestureType? gestureType,
    required bool panEnabled,
    required bool scaleEnabled,
    required bool rotateEnabled,
    required PointerDeviceKind? lastPointerKind,
    required int lastPointerButtons,
  }) {
    if (gestureType == CanvasGestureType.pan) {
      if (lastPointerKind == PointerDeviceKind.mouse &&
          lastPointerButtons == kPrimaryMouseButton) {
        return false;
      }
    }
    return switch (gestureType) {
      CanvasGestureType.rotate => rotateEnabled,
      CanvasGestureType.scale => scaleEnabled,
      CanvasGestureType.pan || null => panEnabled,
    };
  }
}
