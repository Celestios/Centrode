import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:mycelium/src/rust/domain/contents.dart';

class NodeTextSpanBuilder {
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
