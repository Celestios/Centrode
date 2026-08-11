import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import '../../../../../presentation/theme/app_theme_manager.dart';
import '../../../store/graph_data_query.dart';
import '../../../presentation/node_render_state.dart';
import '../../../presentation/viewport_state.dart';
import '../../../presentation/view_state.dart';
import '../../../models/models.dart';
import '../../../engine/config.dart';
import '../widgets/node_visual_constants.dart';
import '../node_widget.dart';
import '../widgets/draw_node_widget.dart';
import '../widgets/highlight_frame.dart';
import '../painters/drawing_node_painter.dart';
import '../../../presentation/strategies/node_text_span_builder.dart';
import '../../../presentation/strategies/node_style_strategy.dart';
import 'package:centrode/shared/widgets/unbounded_stack.dart';

class NodeRenderEntry {
  final UiNode node;
  final NodeViewState viewState;
  final bool isSelected;
  final bool isEditing;

  const NodeRenderEntry({
    required this.node,
    required this.viewState,
    required this.isSelected,
    required this.isEditing,
  });
}

class NodeLayer extends StatelessWidget {
  const NodeLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final query = context.read<GraphDataQuery>();
    final uiState = context.watch<NodeRenderState>();
    final viewport = context.read<ViewportController>();

    return ListenableBuilder(
      listenable: Listenable.merge([uiState, viewport.visibleNodeIds]),
      builder: (context, _) {
        final visibleIds = viewport.visibleNodeIds.value;
        final renderStack = uiState.zOrder.where(visibleIds.contains).toList();

        final entries = <NodeRenderEntry>[];
        NodeRenderEntry? editingEntry;

        for (final id in renderStack) {
          final node = query.nodeLookup[id]!;
          final viewState = uiState.viewStates[id]!;
          final isSelected = uiState.selectedEntities.contains(id);
          final isEditing = uiState.activeEditId == id;

          final entry = NodeRenderEntry(
            node: node,
            viewState: viewState,
            isSelected: isSelected,
            isEditing: isEditing,
          );

          if (isEditing) {
            editingEntry = entry;
          }
          entries.add(entry);
        }

        return UnboundedStack(
          clipBehavior: Clip.none,
          children: [
            RepaintBoundary(
              child: _CanvasNodesHost(
                entries: entries,
                hoveredNodeNotifier: uiState.hoveredNodeNotifier,
              ),
            ),
            if (editingEntry != null)
              Builder(
                builder: (context) {
                  final entry = editingEntry!;
                  return ListenableBuilder(
                    listenable: Listenable.merge([
                      entry.viewState.positionNotifier,
                      entry.viewState.sizeNotifier,
                      entry.viewState.dragWidthNotifier,
                      uiState.hoveredNodeNotifier,
                    ]),
                    builder: (context, _) {
                      final pos = entry.viewState.positionNotifier.value;
                      final rawSize = entry.viewState.sizeNotifier.value;
                      final size = Size(
                        entry.viewState.dragWidthNotifier.value ??
                            rawSize.width,
                        rawSize.height,
                      );
                      final resolvedStyle = entry.node.resolvedStyle;
                      final borderRadius = resolvedStyle?.borderRadius ?? 8.0;
                      final shape = resolvedStyle?.shape ?? 'rectangle';
                      final double fontSize = resolvedStyle?.fontSize ?? 14.0;
                      final double scale = NodeVisualConstants.fontScale(
                        fontSize,
                      );
                      final isHovered =
                          uiState.hoveredNodeNotifier.value == entry.node.id;

                      final Widget editWidget;
                      if (entry.node is DrawingUiNode) {
                        editWidget = DrawNodeWidget(
                          node: entry.node as DrawingUiNode,
                          viewState: entry.viewState,
                          isSelected: entry.isSelected,
                          isEditing: true,
                        );
                      } else {
                        editWidget = HighlightFrame(
                          isEditing: true,
                          isSelected: entry.isSelected,
                          isHovered: isHovered,
                          borderRadius: borderRadius,
                          shape: shape,
                          size: size,
                          scale: scale,
                          child: NodeWidget(
                            viewState: entry.viewState,
                            node: entry.node,
                            isSelected: entry.isSelected,
                            isEditing: true,
                          ),
                        );
                      }

                      return Positioned(
                        key: ValueKey('edit_${entry.node.id}'),
                        left: pos.dx,
                        top: pos.dy,
                        child: editWidget,
                      );
                    },
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _CanvasNodesHost extends StatefulWidget {
  final List<NodeRenderEntry> entries;
  final ValueNotifier<RawUuid?> hoveredNodeNotifier;

  const _CanvasNodesHost({
    required this.entries,
    required this.hoveredNodeNotifier,
  });

  @override
  State<_CanvasNodesHost> createState() => _CanvasNodesHostState();
}

class _CanvasNodesHostState extends State<_CanvasNodesHost> {
  final Set<RawUuid> _dirtyNodeIds = {};
  final Set<RawUuid> _positionOnlyNodeIds = {};
  final Map<RawUuid, VoidCallback> _listeners = {};
  final Map<RawUuid, VoidCallback> _positionListeners = {};
  _CanvasNodesPainter? _painter;
  final ValueNotifier<int> _repaintTrigger = ValueNotifier(0);
  bool _disposed = false;

  @override
  void initState() {
    super.initState();
    _subscribeAll();
    _createPainter();
  }

  @override
  void didUpdateWidget(covariant _CanvasNodesHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    _unsubscribeAll();
    _disposeNodeCache();
    _subscribeAll();
    _painter = _CanvasNodesPainter(
      entries: widget.entries,
      dirtyNodeIds: _dirtyNodeIds,
      positionOnlyNodeIds: _positionOnlyNodeIds,
    );
    _repaintTrigger.value++;
  }

  @override
  void dispose() {
    _disposed = true;
    _unsubscribeAll();
    _disposeNodeCache();
    _repaintTrigger.dispose();
    super.dispose();
  }

  void _disposeNodeCache() {
    if (_painter != null) {
      for (final picture in _painter!._nodeCache.values) {
        picture.dispose();
      }
      _painter!._nodeCache.clear();
    }
  }

  void _createPainter() {
    _painter = _CanvasNodesPainter(
      entries: widget.entries,
      dirtyNodeIds: _dirtyNodeIds,
      positionOnlyNodeIds: _positionOnlyNodeIds,
    );
  }

  void _subscribeAll() {
    for (final entry in widget.entries) {
      final id = entry.node.id;
      void markDirty() {
        if (_disposed) return;
        _dirtyNodeIds.add(id);
        _repaintTrigger.value++;
      }

      void markPosition() {
        if (_disposed) return;
        _positionOnlyNodeIds.add(id);
        _repaintTrigger.value++;
      }

      entry.viewState.positionNotifier.addListener(markPosition);
      entry.viewState.sizeNotifier.addListener(markDirty);
      entry.viewState.dragWidthNotifier.addListener(markDirty);
      entry.viewState.isExpandedNotifier.addListener(markDirty);
      entry.viewState.lineCountNotifier.addListener(markDirty);
      entry.viewState.styleNotifier.addListener(markDirty);
      _positionListeners[id] = markPosition;
      _listeners[id] = markDirty;
    }
    widget.hoveredNodeNotifier.addListener(_onHoverChanged);
  }

  void _unsubscribeAll() {
    for (final entry in widget.entries) {
      final posListener = _positionListeners.remove(entry.node.id);
      if (posListener != null) {
        entry.viewState.positionNotifier.removeListener(posListener);
      }
      final listener = _listeners.remove(entry.node.id);
      if (listener != null) {
        entry.viewState.sizeNotifier.removeListener(listener);
        entry.viewState.dragWidthNotifier.removeListener(listener);
        entry.viewState.isExpandedNotifier.removeListener(listener);
        entry.viewState.lineCountNotifier.removeListener(listener);
        entry.viewState.styleNotifier.removeListener(listener);
      }
    }
    widget.hoveredNodeNotifier.removeListener(_onHoverChanged);
  }


  void _onHoverChanged() {
    if (_disposed) return;
    final oldHovered = _painter!._hoveredNodeId;
    final newHovered = widget.hoveredNodeNotifier.value;

    if (oldHovered == newHovered) return;

    _painter!._hoveredNodeId = newHovered;

    if (oldHovered != null) _dirtyNodeIds.add(oldHovered);
    if (newHovered != null) _dirtyNodeIds.add(newHovered);

    if (_dirtyNodeIds.isNotEmpty) _repaintTrigger.value++;
  }

  @override
  Widget build(BuildContext context) {
    final canvasAccent = AppThemeManager.instance.currentTheme.canvasAccentColor;
    final hoverAccent = AppThemeManager.instance.currentTheme.hoverAccentColor;
    _painter!
      ..selectionColor = canvasAccent
      ..hoverColor = hoverAccent;

    return ValueListenableBuilder<int>(
      valueListenable: _repaintTrigger,
      builder: (context, _, __) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(constraints.maxWidth, constraints.maxHeight);
            return CustomPaint(size: size, painter: _painter);
          },
        );
      },
    );
  }
}

class _CanvasNodesPainter extends CustomPainter {
  List<NodeRenderEntry> entries;
  final Set<RawUuid> dirtyNodeIds;
  final Set<RawUuid> positionOnlyNodeIds;
  RawUuid? _hoveredNodeId;
  Color selectionColor = AppThemeManager.instance.currentTheme.canvasAccentColor;
  Color hoverColor = const Color(0xFF64B5F6);

  final Map<RawUuid, ui.Picture> _nodeCache = {};
  ui.Picture? _cachedPicture;
  final int _entriesGeneration = 0;
  int _cachedGeneration = -1;

  final Map<RawUuid, (RRect, RRect)> _handleCache = {};
  final Paint _shadowPaint = Paint();
  final Paint _bgPaint = Paint();
  final Paint _borderPaint = Paint();
  final Paint _handlePaint = Paint()
    ..color = Color(NodeVisualConstants.handleColor);

  _CanvasNodesPainter({
    required this.entries,
    required this.dirtyNodeIds,
    required this.positionOnlyNodeIds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final activeIds = <RawUuid>{};
    final bool hasDirty = dirtyNodeIds.isNotEmpty;
    final bool hasPositionOnly = positionOnlyNodeIds.isNotEmpty;

    // Case 1: Nothing changed — replay cached picture
    if (!hasDirty && !hasPositionOnly) {
      final bool cacheValid =
          _cachedPicture != null && _cachedGeneration == _entriesGeneration;
      if (cacheValid) {
        canvas.drawPicture(_cachedPicture!);
        return;
      }
    }

    // Ensure all nodes have cached pictures (lazy-record on first paint)
    for (final entry in entries) {
      final nodeId = entry.node.id;
      activeIds.add(nodeId);
      if (!_nodeCache.containsKey(nodeId)) {
        _nodeCache[nodeId] = _recordNodePicture(entry);
      }
    }

    // Case 2: Only positions changed — draw cached pictures at new positions
    if (!hasDirty) {
      for (final entry in entries) {
        final pos = entry.viewState.positionNotifier.value;
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        canvas.drawPicture(_nodeCache[entry.node.id]!);
        canvas.restore();
      }
      _updateCachedPicture(activeIds);
      positionOnlyNodeIds.clear();
      return;
    }

    // Case 3: Content changed — re-record dirty nodes, then composite
    for (final entry in entries) {
      final nodeId = entry.node.id;
      if (dirtyNodeIds.contains(nodeId)) {
        _nodeCache[nodeId]?.dispose();
        _nodeCache[nodeId] = _recordNodePicture(entry);
      }
    }

    for (final entry in entries) {
      final pos = entry.viewState.positionNotifier.value;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.drawPicture(_nodeCache[entry.node.id]!);
      canvas.restore();
    }

    _updateCachedPicture(activeIds);
    dirtyNodeIds.clear();
    positionOnlyNodeIds.clear();
  }

  void _updateCachedPicture(Set<RawUuid> activeIds) {
    final recorder = ui.PictureRecorder();
    final recordCanvas = Canvas(recorder);
    for (final entry in entries) {
      final pos = entry.viewState.positionNotifier.value;
      recordCanvas.save();
      recordCanvas.translate(pos.dx, pos.dy);
      recordCanvas.drawPicture(_nodeCache[entry.node.id]!);
      recordCanvas.restore();
    }
    _cachedPicture?.dispose();
    _cachedPicture = recorder.endRecording();
    _cachedGeneration = _entriesGeneration;

    for (final id in _nodeCache.keys.toList()) {
      if (!activeIds.contains(id)) {
        _nodeCache[id]?.dispose();
        _nodeCache.remove(id);
      }
    }
    for (final id in _handleCache.keys.toList()) {
      if (!activeIds.contains(id)) {
        _handleCache.remove(id);
      }
    }
  }

  ui.Picture _recordNodePicture(NodeRenderEntry entry) {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    _drawNodeContent(canvas, entry);
    return recorder.endRecording();
  }

  void _drawNodeContent(Canvas canvas, NodeRenderEntry entry) {
    if (entry.isEditing) return;
    final node = entry.node;
    final vs = entry.viewState;
    final resolvedStyle = node.resolvedStyle;
    if (resolvedStyle == null) return;

    final rawSize = vs.sizeNotifier.value;
    final w = vs.dragWidthNotifier.value ?? rawSize.width;
    final h = rawSize.height;
    // Record at origin — canvas is translated to node position during compositing
    final rect = Rect.fromLTWH(0, 0, w, h);

    final double scale = NodeVisualConstants.fontScale(resolvedStyle.fontSize);
    final bool isHovered = entry.node.id == _hoveredNodeId;
    final bool isHighlighted = entry.isSelected || entry.isEditing || isHovered;
    final double stroke =
        (entry.isEditing
            ? 1.0
            : entry.isSelected
            ? 1.0
            : 0.5) *
        scale;
    final double gap = 1.5 * scale;

    final rrect = _buildRRect(rect, resolvedStyle, 0.0, scale);

    if (node is! DrawingUiNode) {
      if (entry.isEditing) {
        _shadowPaint.color = Color(NodeVisualConstants.editingShadowColor);
        _shadowPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 16 * scale);
      } else if (entry.isSelected) {
        _shadowPaint.color = Color(NodeVisualConstants.selectedShadowColor);
        _shadowPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * scale);
      } else {
        _shadowPaint.color = Color(resolvedStyle.shadowColor);
        _shadowPaint.maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          resolvedStyle.shadowBlur,
        );
      }

      final double shadowOffsetX = resolvedStyle.shadowOffsetX;
      final double shadowOffsetY = resolvedStyle.shadowOffsetY;
      final shadowOffset = Offset(shadowOffsetX, shadowOffsetY);

      if (shadowOffset != Offset.zero) {
        final shadowRRect = _buildRRect(
          rect.shift(shadowOffset),
          resolvedStyle,
          0.0,
          scale,
        );
        canvas.drawRRect(shadowRRect, _shadowPaint);
      } else {
        canvas.drawRRect(rrect, _shadowPaint);
      }

      _bgPaint.color = Color(resolvedStyle.bgColor);
      canvas.drawRRect(rrect, _bgPaint);
    }

    if (node is! DrawingUiNode) {
      _borderPaint
        ..color = Color(resolvedStyle.strokeColor)
        ..style = PaintingStyle.stroke
        ..strokeWidth = resolvedStyle.strokeWidth.toDouble();
      canvas.drawRRect(rrect, _borderPaint);
    }

    if (isHighlighted && node is! DrawingUiNode) {
      final double inflateAmount = gap + stroke / 2;
      final highlightRect = rect.inflate(inflateAmount);
      final highlightRRect = _buildRRect(
        highlightRect,
        resolvedStyle,
        inflateAmount,
        scale,
      );

      final Color highlightColor;
      if (entry.isEditing) {
        highlightColor = Color(NodeVisualConstants.editingBorderColor);
      } else if (entry.isSelected) {
        highlightColor = selectionColor;
      } else {
        highlightColor = hoverColor;
      }

      _borderPaint
        ..color = highlightColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke;
      canvas.drawRRect(highlightRRect, _borderPaint);
    }

    if (node is DrawingUiNode) {
      _paintDrawingPaths(
        canvas,
        node,
        Offset.zero,
        resolvedStyle,
        Size(w, h),
        isHighlighted: isHighlighted,
        isEditing: entry.isEditing,
        isSelected: entry.isSelected,
        isHovered: isHovered,
      );
    } else {
      _paintText(canvas, entry, rect, resolvedStyle);
      _paintMetadataSphere(canvas, node, rect, scale);
      _paintExpandToggle(canvas, entry, rect, resolvedStyle, scale);
    }

    if (node is! DrawingUiNode) {
      final hasMetadataSphere =
          node is InfoUiNode &&
          (node.tags.isNotEmpty || node.comments.isNotEmpty);
      _paintResizeHandles(
        canvas,
        node.id,
        rect,
        resolvedStyle,
        scale,
        hasMetadataSphere,
      );
    }
  }

  void _paintDrawingPaths(
    Canvas canvas,
    DrawingUiNode node,
    Offset pos,
    NodeStyle style,
    Size size, {
    required bool isHighlighted,
    required bool isEditing,
    required bool isSelected,
    required bool isHovered,
  }) {
    canvas.save();
    canvas.translate(pos.dx + style.padding, pos.dy + style.padding);

    if (isHighlighted) {
      final Color highlightColor;
      if (isEditing) {
        highlightColor = Color(NodeVisualConstants.editingBorderColor);
      } else if (isSelected) {
        highlightColor = selectionColor;
      } else {
        highlightColor = hoverColor;
      }
      _paintDrawingOutline(
        canvas,
        node.parsedPaths,
        highlightColor,
        node.brushThickness,
      );
    }

    final drawingPainter = DrawingNodePainter(
      paths: node.paths,
      parsedPaths: node.parsedPaths,
      brushColor: node.brushColor,
      brushThickness: node.brushThickness,
      brushType: node.brushType.name,
    );
    drawingPainter.paint(canvas, size);

    canvas.restore();
  }

  void _paintDrawingOutline(
    Canvas canvas,
    List<List<Offset>> parsedPaths,
    Color color,
    double brushThickness,
  ) {
    final double offset = brushThickness * 0.5 + 3.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (final points in parsedPaths) {
      if (points.length < 2) continue;

      for (int i = 0; i < points.length - 1; i++) {
        final s1 = points[i];
        final s2 = points[i + 1];
        final dir = s2 - s1;
        final len = dir.distance;
        if (len == 0) continue;
        final normal = Offset(-dir.dy / len, dir.dx / len) * offset;

        final outerPath = Path()
          ..moveTo(s1.dx + normal.dx, s1.dy + normal.dy)
          ..lineTo(s2.dx + normal.dx, s2.dy + normal.dy);
        final innerPath = Path()
          ..moveTo(s1.dx - normal.dx, s1.dy - normal.dy)
          ..lineTo(s2.dx - normal.dx, s2.dy - normal.dy);

        canvas.drawPath(outerPath, paint);
        canvas.drawPath(innerPath, paint);
      }
    }
  }

  RRect _buildRRect(
    Rect rect,
    NodeStyle style, [
    double extraRadius = 0.0,
    double scale = 1.0,
  ]) {
    final radius = style.shape == 'circle'
        ? Radius.circular(rect.shortestSide / 2)
        : Radius.circular(style.borderRadius + extraRadius);
    return RRect.fromRectAndRadius(rect, radius);
  }

  void _paintText(
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
      extraHeight += NodeStyleStrategy.taskBadgeHeight(fontScale);
    }
    if (entry.viewState.lineCount > AppConfig.node.collapsedLineLimit) {
      extraHeight += NodeStyleStrategy.expandToggleSpace(
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

  (RRect, RRect) _getHandleRRects(
    RawUuid nodeId,
    Rect rect,
    double borderRadius,
    double scale,
    bool hasMetadataSphere,
  ) {
    final cached = _handleCache[nodeId];
    final double handleWidth = NodeVisualConstants.handleWidth * scale;
    final double handleTopOffset = hasMetadataSphere
        ? NodeVisualConstants.handleTopOffset * scale
        : 0.0;
    if (cached != null) {
      final (right, left) = cached;
      if (right.outerRect ==
              Rect.fromLTRB(
                rect.right - handleWidth,
                rect.top + handleTopOffset,
                rect.right,
                rect.bottom,
              ) &&
          left.outerRect ==
              Rect.fromLTRB(
                rect.left,
                rect.top,
                rect.left + handleWidth,
                rect.bottom,
              )) {
        return cached;
      }
    }

    final r = Radius.circular(borderRadius);
    final rightHandle = RRect.fromRectAndCorners(
      Rect.fromLTRB(
        rect.right - handleWidth,
        rect.top + handleTopOffset,
        rect.right,
        rect.bottom,
      ),
      topRight: r,
      bottomRight: r,
    );
    final leftHandle = RRect.fromRectAndCorners(
      Rect.fromLTRB(rect.left, rect.top, rect.left + handleWidth, rect.bottom),
      topLeft: r,
      bottomLeft: r,
    );

    final result = (rightHandle, leftHandle);
    _handleCache[nodeId] = result;
    return result;
  }

  void _paintResizeHandles(
    Canvas canvas,
    RawUuid nodeId,
    Rect rect,
    NodeStyle style,
    double scale,
    bool hasMetadataSphere,
  ) {
    final (rightHandle, leftHandle) = _getHandleRRects(
      nodeId,
      rect,
      style.borderRadius,
      scale,
      hasMetadataSphere,
    );
    canvas.drawRRect(rightHandle, _handlePaint);
    canvas.drawRRect(leftHandle, _handlePaint);
  }

  void _paintMetadataSphere(
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

  void _paintExpandToggle(
    Canvas canvas,
    NodeRenderEntry entry,
    Rect rect,
    NodeStyle style,
    double scale,
  ) {
    if (entry.viewState.lineCount <= 3) return;

    final toggleSpace = NodeStyleStrategy.expandToggleSpace(
      entry.viewState.isExpandedNotifier.value,
      scale,
    );
    final taskBadgeHeight = entry.node is TaskUiNode
        ? NodeStyleStrategy.taskBadgeHeight(scale)
        : 0.0;

    final yCenter =
        rect.bottom - style.padding - taskBadgeHeight - toggleSpace / 2;

    // Draw background wide narrow button
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

    // Draw double arrow icon (without any circle around it)
    final iconData = entry.viewState.isExpandedNotifier.value
        ? Icons.keyboard_double_arrow_up
        : Icons.keyboard_double_arrow_down;

    final tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(iconData.codePoint),
        style: TextStyle(
          fontSize: 12.0 * scale,
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

  @override
  bool shouldRepaint(covariant _CanvasNodesPainter oldDelegate) {
    return dirtyNodeIds.isNotEmpty ||
        positionOnlyNodeIds.isNotEmpty ||
        _entriesGeneration != _cachedGeneration;
  }
}
