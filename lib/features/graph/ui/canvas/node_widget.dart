// lib/features/graph/ui/canvas/node_widget.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../presentation/graph_metrics.dart';
import '../../models/models.dart';
import '../../store/graph_data_query.dart';
import '../../presentation/view_state.dart';
import 'canvas_text_editor.dart';

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}

/// A passive node widget that renders exactly what the domain instructs.
///
/// This widget is purely presentational – all interaction handling
/// is delegated to the InteractionController via the Listener in GraphCanvas.
///
/// Style resolution is no longer performed here; instead the widget reads
/// `liveNode.resolvedStyle` which is pre‑computed by the StyleManager.
/// When no resolved style is available (e.g. during a brief transition),
/// a safe default `NodeStyle()` is used.
class NodeWidget extends StatelessWidget {
  final UiNode node;
  final NodeViewState viewState;
  final bool isSelected;
  final bool isEditing;

  const NodeWidget({
    super.key,
    required this.node,
    required this.viewState,
    required this.isSelected,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    // Reactively select the canonical node from the central store.
    // This prevents the widget from rendering stale aesthetics (like old width)
    // when the FSM drops the volatile drag state before the parent layer rebuilds.
    final liveNode = context.select<GraphDataQuery, UiNode>(
      (c) => c.nodeLookup[node.id] ?? node,
    );

    final resolvedStyle = liveNode.resolvedStyle;
    if (resolvedStyle == null) {
      return const SizedBox.shrink();
    }

    // We merge the notifiers so the widget repaints when position, size,
    // or expanded state changes.
    return ListenableBuilder(
      listenable: Listenable.merge([
        viewState.positionNotifier,
        viewState.sizeNotifier,
        viewState.isExpandedNotifier,
        viewState.dragWidthNotifier,
        viewState.lineCountNotifier,
      ]),
      builder: (context, _) {
        final pos = viewState.positionNotifier.value;
        final rawSize = viewState.sizeNotifier.value;
        final size = Size(
          viewState.dragWidthNotifier.value ?? rawSize.width,
          rawSize.height,
        );

        return Transform.translate(
          offset: pos,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Main Visual Body ──────────────────────────
              Container(
                width: size.width,
                height: size.height,
                decoration: BoxDecoration(
                  color: Color(resolvedStyle.bgColor),
                  borderRadius: resolvedStyle.shape == 'circle'
                      ? BorderRadius.circular(size.width / 2)
                      : BorderRadius.circular(resolvedStyle.borderRadius),
                  border: Border.all(
                    color: isSelected
                        ? AppConfig.visuals.selectionAccent
                        : Color(resolvedStyle.strokeColor),
                    width: isSelected
                        ? 2.5
                        : resolvedStyle.strokeWidth.toDouble(),
                  ),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Color(0x4442A5F5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Color(resolvedStyle.shadowColor),
                            blurRadius: resolvedStyle.shadowBlur,
                            spreadRadius: resolvedStyle.shadowSpread,
                            offset: Offset(
                              resolvedStyle.shadowOffsetX,
                              resolvedStyle.shadowOffsetY,
                            ),
                          ),
                        ],
                ),
                padding: EdgeInsets.all(resolvedStyle.padding),
                child: isEditing
                    ? CanvasTextEditor(
                        entityId: liveNode.id,
                        content: liveNode.content,
                        maxLines: null,
                        textStyle: TextStyle(
                          fontSize: resolvedStyle.fontSize,
                          fontFamily: resolvedStyle.fontFamily.isEmpty || resolvedStyle.fontFamily == 'System' ? null : resolvedStyle.fontFamily,
                          color: Color(resolvedStyle.textColor),
                        ),
                      )
                    : _buildNodeContent(context, liveNode, resolvedStyle),
              ),

              // ── Resize Handle Visual (Right Edge) ─────────
              Positioned(
                right: 0,
                top: 24.0, // Shifted down to clear the metadata sphere area
                bottom: 0,
                child: Container(
                  width: AppConfig.node.resizeHandleVisualWidth,
                  decoration: BoxDecoration(
                    // A nearly‑invisible colour that the hit‑tester sees.
                    color: Colors.black.withValues(alpha: 0.01),
                    borderRadius: BorderRadius.horizontal(
                      right: Radius.circular(resolvedStyle.borderRadius),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: AppConfig.node.resizeHandleVisualWidth,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.01),
                    borderRadius: BorderRadius.horizontal(
                      left: Radius.circular(resolvedStyle.borderRadius),
                    ),
                  ),
                ),
              ),

              // ── Metadata Sphere Widget ────────────────────
              if (liveNode is InfoUiNode &&
                  (liveNode.tags.isNotEmpty || liveNode.comments.isNotEmpty))
                Positioned(
                  right:
                      AppConfig.node.metadataSphereOffsetFromRight -
                      AppConfig.node.metadataSphereRadius,
                  top:
                      AppConfig.node.metadataSphereOffsetFromTop -
                      AppConfig.node.metadataSphereRadius,
                  child: Container(
                    width: AppConfig.node.metadataSphereRadius * 2,
                    height: AppConfig.node.metadataSphereRadius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(
                        (liveNode.tags.isNotEmpty &&
                                liveNode.comments.isNotEmpty)
                            ? 0xFFEC407A
                            : liveNode.tags.isNotEmpty
                            ? 0xFF5C6BC0
                            : 0xFF26A69A,
                      ),
                      border: Border.all(
                        color: Colors.white,
                        width: AppConfig.node.metadataSphereStrokeWidth,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNodeContent(
    BuildContext context,
    UiNode liveNode,
    NodeStyle style,
  ) {
    if (liveNode is DrawingUiNode) {
      return CustomPaint(
        painter: DrawingNodePainter(
          paths: liveNode.paths,
          brushColor: liveNode.brushColor,
          brushThickness: liveNode.brushThickness,
          brushType: liveNode.brushType,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Center(
            child: _buildRichText(
              context,
              liveNode.content,
              TextStyle(
                fontSize: style.fontSize,
                fontFamily: style.fontFamily.isEmpty || style.fontFamily == 'System' ? null : style.fontFamily,
                color: Color(style.textColor),
              ),
              viewState.isExpandedNotifier.value,
            ),
          ),
        ),
        if (viewState.lineCount > 3)
          Container(
            margin: const EdgeInsets.only(top: 0.0),
            padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 1.0),
            child: Text(
              viewState.isExpandedNotifier.value ? "Show Less" : "Show More",
              style: const TextStyle(
                fontSize: 10,
                color: Colors.blueAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        if (liveNode is TaskUiNode)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: Color(style.bgColor).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Color(style.textColor).withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              (liveNode).state,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(style.textColor),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRichText(
    BuildContext context,
    Content content,
    TextStyle baseStyle,
    bool isExpanded,
  ) {
    if (content.blocks.isEmpty) {
      return Text("Empty Node", style: baseStyle);
    }
    
    final List<TextSpan> blockSpans = [];
    
    for (int i = 0; i < content.blocks.length; i++) {
      final block = content.blocks[i];
      final List<TextSpan> inlineSpans = [];
      
      // Determine block-level styling
      TextStyle blockStyle = baseStyle;
      if (block.blockType == BlockType.heading) {
        final level = block.attrs?.level ?? 1;
        final double sizeFactor = 1.4 - (level - 1) * 0.08; 
        blockStyle = baseStyle.copyWith(
          fontSize: (baseStyle.fontSize ?? 12.0) * sizeFactor,
          fontWeight: FontWeight.bold,
        );
      } else if (block.blockType == BlockType.blockquote) {
        blockStyle = baseStyle.copyWith(
          fontStyle: FontStyle.italic,
          color: baseStyle.color?.withValues(alpha: 0.85),
        );
      } else if (block.blockType == BlockType.codeBlock) {
        blockStyle = baseStyle.copyWith(
          fontFamily: 'Consolas',
          fontSize: (baseStyle.fontSize ?? 12.0) * 0.9,
          color: baseStyle.color?.withValues(alpha: 0.9),
        );
      }
      
      // Bullet / List prefix
      if (block.blockType == BlockType.bulletList) {
        inlineSpans.add(TextSpan(text: '• ', style: blockStyle));
      } else if (block.blockType == BlockType.orderedList) {
        inlineSpans.add(TextSpan(text: '${i + 1}. ', style: blockStyle));
      }
      
      for (final inline in block.content) {
        if (inline.inlineType == InlineType.hardBreak) {
          inlineSpans.add(const TextSpan(text: '\n'));
          continue;
        }
        
        TextStyle inlineStyle = blockStyle;
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
              inlineStyle = inlineStyle.copyWith(
                color: Colors.blueAccent,
                decoration: TextDecoration.underline,
              );
            }
          }
        }
        
        inlineSpans.add(TextSpan(
          text: inline.text,
          style: inlineStyle,
        ));
      }
      
      if (i < content.blocks.length - 1) {
        inlineSpans.add(const TextSpan(text: '\n'));
      }
      
      blockSpans.add(TextSpan(children: inlineSpans));
    }
    
    return Text.rich(
      TextSpan(children: blockSpans),
      textAlign: TextAlign.center,
      overflow: TextOverflow.fade,
      maxLines: isExpanded ? null : AppConfig.node.collapsedLineLimit,
    );
  }
}

class DrawNodeWidget extends StatelessWidget {
  final DrawingUiNode node;
  final NodeViewState viewState;
  final bool isSelected;
  final bool isEditing;

  const DrawNodeWidget({
    super.key,
    required this.node,
    required this.viewState,
    required this.isSelected,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    // Reactively select the canonical node from the central store.
    // This prevents the widget from rendering stale aesthetics (like old width)
    // when the FSM drops the volatile drag state before the parent layer rebuilds.
    final liveNode = context.select<GraphDataQuery, DrawingUiNode>(
      (c) => (c.nodeLookup[node.id] ?? node) as DrawingUiNode,
    );

    // We merge the notifiers so the widget repaints when position, size,
    // or expanded state changes.
    return ListenableBuilder(
      listenable: Listenable.merge([
        viewState.positionNotifier,
        viewState.sizeNotifier,
        viewState.dragWidthNotifier,
      ]),
      builder: (context, _) {
        final pos = viewState.positionNotifier.value;
        final rawSize = viewState.sizeNotifier.value;
        final size = Size(
          viewState.dragWidthNotifier.value ?? rawSize.width,
          rawSize.height,
        );

        return Transform.translate(
          offset: pos,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: size,
                painter: DrawingNodePainter(
                  brushColor: liveNode.brushColor,
                  brushThickness: liveNode.brushThickness,
                  brushType: liveNode.brushType,
                  paths: liveNode.paths,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class DrawingNodePainter extends CustomPainter {
  final List<String> paths;
  final String brushColor;
  final double brushThickness;
  final String brushType;

  DrawingNodePainter({
    required this.paths,
    required this.brushColor,
    required this.brushThickness,
    required this.brushType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    Color color;
    try {
      final hex = brushColor.replaceFirst('#', '').replaceFirst('0x', '');
      if (hex.length == 6) {
        color = Color(int.parse('FF$hex', radix: 16));
      } else {
        color = Color(int.parse(hex, radix: 16));
      }
    } catch (_) {
      color = const Color(0xFF00E5FF);
    }

    if (brushType == 'highlighter') {
      color = color.withValues(alpha: 0.4);
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = brushThickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final pathStr in paths) {
      final points = pathStr
          .split(';')
          .map((p) {
            final coords = p.split(',');
            if (coords.length < 2) return null;
            final x = double.tryParse(coords[0]);
            final y = double.tryParse(coords[1]);
            if (x == null || y == null) return null;
            return Offset(x, y);
          })
          .whereType<Offset>()
          .toList();

      if (points.isEmpty) continue;
      final path = Path();
      path.moveTo(points[0].dx, points[0].dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DrawingNodePainter oldDelegate) {
    return oldDelegate.paths != paths ||
        oldDelegate.brushColor != brushColor ||
        oldDelegate.brushThickness != brushThickness ||
        oldDelegate.brushType != brushType;
  }
}
