import 'dart:math';
import 'package:flutter/material.dart' hide Theme;
import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:centrode/shared/elements/elements.dart';

abstract final class AppConfig {
  AppConfig._();

  static const grid = _Grid();
  static const canvas = _Canvas();
  static const interaction = _Interaction();
  static const node = _Node();
  static const port = _Port();
  static const relation = _Relation();
  static const toolbar = _Toolbar();
  static const visuals = _Visuals();
  static const editor = _Editor();
  static const liquidGlass = _LiquidGlass();
}

class _Grid {
  const _Grid();

  final double baseSize = CanvasTokens.gridBase;
  final double dotRadius = CanvasTokens.gridDotRadius;
}

class _Canvas {
  const _Canvas();

  final double boundaryMargin = 600.0;
  final double initialBoundaryMargin = 600.0;
  final double minScale = 0.2;
  final double maxScale = 3.0;
  final double scaleFactor = 1000.0;
  final double overscanRatio = 0.25;
  final double elasticResistance = 90.0;
  final double springStiffness = 300.0;
  final double springDamping = 34.0;
}

class _Interaction {
  const _Interaction();

  final int doubleTapMs = 300;
  final double doubleTapDistance = UiSpacing.gutter;
  final double snapDistance = 40.0;
  final double resizeEdgeWidth = CanvasTokens.edgeResizeHitbox;
  final Size relationLabelHitArea = const Size(100, 40);
  final double relationTipHitDistance = UiSpacing.gutter;
  final double relationLineHitThreshold = UiSpacing.standard;
}

class _Node {
  const _Node();

  final double defaultWidth = CanvasTokens.nodeDefaultWidth;
  final double minWidth = CanvasTokens.nodeMinWidth;
  final double maxWidth = CanvasTokens.nodeMaxWidth;
  final double autoWrapThreshold = CanvasTokens.autoWrapThreshold;
  final double resizeHandleVisualWidth = CanvasTokens.handleWidth;
  final double editingBufferWidth = 45.0;
  final int collapsedLineLimit = 3;
  final Size defaultSize = const Size(100, 80);
  final double defaultFontSize = CanvasTokens.referenceFontSize;
  final double minFontSize = UiFont.micro;
  final double maxFontSize = 40.0;

  double scaledDefaultWidth(double fontSize) =>
      defaultWidth * CanvasTokens.fontScale(fontSize);
  double scaledMinWidth(double fontSize) =>
      minWidth * CanvasTokens.fontScale(fontSize);
  double scaledMaxWidth(double fontSize) =>
      maxWidth * CanvasTokens.fontScale(fontSize);
  double scaledAutoWrapThreshold(double fontSize) =>
      autoWrapThreshold * CanvasTokens.fontScale(fontSize);
  double scaledEditingBufferWidth(double fontSize) =>
      editingBufferWidth * CanvasTokens.fontScale(fontSize);

  final double metadataSphereOffsetFromRight = 10.0;
  final double metadataSphereOffsetFromTop = 10.0;
  final double metadataSphereRadius = 5.0;
  final double metadataSphereStrokeWidth = UiStrokeWidth.thick;
  final double metadataSphereHitboxRadius = 12.0;
  final Offset metadataPreviewOffset = const Offset(0, -34);
  final double metadataPreviewWidth = 140.0;
  final double metadataPreviewBorderRadius = UiRadius.card;
  final double metadataPreviewBlur = 10.0;
  List<int> get defaultTagColors =>
      CentrodeDerivedPalette.current.tagColors.map((c) => c.toARGB32()).toList();
}

class _Toolbar {
  const _Toolbar();

  final double singleWidth = 90.0;
  final double multiWidth = 105.0;
  final double height = UiControlSize.standard;
  final Offset singleOffset = const Offset(-52, 0);
  final Offset multiOffset = const Offset(-52, 0);
}

class _Visuals {
  const _Visuals();

  final String defaultFont = 'Inter';
  final String defaultShape = 'rectangle';
  final List<String> availableFonts = const [
    'System',
    'Inter',
    'Roboto',
    'Consolas',
  ];
  List<int> get textColors =>
      CentrodeDerivedPalette.current.swatches.map((c) => c.toARGB32()).toList();
}

class _Port {
  const _Port();

  final double edgeOffset = UiSpacing.standard;
  final double hitRadius = CanvasTokens.portHitRadius;
  final double drawRadius = CanvasTokens.portDrawRadius;
}

class _Relation {
  const _Relation();

  final double strokeWidth = UiStrokeWidth.thick;
  final double selectedStrokeWidth = UiStrokeWidth.thick;
  final double labelFontSize = UiFont.micro;
  final Offset startFallback = const Offset(100, 30);
  final Offset endFallback = const Offset(0, 30);
  final double editorVerticalOffset = 15.0;
  final double editorMinWidth = 100.0;
  final Color editorBgColor = Colors.white;
}

class _Editor {
  const _Editor();

  final double fontSizeRelation = UiFont.micro;
}

class _LiquidGlass {
  const _LiquidGlass();

  final double refractStrength = 0.16;
  final double bridgeReachFactor = 2.0;
  final double bridgeThicknessFactor = 0.4;
  final bool useLocalCoordinates = true;
}

double calculateEffectiveGridSize(double scale) {
  if (scale <= 0) return AppConfig.grid.baseSize;
  const double targetScreenSpacing = 20.0;
  final double targetGridSize = targetScreenSpacing / scale;
  final double ratio = targetGridSize / AppConfig.grid.baseSize;
  final double step = pow(2, (log(ratio) / ln2).round() + 1).toDouble();
  final double clampedStep = step.clamp(1.0, 10.0);
  return AppConfig.grid.baseSize * clampedStep;
}
