import 'dart:ui';
import 'package:mycelium/shared/logging.dart';
import 'config.dart';
import '../presentation/strategies/relation_layout_strategy.dart';
import '../presentation/routing/relation_layout_context.dart';
import '../models/models.dart';
import '../models/port.dart';
import 'interaction_context.dart';
import 'base_interaction_state.dart';

enum HitTestType {
  none,
  rightClick,
  relationTipStart,
  relationTipEnd,
  metadataSphere,
  expandToggle,
  resizeRight,
  resizeLeft,
  body,
  relationLabel,
  port,
}

class PointerHitResult {
  final HitTestType type;
  final String? hitNodeId;
  final String? hitEntityId;
  final ResizeEdge? draggedEdge;
  final String? relationId;
  final Port? hitPort;
  final Offset? originalPosition;
  final double? grabOffsetX;
  final double? initialLeft;
  final double? initialWidth;

  const PointerHitResult({
    required this.type,
    this.hitNodeId,
    this.hitEntityId,
    this.draggedEdge,
    this.relationId,
    this.hitPort,
    this.originalPosition,
    this.grabOffsetX,
    this.initialLeft,
    this.initialWidth,
  });
}

class HitTestResolver {
  final Logger _hitTestLog = Logger('HitTestResolver');

  PointerHitResult resolve(Offset pCanvas, InteractionContext ctx, bool isDoubleTap) {
    final layoutContext = RelationLayoutContext(
      nodeViewStates: ctx.nodeViewStates,
      relations: ctx.getRelations().toList(),
      pathCache: ctx.relationPathCache,
    );

    final nodeIds = ctx.zOrder.reversed.toList();
    if (nodeIds.isEmpty) {
      nodeIds.addAll(ctx.nodeViewStates.keys.toList().reversed);
    }

    final selectedEntities = ctx.getSelectedEntities();
    _hitTestLog.fine('resolve pCanvas=(${pCanvas.dx}, ${pCanvas.dy}) selected=${selectedEntities.length}');

    final result = _resolveRelationTips(pCanvas, ctx, layoutContext, selectedEntities) ??
        _resolveMetadataSphere(pCanvas, ctx, nodeIds) ??
        _resolvePorts(pCanvas, ctx, nodeIds) ??
        _resolveNodeHits(pCanvas, ctx, nodeIds) ??
        _resolveRelationLabel(pCanvas, ctx, nodeIds, layoutContext) ??
        const PointerHitResult(type: HitTestType.none);

    if (result.type != HitTestType.none) {
      _hitTestLog.fine('resolve hit: ${result.type} entity=${result.hitNodeId ?? result.hitEntityId ?? result.relationId}');
    }

    return result;
  }

  PointerHitResult? _resolveRelationTips(
    Offset pCanvas,
    InteractionContext ctx,
    RelationLayoutContext layoutContext,
    Set<String> selectedEntities,
  ) {
    for (final id in selectedEntities) {
      UiRelation? rel;
      for (final r in ctx.getRelations()) {
        if (r.id == id) {
          rel = r;
          break;
        }
      }
      if (rel == null) continue;

      final from = ctx.nodeViewStates[rel.fromNodeId];
      final to = ctx.nodeViewStates[rel.toNodeId];
      if (from == null || to == null) continue;

      final layoutStrategy = RelationLayoutStrategy.fromType(
        rel.layout?.strategyType,
      );
      final (handleStart, handleEnd) = layoutStrategy.resolveTipHandles(
        rel,
        from,
        to,
        layoutContext,
      );

      if ((pCanvas - handleStart).distance <
          AppConfig.interaction.relationTipHitDistance) {
        return PointerHitResult(
          type: HitTestType.relationTipStart,
          relationId: rel.id,
          originalPosition: handleStart,
        );
      } else if ((pCanvas - handleEnd).distance <
          AppConfig.interaction.relationTipHitDistance) {
        return PointerHitResult(
          type: HitTestType.relationTipEnd,
          relationId: rel.id,
          originalPosition: handleEnd,
        );
      }
    }
    return null;
  }

  PointerHitResult? _resolveMetadataSphere(
    Offset pCanvas,
    InteractionContext ctx,
    List<String> nodeIds,
  ) {
    for (final nodeId in nodeIds) {
      final vs = ctx.nodeViewStates[nodeId];
      if (vs == null || vs.sizeNotifier.value == Size.zero) continue;
      final node = ctx.getNode(nodeId);
      if (node is InfoUiNode &&
          (node.tags.isNotEmpty || node.comments.isNotEmpty)) {
        final nodeRect = vs.rect;
        final center = Offset(
          nodeRect.right - AppConfig.node.metadataSphereOffsetFromRight,
          nodeRect.top + AppConfig.node.metadataSphereOffsetFromTop,
        );
        if ((pCanvas - center).distance <
            AppConfig.node.metadataSphereHitboxRadius) {
          return PointerHitResult(
            type: HitTestType.metadataSphere,
            hitNodeId: nodeId,
          );
        }
      }
    }
    return null;
  }

  static bool isMetadataSphereHit(
    Offset pCanvas,
    InteractionContext ctx,
    String nodeId,
  ) {
    final vs = ctx.nodeViewStates[nodeId];
    if (vs == null || vs.sizeNotifier.value == Size.zero) return false;
    final node = ctx.getNode(nodeId);
    if (node is! InfoUiNode) return false;
    if (node.tags.isEmpty && node.comments.isEmpty) return false;
    final nodeRect = vs.rect;
    final center = Offset(
      nodeRect.right - AppConfig.node.metadataSphereOffsetFromRight,
      nodeRect.top + AppConfig.node.metadataSphereOffsetFromTop,
    );
    return (pCanvas - center).distance <
        AppConfig.node.metadataSphereHitboxRadius;
  }

