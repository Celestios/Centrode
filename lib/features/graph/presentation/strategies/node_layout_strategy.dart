import 'package:flutter/material.dart';
import 'package:mycelium/features/graph/presentation/graph_metrics.dart';
import 'package:mycelium/features/graph/models/graph_node.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import 'node_style_strategy.dart';

/// Responsible for computing the physical size of a node based on its content,
/// style, and grid constraints.
abstract class NodeLayoutStrategy {
  const NodeLayoutStrategy();

  /// Resolves the correct layout strategy based on type.
  static NodeLayoutStrategy fromType(String? type, {UiNode? fallbackNode}) {
    if (type == 'task') {
      return const TaskNodeLayoutStrategy();
    }
    if (type == 'info') {
      return const InfoNodeLayoutStrategy();
    }
    if (fallbackNode != null) {
      return fallbackNode is TaskUiNode
          ? const TaskNodeLayoutStrategy()
          : const InfoNodeLayoutStrategy();
    }
    return const InfoNodeLayoutStrategy();
  }


  /// Calculates the size of the node.
  /// Snaps the result to the grid defined in [AppConfig].
  Size calculate(UiNode node, NodeStyle? style, {bool isEditing = false});

  /// Centralized helper to compute a node's physical size based on its runtime type.
  static Size calculateSize(UiNode node, {bool isEditing = false}) {
    final strategyType = node.resolvedLayout?.strategyType ?? node.layout?.strategyType;
    final strategy = fromType(strategyType, fallbackNode: node);
    return strategy.calculate(node, node.resolvedStyle, isEditing: isEditing);
  }
}

class InfoNodeLayoutStrategy extends NodeLayoutStrategy {
  const InfoNodeLayoutStrategy();

  @override
  Size calculate(UiNode node, NodeStyle? style, {bool isEditing = false}) {
    return _calculateDefaultLayout(node, style, isEditing: isEditing);
  }
}

class TaskNodeLayoutStrategy extends NodeLayoutStrategy {
  const TaskNodeLayoutStrategy();

  @override
  Size calculate(UiNode node, NodeStyle? style, {bool isEditing = false}) {
    return _calculateDefaultLayout(node, style, isEditing: isEditing);
  }
}

Size _calculateDefaultLayout(UiNode node, NodeStyle? style, {bool isEditing = false}) {
  final content = node.content;
  // Fallback if text is empty
  if (content.text.isEmpty) {
    return AppConfig.node.defaultSize;
  }

  final resolvedStyle = style ?? NodeStyleStrategy.fallbackStyle();

  final textStyle = TextStyle(
    fontFamily: resolvedStyle.fontFamily,
    fontSize: resolvedStyle.fontSize,
  );

  // 1. Determine dynamic or manual width target
  // If the node has custom style set, it has been manually resized
  final bool isManual = node.style != null && node.style!.width > 0;
  double targetWidth;

  if (isManual) {
    targetWidth = node.style!.width.toDouble();
  } else {
    // Dynamic Sizing Mode: Measure the text on a single line to see how wide it naturally wants to be
    final tempPainter = TextPainter(
      text: TextSpan(text: content.text, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout(); // infinite maxWidth default
    
    // In edit mode, add a horizontal breathing room/buffer space
    // to prevent late wrapping visual glitches in the inline text field.
    final neededWidth = tempPainter.width +
        16.0 +
        (isEditing ? AppConfig.node.editingBufferWidth : 0.0);
    // Auto-grow between defaultWidth and autoWrapThreshold
    targetWidth = neededWidth.clamp(
      AppConfig.node.defaultWidth,
      AppConfig.node.autoWrapThreshold,
    );
  }

  // Double-safe clamp to absolute physical node limits
  targetWidth = targetWidth.clamp(
    AppConfig.node.minWidth,
    AppConfig.node.maxWidth,
  );

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
  node.lineCount = lineCount; // Write the actual computed line count back to the node dynamically
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
