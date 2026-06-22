// lib/features/graph/ui/canvas/node_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../engine/config.dart';
import '../../models/models.dart';
import '../../store/graph_data_query.dart';
import '../../presentation/view_state.dart';
import '../../presentation/strategies/node_layout_strategy.dart';
import 'canvas_text_editor.dart';
import 'node_visual_constants.dart';

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
        viewState.styleNotifier,
      ]),
      builder: (context, _) {
        final rawSize = viewState.sizeNotifier.value;
        final size = Size(
          viewState.dragWidthNotifier.value ?? rawSize.width,
          rawSize.height,
        );

        final double scale = NodeVisualConstants.fontScale(resolvedStyle.fontSize);
        final double padding = isEditing ? (2.0 * scale) : resolvedStyle.padding;

        final scaledBadgeFontSize = NodeVisualConstants.scaledBadgeFontSize(resolvedStyle.fontSize);
        final scaledShowMoreFontSize = NodeVisualConstants.scaledShowMoreFontSize(resolvedStyle.fontSize);

        return Stack(
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
                  color: Color(resolvedStyle.strokeColor),
                  width: resolvedStyle.strokeWidth.toDouble(),
                ),
                boxShadow: isEditing
                    ? [
                        BoxShadow(
                          color: Color(NodeVisualConstants.editingShadowColor),
                          blurRadius: 16 * scale,
                          spreadRadius: 4 * scale,
                        ),
                      ]
                    : (isSelected
                        ? [
                            BoxShadow(
                              color: Color(NodeVisualConstants.selectedShadowColor),
                              blurRadius: 8 * scale,
                              spreadRadius: 2 * scale,
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
              padding: EdgeInsets.all(padding),
              child: _buildNodeContent(
                context,
                liveNode,
                resolvedStyle,
                isEditing: isEditing,
                scaledBadgeFontSize: scaledBadgeFontSize,
                scaledShowMoreFontSize: scaledShowMoreFontSize,
              ),
            ),

            // ── Resize Handle Visual (Right Edge) ─────────
            Positioned(
              right: 0,
              top: (liveNode is InfoUiNode &&
                  (liveNode.tags.isNotEmpty || liveNode.comments.isNotEmpty))
                  ? NodeVisualConstants.handleTopOffset * scale
                  : 0,
              bottom: 0,
              child: Container(
                width: AppConfig.node.resizeHandleVisualWidth * scale,
                decoration: BoxDecoration(
                  // A nearly‑invisible colour that the hit‑tester sees.
                  color: Color(NodeVisualConstants.handleColor),
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
                width: AppConfig.node.resizeHandleVisualWidth * scale,
                decoration: BoxDecoration(
                  color: Color(NodeVisualConstants.handleColor),
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
                    (AppConfig.node.metadataSphereOffsetFromRight -
                    AppConfig.node.metadataSphereRadius) * scale,
                top:
                    (AppConfig.node.metadataSphereOffsetFromTop -
                    AppConfig.node.metadataSphereRadius) * scale,
                child: Container(
                  width: AppConfig.node.metadataSphereRadius * 2 * scale,
                  height: AppConfig.node.metadataSphereRadius * 2 * scale,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(
                      NodeVisualConstants.metadataSphereColor(
                        hasTags: liveNode.tags.isNotEmpty,
                        hasComments: liveNode.comments.isNotEmpty,
                      ),
                    ),
                    border: Border.all(
                      color: Colors.white,
                      width: AppConfig.node.metadataSphereStrokeWidth * scale,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 2 * scale,
                        offset: Offset(0, 1 * scale),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildNodeContent(
    BuildContext context,
    UiNode liveNode,
    NodeStyle style, {
    required bool isEditing,
    double scaledBadgeFontSize = 10.0,
    double scaledShowMoreFontSize = 10.0,
  }) {
    final double scale = NodeVisualConstants.fontScale(style.fontSize);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: isEditing
              ? Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: double.infinity,
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
                  ),
                )
              : Align(
                  alignment: Alignment.center,
                  child: SizedBox(
                    width: double.infinity,
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
        ),
        if (viewState.lineCount > 3)
          Container(
            margin: EdgeInsets.only(
              top: (viewState.isExpandedNotifier.value ? 6.0 : 2.0) * scale,
            ),
            width: double.infinity,
            height: 16.0 * scale,
            decoration: BoxDecoration(
              color: Color(style.textColor).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(4.0 * scale),
            ),
            child: Center(
              child: Icon(
                viewState.isExpandedNotifier.value
                    ? Icons.keyboard_double_arrow_up
                    : Icons.keyboard_double_arrow_down,
                size: 12.0 * scale,
                color: Color(style.textColor).withValues(alpha: 0.7),
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
                fontSize: scaledBadgeFontSize,
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
  List<(TextSpan, TextAlign)>? _cachedBlockSpans;
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

  void _ensureBuilt() {
    if (_cachedContent == widget.content && _cachedBaseStyle == widget.baseStyle) return;
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

    _cachedBlockSpans = NodeLayoutStrategy.buildPerBlockTextSpans(
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

  @override
  Widget build(BuildContext context) {
    _ensureBuilt();

    if (widget.isExpanded) {
      return ClipRect(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < _cachedBlockSpans!.length; i++)
              Text.rich(
                _cachedBlockSpans![i].$1,
                textAlign: _cachedBlockSpans![i].$2,
              ),
          ],
        ),
      );
    }

    final alignment = _cachedBlockSpans != null && _cachedBlockSpans!.isNotEmpty
        ? _cachedBlockSpans!.first.$2
        : TextAlign.center;

    return Text.rich(
      _cachedTextSpan!,
      textAlign: alignment,
      overflow: TextOverflow.fade,
      maxLines: AppConfig.node.collapsedLineLimit,
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
                parsedPaths: liveNode.parsedPaths,
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
  final List<List<Offset>>? parsedPaths;
  final String brushColor;
  final double brushThickness;
  final String brushType;

  late final Color _parsedColor = _parseColor(brushColor);

  static Color _parseColor(String hex) {
    final clean = hex.replaceFirst('#', '').replaceFirst('0x', '');
    if (clean.length == 6) {
      return Color(int.parse('FF$clean', radix: 16));
    }
    return Color(int.parse(clean, radix: 16));
  }

  DrawingNodePainter({
    required this.paths,
    this.parsedPaths,
    required this.brushColor,
    required this.brushThickness,
    required this.brushType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    var color = _parsedColor;

    if (brushType == 'highlighter') {
      color = color.withValues(alpha: 0.4);
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = brushThickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final resolvedPaths = parsedPaths ?? paths.map((pathStr) {
      return pathStr
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
    }).toList();

    for (final points in resolvedPaths) {
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
        oldDelegate.parsedPaths != parsedPaths ||
        oldDelegate.brushColor != brushColor ||
        oldDelegate.brushThickness != brushThickness ||
        oldDelegate.brushType != brushType;
  }
}

class HighlightFrame extends StatelessWidget {
  final Widget child;
  final bool isEditing;
  final bool isSelected;
  final double borderRadius;
  final String shape;
  final Size size;
  final double scale;

  const HighlightFrame({
    super.key,
    required this.child,
    required this.isEditing,
    required this.isSelected,
    required this.borderRadius,
    required this.shape,
    required this.size,
    required this.scale,
  });

  @override
  Widget build(BuildContext context) {
    final bool isHighlighted = isSelected || isEditing;
    if (!isHighlighted) return child;

    final double stroke = (isEditing ? 1.0 : 0.6) * scale;
    final double gap = 1.5 * scale;
    final double totalOffset = gap + stroke;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        Positioned(
          left: -totalOffset,
          top: -totalOffset,
          right: -totalOffset,
          bottom: -totalOffset,
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: shape == 'circle'
                    ? BorderRadius.circular((size.width + totalOffset * 2) / 2)
                    : BorderRadius.circular(borderRadius + totalOffset),
                border: Border.all(
                  color: isEditing
                      ? Color(NodeVisualConstants.editingBorderColor)
                      : AppConfig.visuals.selectionAccent,
                  width: stroke,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

