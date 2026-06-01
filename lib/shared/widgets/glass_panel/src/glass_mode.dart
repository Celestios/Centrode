part of '../glass_panel.dart';

/// Rendering quality/performance trade-off for glass panels.
enum GlassMode {
  /// Full shader-backed rendering with refraction and bridge blending.
  quality,

  /// Lightweight blur/tint rendering with no shader dependency.
  performance,
}
