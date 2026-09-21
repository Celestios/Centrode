import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:centrode/shared/theme/theme_derived_palette.dart';
import 'package:flutter/material.dart';
import 'package:centrode/features/graph/models/models.dart';
import '../components/node_shape_definitions.dart';
import 'inspector_showcase_card_shell.dart';
import 'showcase_painters.dart';

class NodeShowcaseData {
  final String shape;
  final String fillStyle;
  final double opacity;
  final double cornerRadius;
  final String borderStyle;
  final double borderWidth;
  final double borderOpacity;
  final Color? customBorderColor;
  final String fontFamily;
  final double fontSize;
  final String textAlign;
  final String highlightColor;
  final Color textColor;
  final String underlineStyle;
  final Color? underlineColor;
  final TextDirection textDirection;
  final String topicText;
  final bool isBold;
  final bool isItalic;
  final bool isStrikethrough;
  final String letterCase;
  final double letterSpacing;
  final double lineHeight;
  final Color? customBgColor;
  final String shadowMode;
  final double shadowBlur;
  final double shadowDistance;
  final Color? customShadowColor;

  const NodeShowcaseData({
    required this.shape,
    required this.fillStyle,
    required this.opacity,
    required this.cornerRadius,
    required this.borderStyle,
    required this.borderWidth,
    required this.borderOpacity,
    this.customBorderColor,
    required this.fontFamily,
    required this.fontSize,
    required this.textAlign,
    required this.highlightColor,
    this.textColor = Colors.white,
    this.underlineStyle = 'none',
    this.underlineColor,
    this.textDirection = TextDirection.ltr,
    this.topicText = 'Topic',
    this.isBold = false,
    this.isItalic = false,
    this.isStrikethrough = false,
    this.letterCase = 'normal',
    this.letterSpacing = 0.0,
    this.lineHeight = 1.2,
    this.customBgColor,
    this.shadowMode = 'none',
    this.shadowBlur = 14.0,
    this.shadowDistance = 4.0,
    this.customShadowColor,
  });
}

/// Live Node Showcase Object rendering in real-time with subtle blueprint background.
class NodeShowcaseCard extends StatelessWidget {
  final NodeShowcaseData data;
  final Color accentColor;

