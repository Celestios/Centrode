import 'package:flutter/material.dart';
import 'package:mycelium/features/graph/presentation/graph_metrics.dart';
import 'package:mycelium/features/graph/models/graph_node.dart';
import 'package:mycelium/src/rust/domain/styles.dart';

/// Responsible for computing the physical size of a node based on its content,
/// style, and grid constraints.
abstract class NodeLayoutStrategy {
  const NodeLayoutStrategy();

  /// Calculates the size of the node.
  /// Snaps the result to the grid defined in [AppConfig].
  Size calculate(UiNode node, NodeStyle? style);
}

class InfoNodeLayoutStrategy extends NodeLayoutStrategy {
  const InfoNodeLayoutStrategy();

  @override
  Size calculate(UiNode node, NodeStyle? style) {
    return _calculateDefaultLayout(node, style);
  }
}

class TaskNodeLayoutStrategy extends NodeLayoutStrategy {
  const TaskNodeLayoutStrategy();

  @override
  Size calculate(UiNode node, NodeStyle? style) {
    return _calculateDefaultLayout(node, style);
  }
}

Size _calculateDefaultLayout(UiNode node, NodeStyle? style) {
  final content = node.content;
  // Fallback if text is empty
  if (content.text.isEmpty) {
    return AppConfig.node.defaultSize;
  }

  final resolvedStyle = style ??
      NodeStyle(
        bgColor: 0xFFFFFFFF,
        strokeColor: 0xFF000000,
        strokeWidth: 1,
        fontFamily: AppConfig.visuals.defaultFont,
        fontSize: 12.0,
        shape: AppConfig.visuals.defaultShape,
        width: AppConfig.node.defaultWidth.toInt(),
        height: AppConfig.node.defaultSize.height.toInt(),
        textColor: 0xFF000000,
        borderRadius: 8.0,
        padding: 8.0,
        shadowColor: 0x33000000,
        shadowBlur: 4.0,
        shadowSpread: 0.0,
        shadowOffsetX: 2.0,
        shadowOffsetY: 2.0,
      );

  final textStyle = TextStyle(
    fontFamily: resolvedStyle.fontFamily,
    fontSize: resolvedStyle.fontSize,
  );

  // Use current width if set, otherwise fallback to default
  final double targetWidth = (node.size.width > 0)
      ? node.size.width
      : AppConfig.node.defaultWidth;
  final double contentWidth = (targetWidth - 16).clamp(
    1,
    double.infinity,
  ); // Assuming 8px padding on each side

  final tp = TextPainter(
    text: TextSpan(text: content.text, style: textStyle),
    textDirection: TextDirection.ltr,
  )..layout(maxWidth: contentWidth);

  final lineMetrics = tp.computeLineMetrics();
  final lineCount = lineMetrics.length;
  double textHeight;

  // Handle "Show More" logic based on line count
  if (lineCount > AppConfig.node.collapsedLineLimit && !node.isExpanded) {
    textHeight = lineMetrics
        .take(AppConfig.node.collapsedLineLimit)
        .fold(0.0, (sum, m) => sum + m.height);
    textHeight += 2.0; // Buffer
  } else {
    textHeight = tp.height;
    if (lineCount > AppConfig.node.collapsedLineLimit) {
      textHeight += 5.0; // Space for "Show Less" button if needed
    }
  }

  final totalHeight = textHeight + 20; // 10px padding top and bottom

  // Quantization: Snap to grid
  final gridSize = AppConfig.grid.baseSize;

  // We ceil to the next grid step to ensure content fits and avoid loops
  final snappedWidth = (targetWidth / gridSize).ceil() * gridSize;
  final snappedHeight = (totalHeight / gridSize).ceil() * gridSize;

  return Size(snappedWidth, snappedHeight);
}