  PointerHitResult? _resolvePorts(
    Offset pCanvas,
    InteractionContext ctx,
    List<String> nodeIds,
  ) {
    for (final nodeId in nodeIds) {
      final vs = ctx.nodeViewStates[nodeId];
      if (vs == null || vs.sizeNotifier.value == Size.zero) continue;

      for (final port in vs.ports.allPorts) {
        if ((pCanvas - port.position).distance < AppConfig.port.hitRadius) {
          return PointerHitResult(
            type: HitTestType.port,
            hitNodeId: nodeId,
            hitPort: port,
          );
        }
      }
    }
    return null;
  }

  PointerHitResult? _resolveNodeHits(
    Offset pCanvas,
    InteractionContext ctx,
    List<String> nodeIds,
  ) {
    for (final nodeId in nodeIds) {
      final vs = ctx.nodeViewStates[nodeId];
      if (vs == null || vs.sizeNotifier.value == Size.zero) continue;

      final node = ctx.getNode(nodeId);
      if (node == null) continue;
      if (vs.lineCount > AppConfig.node.collapsedLineLimit &&
          vs.getExpandToggleHitbox(node).contains(pCanvas)) {
        return PointerHitResult(type: HitTestType.expandToggle, hitNodeId: nodeId);
      }

      if (node is! DrawingUiNode) {
        if (vs.rightResizeHitbox.contains(pCanvas)) {
          return PointerHitResult(
            type: HitTestType.resizeRight,
            hitNodeId: nodeId,
            draggedEdge: ResizeEdge.right,
          );
        } else if (vs.leftResizeHitbox.contains(pCanvas)) {
          return PointerHitResult(
            type: HitTestType.resizeLeft,
            hitNodeId: nodeId,
            draggedEdge: ResizeEdge.left,
          );
        }
      }

      if (node is DrawingUiNode) {
        final nodePos = vs.positionNotifier.value;
        if (_isPointNearDrawing(pCanvas, node, nodePos)) {
          return PointerHitResult(type: HitTestType.body, hitNodeId: nodeId);
        }
      } else if (vs.rect.contains(pCanvas)) {
        return PointerHitResult(type: HitTestType.body, hitNodeId: nodeId);
      }
    }
    return null;
  }

  PointerHitResult? _resolveRelationLabel(
    Offset pCanvas,
    InteractionContext ctx,
    List<String> nodeIds,
    RelationLayoutContext layoutContext,
  ) {
    for (final rel in ctx.getRelations()) {
      final fVs = ctx.nodeViewStates[rel.fromNodeId];
      final tVs = ctx.nodeViewStates[rel.toNodeId];
      if (fVs == null || tVs == null) continue;

      final layoutStrategy = RelationLayoutStrategy.fromType(
        rel.layout?.strategyType,
      );
      final (start, end) = layoutStrategy.resolveEndpoints(rel, fVs, tVs);
      final mid = layoutStrategy.computeLabelPosition(
        start,
        end,
        fVs,
        tVs,
        rel,
        layoutContext,
      );

      if (Rect.fromCenter(
        center: mid,
        width: AppConfig.interaction.relationLabelHitArea.width,
        height: AppConfig.interaction.relationLabelHitArea.height,
      ).contains(pCanvas)) {
        return PointerHitResult(type: HitTestType.relationLabel, hitEntityId: rel.id);
      }

      if (layoutStrategy.isPointNear(
        pCanvas,
        start,
        end,
        fVs,
        tVs,
        rel,
        AppConfig.interaction.relationLineHitThreshold,
        layoutContext,
      )) {
        return PointerHitResult(type: HitTestType.relationLabel, hitEntityId: rel.id);
      }
    }
    return null;
  }

  static bool _isPointNearDrawing(Offset pCanvas, DrawingUiNode node, Offset nodePos) {
    final double threshold = node.brushThickness * 0.5 + 24.0;

    for (final rawPoints in node.parsedPaths) {
      final points = rawPoints.map((pt) => Offset(pt.dx + nodePos.dx, pt.dy + nodePos.dy)).toList();
      if (points.isEmpty) continue;

      if (points.length == 1) {
        if ((pCanvas - points[0]).distance < threshold) {
          return true;
        }
        continue;
      }

      for (int i = 0; i < points.length - 1; i++) {
        if (_isPointNearSegment(pCanvas, points[i], points[i + 1], threshold)) {
          return true;
        }
      }
    }
    return false;
  }

  static bool _isPointNearSegment(Offset p, Offset s1, Offset s2, double threshold) {
    final double l2 = (s1 - s2).distanceSquared;
    if (l2 == 0.0) return (p - s1).distance < threshold;

    final double t = (((p.dx - s1.dx) * (s2.dx - s1.dx) + (p.dy - s1.dy) * (s2.dy - s1.dy)) / l2).clamp(0.0, 1.0);
    final Offset projection = Offset(
      s1.dx + t * (s2.dx - s1.dx),
      s1.dy + t * (s2.dy - s1.dy),
    );
    return (p - projection).distance < threshold;
  }
}
