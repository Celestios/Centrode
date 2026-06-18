import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:mycelium/features/graph/engine/config.dart';
import 'package:mycelium/features/graph/models/graph_node.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import 'package:mycelium/src/rust/domain/contents.dart';
import 'node_style_strategy.dart';
import 'node_text_span_builder.dart';

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

  /// Calculates the size and line count of the node.
  /// Snaps the result to the grid defined in [AppConfig].
  ({Size size, int lineCount}) calculate(UiNode node, NodeStyle? style, {bool isEditing = false});

  /// Centralized helper to compute a node's physical size based on its runtime type.
  static ({Size size, int lineCount}) calculateSize(UiNode node, {bool isEditing = false}) {
    final strategyType =
        node.resolvedLayout?.strategyType ?? node.layout?.strategyType;
    final strategy = fromType(strategyType, fallbackNode: node);
    return strategy.calculate(node, node.resolvedStyle, isEditing: isEditing);
  }

  static TextSpan buildRichTextSpan(
    Content content,
    TextStyle baseStyle, {
    void Function(String url)? onLinkTap,
    void Function(TapGestureRecognizer recognizer)? registerRecognizer,
  }) {
    return NodeTextSpanBuilder.buildRichTextSpan(
      content,
      baseStyle,
      onLinkTap: onLinkTap,
      registerRecognizer: registerRecognizer,
    );
  }

  static List<(TextSpan, TextAlign)> buildPerBlockTextSpans(
    Content content,
    TextStyle baseStyle, {
    void Function(String url)? onLinkTap,
    void Function(TapGestureRecognizer recognizer)? registerRecognizer,
  }) {
    return NodeTextSpanBuilder.buildPerBlockTextSpans(
      content,
      baseStyle,
      onLinkTap: onLinkTap,
      registerRecognizer: registerRecognizer,
    );
  }
}

class InfoNodeLayoutStrategy extends NodeLayoutStrategy {
  const InfoNodeLayoutStrategy();

  @override
  ({Size size, int lineCount}) calculate(UiNode node, NodeStyle? style, {bool isEditing = false}) {
    return _calculateDefaultLayout(node, style, isEditing: isEditing);
  }
}

class TaskNodeLayoutStrategy extends NodeLayoutStrategy {
  const TaskNodeLayoutStrategy();

  @override
  ({Size size, int lineCount}) calculate(UiNode node, NodeStyle? style, {bool isEditing = false}) {
    return _calculateDefaultLayout(node, style, isEditing: isEditing);
  }
}

({Size size, int lineCount}) _calculateDefaultLayout(
  UiNode node,
  NodeStyle? style, {
  bool isEditing = false,
}) {
  final content = node.content;
  // Fallback if text is empty — preserve the node's current size
  if (content.text.isEmpty) {
    return (size: node.size, lineCount: node.lineCount);
  }

  final resolvedStyle = style ?? NodeStyleStrategy.fallbackStyle();
  final fontSize = resolvedStyle.fontSize;

  final fontFamily = resolvedStyle.fontFamily.isEmpty || resolvedStyle.fontFamily == 'System'
      ? null
      : resolvedStyle.fontFamily;

  final textStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: resolvedStyle.fontSize,
  );

  final richSpan = NodeLayoutStrategy.buildRichTextSpan(content, textStyle);

  // 1. Determine dynamic or manual width target
  // If the node has custom style set, it has been manually resized
  final bool isManual = node.style != null && node.style!.width > 0;
  double targetWidth;

  if (isManual) {
    targetWidth = node.style!.width.toDouble();
  } else {
    // Dynamic Sizing Mode: Measure the text on a single line to see how wide it naturally wants to be
    final tempPainter = TextPainter(
      text: richSpan,
      textDirection: TextDirection.ltr,
    )..layout(); // infinite maxWidth default

    // In edit mode, add a horizontal breathing room/buffer space
    // to prevent late wrapping visual glitches in the inline text field.
    final neededWidth =
        tempPainter.width +
        16.0 +
        (isEditing ? AppConfig.node.scaledEditingBufferWidth(fontSize) : 0.0);
    // Auto-grow between defaultWidth and autoWrapThreshold
    targetWidth = neededWidth.clamp(
      AppConfig.node.scaledDefaultWidth(fontSize),
      AppConfig.node.scaledAutoWrapThreshold(fontSize),
    );
  }

  // Double-safe clamp to absolute physical node limits
  targetWidth = targetWidth.clamp(
    AppConfig.node.scaledMinWidth(fontSize),
    AppConfig.node.scaledMaxWidth(fontSize),
  );

  final double contentWidth = (targetWidth - 2 * resolvedStyle.padding).clamp(
    1,
    double.infinity,
  );

  final tp = TextPainter(
    text: richSpan,
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
  } else if (node.isExpanded) {
    // Measure using per-block TextSpans (same method as rendering) to avoid
    // measurement/rendering mismatch that causes overflow.
    final blockSpans = NodeLayoutStrategy.buildPerBlockTextSpans(content, textStyle);
    textHeight = 0.0;
    for (final (span, _) in blockSpans) {
      final blockPainter = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: contentWidth);
      textHeight += blockPainter.height;
      blockPainter.dispose();
    }
    textHeight += blockSpans.length * 2.0;
    textHeight *= 1.08;
  } else {
    textHeight = tp.height;
  }

  double extraHeight = 0.0;
  final fontScale = fontSize / 14.0;
  if (node is TaskUiNode) {
    extraHeight += 22.0 * fontScale;
  }
  if (lineCount > AppConfig.node.collapsedLineLimit) {
    extraHeight += node.isExpanded ? 30.0 * fontScale : 24.0 * fontScale;
  }

  final totalHeight = textHeight + 2 * resolvedStyle.padding + extraHeight;

  // Quantization: Snap to grid
  final gridSize = AppConfig.grid.baseSize;

  // We ceil to the next grid step to ensure content fits and avoid loops
  final snappedWidth = (targetWidth / gridSize).ceil() * gridSize;
  final snappedHeight = (totalHeight / gridSize).ceil() * gridSize;

  return (size: Size(snappedWidth, snappedHeight), lineCount: lineCount);
}
