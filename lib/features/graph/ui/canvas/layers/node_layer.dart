import 'dart:math' as math;
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
import '../../../presentation/strategies/node_layout_strategy.dart';
import '../../../presentation/strategies/relation_style_strategy.dart';
import '../../../store/relation_engine_state.dart';
import 'package:centrode/shared/widgets/unbounded_stack.dart';

Color getContainerBaseColor(ContainerUiNode node, NodeStyle resolvedStyle) {
  if (resolvedStyle.strokeColor != 0 && resolvedStyle.strokeColor != 0xFF000000) {
    return Color(resolvedStyle.strokeColor);
  }
  if (resolvedStyle.bgColor != 0 && resolvedStyle.bgColor != 0x00000000) {
    return Color(resolvedStyle.bgColor).withValues(alpha: 1.0);
  }
  return const Color(0xFF64B5F6);
}

void drawDashedRRect(Canvas canvas, RRect rrect, Paint paint, [double dashWidth = 12.0, double dashSpace = 8.0]) {
  final path = Path()..addRRect(rrect);
  for (final metric in path.computeMetrics()) {
    double distance = 0.0;
    while (distance < metric.length) {
      final double len = math.min(dashWidth, metric.length - distance);
      canvas.drawPath(metric.extractPath(distance, distance + len), paint);
      distance += dashWidth + dashSpace;
    }
  }
}

