import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:centrode/features/graph/engine/config.dart';
import 'package:centrode/features/graph/models/graph_node.dart';
import 'package:centrode/src/rust/domain/base_models.dart' hide Size;
import 'package:centrode/src/rust/domain/styles.dart' hide EndpointShape;
import 'package:centrode/src/rust/domain/contents.dart';
import 'node_style_strategy.dart';
import 'node_text_span_builder.dart';

abstract class NodeLayoutStrategy {
  const NodeLayoutStrategy();

  Size calculateIntrinsicSize(
    UiNode node,
    NodeStyle style,
    BoxConstraints constraints,
  );

  ({Size size, int lineCount}) calculateSize(
    UiNode node, {
    bool isEditing = false,
    double? overrideWidth,
  });

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

class DefaultNodeLayoutStrategy implements NodeLayoutStrategy {
  const DefaultNodeLayoutStrategy();

  @override
  Size calculateIntrinsicSize(
    UiNode node,
    NodeStyle style,
    BoxConstraints constraints,
  ) {
    final minW = _computeMinWidth(node);
    final hasFixedAspect = _hasFixedAspectRatio(node);

    final width = node.size.width.clamp(minW, constraints.maxWidth);
    final height = hasFixedAspect
        ? (width / (node.size.width / node.size.height))
        : node.size.height.clamp(0.0, constraints.maxHeight);

    return Size(width, height);
  }

  @override
  ({Size size, int lineCount}) calculateSize(
    UiNode node, {
    bool isEditing = false,
    double? overrideWidth,
  }) {
    if (node is DrawingUiNode || node is FrameUiNode) {
      return (size: node.size, lineCount: 0);
    }
    return _calculateDefaultLayout(
      node,
      node.resolvedStyle,
      isEditing: isEditing,
      overrideWidth: overrideWidth,
    );
  }

  static double _computeMinWidth(UiNode node) => switch (node) {
    CommentUiNode() => 200.0,
    ContainerUiNode() => 300.0,
    DrawingUiNode() => 100.0,
    FrameUiNode() => 400.0,
    InfoUiNode() => 250.0,
    InterUiNode() => 150.0,
    MediaUiNode() => 300.0,
    ShapeUiNode() => 100.0,
    TaskUiNode() => 280.0,
  };