  const NodeShowcaseCard({
    super.key,
    required this.data,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = CentrodeDerivedPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color nodeBgColor;
    final effectiveBaseColor = data.customBgColor ?? accentColor;
    if (data.fillStyle == 'solid') {
      nodeBgColor = effectiveBaseColor.withValues(alpha: (data.opacity / 100).clamp(0.05, 1.0));
    } else if (data.fillStyle == 'glass') {
      if (data.customBgColor != null) {
        nodeBgColor = data.customBgColor!.withValues(alpha: (0.5 * (data.opacity / 100)).clamp(0.05, 0.95));
      } else {
        nodeBgColor = palette.surface.cardBackground.withValues(
          alpha: ((isDark ? 0.65 : 0.85) * (data.opacity / 100)).clamp(0.05, 0.95),
        );
      }
    } else {
      nodeBgColor = Colors.transparent;
    }

    final effectiveBorderBase = data.customBorderColor ?? accentColor;
    final borderColor = effectiveBorderBase.withValues(alpha: (data.borderOpacity / 100).clamp(0.0, 1.0));

    double targetWidth = 140;
    double targetHeight = 46;
    if (data.shape == 'circle') {
      targetWidth = 60;
      targetHeight = 60;
    } else if (data.shape == 'capsule' || data.shape == 'pill') {
      targetWidth = 140;
      targetHeight = 38;
    } else if (data.shape == 'diamond' || data.shape == 'hexagon') {
      targetWidth = 120;
      targetHeight = 52;
    }

    String? effectiveFontFamily;
    final lowerFont = data.fontFamily.toLowerCase();
    if (lowerFont == 'mono' || lowerFont == 'jetbrains mono') {
      effectiveFontFamily = 'monospace';
    } else if (lowerFont == 'outfit') {
      effectiveFontFamily = 'Outfit';
    } else if (lowerFont == 'fira code') {
      effectiveFontFamily = 'Fira Code';
    } else if (lowerFont == 'roboto') {
      effectiveFontFamily = 'Roboto';
    } else if (lowerFont == 'cinzel') {
      effectiveFontFamily = 'Cinzel';
    } else if (lowerFont == 'caveat') {
      effectiveFontFamily = 'Caveat';
    }

    Color? highlightBgColor;
    if (data.highlightColor == 'yellow') {
      highlightBgColor = const Color(0x77FFE600);
    } else if (data.highlightColor == 'cyan') {
      highlightBgColor = const Color(0x7700E5FF);
    } else if (data.highlightColor == 'green') {
      highlightBgColor = const Color(0x7700FF66);
    } else if (data.highlightColor == 'pink') {
      highlightBgColor = const Color(0x77FF007A);
    } else if (data.highlightColor == 'orange') {
      highlightBgColor = const Color(0x77FF8800);
    }

    final List<TextDecoration> decorations = [];
    TextDecorationStyle decorationStyle = TextDecorationStyle.solid;
    if (data.underlineStyle == 'solid') {
      decorations.add(TextDecoration.underline);
      decorationStyle = TextDecorationStyle.solid;
    } else if (data.underlineStyle == 'dashed') {
      decorations.add(TextDecoration.underline);
      decorationStyle = TextDecorationStyle.dashed;
    } else if (data.underlineStyle == 'wavy') {
      decorations.add(TextDecoration.underline);
      decorationStyle = TextDecorationStyle.wavy;
    }

    if (data.isStrikethrough) {
      decorations.add(TextDecoration.lineThrough);
    }

    final TextDecoration effectiveDecoration = decorations.isEmpty
        ? TextDecoration.none
        : TextDecoration.combine(decorations);

    TextAlign align = TextAlign.center;
    if (data.textAlign == 'left') {
      align = TextAlign.left;
    } else if (data.textAlign == 'right') {
      align = TextAlign.right;
    } else if (data.textAlign == 'justify') {
      align = TextAlign.justify;
    }

    final displayedTopic = ContentBuilder.applyLetterCase(data.topicText, data.letterCase);

    final effectiveTextColor = (data.textColor == Colors.white && !isDark)
        ? palette.textOn(nodeBgColor.a > 0.1 ? nodeBgColor : palette.surface.controlBackground)
        : data.textColor;

    final previewTextStyle = TextStyle(
      fontFamily: effectiveFontFamily,
      fontSize: (data.fontSize * 0.85).clamp(8.0, 15.0),
      fontWeight: data.isBold ? FontWeight.w800 : FontWeight.w500,
      fontStyle: data.isItalic ? FontStyle.italic : FontStyle.normal,
      color: effectiveTextColor,
      backgroundColor: highlightBgColor,
      decoration: effectiveDecoration,
      decorationStyle: decorationStyle,
      decorationColor: data.underlineColor ?? effectiveTextColor,
      letterSpacing: data.letterSpacing,
      height: data.lineHeight,
    );

    return InspectorShowcaseCardShell(
      accentColor: accentColor,
      child: AnimatedContainer(
        duration: UiMotion.fast,
        width: targetWidth,
        height: targetHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: ShapeNodePainter(
                  shape: data.shape,
                  fillColor: nodeBgColor,
                  borderStyle: data.borderStyle,
                  borderWidth: data.borderWidth,
                  borderColor: borderColor,
                  cornerRadius: data.cornerRadius,
                  shadowMode: data.shadowMode,
                  shadowBlur: data.shadowBlur,
                  shadowDistance: data.shadowDistance,
                  shadowColor: data.customShadowColor ?? accentColor,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
              child: Directionality(
                textDirection: data.textDirection,
                child: Text(
                  displayedTopic,
                  textAlign: align,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: previewTextStyle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShapeNodePainter extends CustomPainter {
  final String shape;
  final Color fillColor;
  final String borderStyle;
  final double borderWidth;
  final Color borderColor;
  final double cornerRadius;
  final String shadowMode;
  final double shadowBlur;
  final double shadowDistance;
  final Color shadowColor;

  ShapeNodePainter({
    required this.shape,
    required this.fillColor,
    required this.borderStyle,
    required this.borderWidth,
    required this.borderColor,
    required this.cornerRadius,
    this.shadowMode = 'none',
    this.shadowBlur = 14.0,
    this.shadowDistance = 4.0,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final path = buildShapePath(shape, rect, cornerRadius: cornerRadius.clamp(0, 24));

    // Shadow / Glow Rendering
    if (shadowMode == 'glow') {
      final glowPaint = Paint()
        ..color = shadowColor.withValues(alpha: 0.45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur.clamp(2.0, 32.0));
      canvas.drawPath(path, glowPaint);
    } else if (shadowMode == 'soft') {
      final shadowPath = path.shift(Offset(0, shadowDistance));
      final softShadowPaint = Paint()
        ..color = shadowColor.withValues(alpha: 0.35)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur.clamp(2.0, 32.0));
      canvas.drawPath(shadowPath, softShadowPaint);
    } else if (shadowMode == 'crisp') {
      final crispShadowPath = path.shift(Offset(0, shadowDistance));
      final crispPaint = Paint()
        ..color = shadowColor.withValues(alpha: 0.55)
        ..style = PaintingStyle.fill;
      canvas.drawPath(crispShadowPath, crispPaint);
    }

    // Body Fill
    if (fillColor.a > 0) {
      final fillPaint = Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);
    }

    // Border Stroke
    if (borderWidth > 0 && borderColor.a > 0) {
      final strokePaint = Paint()
        ..color = borderColor
        ..strokeWidth = borderWidth
        ..style = PaintingStyle.stroke;

      if (borderStyle == 'solid') {
        canvas.drawPath(path, strokePaint);
      } else {
        drawDashedPath(canvas, path, strokePaint, borderStyle: borderStyle);
      }
    }
  }

  @override
  bool shouldRepaint(covariant ShapeNodePainter oldDelegate) {
    return oldDelegate.shape != shape ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.borderStyle != borderStyle ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.cornerRadius != cornerRadius ||
        oldDelegate.shadowMode != shadowMode ||
        oldDelegate.shadowBlur != shadowBlur ||
        oldDelegate.shadowDistance != shadowDistance ||
        oldDelegate.shadowColor != shadowColor;
  }
}