void paintContainerTopLeftTag(Canvas canvas, Rect rect, double scale, Color containerColor, {double opacity = 1.0}) {
  if (opacity <= 0.0) return;
  final hsl = HSLColor.fromColor(containerColor);
  final badgeTextColor = hsl
      .withSaturation((hsl.saturation * 1.2).clamp(0.0, 1.0))
      .withLightness((hsl.lightness + 0.3).clamp(0.0, 0.95))
      .toColor()
      .withValues(alpha: opacity);
  final badgeBgColor = hsl
      .withSaturation((hsl.saturation * 0.8).clamp(0.0, 1.0))
      .withLightness(0.12)
      .toColor()
      .withValues(alpha: 0.85 * opacity);

  final tagSpan = TextSpan(
    text: ' CONTAINER ',
    style: TextStyle(
      color: badgeTextColor,
      fontSize: (10.0 * scale).clamp(9.0, 13.0),
      fontWeight: FontWeight.bold,
      letterSpacing: 1.0,
    ),
  );
  final tp = TextPainter(text: tagSpan, textDirection: TextDirection.ltr)..layout();

  final borderWidth = 2.0 * scale;
  final tagBg = RRect.fromRectAndRadius(
    Rect.fromLTWH(
      rect.left + 12 * scale - borderWidth / 2,
      rect.top + 12 * scale - borderWidth / 2,
      tp.width + 12 * scale,
      tp.height + 6 * scale,
    ),
    Radius.circular(4.0 * scale),
  );
  canvas.drawRRect(tagBg, Paint()..color = badgeBgColor);
  canvas.drawRRect(
    tagBg,
    Paint()
      ..color = containerColor.withValues(alpha: 0.6 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0,
  );
  tp.paint(canvas, Offset(rect.left + 18 * scale - borderWidth / 2, rect.top + 15 * scale - borderWidth / 2));
  tp.dispose();
}

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
    final uiState = context.read<NodeRenderState>();
    final viewport = context.read<ViewportController>();

    return ListenableBuilder(
      listenable: Listenable.merge([
        uiState,
        viewport.visibleNodeIds,
        viewport.viewportStateNotifier,
        viewport.activeScopeNotifier,
      ]),
      builder: (context, _) {
        final activeScope = viewport.activeScopeNotifier.value;
        final visibleIds = viewport.visibleNodeIds.value;
        final cameraScale = viewport.viewportStateNotifier.value.scale;

        final renderStack = uiState.zOrder.where((id) {
          final node = query.nodeLookup[id];
          if (node == null) return false;
          if (!query.isNodeInScope(id, activeScope)) return false;
          final bool scopeMatches = visibleIds.any((vId) => query.isNodeInScope(vId, activeScope));
          return !scopeMatches || visibleIds.contains(id);
        }).toList();

        final entries = <NodeRenderEntry>[];
        NodeRenderEntry? editingEntry;

        for (final id in renderStack) {
          final node = query.nodeLookup[id];
          final viewState = uiState.viewStates[id];
          if (node == null || viewState == null) continue;
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
            if (activeScope is ContainerViewportScope)
              Builder(
                builder: (context) {
                  final container = query.nodeLookup[activeScope.containerId] as ContainerUiNode?;
                  final vs = uiState.viewStates[activeScope.containerId];
                  final effectiveOuterSize = (vs != null && vs.sizeNotifier.value.width > 0 && vs.sizeNotifier.value.height > 0)
                      ? Size(vs.dragWidthNotifier.value ?? vs.sizeNotifier.value.width, vs.sizeNotifier.value.height)
                      : (activeScope.outerSize.width > 0 && activeScope.outerSize.height > 0)
                          ? activeScope.outerSize
                          : (container != null)
                              ? const DefaultNodeLayoutStrategy().calculateSize(container).size
                              : const Size(300.0, 180.0);
                  final aspectRatio = effectiveOuterSize.height / (effectiveOuterSize.width > 0 ? effectiveOuterSize.width : 1.0);
                  final internalSize = Size(1600.0, 1600.0 * aspectRatio);
                  return Positioned(
                    left: 0,
                    top: 0,
                    width: internalSize.width,
                    height: internalSize.height,
                    child: IgnorePointer(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          size: internalSize,
                          painter: _ContainerBoundaryPainter(
                            container: container,
                            effectiveSize: effectiveOuterSize,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            RepaintBoundary(
              child: _CanvasNodesHost(
                entries: entries,
                hoveredNodeNotifier: uiState.hoveredNodeNotifier,
                cameraScale: cameraScale,
                activeScope: activeScope,
                nodeLookup: query.nodeLookup,
                relations: query.relations,
                relationEngine: query.relationEngine,
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
  final double cameraScale;
  final ViewportScope activeScope;
  final Map<RawUuid, UiNode> nodeLookup;
  final Iterable<UiRelation>? relations;
  final RelationEngineState? relationEngine;

  const _CanvasNodesHost({
    required this.entries,
    required this.hoveredNodeNotifier,
    required this.cameraScale,
    required this.activeScope,
    required this.nodeLookup,
    this.relations,
    this.relationEngine,
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

  RawUuid? _lastHoveredId;

  @override
  void initState() {
    super.initState();
    _subscribeAll();
    _createPainter();
    _lastHoveredId = widget.hoveredNodeNotifier.value;
    _painter?._hoveredNodeId = _lastHoveredId;
    widget.hoveredNodeNotifier.addListener(_onHoverChanged);
  }

  void _onHoverChanged() {
    final newHovered = widget.hoveredNodeNotifier.value;
    if (_lastHoveredId != newHovered) {
      if (_lastHoveredId != null) _dirtyNodeIds.add(_lastHoveredId!);
      if (newHovered != null) _dirtyNodeIds.add(newHovered);
      _lastHoveredId = newHovered;
      _painter?._hoveredNodeId = newHovered;
      _repaintTrigger.value++;
    }
  }

  @override
  void didUpdateWidget(covariant _CanvasNodesHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hoveredNodeNotifier != widget.hoveredNodeNotifier) {
      oldWidget.hoveredNodeNotifier.removeListener(_onHoverChanged);
      widget.hoveredNodeNotifier.addListener(_onHoverChanged);
    }
    _unsubscribeEntries(oldWidget.entries);
    _disposeNodeCache();
    _subscribeAll();
    _createPainter();
    _repaintTrigger.value++;
  }

  @override
  void dispose() {
    _disposed = true;
    widget.hoveredNodeNotifier.removeListener(_onHoverChanged);
    _unsubscribeEntries(widget.entries);
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
      _painter!._cachedPicture?.dispose();
      _painter!._cachedPicture = null;
    }
  }

  void _createPainter() {
    _painter = _CanvasNodesPainter(
      repaint: _repaintTrigger,
      entries: widget.entries,
      dirtyNodeIds: _dirtyNodeIds,
      positionOnlyNodeIds: _positionOnlyNodeIds,
      cameraScale: widget.cameraScale,
      activeScope: widget.activeScope,
      nodeLookup: widget.nodeLookup,
      relations: widget.relations,
      relationEngine: widget.relationEngine,
    );
    _painter?._hoveredNodeId = _lastHoveredId;
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

      final vs = entry.viewState;
      vs.positionNotifier.addListener(markPosition);
      vs.sizeNotifier.addListener(markDirty);
      vs.dragWidthNotifier.addListener(markDirty);
      vs.visualScaleNotifier.addListener(markDirty);
      vs.isExpandedNotifier.addListener(markDirty);
      vs.lineCountNotifier.addListener(markDirty);
      vs.styleNotifier.addListener(markDirty);

      _listeners[id] = markDirty;
      _positionListeners[id] = markPosition;
    }
  }

  void _unsubscribeEntries(List<NodeRenderEntry> entries) {
    for (final entry in entries) {
      final id = entry.node.id;
      final vs = entry.viewState;
      final markDirty = _listeners.remove(id);
      final markPos = _positionListeners.remove(id);
      if (markDirty != null) {
        vs.sizeNotifier.removeListener(markDirty);
        vs.dragWidthNotifier.removeListener(markDirty);
        vs.visualScaleNotifier.removeListener(markDirty);
        vs.isExpandedNotifier.removeListener(markDirty);
        vs.lineCountNotifier.removeListener(markDirty);
        vs.styleNotifier.removeListener(markDirty);
      }
      if (markPos != null) {
        vs.positionNotifier.removeListener(markPos);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _painter,
      size: Size.infinite,
    );
  }
}

class _CanvasNodesPainter extends CustomPainter {
  List<NodeRenderEntry> entries;
  final Set<RawUuid> dirtyNodeIds;
  final Set<RawUuid> positionOnlyNodeIds;
  final double cameraScale;
  final ViewportScope activeScope;
  final Map<RawUuid, UiNode> nodeLookup;
  final Iterable<UiRelation>? relations;
  final RelationEngineState? relationEngine;
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
    this.cameraScale = 1.0,
    this.activeScope = const RootViewportScope(),
    required this.nodeLookup,
    this.relations,
    this.relationEngine,
    super.repaint,
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

    Offset resolveWorldPos(NodeRenderEntry entry) =>
        entry.viewState.positionNotifier.value;

    // Case 2: Only positions changed — draw cached pictures at new positions
    if (!hasDirty) {
      _paintOutsideNodes(canvas);
      for (final entry in entries) {
        final pos = resolveWorldPos(entry);
        final visualScale = entry.viewState.visualScaleNotifier.value;
        canvas.save();
        canvas.translate(pos.dx, pos.dy);
        if (visualScale != 1.0) {
          canvas.scale(visualScale, visualScale);
        }
        canvas.drawPicture(_nodeCache[entry.node.id]!);
        canvas.restore();
      }
      positionOnlyNodeIds.clear();
      _cachedPicture?.dispose();
      _cachedPicture = null;
      _cachedGeneration = -1;
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

    _paintOutsideNodes(canvas);
    for (final entry in entries) {
      final pos = resolveWorldPos(entry);
      final visualScale = entry.viewState.visualScaleNotifier.value;
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      if (visualScale != 1.0) {
        canvas.scale(visualScale, visualScale);
      }
      canvas.drawPicture(_nodeCache[entry.node.id]!);
      canvas.restore();
    }

    _updateCachedPicture(activeIds);
    dirtyNodeIds.clear();
    positionOnlyNodeIds.clear();
  }

  void _updateCachedPicture(Set<RawUuid> activeIds) {
    Offset resolveWorldPos(NodeRenderEntry entry) =>
        entry.viewState.positionNotifier.value;

    final recorder = ui.PictureRecorder();
    final recordCanvas = Canvas(recorder);
    _paintOutsideNodes(recordCanvas);
    for (final entry in entries) {
      final pos = resolveWorldPos(entry);
      final visualScale = entry.viewState.visualScaleNotifier.value;
      recordCanvas.save();
      recordCanvas.translate(pos.dx, pos.dy);
      if (visualScale != 1.0) {
        recordCanvas.scale(visualScale, visualScale);
      }
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

    final isContainer = node is ContainerUiNode;
    final rawSize = vs.sizeNotifier.value;
    final w = vs.dragWidthNotifier.value ?? rawSize.width;
    final h = rawSize.height;
    // Record at origin — canvas is translated to node position during compositing
    final rect = Rect.fromLTWH(0, 0, w, h);

    final double fontScale = NodeVisualConstants.fontScale(resolvedStyle.fontSize);
    final bool isHovered = entry.node.id == _hoveredNodeId;
    final bool isHighlighted = entry.isSelected || entry.isEditing || isHovered;
    final double stroke =
        (entry.isEditing
            ? 1.0
            : entry.isSelected
            ? 1.0
            : 0.5) *
        fontScale;
    final double gap = 1.5 * fontScale;
    final screenWidth = w * cameraScale;
    final isStage2ApproachContainer = isContainer && node.isClosed && screenWidth >= 80.0;

    final rrect = _buildRRect(rect, resolvedStyle, 0.0, fontScale);

    Color? containerBaseColor;
    Color? containerBorderColor;
    Color? containerBgColor;
    if (isContainer) {
      containerBaseColor = _getContainerBaseColor(node, resolvedStyle);
      final hsl = HSLColor.fromColor(containerBaseColor);
      containerBorderColor = hsl
          .withSaturation((hsl.saturation * 1.35).clamp(0.0, 1.0))
          .withLightness(hsl.lightness.clamp(0.4, 0.75))
          .toColor()
          .withValues(alpha: 0.85);
      containerBgColor = hsl
          .withSaturation((hsl.saturation * 1.1).clamp(0.0, 1.0))
          .toColor()
          .withValues(alpha: 0.08);
    }

    if (node is! DrawingUiNode) {
      if (!isContainer || node.isClosed) {
        if (entry.isEditing) {
          _shadowPaint.color = Color(NodeVisualConstants.editingShadowColor);
          _shadowPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 16 * fontScale);
        } else if (entry.isSelected) {
          _shadowPaint.color = Color(NodeVisualConstants.selectedShadowColor);
          _shadowPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, 8 * fontScale);
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
            fontScale,
          );
          canvas.drawRRect(shadowRRect, _shadowPaint);
        } else {
          canvas.drawRRect(rrect, _shadowPaint);
        }

        if (isStage2ApproachContainer) {
          final double t = ((screenWidth - 80.0) / (180.0 - 80.0)).clamp(0.0, 1.0);
          _bgPaint.color = Color(resolvedStyle.bgColor).withValues(alpha: (1.0 - t).clamp(0.0, 1.0));
          canvas.drawRRect(rrect, _bgPaint);
          _borderPaint
            ..color = Color(resolvedStyle.strokeColor).withValues(alpha: (1.0 - t).clamp(0.0, 1.0))
            ..style = PaintingStyle.stroke
            ..strokeWidth = resolvedStyle.strokeWidth.toDouble();
          canvas.drawRRect(rrect, _borderPaint);
        } else {
          _bgPaint.color = Color(resolvedStyle.bgColor);
          canvas.drawRRect(rrect, _bgPaint);
          _borderPaint
            ..color = Color(resolvedStyle.strokeColor)
            ..style = PaintingStyle.stroke
            ..strokeWidth = resolvedStyle.strokeWidth.toDouble();
          canvas.drawRRect(rrect, _borderPaint);
        }
      }
    }

    final isInteractableNode = !(node is ContainerUiNode && !node.isClosed);

    if (isHighlighted && node is! DrawingUiNode && isInteractableNode) {
      final double inflateAmount = gap + stroke / 2;
      final highlightRect = rect.inflate(inflateAmount);
      final highlightRRect = _buildRRect(
        highlightRect,
        resolvedStyle,
        inflateAmount,
        fontScale,
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
    } else if (node is ContainerUiNode) {
      final aspectRatio = h / (w > 0 ? w : 1.0);
      final internalW = 1600.0;
      final internalH = 1600.0 * aspectRatio;
      final sx = w / internalW;
      final sy = h / internalH;
      final internalRect = Rect.fromLTWH(0, 0, internalW, internalH);
      final internalRRect = RRect.fromRectAndRadius(internalRect, const Radius.circular(16.0));

      if (node.isClosed) {
        if (screenWidth < 80.0) {
          // Stage 1: Centered title in closed card
          _paintContainerTitleCentered(canvas, rect, node.title, resolvedStyle, 1.0, fontScale);
        } else {
          // Stage 2: Approach Zone (Title fades out, internal dashed border + tag + inside preview fade in transformed to node bounds)
          final double t = ((screenWidth - 80.0) / (180.0 - 80.0)).clamp(0.0, 1.0);
          _paintContainerTitleCentered(canvas, rect, node.title, resolvedStyle, 1.0 - t, fontScale);

          canvas.save();
          canvas.scale(sx, sy);
          if (containerBgColor != null) {
            _bgPaint.color = containerBgColor.withValues(alpha: containerBgColor.a * t);
            canvas.drawRRect(internalRRect, _bgPaint);
          }
          _paintContainerInsidePreview(canvas, node, internalRect, internalRRect, t);
          _borderPaint
            ..color = (containerBorderColor ?? const Color(0xFF64B5F6)).withValues(alpha: 0.85 * t)
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(resolvedStyle.strokeWidth.toDouble(), 2.0);
          _drawDashedRRect(canvas, internalRRect, _borderPaint, 16.0, 10.0);
          _paintContainerTopLeftTag(canvas, internalRect, 1.0, containerBaseColor ?? const Color(0xFF64B5F6), opacity: t);
          canvas.restore();
        }
      } else {
        // Stage 3: Open Container — dashed border + background + inside preview + top-left tag in internal coordinates, transformed to node bounds
        canvas.save();
        canvas.scale(sx, sy);
        if (containerBgColor != null) {
          _bgPaint.color = containerBgColor;
          canvas.drawRRect(internalRRect, _bgPaint);
        }
        _paintContainerInsidePreview(canvas, node, internalRect, internalRRect, 1.0);
        _borderPaint
          ..color = containerBorderColor ?? const Color(0xFF64B5F6).withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = math.max(resolvedStyle.strokeWidth.toDouble(), 2.0);
        _drawDashedRRect(canvas, internalRRect, _borderPaint, 16.0, 10.0);
        _paintContainerTopLeftTag(canvas, internalRect, 1.0, containerBaseColor ?? const Color(0xFF64B5F6), opacity: 1.0);
        canvas.restore();
      }
    } else {
      _paintText(canvas, entry, rect, resolvedStyle);
      _paintMetadataSphere(canvas, node, rect, fontScale);
      _paintExpandToggle(canvas, entry, rect, resolvedStyle, fontScale);
    }

    if (node is! DrawingUiNode && isInteractableNode) {
      final hasMetadataSphere =
          node is InfoUiNode &&
          (node.tags.isNotEmpty || node.comments.isNotEmpty);
      _paintResizeHandles(
        canvas,
        node.id,
        rect,
        resolvedStyle,
        fontScale,
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

    final toggleSpace = expandToggleSpace(
      entry.viewState.isExpandedNotifier.value,
      scale,
    );
    final badgeHeight = entry.node is TaskUiNode
        ? taskBadgeHeight(scale)
        : 0.0;

    final yCenter =
        rect.bottom - style.padding - badgeHeight - toggleSpace / 2;

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

  void _drawDashedRRect(Canvas canvas, RRect rrect, Paint paint, [double dashWidth = 12.0, double dashSpace = 8.0]) =>
      drawDashedRRect(canvas, rrect, paint, dashWidth, dashSpace);

  void _paintContainerTitleCentered(
    Canvas canvas,
    Rect rect,
    String title,
    NodeStyle style,
    double opacity,
    double scale,
  ) {
    if (opacity <= 0.0) return;
    final tp = TextPainter(
      text: TextSpan(
        text: title.toUpperCase(),
        style: TextStyle(
          fontSize: (style.fontSize * 0.85).clamp(10.0, 14.0),
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: Color(style.textColor).withValues(alpha: opacity),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width - 16 * scale);

    tp.paint(
      canvas,
      Offset(
        rect.left + (rect.width - tp.width) / 2,
        rect.top + (rect.height - tp.height) / 2,
      ),
    );
    tp.dispose();
  }

  Color _getContainerBaseColor(ContainerUiNode node, NodeStyle resolvedStyle) =>
      getContainerBaseColor(node, resolvedStyle);

  void _paintContainerTopLeftTag(Canvas canvas, Rect rect, double scale, Color containerColor, {double opacity = 1.0}) =>
      paintContainerTopLeftTag(canvas, rect, scale, containerColor, opacity: opacity);

  void _paintOutsideNodes(Canvas canvas) {
    if (activeScope is! ContainerViewportScope) return;
    final scope = activeScope as ContainerViewportScope;
    final parentContainer = nodeLookup[scope.containerId] as ContainerUiNode?;
    final containerPos = parentContainer?.position ?? scope.containerPositionInParent;
    final effectiveOuterSize = (scope.outerSize.width > 0 && scope.outerSize.height > 0)
        ? scope.outerSize
        : (parentContainer != null
            ? const DefaultNodeLayoutStrategy().calculateSize(parentContainer).size
            : const Size(300.0, 180.0));
    final aspectRatio = effectiveOuterSize.height / (effectiveOuterSize.width > 0 ? effectiveOuterSize.width : 1.0);
    final internalW = 1600.0;
    final internalH = 1600.0 * aspectRatio;
    final sx = internalW / (effectiveOuterSize.width > 0 ? effectiveOuterSize.width : 1.0);
    final sy = internalH / (effectiveOuterSize.height > 0 ? effectiveOuterSize.height : 1.0);

    canvas.save();
    canvas.scale(sx, sy);
    canvas.translate(-containerPos.dx, -containerPos.dy);

    final parentScopeContainerId = scope.parentScope is ContainerViewportScope
        ? (scope.parentScope as ContainerViewportScope).containerId
        : null;

    final outsideNodes = nodeLookup.values.where((n) =>
        n.id != scope.containerId &&
        n.parentContainerId == parentScopeContainerId
    ).toList();

    for (final outsideNode in outsideNodes) {
      _paintChildNodePreview(canvas, outsideNode);
    }

    canvas.restore();
  }

  void _paintContainerInsidePreview(
    Canvas canvas,
    ContainerUiNode containerNode,
    Rect internalRect,
    RRect internalRRect,
    double opacity,
  ) {
    if (opacity <= 0.0) return;
    final children = nodeLookup.values
        .where((n) => n.parentContainerId == containerNode.id)
        .toList();
    if (children.isEmpty) return;

    final double clampedOpacity = opacity.clamp(0.0, 1.0);
    canvas.save();
    canvas.clipRRect(internalRRect);
    canvas.saveLayer(
      internalRect,
      Paint()..color = Color.fromARGB((255 * clampedOpacity).round(), 255, 255, 255),
    );

    // 1. Draw relations between inside children
    if (relations != null) {
      final childIds = children.map((c) => c.id).toSet();
      for (final rel in relations!) {
        if (childIds.contains(rel.fromNodeId) && childIds.contains(rel.toNodeId)) {
          _paintChildRelation(canvas, rel);
        }
      }
    }

    // 2. Draw child nodes
    for (final child in children) {
      _paintChildNodePreview(canvas, child);
    }

    canvas.restore();
    canvas.restore();
  }

  void _paintChildRelation(Canvas canvas, UiRelation rel) {
    final fromNode = nodeLookup[rel.fromNodeId];
    final toNode = nodeLookup[rel.toNodeId];
    if (fromNode == null || toNode == null) return;

    final resolved = RelationStyleStrategy.resolveStyle(rel);
    final cached = relationEngine?.cache[rel.id];

    final strokeColor = resolved.strokeColor != 0
        ? Color(resolved.strokeColor)
        : const Color(0xFF64B5F6);
    final strokeWidth = resolved.strokeWidth > 0 ? resolved.strokeWidth.toDouble() : 2.0;

    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (cached != null && cached.pathPoints.isNotEmpty) {
      final path = Path();
      path.moveTo(cached.pathPoints.first.x, cached.pathPoints.first.y);
      for (int i = 1; i < cached.pathPoints.length; i++) {
        path.lineTo(cached.pathPoints[i].x, cached.pathPoints[i].y);
      }
      if (resolved.strokePattern == 'dashed' || resolved.strokePattern == 'dotted') {
        final dashLen = resolved.strokePattern == 'dashed' ? 8.0 : 2.0;
        final gapLen = resolved.strokePattern == 'dashed' ? 6.0 : 4.0;
        final dashedPath = Path();
        for (final metric in path.computeMetrics()) {
          double distance = 0.0;
          while (distance < metric.length) {
            final len = math.min(dashLen, metric.length - distance);
            dashedPath.addPath(metric.extractPath(distance, distance + len), Offset.zero);
            distance += dashLen + gapLen;
          }
        }
        canvas.drawPath(dashedPath, paint);
      } else {
        canvas.drawPath(path, paint);
      }
    } else {
      final fromCenter = fromNode.position + Offset(
        (fromNode.size.width > 0 ? fromNode.size.width : 100.0) / 2,
        (fromNode.size.height > 0 ? fromNode.size.height : 80.0) / 2,
      );
      final toCenter = toNode.position + Offset(
        (toNode.size.width > 0 ? toNode.size.width : 100.0) / 2,
        (toNode.size.height > 0 ? toNode.size.height : 80.0) / 2,
      );
      canvas.drawLine(fromCenter, toCenter, paint);
    }
  }

  void _paintChildNodePreview(Canvas canvas, UiNode child) {
    final childPos = child.position;
    final childStyle = child.resolvedStyle ?? NodeStyleStrategy.resolveStyle(child);
    final childSize = (child.size.width > 0 && child.size.height > 0)
        ? child.size
        : const DefaultNodeLayoutStrategy().calculateSize(child).size;
    final childRect = Rect.fromLTWH(childPos.dx, childPos.dy, childSize.width, childSize.height);
    final childRRect = _buildRRect(childRect, childStyle, 0.0, 1.0);

    if (child is DrawingUiNode) {
      _paintDrawingPaths(
        canvas,
        child,
        childPos,
        childStyle,
        childSize,
        isHighlighted: false,
        isEditing: false,
        isSelected: false,
        isHovered: false,
      );
    } else if (child is ContainerUiNode) {
      final childBaseColor = _getContainerBaseColor(child, childStyle);
      final hsl = HSLColor.fromColor(childBaseColor);
      final childBorderColor = hsl
          .withSaturation((hsl.saturation * 1.35).clamp(0.0, 1.0))
          .withLightness(hsl.lightness.clamp(0.4, 0.75))
          .toColor()
          .withValues(alpha: 0.85);
      final childBgColor = hsl
          .withSaturation((hsl.saturation * 1.1).clamp(0.0, 1.0))
          .toColor()
          .withValues(alpha: 0.08);

      canvas.drawRRect(childRRect, Paint()..color = childBgColor);
      final childBorderPaint = Paint()
        ..color = childBorderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(childStyle.strokeWidth.toDouble(), 2.0);
      _drawDashedRRect(canvas, childRRect, childBorderPaint, 16.0, 10.0);
      _paintContainerTitleCentered(canvas, childRect, child.title, childStyle, 1.0, 1.0);
    } else {
      // Background & Shadow
      if (childStyle.shadowBlur > 0) {
        final shadowOffset = Offset(childStyle.shadowOffsetX, childStyle.shadowOffsetY);
        final shadowRRect = _buildRRect(childRect.shift(shadowOffset), childStyle, 0.0, 1.0);
        canvas.drawRRect(
          shadowRRect,
          Paint()
            ..color = Color(childStyle.shadowColor)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, childStyle.shadowBlur),
        );
      }
      canvas.drawRRect(childRRect, Paint()..color = Color(childStyle.bgColor));
      canvas.drawRRect(
        childRRect,
        Paint()
          ..color = Color(childStyle.strokeColor)
          ..style = PaintingStyle.stroke
          ..strokeWidth = childStyle.strokeWidth.toDouble(),
      );

      // Text Content
      if (child.content.text.isNotEmpty) {
        _paintPreviewText(canvas, child.content, childRect, childStyle);
      }
    }
  }

  void _paintPreviewText(
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

    final yCenter = rect.top + style.padding + (rect.height - style.padding * 2) / 2;
    double y = yCenter - totalTextHeight / 2;

    for (final tp in painters) {
      tp.paint(canvas, Offset(rect.left + style.padding, y));
      y += tp.height;
      tp.dispose();
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasNodesPainter oldDelegate) {
    return dirtyNodeIds.isNotEmpty ||
        positionOnlyNodeIds.isNotEmpty ||
        cameraScale != oldDelegate.cameraScale ||
        activeScope != oldDelegate.activeScope ||
        entries != oldDelegate.entries ||
        relations != oldDelegate.relations ||
        _entriesGeneration != _cachedGeneration;
  }
}

class _ContainerBoundaryPainter extends CustomPainter {
  final ContainerUiNode? container;
  final Size effectiveSize;

  _ContainerBoundaryPainter({
    required this.container,
    required this.effectiveSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final aspectRatio = effectiveSize.width > 0
        ? effectiveSize.height / effectiveSize.width
        : (1200.0 / 1600.0);
    final internalSize = Size(1600.0, 1600.0 * aspectRatio);
    final rect = Rect.fromLTWH(0, 0, internalSize.width, internalSize.height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(16.0));

    final baseColor = container != null && container!.resolvedStyle != null
        ? getContainerBaseColor(container!, container!.resolvedStyle!)
        : const Color(0xFF64B5F6);

    final hsl = HSLColor.fromColor(baseColor);
    final borderColor = hsl
        .withSaturation((hsl.saturation * 1.35).clamp(0.0, 1.0))
        .withLightness(hsl.lightness.clamp(0.4, 0.75))
        .toColor()
        .withValues(alpha: 0.85);
    final bgColor = hsl
        .withSaturation((hsl.saturation * 1.1).clamp(0.0, 1.0))
        .toColor()
        .withValues(alpha: 0.08);

    // Background tint
    canvas.drawRRect(rrect, Paint()..color = bgColor..style = PaintingStyle.fill);

    // Dashed border (crisp 2px)
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    drawDashedRRect(canvas, rrect, borderPaint, 16.0, 10.0);

    paintContainerTopLeftTag(canvas, rect, 1.0, baseColor, opacity: 1.0);
  }

  @override
  bool shouldRepaint(covariant _ContainerBoundaryPainter oldDelegate) {
    return oldDelegate.container != container;
  }
}

