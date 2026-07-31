import 'dart:ui';
import 'package:centrode/shared/logging.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'config.dart';
import 'package:centrode/shared/utils/geometry.dart';
import '../models/models.dart';
import '../models/port.dart';
import 'interaction_context.dart';
import 'base_interaction_state.dart';
import 'z_order_utils.dart';

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
  final RawUuid? hitNodeId;
  final RawUuid? hitEntityId;
  final ResizeEdge? draggedEdge;
  final RawUuid? relationId;
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
  static final Logger _hitTestLog = Logger('HitTestResolver');

  const HitTestResolver();

  PointerHitResult resolve(
    Offset pCanvas,
    InteractionContext ctx,
    bool isDoubleTap,
  ) {
    final nodeIds = resolveZOrderToNodeIds(ctx.zOrder, ctx.nodeViewStates);

    final selectedEntities = ctx.getSelectedEntities();
    _hitTestLog.fine(
      'resolve pCanvas=(${pCanvas.dx}, ${pCanvas.dy}) selected=${selectedEntities.length}',
    );

    final result =
        _resolveRelationTips(pCanvas, ctx, selectedEntities) ??
        _resolveMetadataSphere(pCanvas, ctx, nodeIds) ??
        _resolvePorts(pCanvas, ctx, nodeIds) ??
        _resolveNodeHits(pCanvas, ctx, nodeIds) ??
        _resolveRelationLabel(pCanvas, ctx) ??
        const PointerHitResult(type: HitTestType.none);

    if (result.type != HitTestType.none) {
      _hitTestLog.fine(
        'resolve hit: ${result.type} entity=${result.hitNodeId ?? result.hitEntityId ?? result.relationId}',
      );
    }

    return result;
  }

  PointerHitResult? _resolveRelationTips(
    Offset pCanvas,
    InteractionContext ctx,
    Set<RawUuid> selectedEntities,
  ) {
    final cache = ctx.relationEngine.cache;

    for (final id in selectedEntities) {
      final cached = cache[id];
      if (cached == null || cached.pathPoints.isEmpty) continue;

      final startHandle = Offset(
        cached.startHandlePos.x,
        cached.startHandlePos.y,
      );
      final endHandle = Offset(cached.endHandlePos.x, cached.endHandlePos.y);

      if ((pCanvas - startHandle).distance <
          AppConfig.interaction.relationTipHitDistance) {
        return PointerHitResult(
          type: HitTestType.relationTipStart,
          relationId: id,
          originalPosition: startHandle,
        );
      } else if ((pCanvas - endHandle).distance <
          AppConfig.interaction.relationTipHitDistance) {
        return PointerHitResult(
          type: HitTestType.relationTipEnd,
          relationId: id,
          originalPosition: endHandle,
        );
      }
    }
    return null;
  }

  PointerHitResult? _resolveMetadataSphere(
    Offset pCanvas,
    InteractionContext ctx,
    List<RawUuid> nodeIds,
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
    RawUuid nodeId,
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
    List<RawUuid> nodeIds,
  ) {
    final hoveredId = ctx.hoveredNodeId;
    if (hoveredId != null) {
      final vs = ctx.nodeViewStates[hoveredId];
      if (vs != null && vs.sizeNotifier.value != Size.zero) {
        for (final port in vs.ports.allPorts) {
          if ((pCanvas - port.position).distance <
              AppConfig.port.hitRadius * vs.currentScale) {
            return PointerHitResult(
              type: HitTestType.port,
              hitNodeId: hoveredId,
              hitPort: port,
            );
          }
        }
      }
      return null;
    }

    for (final nodeId in nodeIds) {
      final vs = ctx.nodeViewStates[nodeId];
      if (vs == null || vs.sizeNotifier.value == Size.zero) continue;

      for (final port in vs.ports.allPorts) {
        if ((pCanvas - port.position).distance <
            AppConfig.port.hitRadius * vs.currentScale) {
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
    List<RawUuid> nodeIds,
  ) {
    for (final nodeId in nodeIds) {
      final vs = ctx.nodeViewStates[nodeId];
      if (vs == null || vs.sizeNotifier.value == Size.zero) continue;

      final node = ctx.getNode(nodeId);
      if (node == null) continue;
      if (vs.lineCount > AppConfig.node.collapsedLineLimit &&
          vs.getExpandToggleHitbox(node).contains(pCanvas)) {
        return PointerHitResult(
          type: HitTestType.expandToggle,
          hitNodeId: nodeId,
        );
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
  ) {
    final cache = ctx.relationEngine.cache;

    for (final rel in ctx.getRelations()) {
      final cached = cache[rel.id];
      if (cached == null) continue;

      final labelPos = Offset(cached.labelPosition.x, cached.labelPosition.y);

      if (Rect.fromCenter(
        center: labelPos,
        width: AppConfig.interaction.relationLabelHitArea.width,
        height: AppConfig.interaction.relationLabelHitArea.height,
      ).contains(pCanvas)) {
        return PointerHitResult(
          type: HitTestType.relationLabel,
          hitEntityId: rel.id,
        );
      }

      final points = cached.pathPoints.map((p) => Offset(p.x, p.y)).toList();

      if (isPointNearPolyline(
        pCanvas,
        points,
        AppConfig.interaction.relationLineHitThreshold,
      )) {
        return PointerHitResult(
          type: HitTestType.relationLabel,
          hitEntityId: rel.id,
        );
      }
    }
    return null;
  }

  static bool _isPointNearDrawing(
    Offset pCanvas,
    DrawingUiNode node,
    Offset nodePos,
  ) {
    final double threshold = node.brushThickness * 0.5 + 24.0;

    for (final rawPoints in node.parsedPaths) {
      final points = rawPoints
          .map((pt) => Offset(pt.dx + nodePos.dx, pt.dy + nodePos.dy))
          .toList();
      if (points.isEmpty) continue;

      if (points.length == 1) {
        if ((pCanvas - points[0]).distance < threshold) {
          return true;
        }
        continue;
      }

      for (int i = 0; i < points.length - 1; i++) {
        if (distanceToSegment(pCanvas, points[i], points[i + 1]) <= threshold) {
          return true;
        }
      }
    }
    return false;
  }
}
