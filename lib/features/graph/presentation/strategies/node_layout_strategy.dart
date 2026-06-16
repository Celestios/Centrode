import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:mycelium/features/graph/engine/config.dart';
import 'package:mycelium/features/graph/models/graph_node.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import 'package:mycelium/src/rust/domain/contents.dart';
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
    final strategyType =
        node.resolvedLayout?.strategyType ?? node.layout?.strategyType;
    final strategy = fromType(strategyType, fallbackNode: node);
    return strategy.calculate(node, node.resolvedStyle, isEditing: isEditing);
  }

  /// Helper to build a styled TextSpan hierarchy representing the rich content.
  static TextSpan buildRichTextSpan(
    Content content,
    TextStyle baseStyle, {
    void Function(String url)? onLinkTap,
    void Function(TapGestureRecognizer recognizer)? registerRecognizer,
  }) {
    if (content.blocks.isEmpty) {
      return TextSpan(text: '', style: baseStyle);
    }

    final List<TextSpan> blockSpans = [];

    for (int i = 0; i < content.blocks.length; i++) {
      final block = content.blocks[i];
      final inlineSpans = _buildInlineSpansForBlock(
        block, i, baseStyle, onLinkTap: onLinkTap, registerRecognizer: registerRecognizer,
      );

      if (i < content.blocks.length - 1) {
        inlineSpans.add(const TextSpan(text: '\n'));
      }

      blockSpans.add(TextSpan(children: inlineSpans));
    }

    return TextSpan(children: blockSpans);
  }

  /// Builds per-block text spans with their alignment for per-paragraph rendering.
  static List<(TextSpan, TextAlign)> buildPerBlockTextSpans(
    Content content,
    TextStyle baseStyle, {
    void Function(String url)? onLinkTap,
    void Function(TapGestureRecognizer recognizer)? registerRecognizer,
  }) {
    if (content.blocks.isEmpty) {
      return [(TextSpan(text: '', style: baseStyle), TextAlign.center)];
    }

    final result = <(TextSpan, TextAlign)>[];

    for (int i = 0; i < content.blocks.length; i++) {
      final block = content.blocks[i];
      final inlineSpans = _buildInlineSpansForBlock(
        block, i, baseStyle, onLinkTap: onLinkTap, registerRecognizer: registerRecognizer,
      );

      TextAlign textAlign = TextAlign.center;
      if (block.attrs?.textAlign != null) {
        switch (block.attrs!.textAlign) {
          case 'left':
            textAlign = TextAlign.left;
            break;
          case 'center':
            textAlign = TextAlign.center;
            break;
          case 'right':
            textAlign = TextAlign.right;
            break;
        }
      }

      result.add((TextSpan(children: inlineSpans), textAlign));
    }

    return result;
  }

  static TextStyle _resolveBlockStyle(ContentBlock block, TextStyle baseStyle) {
    if (block.blockType == BlockType.heading) {
      final level = block.attrs?.level ?? 1;
      final double sizeFactor = level == 1 ? 1.4 : (level == 2 ? 1.25 : 1.15);
      return baseStyle.copyWith(
        fontSize: (baseStyle.fontSize ?? 12.0) * sizeFactor,
        fontWeight: FontWeight.bold,
      );
    } else if (block.blockType == BlockType.blockquote) {
      return baseStyle.copyWith(
        fontStyle: FontStyle.italic,
        color: baseStyle.color?.withValues(alpha: 0.85),
      );
    } else if (block.blockType == BlockType.codeBlock) {
      return baseStyle.copyWith(
        fontFamily: 'Consolas',
        fontSize: (baseStyle.fontSize ?? 12.0) * 0.9,
        color: baseStyle.color?.withValues(alpha: 0.9),
      );
    }
    return baseStyle;
  }

  static List<TextSpan> _buildInlineSpansForBlock(
    ContentBlock block,
    int blockIndex,
    TextStyle baseStyle, {
    void Function(String url)? onLinkTap,
    void Function(TapGestureRecognizer recognizer)? registerRecognizer,
  }) {
    final inlineSpans = <TextSpan>[];
    final blockStyle = _resolveBlockStyle(block, baseStyle);

    if (block.blockType == BlockType.bulletList) {
      inlineSpans.add(TextSpan(text: '• ', style: blockStyle));
    } else if (block.blockType == BlockType.orderedList) {
      inlineSpans.add(TextSpan(text: '${blockIndex + 1}. ', style: blockStyle));
    }

    for (final inline in block.content) {
      if (inline.inlineType == InlineType.hardBreak) {
        inlineSpans.add(const TextSpan(text: '\n'));
        continue;
      }

      TextStyle inlineStyle = blockStyle;
      TapGestureRecognizer? linkRecognizer;

      if (inline.marks != null && block.blockType != BlockType.codeBlock) {
        for (final mark in inline.marks!) {
          if (mark.markType == MarkType.bold) {
            inlineStyle = inlineStyle.copyWith(fontWeight: FontWeight.bold);
          } else if (mark.markType == MarkType.italic) {
            inlineStyle = inlineStyle.copyWith(fontStyle: FontStyle.italic);
          } else if (mark.markType == MarkType.underline) {
            inlineStyle = inlineStyle.copyWith(decoration: TextDecoration.underline);
          } else if (mark.markType == MarkType.strikethrough) {
            inlineStyle = inlineStyle.copyWith(decoration: TextDecoration.lineThrough);
          } else if (mark.markType == MarkType.code) {
            inlineStyle = inlineStyle.copyWith(
              fontFamily: 'Consolas',
              backgroundColor: baseStyle.color?.withValues(alpha: 0.1),
            );
          } else if (mark.markType == MarkType.link) {
            final String? url = mark.attrs?.href;
            inlineStyle = inlineStyle.copyWith(
              color: Colors.blueAccent,
              decoration: TextDecoration.underline,
            );
            if (url != null && onLinkTap != null) {
              final rec = TapGestureRecognizer()..onTap = () => onLinkTap(url);
              registerRecognizer?.call(rec);
              linkRecognizer = rec;
            }
          } else if (mark.markType == MarkType.highlight) {
            final colorVal = mark.attrs?.color ?? 0xFFFFF200;
            inlineStyle = inlineStyle.copyWith(
              backgroundColor: Color(colorVal),
            );
          } else if (mark.markType == MarkType.textColor) {
            final colorVal = mark.attrs?.color ?? 0xFF000000;
            inlineStyle = inlineStyle.copyWith(
              color: Color(colorVal),
            );
          } else if (mark.markType == MarkType.fontFamily) {
            final fontFam = mark.attrs?.fontFamily;
            if (fontFam != null && fontFam.isNotEmpty) {
              inlineStyle = inlineStyle.copyWith(
                fontFamily: fontFam == 'System' ? null : fontFam,
              );
            }
          }
        }
      }

      inlineSpans.add(TextSpan(
        text: inline.text,
        style: inlineStyle,
        recognizer: linkRecognizer,
      ));
    }

    return inlineSpans;
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

Size _calculateDefaultLayout(
  UiNode node,
  NodeStyle? style, {
  bool isEditing = false,
}) {
  final content = node.content;
  // Fallback if text is empty
  if (content.text.isEmpty) {
    return AppConfig.node.defaultSize;
  }

  final resolvedStyle = style ?? NodeStyleStrategy.fallbackStyle();

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
  node.lineCount =
      lineCount; // Write the actual computed line count back to the node dynamically
  double textHeight;

  // Handle "Show More" logic based on line count
  if (lineCount > AppConfig.node.collapsedLineLimit && !node.isExpanded) {
    textHeight = lineMetrics
        .take(AppConfig.node.collapsedLineLimit)
        .fold(0.0, (sum, m) => sum + m.height);
    textHeight += 2.0; // Buffer
  } else {
    textHeight = tp.height;
  }

  double extraHeight = 0.0;
  if (node is TaskUiNode) {
    extraHeight += 22.0; // Space for the task status badge
  }
  if (lineCount > AppConfig.node.collapsedLineLimit) {
    extraHeight += node.isExpanded ? 30.0 : 24.0; // Space for the "Show More" / "Show Less" button
  }

  final totalHeight = textHeight + 20.0 + extraHeight; // 10px padding top and bottom + extra spacing

  // Quantization: Snap to grid
  final gridSize = AppConfig.grid.baseSize;

  // We ceil to the next grid step to ensure content fits and avoid loops
  final snappedWidth = (targetWidth / gridSize).ceil() * gridSize;
  final snappedHeight = (totalHeight / gridSize).ceil() * gridSize;

  return Size(snappedWidth, snappedHeight);
}