  static bool _hasFixedAspectRatio(UiNode node) => switch (node) {
    DrawingUiNode() || MediaUiNode() => true,
    _ => false,
  };
}

({Size size, int lineCount}) _calculateDefaultLayout(
  UiNode node,
  NodeStyle? style, {
  bool isEditing = false,
  double? overrideWidth,
}) {
  final content = node.content;
  if (content.text.isEmpty) {
    final manualWidth = overrideWidth ??
        (node.style != null && node.style!.width > 0
            ? node.style!.width.toDouble()
            : null);
    final width = manualWidth ?? node.size.width;
    return (size: Size(width, node.size.height), lineCount: node.lineCount);
  }

  final resolvedStyle = style ?? NodeStyleStrategy.fallbackStyle();
  final fontSize = resolvedStyle.fontSize;

  final fontFamily =
      resolvedStyle.fontFamily.isEmpty || resolvedStyle.fontFamily == 'System'
      ? null
      : resolvedStyle.fontFamily;

  final textStyle = TextStyle(
    fontFamily: fontFamily,
    fontSize: resolvedStyle.fontSize,
  );

  final richSpan = NodeLayoutStrategy.buildRichTextSpan(content, textStyle);

  final bool isManual = node.style != null && node.style!.width > 0;
  double targetWidth;

  if (overrideWidth != null) {
    targetWidth = overrideWidth;
  } else if (isManual) {
    targetWidth = node.style!.width.toDouble();
  } else {
    final tempPainter = TextPainter(
      text: richSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final neededWidth =
        tempPainter.width +
        16.0 +
        (isEditing ? AppConfig.node.scaledEditingBufferWidth(fontSize) : 0.0);
    targetWidth = neededWidth.clamp(
      AppConfig.node.scaledDefaultWidth(fontSize),
      AppConfig.node.scaledAutoWrapThreshold(fontSize),
    );
  }

  targetWidth = targetWidth.clamp(
    AppConfig.node.scaledMinWidth(fontSize),
    AppConfig.node.scaledMaxWidth(fontSize),
  );

  final double contentWidth = (targetWidth - 2 * resolvedStyle.padding).clamp(
    1,
    double.infinity,
  );

  final tp = TextPainter(text: richSpan, textDirection: TextDirection.ltr)
    ..layout(maxWidth: contentWidth);

  final lineMetrics = tp.computeLineMetrics();
  final lineCount = lineMetrics.length;
  double textHeight;

  if (lineCount > AppConfig.node.collapsedLineLimit && !node.isExpanded) {
    textHeight = lineMetrics
        .take(AppConfig.node.collapsedLineLimit)
        .fold(0.0, (sum, m) => sum + m.height);
    textHeight += 2.0;
  } else if (node.isExpanded) {
    final blockSpans = NodeLayoutStrategy.buildPerBlockTextSpans(
      content,
      textStyle,
    );
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

  final attachments = node is InfoUiNode
      ? node.attachments
      : (node is TaskUiNode ? node.attachments : const <Attachment>[]);

  double extraHeight = 0.0;
  final fontScale = fontSize / 14.0;
  if (node is TaskUiNode) {
    extraHeight += taskBadgeHeight(fontScale);
  }
  if (lineCount > AppConfig.node.collapsedLineLimit) {
    extraHeight += expandToggleSpace(
      node.isExpanded,
      fontScale,
    );
  }

  final imageAttachment = attachments.where((a) => a.mimeType.startsWith('image/')).firstOrNull;
  final hasOther = attachments.any((a) => !a.mimeType.startsWith('image/'));
  double effectiveTargetWidth = targetWidth;

  if (imageAttachment != null) {
    if (imageAttachment.width != null && imageAttachment.height != null && imageAttachment.width! > 0) {
      final double naturalW = imageAttachment.width!.toDouble();
      final double naturalH = imageAttachment.height!.toDouble();
      effectiveTargetWidth = overrideWidth ?? naturalW.clamp(200.0, 360.0);
      final double aspect = naturalW / naturalH;
      final double imgH = (effectiveTargetWidth / aspect).clamp(100.0 * fontScale, 400.0 * fontScale);
      extraHeight += imgH;
    } else {
      effectiveTargetWidth = overrideWidth ?? targetWidth.clamp(240.0, 360.0);
      extraHeight += 140.0 * fontScale;
    }
  } else if (attachments.isNotEmpty) {
    effectiveTargetWidth = overrideWidth ?? targetWidth.clamp(140.0, AppConfig.node.scaledMaxWidth(fontSize));
  }

  final int otherCount = attachments.where((a) => !a.mimeType.startsWith('image/')).length;
  if (otherCount > 0) {
    extraHeight += (24.0 * fontScale * otherCount);
  }

  final double effectivePadding = imageAttachment != null
      ? (6.0 * fontScale)
      : (hasOther ? (6.0 * fontScale) : (2 * resolvedStyle.padding));
  final double effectiveTextHeight = imageAttachment != null
      ? (content.text.isEmpty ? (22.0 * fontScale) : textHeight.clamp(20.0 * fontScale, 70.0 * fontScale))
      : textHeight;

  final totalHeight = effectiveTextHeight + effectivePadding + extraHeight;

  final gridSize = AppConfig.grid.baseSize;
  final snappedWidth = (effectiveTargetWidth / gridSize).ceil() * gridSize;
  final snappedHeight = (totalHeight / gridSize).ceil() * gridSize;

  return (size: Size(snappedWidth, snappedHeight), lineCount: lineCount);
}
