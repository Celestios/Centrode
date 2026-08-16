import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import '../../../../../presentation/theme/app_theme_manager.dart';
import '../../../models/models.dart';
import '../../../presentation/strategies/node_layout_strategy.dart';
import '../../../store/relation_engine_state.dart';
import '../utils/container_paint_utils.dart';
import '../widgets/node_visual_constants.dart';
import 'node_render_entry.dart';
import 'nodes/shape_node_renderer.dart';
import 'nodes/node_selection_renderer.dart';
import 'nodes/text_node_renderer.dart';
import 'nodes/container_node_renderer.dart';

class CanvasNodesPainter extends CustomPainter {
  List<NodeRenderEntry> entries;
  final Set<RawUuid> dirtyNodeIds;
  final Set<RawUuid> positionOnlyNodeIds;
  final double cameraScale;
  final ViewportScope activeScope;
  final Map<RawUuid, UiNode> nodeLookup;
  final Iterable<UiRelation>? relations;
  final RelationEngineState? relationEngine;
  RawUuid? hoveredNodeId;
  Color selectionColor =
      AppThemeManager.instance.currentTheme.canvasAccentColor;
  Color hoverColor = const Color(0xFF64B5F6);

  final Map<RawUuid, ui.Picture> nodeCache = {};
  ui.Picture? cachedPicture;
  final int _entriesGeneration = 0;
  int _cachedGeneration = -1;

  final NodeSelectionRenderer selectionRenderer = NodeSelectionRenderer();
  final Paint _bgPaint = Paint();
  final Paint _borderPaint = Paint();

