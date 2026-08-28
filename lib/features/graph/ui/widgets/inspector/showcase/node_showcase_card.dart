import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'package:centrode/features/graph/models/models.dart';
import '../components/node_shape_definitions.dart';
import 'showcase_painters.dart';

/// Live Node Showcase Object rendering in real-time with subtle blueprint background.
class NodeShowcaseCard extends StatelessWidget {
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
  final Color accentColor;
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

  const NodeShowcaseCard({
    super.key,
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
    this.isBold = false,
    this.isItalic = false,
    this.isStrikethrough = false,
    this.letterCase = 'normal',
    this.letterSpacing = 0.0,
    this.lineHeight = 1.2,
    this.customBgColor,
    this.topicText = 'Topic',
    this.shadowMode = 'none',
    this.shadowBlur = 14.0,
    this.shadowDistance = 4.0,
    this.customShadowColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    Color nodeBgColor;
    final effectiveBaseColor = customBgColor ?? accentColor;
    if (fillStyle == 'solid') {
      nodeBgColor = effectiveBaseColor.withValues(alpha: (opacity / 100).clamp(0.05, 1.0));
    } else if (fillStyle == 'glass') {
      if (customBgColor != null) {
        nodeBgColor = customBgColor!.withValues(alpha: (0.5 * (opacity / 100)).clamp(0.05, 0.95));
      } else {
        nodeBgColor = Colors.black.withValues(alpha: (0.45 * (opacity / 100)).clamp(0.05, 0.95));
      }
    } else {
      nodeBgColor = Colors.transparent;
    }

    final effectiveBorderBase = customBorderColor ?? accentColor;
    final borderColor = effectiveBorderBase.withValues(alpha: (borderOpacity / 100).clamp(0.0, 1.0));

    double targetWidth = 140;
    double targetHeight = 46;
    if (shape == 'circle') {
      targetWidth = 60;
      targetHeight = 60;
    } else if (shape == 'capsule' || shape == 'pill') {
      targetWidth = 140;
      targetHeight = 38;
    } else if (shape == 'diamond' || shape == 'hexagon') {
      targetWidth = 120;
      targetHeight = 52;
    }

    String? effectiveFontFamily;
    final lowerFont = fontFamily.toLowerCase();
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
    if (highlightColor == 'yellow') {
      highlightBgColor = const Color(0x77FFE600);
    } else if (highlightColor == 'cyan') {
      highlightBgColor = const Color(0x7700E5FF);
    } else if (highlightColor == 'green') {
      highlightBgColor = const Color(0x7700FF66);
    } else if (highlightColor == 'pink') {
      highlightBgColor = const Color(0x77FF007A);
    } else if (highlightColor == 'orange') {
      highlightBgColor = const Color(0x77FF8800);
    }

    final List<TextDecoration> decorations = [];
    TextDecorationStyle decorationStyle = TextDecorationStyle.solid;
    if (underlineStyle == 'solid') {
      decorations.add(TextDecoration.underline);
      decorationStyle = TextDecorationStyle.solid;
    } else if (underlineStyle == 'dashed') {
      decorations.add(TextDecoration.underline);
      decorationStyle = TextDecorationStyle.dashed;
    } else if (underlineStyle == 'wavy') {
      decorations.add(TextDecoration.underline);
      decorationStyle = TextDecorationStyle.wavy;
    }

    if (isStrikethrough) {
      decorations.add(TextDecoration.lineThrough);
    }

    final TextDecoration effectiveDecoration = decorations.isEmpty
        ? TextDecoration.none
        : TextDecoration.combine(decorations);

    TextAlign align = TextAlign.center;
    if (textAlign == 'left') {
      align = TextAlign.left;
    } else if (textAlign == 'right') {
      align = TextAlign.right;
    } else if (textAlign == 'justify') {
      align = TextAlign.justify;
    }

    final displayedTopic = ContentBuilder.applyLetterCase(topicText, letterCase);

    final previewTextStyle = TextStyle(
      fontFamily: effectiveFontFamily,
      fontSize: (fontSize * 0.85).clamp(8.0, 15.0),
      fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      color: textColor,
      backgroundColor: highlightBgColor,
      decoration: effectiveDecoration,
      decorationStyle: decorationStyle,
      decorationColor: underlineColor ?? textColor,
      letterSpacing: letterSpacing,
      height: lineHeight,
    );

    return Container(
      height: 85,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(UiRadius.card),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: UiStrokeWidth.subtle,
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: ShowcaseGridPainter(accentColor.withValues(alpha: 0.12)),
          ),
          AnimatedContainer(
            duration: UiMotion.fast,
            width: targetWidth,
            height: targetHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: ShapeNodePainter(
                      shape: shape,
                      fillColor: nodeBgColor,
                      borderStyle: borderStyle,
                      borderWidth: borderWidth,
                      borderColor: borderColor,
                      cornerRadius: cornerRadius,
                      accentColor: accentColor,
                      shadowMode: shadowMode,
                      shadowBlur: shadowBlur,
                      shadowDistance: shadowDistance,
                      shadowColor: customShadowColor ?? accentColor,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                  child: Directionality(
                    textDirection: textDirection,
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
        ],
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
  final Color accentColor;
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
    required this.accentColor,
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
        ..color = Colors.black.withValues(alpha: 0.45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur.clamp(2.0, 32.0));
      canvas.drawPath(shadowPath, softShadowPaint);
    } else if (shadowMode == 'crisp') {
      final crispShadowPath = path.shift(Offset(0, shadowDistance));
      final crispPaint = Paint()
        ..color = Colors.black.withValues(alpha: 0.75)
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
        oldDelegate.accentColor != accentColor ||
        oldDelegate.shadowMode != shadowMode ||
        oldDelegate.shadowBlur != shadowBlur ||
        oldDelegate.shadowDistance != shadowDistance ||
        oldDelegate.shadowColor != shadowColor;
  }
}
