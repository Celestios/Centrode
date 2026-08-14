import 'package:centrode/src/rust/domain/styles.dart' hide EndpointShape;
import 'package:centrode/features/graph/models/graph_node.dart';
import 'package:centrode/features/graph/engine/config.dart';
import 'package:centrode/presentation/theme/graph_theme.dart';
import 'package:centrode/shared/utils/color_utils.dart';

abstract class NodeStyleStrategy {
  const NodeStyleStrategy();

  NodeStyle computeStyle(UiNode node, GraphTheme theme);

  static const double _referenceFontSize = 14.0;

  static double expandToggleSpace(bool isExpanded, double fontScale) =>
      (isExpanded ? 24.0 : 18.0) * fontScale;
  static double taskBadgeHeight(double fontScale) => 22.0 * fontScale;

  static NodeStyle fallbackStyle([
    double? width,
    double? height,
    double? fontSize,
  ]) {
    final fs = fontSize ?? _referenceFontSize;
    return NodeStyle(
      bgColor: 0xFFFFFFFF,
      strokeColor: 0xFF000000,
      strokeWidth: 1,
      fontFamily: AppConfig.visuals.defaultFont,
      fontSize: fs,
      shape: AppConfig.visuals.defaultShape,
      width: (width ?? 0).round(),
      height: (height ?? 0).round(),
      textColor: 0xFF000000,
      borderRadius: 8.0,
      padding: 8.0,
      shadowColor: 0x33000000,
      shadowBlur: 4.0,
      shadowSpread: 0.0,
      shadowOffsetX: 2.0,
      shadowOffsetY: 2.0,
      strategyType: 'default',
    );
  }

  static NodeStyle scaleStyle(NodeStyle base) {
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

  static NodeStyle resolveStyle(UiNode node, {GraphTheme? theme}) {
    if (node.resolvedStyle != null) return node.resolvedStyle!;

    const strategy = DefaultNodeStyleStrategy();
    final NodeStyle base;
    if (theme != null) {
      base = strategy.computeStyle(node, theme);
    } else if (node is DrawingUiNode) {
      base = fallbackStyle().copyWith(
        bgColor: 0x00000000,
        strokeColor: 0x00000000,
        shadowColor: 0x00000000,
        padding: 0.0,
        borderRadius: 0.0,
        strategyType: 'drawing',
      );
    } else if (node is ContainerUiNode) {
      base = fallbackStyle(node.size.width, node.size.height).copyWith(
        bgColor: 0x1A2196F3,
        strokeColor: 0xFF64B5F6,
        strokeWidth: 2,
        borderRadius: 12.0,
        textColor: 0xFFFFFFFF,
      );
    } else {
      base = fallbackStyle();
    }
    return scaleStyle(base);
  }
}

class DefaultNodeStyleStrategy implements NodeStyleStrategy {
  const DefaultNodeStyleStrategy();

  @override
  NodeStyle computeStyle(UiNode node, GraphTheme theme) {
    if (node.style != null) return node.style!;

    if (node is ContainerUiNode) {
      return NodeStyleStrategy.fallbackStyle(
        node.size.width,
        node.size.height,
        theme.bodyFontSize,
      ).copyWith(
        bgColor: 0x1A2196F3,
        strokeColor: 0xFF64B5F6,
        strokeWidth: 2,
        fontFamily: theme.fontFamily,
        textColor: 0xFFFFFFFF,
        borderRadius: 12.0,
      );
    }

    final int bgColor = _computeBaseColor(node, theme);
    return NodeStyleStrategy.fallbackStyle(
      null,
      null,
      theme.bodyFontSize,
    ).copyWith(
      bgColor: bgColor,
      strokeColor: ColorUtils.getContrastStrokeColorInt(bgColor),
      fontFamily: theme.fontFamily,
      textColor: ColorUtils.getContrastTextColorInt(bgColor),
      borderRadius: theme.borderRadius,
    );
  }

  int _computeBaseColor(UiNode node, GraphTheme theme) {
    return switch (node) {
      TaskUiNode() => 0xFF34D399,
      DrawingUiNode() => 0x00000000,
      ContainerUiNode() => 0x1A2196F3,
      InfoUiNode() => theme.primaryColor.toARGB32(),
      _ => theme.primaryColor.toARGB32(),
    };
  }
}