  CanvasNodesPainter({
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
          cachedPicture != null && _cachedGeneration == _entriesGeneration;
      if (cacheValid) {
        canvas.drawPicture(cachedPicture!);
        return;
      }
    }

    // Ensure all nodes have cached pictures (lazy-record on first paint)
    for (final entry in entries) {
      final nodeId = entry.node.id;
      activeIds.add(nodeId);
      if (!nodeCache.containsKey(nodeId)) {
        nodeCache[nodeId] = _recordNodePicture(entry);
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
        canvas.drawPicture(nodeCache[entry.node.id]!);
        canvas.restore();
      }
      positionOnlyNodeIds.clear();
      cachedPicture?.dispose();
      cachedPicture = null;
      _cachedGeneration = -1;
      return;
    }

    // Case 3: Content changed — re-record dirty nodes, then composite
    for (final entry in entries) {
      final nodeId = entry.node.id;
      if (dirtyNodeIds.contains(nodeId)) {
        nodeCache[nodeId]?.dispose();
        nodeCache[nodeId] = _recordNodePicture(entry);
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
      canvas.drawPicture(nodeCache[entry.node.id]!);
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
      recordCanvas.drawPicture(nodeCache[entry.node.id]!);
      recordCanvas.restore();
    }
    cachedPicture?.dispose();
    cachedPicture = recorder.endRecording();
    _cachedGeneration = _entriesGeneration;

    for (final id in nodeCache.keys.toList()) {
      if (!activeIds.contains(id)) {
        nodeCache[id]?.dispose();
        nodeCache.remove(id);
      }
    }
    selectionRenderer.cleanupHandles(activeIds);
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

    final double fontScale =
        NodeVisualConstants.fontScale(resolvedStyle.fontSize);
    final bool isHovered = entry.node.id == hoveredNodeId;
    final bool isHighlighted =
        entry.isSelected || entry.isEditing || isHovered;
    final double stroke = (entry.isEditing
            ? 1.0
            : entry.isSelected
                ? 1.0
                : 0.5) *
        fontScale;
    final double gap = 1.5 * fontScale;
    final screenWidth = w * cameraScale;
    final isStage2ApproachContainer =
        isContainer && node.isClosed && screenWidth >= 80.0;

    final rrect = ShapeNodeRenderer.buildRRect(rect, resolvedStyle, 0.0, fontScale);

    Color? containerBaseColor;
    Color? containerBorderColor;
    Color? containerBgColor;
    if (isContainer) {
      containerBaseColor = getContainerBaseColor(node, resolvedStyle);
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
        selectionRenderer.paintShadow(
          canvas,
          rect,
          rrect,
          resolvedStyle,
          isEditing: entry.isEditing,
          isSelected: entry.isSelected,
          fontScale: fontScale,
        );

        if (isStage2ApproachContainer) {
          final double t =
              ((screenWidth - 80.0) / (180.0 - 80.0)).clamp(0.0, 1.0);
          _bgPaint.color = Color(resolvedStyle.bgColor)
              .withValues(alpha: (1.0 - t).clamp(0.0, 1.0));
          canvas.drawRRect(rrect, _bgPaint);
          _borderPaint
            ..color = Color(resolvedStyle.strokeColor)
                .withValues(alpha: (1.0 - t).clamp(0.0, 1.0))
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
      selectionRenderer.paintHighlightBorder(
        canvas,
        rect,
        resolvedStyle,
        isEditing: entry.isEditing,
        isSelected: entry.isSelected,
        stroke: stroke,
        gap: gap,
        fontScale: fontScale,
        selectionColor: selectionColor,
        hoverColor: hoverColor,
      );
    }

    if (node is DrawingUiNode) {
      ShapeNodeRenderer.paintDrawingPaths(
        canvas,
        node,
        Offset.zero,
        resolvedStyle,
        Size(w, h),
        isHighlighted: isHighlighted,
        isEditing: entry.isEditing,
        isSelected: entry.isSelected,
        isHovered: isHovered,
        selectionColor: selectionColor,
        hoverColor: hoverColor,
      );
    } else if (node is ContainerUiNode) {
      ContainerNodeRenderer.paintContainerCard(
        canvas: canvas,
        node: node,
        resolvedStyle: resolvedStyle,
        rect: rect,
        w: w,
        h: h,
        screenWidth: screenWidth,
        fontScale: fontScale,
        containerBaseColor: containerBaseColor,
        containerBorderColor: containerBorderColor,
        containerBgColor: containerBgColor,
        nodeLookup: nodeLookup,
        relations: relations,
        relationEngine: relationEngine,
      );
    } else {
      TextNodeRenderer.paintText(canvas, entry, rect, resolvedStyle);
      TextNodeRenderer.paintMetadataSphere(canvas, node, rect, fontScale);
      TextNodeRenderer.paintExpandToggle(
        canvas,
        entry,
        rect,
        resolvedStyle,
        fontScale,
      );
    }

    if (node is! DrawingUiNode && isInteractableNode) {
      final hasMetadataSphere = node is InfoUiNode &&
          (node.tags.isNotEmpty || node.comments.isNotEmpty);
      selectionRenderer.paintResizeHandles(
        canvas,
        node.id,
        rect,
        resolvedStyle,
        fontScale,
        hasMetadataSphere,
      );
    }
  }

  void _paintOutsideNodes(Canvas canvas) {
    if (activeScope is! ContainerViewportScope) return;
    final scope = activeScope as ContainerViewportScope;
    final parentContainer =
        nodeLookup[scope.containerId] as ContainerUiNode?;
    final containerPos =
        parentContainer?.position ?? scope.containerPositionInParent;
    final effectiveOuterSize =
        (scope.outerSize.width > 0 && scope.outerSize.height > 0)
            ? scope.outerSize
            : (parentContainer != null
                ? const DefaultNodeLayoutStrategy()
                    .calculateSize(parentContainer)
                    .size
                : const Size(300.0, 180.0));
    final aspectRatio = effectiveOuterSize.height /
        (effectiveOuterSize.width > 0 ? effectiveOuterSize.width : 1.0);
    final internalW = 1600.0;
    final internalH = 1600.0 * aspectRatio;
    final sx = internalW /
        (effectiveOuterSize.width > 0 ? effectiveOuterSize.width : 1.0);
    final sy = internalH /
        (effectiveOuterSize.height > 0 ? effectiveOuterSize.height : 1.0);

    canvas.save();
    canvas.scale(sx, sy);
    canvas.translate(-containerPos.dx, -containerPos.dy);

    final parentScopeContainerId = scope.parentScope is ContainerViewportScope
        ? (scope.parentScope as ContainerViewportScope).containerId
        : null;

    final outsideNodes = nodeLookup.values
        .where((n) =>
            n.id != scope.containerId &&
            n.parentContainerId == parentScopeContainerId)
        .toList();

    for (final outsideNode in outsideNodes) {
      ContainerNodeRenderer.paintChildNodePreview(
        canvas: canvas,
        child: outsideNode,
      );
    }

    canvas.restore();
  }

  void disposeCaches() {
    for (final picture in nodeCache.values) {
      picture.dispose();
    }
    nodeCache.clear();
    cachedPicture?.dispose();
    cachedPicture = null;
    selectionRenderer.clearHandles();
  }

  @override
  bool shouldRepaint(covariant CanvasNodesPainter oldDelegate) {
    return dirtyNodeIds.isNotEmpty ||
        positionOnlyNodeIds.isNotEmpty ||
        cameraScale != oldDelegate.cameraScale ||
        activeScope != oldDelegate.activeScope ||
        entries != oldDelegate.entries ||
        relations != oldDelegate.relations ||
        _entriesGeneration != _cachedGeneration;
  }
}
