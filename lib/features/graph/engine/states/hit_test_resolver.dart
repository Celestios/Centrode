import 'dart:ui';
import '../config.dart';
import '../../presentation/strategies/relation_layout_strategy.dart';
import '../../presentation/routing/relation_layout_context.dart';
import '../../models/models.dart';
import '../interaction_context.dart';
import '../base_interaction_state.dart';

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
}

class PointerHitResult {
  final HitTestType type;
  final String? hitNodeId;
  final String? hitEntityId;
  final ResizeEdge? draggedEdge;
  final String? relationId;
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
    this.originalPosition,
    this.grabOffsetX,
    this.initialLeft,
    this.initialWidth,
  });
}

class HitTestResolver {
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

    return _resolveRelationTips(pCanvas, ctx, layoutContext, selectedEntities) ??
        _resolveMetadataSphere(pCanvas, ctx, nodeIds) ??
        _resolveNodeHits(pCanvas, ctx, nodeIds) ??
        _resolveRelationLabel(pCanvas, ctx, nodeIds, layoutContext) ??
        const PointerHitResult(type: HitTestType.none);
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

  PointerHitResult? _resolveNodeHits(
    Offset pCanvas,
    InteractionContext ctx,
    List<String> nodeIds,
  ) {
    for (final nodeId in nodeIds) {
      final vs = ctx.nodeViewStates[nodeId];
      if (vs == null || vs.sizeNotifier.value == Size.zero) continue;

      if (vs.lineCount > AppConfig.node.collapsedLineLimit &&
          vs.expandToggleHitbox.contains(pCanvas)) {
        return PointerHitResult(type: HitTestType.expandToggle, hitNodeId: nodeId);
      }

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
}
