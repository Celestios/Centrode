// lib/features/graph/ui/canvas/node_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../presentation/graph_metrics.dart';
import '../../models/models.dart';
import '../../store/graph_data_query.dart';
import '../../presentation/view_state.dart';
import '../../presentation/strategies/node_layout_strategy.dart';
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

    return ListenableBuilder(
      listenable: Listenable.merge([
        viewState.sizeNotifier,
        viewState.isExpandedNotifier,
        viewState.dragWidthNotifier,
        viewState.lineCountNotifier,
      ]),
      builder: (context, _) {
        final rawSize = viewState.sizeNotifier.value;
        final size = Size(
          viewState.dragWidthNotifier.value ?? rawSize.width,
          rawSize.height,
        );

        final bool isHighlighted = isSelected || isEditing;
        final double strokeWidth = isHighlighted
            ? 3.0
            : resolvedStyle.strokeWidth.toDouble();
        final double strokeDiff = isHighlighted
            ? (3.0 - resolvedStyle.strokeWidth.toDouble())
            : 0.0;

        return Transform.translate(
          offset: -Offset(strokeDiff, strokeDiff),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Main Visual Body ──────────────────────────
              Container(
                width: size.width + strokeDiff * 2,
                height: size.height + strokeDiff * 2,
                decoration: BoxDecoration(
                  color: Color(resolvedStyle.bgColor),
                  borderRadius: resolvedStyle.shape == 'circle'
                      ? BorderRadius.circular((size.width + strokeDiff * 2) / 2)
                      : BorderRadius.circular(resolvedStyle.borderRadius),
                   border: Border.all(
                    color: isEditing
                        ? const Color(0xFF2196F3)
                        : (isSelected
                            ? AppConfig.visuals.selectionAccent
                            : Color(resolvedStyle.strokeColor)),
                    width: strokeWidth,
                  ),
                  boxShadow: isEditing
                      ? [
                          const BoxShadow(
                            color: Color(0x602196F3),
                            blurRadius: 16,
                            spreadRadius: 4,
                          ),
                        ]
                      : (isSelected
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
                            ]),
                ),
                padding: EdgeInsets.all(isEditing ? 2.0 : resolvedStyle.padding),
                child: _buildNodeContent(
                  context,
                  liveNode,
                  resolvedStyle,
                  isEditing: isEditing,
                ),
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
    NodeStyle style, {
    required bool isEditing,
  }) {
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
          child: isEditing
              ? Center(
                  child: CanvasTextEditor(
                    entityId: liveNode.id,
                    content: liveNode.content,
                    maxLines: null,
                    textStyle: TextStyle(
                      fontSize: style.fontSize,
                      fontFamily: style.fontFamily.isEmpty || style.fontFamily == 'System' ? null : style.fontFamily,
                      color: Color(style.textColor),
                    ),
                  ),
                )
              : Center(
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
            margin: EdgeInsets.only(
              top: viewState.isExpandedNotifier.value ? 8.0 : 2.0,
            ),
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 1.0),
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
    return NodeRichText(
      content: content,
      baseStyle: baseStyle,
      isExpanded: isExpanded,
    );
  }
}

class NodeRichText extends StatefulWidget {
  final Content content;
  final TextStyle baseStyle;
  final bool isExpanded;

  const NodeRichText({
    super.key,
    required this.content,
    required this.baseStyle,
    required this.isExpanded,
  });

  @override
  State<NodeRichText> createState() => _NodeRichTextState();
}

class _NodeRichTextState extends State<NodeRichText> {
  final List<TapGestureRecognizer> _recognizers = [];
  TextSpan? _cachedTextSpan;
  Content? _cachedContent;
  TextStyle? _cachedBaseStyle;

  @override
  void dispose() {
    _clearRecognizers();
    super.dispose();
  }

  void _clearRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    if (_cachedTextSpan == null ||
        _cachedContent != widget.content ||
        _cachedBaseStyle != widget.baseStyle) {
      _clearRecognizers();
      _cachedContent = widget.content;
      _cachedBaseStyle = widget.baseStyle;
      _cachedTextSpan = NodeLayoutStrategy.buildRichTextSpan(
        widget.content,
        widget.baseStyle,
        onLinkTap: (url) async {
          final Uri uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri);
          }
        },
        registerRecognizer: (recognizer) {
          _recognizers.add(recognizer);
        },
      );
    }

    TextAlign textAlign = TextAlign.center;
    for (final block in widget.content.blocks) {
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
        break;
      }
    }

    return Text.rich(
      _cachedTextSpan!,
      textAlign: textAlign,
      overflow: TextOverflow.fade,
      maxLines: widget.isExpanded ? null : AppConfig.node.collapsedLineLimit,
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
        viewState.sizeNotifier,
        viewState.dragWidthNotifier,
      ]),
      builder: (context, _) {
        final rawSize = viewState.sizeNotifier.value;
        final size = Size(
          viewState.dragWidthNotifier.value ?? rawSize.width,
          rawSize.height,
        );

        return Stack(
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
