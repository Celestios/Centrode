import 'package:mycelium/src/rust/domain/styles.dart'; // NodeStyle
import 'package:mycelium/presentation/theme/graph_theme.dart';
import 'package:mycelium/features/graph/models/graph_node.dart';
import 'package:mycelium/features/graph/presentation/graph_metrics.dart';
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

  /// Centralized aesthetic fallback config used across the store and layouts.
  static NodeStyle fallbackStyle([double? width, double? height]) {
    return NodeStyle(
      bgColor: 0xFFFFFFFF,
      strokeColor: 0xFF000000,
      strokeWidth: 1,
      fontFamily: AppConfig.visuals.defaultFont,
      fontSize: 12.0,
      shape: AppConfig.visuals.defaultShape,
      width: (width ?? AppConfig.node.defaultWidth).round(),
      height: (height ?? AppConfig.node.defaultSize.height).round(),
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

  /// Centralized static helper to resolve a node's populated style.
  static NodeStyle resolveStyle(UiNode node, {GraphTheme? theme}) {
    if (node.resolvedStyle != null) return node.resolvedStyle!;
    final strategyType = node.resolvedStyle?.strategyType ?? node.style?.strategyType;
    final strategy = fromType(strategyType, fallbackNode: node);
    if (theme != null) {
      return strategy.resolve(node, theme);
    }
    if (node is DrawingUiNode) {
      return fallbackStyle(node.size.width, node.size.height).copyWith(
        bgColor: 0x00000000,
        strokeColor: 0x00000000,
        strategyType: 'drawing',
      );
    }
    return fallbackStyle(node.size.width, node.size.height);
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
      width: node.size.width.round(),
      height: node.size.height.round(),
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
    return NodeStyleStrategy.fallbackStyle().copyWith(
      bgColor: bgColor,
      strokeColor: ColorUtils.getContrastStrokeColorInt(bgColor),
      fontFamily: theme.fontFamily,
      fontSize: theme.bodyFontSize,
      width: 150,
      height: 40,
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
    return NodeStyleStrategy.fallbackStyle().copyWith(
      bgColor: bgColor,
      strokeColor: ColorUtils.getContrastStrokeColorInt(bgColor),
      fontFamily: theme.fontFamily,
      fontSize: theme.bodyFontSize,
      width: 150,
      height: 40,
      textColor: ColorUtils.getContrastTextColorInt(bgColor),
      borderRadius: theme.borderRadius,
    );
  }
}
