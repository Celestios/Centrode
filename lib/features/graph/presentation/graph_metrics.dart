import 'dart:math';
import 'package:flutter/material.dart' hide Theme;
import 'package:mycelium/shared/widgets/glass_panel/glass_panel.dart';

abstract final class AppConfig {
  AppConfig._();

  static const grid = _Grid();
  static const canvas = _Canvas();
  static const interaction = _Interaction();
  static const node = _Node();
  static const relation = _Relation();
  static const toolbar = _Toolbar();
  static const visuals = _Visuals();
  static const editor = _Editor();
  static const liquidGlass = _LiquidGlass();
}

class _Grid {
  const _Grid();

  final double baseSize = 20.0;
  final double dotRadius = 1.5;
}

class _Canvas {
  const _Canvas();

  final double boundaryMargin = 500.0;
  final double minScale = 0.2;
  final double maxScale = 3.0;
  final double scaleFactor = 1000.0;
  final double overscanRatio = 0.25;
}

class _Interaction {
  const _Interaction();

  final int doubleTapMs = 300;
  final double doubleTapDistance = 20.0;
  final double snapDistance = 40.0;
  final double resizeEdgeWidth = 15.0;
  final Size relationLabelHitArea = const Size(100, 40);
}

class _Node {
  const _Node();

  final double defaultWidth = 100.0;
  final double minWidth = 60.0;
  final double maxWidth = 500.0;
  final double autoWrapThreshold = 240.0;
  final double resizeHandleVisualWidth = 5.0;
  final double editingBufferWidth = 35.0;
  final int collapsedLineLimit = 3;
  final Size defaultSize = const Size(100, 60);

  final double metadataSphereOffsetFromRight = 10.0;
  final double metadataSphereOffsetFromTop = 10.0;
  final double metadataSphereRadius = 5.0;
  final double metadataSphereStrokeWidth = 1.5;
  final double metadataSphereHitboxRadius = 12.0;
  final Offset metadataPreviewOffset = const Offset(0, -12);
  final double metadataPreviewWidth = 220.0;
  final double metadataPreviewBorderRadius = 8.0;
  final double metadataPreviewBlur = 8.0;
  final List<int> defaultTagColors = const [
    0xFF5C6BC0,
    0xFF26A69A,
    0xFFEC407A,
    0xFFFFA726,
    0xFF78909C,
  ];
}

class _Toolbar {
  const _Toolbar();

  final double singleWidth = 90.0;
  final double multiWidth = 105.0;
  final double height = 32.0;
  final Offset singleOffset = const Offset(-52, 0);
  final Offset multiOffset = const Offset(-52, 0);
}

class _Visuals {
  const _Visuals();

  final Color selectionAccent = const Color(0xFF42A5F5);
  final String defaultFont = 'Inter';
  final String defaultShape = 'rectangle';
}

class _Relation {
  const _Relation();

  final double strokeWidth = 1.5;
  final double selectedStrokeWidth = 3.0;
  final double labelFontSize = 10.0;
  final Offset startFallback = const Offset(100, 30);
  final Offset endFallback = const Offset(0, 30);
  final double editorVerticalOffset = 15.0;
  final double editorMinWidth = 100.0;
  final Color editorBgColor = Colors.white;
}

class _Editor {
  const _Editor();

  final double fontSizeRelation = 10.0;
}

class _LiquidGlass {
  const _LiquidGlass();

  final GlassSettings settings = const GlassSettings(
    refractStrength: 0.16,
    bridgeReachFactor: 2.0,
    bridgeThicknessFactor: 0.4,
    useLocalCoordinates: true,
  );
}

/// Calculates the dynamic grid size based on the current zoom level (Dynamic LOD).
double calculateEffectiveGridSize(double scale) {
  if (scale <= 0) return AppConfig.grid.baseSize;
  final double lod = max(1.0, (1.0 / scale).floorToDouble());
  final effectiveSize = AppConfig.grid.baseSize * lod;
  return effectiveSize;
}
