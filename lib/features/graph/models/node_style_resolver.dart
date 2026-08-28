import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:centrode/src/rust/domain/styles.dart' hide EndpointShape;
import 'package:centrode/features/graph/models/graph_node.dart';

const double _referenceFontSize = 14.0;
const String defaultNodeFont = 'Inter';
const String defaultNodeShape = 'rectangle';

const int containerBgColor = 0x1A2196F3;
const int containerStrokeColor = 0xFF64B5F6;
const int frameBgColor = 0x14BCAAA4;
const int frameStrokeColor = 0xFFBCAAA4;

double expandToggleSpace(bool isExpanded, double fontScale) =>
    (isExpanded ? 24.0 : 18.0) * fontScale;

double taskBadgeHeight(double fontScale) => 22.0 * fontScale;

NodeStyle fallbackStyle([
  double? width,
  double? height,
  double? fontSize,
]) {
  final fs = fontSize ?? _referenceFontSize;
  return NodeStyle(
    bgColor: 0xFFFFFFFF,
    strokeColor: 0xFF000000,
    strokeWidth: UiStrokeWidth.standard.toInt(),
    fontFamily: defaultNodeFont,
    fontSize: fs,
    shape: defaultNodeShape,
    width: (width ?? 0).round(),
    height: (height ?? 0).round(),
    textColor: 0xFF000000,
    borderRadius: UiRadius.card,
    padding: UiSpacing.standard,
    shadowColor: 0x33000000,
    shadowBlur: 4.0,
    shadowSpread: 0.0,
    shadowOffsetX: 2.0,
    shadowOffsetY: 2.0,
    strategyType: 'default',
  );
}

NodeStyle scaleStyle(NodeStyle base) {
  final double fs = base.fontSize;
  final double scale = fs / _referenceFontSize;

  final double basePadding = base.padding;
  final double extraCornerPadding = base.borderRadius * 0.15;
  final double scaledPadding = (basePadding + extraCornerPadding) * scale;

  return base.copyWith(
    strokeWidth: (base.strokeWidth * scale).round().clamp(1, 999),
    borderRadius: base.borderRadius * scale,
    padding: scaledPadding,
    shadowBlur: base.shadowBlur * scale,
    shadowSpread: base.shadowSpread * scale,
    shadowOffsetX: base.shadowOffsetX * scale,
    shadowOffsetY: base.shadowOffsetY * scale,
  );
}

NodeStyle resolveStyle(UiNode node) {
  if (node.resolvedStyle != null) return node.resolvedStyle!;

  final NodeStyle base = switch (node) {
    DrawingUiNode() => fallbackStyle().copyWith(
        bgColor: 0x00000000,
        strokeColor: 0x00000000,
        shadowColor: 0x00000000,
        padding: 0.0,
        borderRadius: 0.0,
        strategyType: 'drawing',
      ),
    ContainerUiNode(:final size) =>
      fallbackStyle(size.width, size.height).copyWith(
        bgColor: containerBgColor,
        strokeColor: containerStrokeColor,
        strokeWidth: UiStrokeWidth.thick.toInt(),
        borderRadius: UiRadius.panel,
        textColor: 0xFFFFFFFF,
      ),
    FrameUiNode(:final size) =>
      fallbackStyle(size.width, size.height).copyWith(
        bgColor: frameBgColor,
        strokeColor: frameStrokeColor,
        strokeWidth: UiStrokeWidth.thick.toInt(),
        borderRadius: UiRadius.card,
        textColor: 0xFFFFFFFF,
      ),
    _ => fallbackStyle(),
  };
  return scaleStyle(base);
}
