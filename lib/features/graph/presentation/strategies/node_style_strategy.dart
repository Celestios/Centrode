import 'package:mycelium/src/rust/domain/styles.dart'; // NodeStyle
import 'package:mycelium/presentation/theme/graph_theme.dart';
import 'package:mycelium/features/graph/models/graph_node.dart';
import 'package:mycelium/features/graph/engine/config.dart';
import 'package:mycelium/shared/utils/color_utils.dart';

/// Responsible for computing the *base* [NodeStyle] for a node,
/// using per‑node overrides and theme defaults.
abstract class NodeStyleStrategy {
  const NodeStyleStrategy();

  /// Resolves the correct style strategy based on type.
  static NodeStyleStrategy fromType(String? type, {UiNode? fallbackNode}) {
    if (type == 'task') {
      return const TaskNodeStyleStrategy();
    }
    if (type == 'info') {
      return const InfoNodeStyleStrategy();
    }
    if (type == 'drawing') {
      return const DrawingNodeStyleStrategy();
    }
    if (fallbackNode != null) {
      if (fallbackNode is DrawingUiNode) {
        return const DrawingNodeStyleStrategy();
      }
      return fallbackNode is TaskUiNode
          ? const TaskNodeStyleStrategy()
          : const InfoNodeStyleStrategy();
    }
    return const InfoNodeStyleStrategy();
  }

  /// Returns a fully populated [NodeStyle] for rendering.
  /// [node.style] may be null → use theme defaults.
  NodeStyle resolve(UiNode node, GraphTheme theme);

  static const double _referenceFontSize = 14.0;

  /// Centralized aesthetic fallback config used across the store and layouts.
  /// All visual properties are pre-scaled by [fontSize] relative to the
  /// design baseline (14pt). Consumers should use values directly without
  /// additional scaling.
  ///
  /// [width] and [height] default to 0 (auto-size sentinel). The layout
  /// strategy interprets `width > 0` as manual sizing mode. Only explicit
  /// resize operations should set positive width/height.
  static NodeStyle fallbackStyle([double? width, double? height, double? fontSize]) {
    final fs = fontSize ?? _referenceFontSize;
    final s = fs / _referenceFontSize;
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
      borderRadius: 8.0 * s,
      padding: 8.0 * s,
      shadowColor: 0x33000000,
      shadowBlur: 4.0 * s,
      shadowSpread: 0.0,
      shadowOffsetX: 2.0 * s,
      shadowOffsetY: 2.0 * s,
      strategyType: 'default',
    );
  }

  /// Centralized static helper to resolve a node's populated style.
  static NodeStyle resolveStyle(UiNode node, {GraphTheme? theme}) {
    if (node.resolvedStyle != null) return node.resolvedStyle!;
    final strategyType =
        node.resolvedStyle?.strategyType ?? node.style?.strategyType;
    final strategy = fromType(strategyType, fallbackNode: node);
    if (theme != null) {
      return strategy.resolve(node, theme);
    }
    if (node is DrawingUiNode) {
      return fallbackStyle().copyWith(
        bgColor: 0x00000000,
        strokeColor: 0x00000000,
        strategyType: 'drawing',
      );
    }
    return fallbackStyle();
  }
}

class DrawingNodeStyleStrategy extends NodeStyleStrategy {
  const DrawingNodeStyleStrategy();

  @override
  NodeStyle resolve(UiNode node, GraphTheme theme) {
    if (node.style != null) return node.style!;
    return NodeStyleStrategy.fallbackStyle().copyWith(
      bgColor: 0x00000000,
      strokeColor: 0x00000000,
      textColor: 0x00000000,
      strategyType: 'drawing',
    );
  }
}

class InfoNodeStyleStrategy extends NodeStyleStrategy {
  const InfoNodeStyleStrategy();

  @override
  NodeStyle resolve(UiNode node, GraphTheme theme) {
    if (node.style != null) return node.style!;
    final int bgColor = theme.primaryColor.toARGB32();
    return NodeStyleStrategy.fallbackStyle(
      null, null, theme.bodyFontSize,
    ).copyWith(
      bgColor: bgColor,
      strokeColor: ColorUtils.getContrastStrokeColorInt(bgColor),
      fontFamily: theme.fontFamily,
      textColor: ColorUtils.getContrastTextColorInt(bgColor),
      borderRadius: theme.borderRadius,
    );
  }
}

class TaskNodeStyleStrategy extends NodeStyleStrategy {
  const TaskNodeStyleStrategy();

  @override
  NodeStyle resolve(UiNode node, GraphTheme theme) {
    if (node.style != null) return node.style!;
    const int bgColor = 0xFF34D399;
    return NodeStyleStrategy.fallbackStyle(
      null, null, theme.bodyFontSize,
    ).copyWith(
      bgColor: bgColor,
      strokeColor: ColorUtils.getContrastStrokeColorInt(bgColor),
      fontFamily: theme.fontFamily,
      textColor: ColorUtils.getContrastTextColorInt(bgColor),
      borderRadius: theme.borderRadius,
    );
  }
}
