import 'package:flutter/material.dart';
import 'package:mycelium/src/rust/domain/styles.dart'; // NodeStyle
import 'package:mycelium/presentation/theme/graph_theme.dart';
import 'package:mycelium/features/graph/models/graph_node.dart';
import 'package:mycelium/features/graph/presentation/graph_metrics.dart';

/// Responsible for computing the *base* [NodeStyle] for a node,
/// using per‑node overrides and theme defaults.
abstract class NodeStyleStrategy {
  const NodeStyleStrategy();

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
    );
  }

  /// Centralized static helper to resolve a node's populated style.
  static NodeStyle resolveStyle(UiNode node, {GraphTheme? theme}) {
    if (node.resolvedStyle != null) return node.resolvedStyle!;
    final strategy = node is InfoUiNode
        ? const InfoNodeStyleStrategy()
        : const TaskNodeStyleStrategy();
    if (theme != null) {
      return strategy.resolve(node, theme);
    }
    return fallbackStyle(node.size.width, node.size.height);
  }
}

class InfoNodeStyleStrategy extends NodeStyleStrategy {
  const InfoNodeStyleStrategy();

  @override
  NodeStyle resolve(UiNode node, GraphTheme theme) {
    if (node.style != null) return node.style!;
    return NodeStyle(
      bgColor: theme.primaryColor.toARGB32(),
      strokeColor: theme.dividerColor.toARGB32(),
      strokeWidth: 1,
      fontFamily: theme.fontFamily,
      fontSize: theme.bodyFontSize,
      shape: 'rectangle',
      width: 150,
      height: 40,
      // --- Advanced Style Properties ---
      textColor: theme.bodyTextColor.toARGB32(),
      borderRadius: theme.borderRadius,
      padding: 8.0,
      shadowColor: const Color(0x33000000).toARGB32(),
      shadowBlur: 4.0,
      shadowSpread: 0.0,
      shadowOffsetX: 2.0,
      shadowOffsetY: 2.0,
    );
  }
}

class TaskNodeStyleStrategy extends NodeStyleStrategy {
  const TaskNodeStyleStrategy();

  @override
  NodeStyle resolve(UiNode node, GraphTheme theme) {
    if (node.style != null) return node.style!;
    return NodeStyle(
      bgColor: 0xFFC8E6C9,
      strokeColor: 0xFF000000,
      strokeWidth: 1,
      fontFamily: theme.fontFamily,
      fontSize: theme.bodyFontSize,
      shape: 'rectangle',
      width: 150,
      height: 40,
      // --- Advanced Style Properties ---
      textColor: 0xFF1B5E20,
      borderRadius: theme.borderRadius,
      padding: 8.0,
      shadowColor: const Color(0x33000000).toARGB32(),
      shadowBlur: 4.0,
      shadowSpread: 0.0,
      shadowOffsetX: 2.0,
      shadowOffsetY: 2.0,
    );
  }
}
