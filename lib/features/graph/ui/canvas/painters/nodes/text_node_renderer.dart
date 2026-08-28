import 'package:centrode/shared/theme/design_tokens.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../engine/config.dart';
import '../../../../models/models.dart';
import '../../../../presentation/strategies/node_style_strategy.dart'
    show expandToggleSpace, taskBadgeHeight;
import '../../../../presentation/strategies/node_text_span_builder.dart';
import '../../widgets/node_visual_constants.dart';
import '../node_render_entry.dart';

class TextNodeRenderer {
  const TextNodeRenderer();

  static void paintText(
    Canvas canvas,
    NodeRenderEntry entry,
    Rect rect,
    NodeStyle style,
  ) {
    final content = entry.node.content;
    if (content.text.isEmpty) return;

    final baseStyle = TextStyle(
      fontSize: style.fontSize,
      fontFamily: style.fontFamily.isEmpty || style.fontFamily == 'System'
          ? null
          : style.fontFamily,
      color: Color(style.textColor),
    );

    final maxWidth = rect.width - style.padding * 2;
    final isExpanded = entry.viewState.isExpandedNotifier.value;
    final maxLines = isExpanded ? null : AppConfig.node.collapsedLineLimit;

    final blockSpans = NodeTextSpanBuilder.buildPerBlockTextSpans(
      content,
      baseStyle,
    );

    int totalLinesPainted = 0;
    final List<TextPainter> painters = [];
    double totalTextHeight = 0.0;

    for (final (span, textAlign) in blockSpans) {
      if (maxLines != null && totalLinesPainted >= maxLines) break;

      final tp = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
        textAlign: textAlign,
        maxLines: maxLines != null ? maxLines - totalLinesPainted : null,
        ellipsis: maxLines != null ? '...' : null,
      )..layout(minWidth: maxWidth, maxWidth: maxWidth);

      final lineCount = tp.computeLineMetrics().length;
      final effectiveLines = lineCount > 0 ? lineCount : 1;

      if (maxLines != null && totalLinesPainted + effectiveLines > maxLines) {
        break;
      }

      painters.add(tp);
      totalTextHeight += tp.height;
      totalLinesPainted += effectiveLines;
    }

    final fontScale = style.fontSize / 14.0;
    double extraHeight = 0.0;
    if (entry.node is TaskUiNode) {
      extraHeight += taskBadgeHeight(fontScale);
    }
    if (entry.viewState.lineCount > AppConfig.node.collapsedLineLimit) {
      extraHeight += expandToggleSpace(
        entry.viewState.isExpandedNotifier.value,
        fontScale,
      );
    }

    final yCenter =
        rect.top +
        style.padding +
        (rect.height - style.padding * 2 - extraHeight) / 2;
    double y = yCenter - totalTextHeight / 2;

    for (final tp in painters) {
      tp.paint(canvas, Offset(rect.left + style.padding, y));
      y += tp.height;
      tp.dispose();
    }
  }

  static void paintPreviewText(
    Canvas canvas,
    Content content,
    Rect rect,
    NodeStyle style,
  ) {
    final baseStyle = TextStyle(
      fontSize: style.fontSize,
      fontFamily: style.fontFamily.isEmpty || style.fontFamily == 'System'
          ? null
          : style.fontFamily,
      color: Color(style.textColor),
    );

    final maxWidth = math.max(10.0, rect.width - style.padding * 2);
    final blockSpans = NodeTextSpanBuilder.buildPerBlockTextSpans(
      content,
      baseStyle,
    );

    final List<TextPainter> painters = [];
    double totalTextHeight = 0.0;

    for (final (span, textAlign) in blockSpans) {
      final tp = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
        textAlign: textAlign,
        maxLines: AppConfig.node.collapsedLineLimit,
        ellipsis: '...',
      )..layout(minWidth: maxWidth, maxWidth: maxWidth);

      painters.add(tp);
      totalTextHeight += tp.height;
    }

    final yCenter =
        rect.top + style.padding + (rect.height - style.padding * 2) / 2;
    double y = yCenter - totalTextHeight / 2;

    for (final tp in painters) {
      tp.paint(canvas, Offset(rect.left + style.padding, y));
      y += tp.height;
      tp.dispose();
    }
  }

  static void paintMetadataSphere(
    Canvas canvas,
    UiNode node,
    Rect rect,
    double scale,
  ) {
    if (node is! InfoUiNode) return;
    if (node.tags.isEmpty && node.comments.isEmpty) return;

    final center = Offset(
      rect.right - AppConfig.node.metadataSphereOffsetFromRight * scale,
      rect.top + AppConfig.node.metadataSphereOffsetFromTop * scale,
    );
    final r = AppConfig.node.metadataSphereRadius * scale;

    final color = NodeVisualConstants.metadataSphereColor(
      hasTags: node.tags.isNotEmpty,
      hasComments: node.comments.isNotEmpty,
    );

    final shadowPaint = Paint()
      ..color = Colors.black26
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 * scale);
    canvas.drawCircle(center + Offset(0, 1 * scale), r, shadowPaint);

    final fillPaint = Paint()..color = Color(color);
    canvas.drawCircle(center, r, fillPaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * scale;
    canvas.drawCircle(center, r, borderPaint);
  }

  static void paintExpandToggle(
    Canvas canvas,
    NodeRenderEntry entry,
    Rect rect,
    NodeStyle style,
    double scale,
  ) {
    if (entry.viewState.lineCount <= 3) return;

    final toggleSpace = expandToggleSpace(
      entry.viewState.isExpandedNotifier.value,
      scale,
    );
    final badgeHeight = entry.node is TaskUiNode
        ? taskBadgeHeight(scale)
        : 0.0;

    final yCenter =
        rect.bottom - style.padding - badgeHeight - toggleSpace / 2;

    final double buttonHeight = 16.0 * scale;
    final double buttonWidth = rect.width - 2 * style.padding;
    final double buttonLeft = rect.left + style.padding;
    final double buttonTop = yCenter - buttonHeight / 2;
    final buttonRect = Rect.fromLTWH(
      buttonLeft,
      buttonTop,
      buttonWidth,
      buttonHeight,
    );
    final buttonRRect = RRect.fromRectAndRadius(
      buttonRect,
      Radius.circular(4.0 * scale),
    );

    final bgPaint = Paint()
      ..color = Color(style.textColor).withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(buttonRRect, bgPaint);

    final iconData = entry.viewState.isExpandedNotifier.value
        ? Icons.keyboard_double_arrow_up
        : Icons.keyboard_double_arrow_down;

    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: UiFont.standard * scale,
          fontFamily: 'MaterialIcons',
          color: Color(style.textColor).withValues(alpha: 0.7),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(
      canvas,
      Offset(rect.center.dx - tp.width / 2, yCenter - tp.height / 2),
    );
    tp.dispose();
  }
}
