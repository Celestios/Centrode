import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import '../../models/models.dart';
import '../viewport_state.dart';
import 'node_layout_strategy.dart';

/// Encapsulates the zoom-in and zoom-out transition logic for container nodes.
///
/// Extracted from [ViewportController.checkContainerZoomTransition] to follow OCP:
/// new container-like types or transition behaviors require a new strategy,
/// not modification of the viewport controller.
abstract class ContainerZoomStrategy {
  const ContainerZoomStrategy();

  /// Checks whether a closed container should be opened (zoom-in transition).
  ///
  /// Returns the target transform matrix if the transition should fire,
  /// or null if no transition is needed.
  ContainerZoomResult? checkZoomIn({
    required ContainerUiNode node,
    required Map<RawUuid, UiNode> nodeLookup,
    required double currentScale,
    required Size viewportSize,
    required Offset cursorCanvas,
    required NodeLayoutStrategy layoutStrategy,
  });

  /// Checks whether an open container should be closed (zoom-out transition).
  ///
  /// Returns the target transform matrix if the transition should fire,
  /// or null if no transition is needed.
  ContainerZoomResult? checkZoomOut({
    required ContainerUiNode node,
    required ContainerViewportScope currentScope,
    required double currentScale,
    required Size viewportSize,
    required Offset cursorCanvas,
    required NodeLayoutStrategy layoutStrategy,
  });
}

/// Result of a container zoom transition check.
class ContainerZoomResult {
  final Matrix4 targetMatrix;
  final Size nodeSize;
  final double containerInitScale;
  final Size internalSize;

  const ContainerZoomResult({
    required this.targetMatrix,
    required this.nodeSize,
    required this.containerInitScale,
    required this.internalSize,
  });
}

/// Default implementation of [ContainerZoomStrategy].
///
/// Thresholds:
/// - Zoom-in:  container rendered at >= 180px width on screen, cursor within 60px inflated rect
/// - Zoom-out: current scale <= exitScale (containerInitScale * 0.65), cursor within 200px inflated internal rect
class DefaultContainerZoomStrategy extends ContainerZoomStrategy {
  const DefaultContainerZoomStrategy();

  static const double _zoomInScreenWidthThreshold = 180.0;
  static const double _zoomInHitAreaInflation = 60.0;
  static const double _zoomOutHitAreaInflation = 200.0;
  static const double _internalWidth = 1600.0;
  static const double _margin = 80.0;

  @override
  ContainerZoomResult? checkZoomIn({
    required ContainerUiNode node,
    required Map<RawUuid, UiNode> nodeLookup,
    required double currentScale,
    required Size viewportSize,
    required Offset cursorCanvas,
    required NodeLayoutStrategy layoutStrategy,
  }) {
    if (!node.isClosed) return null;

    final worldPos = node.getAbsoluteWorldPosition(nodeLookup);
    final nodeSize = layoutStrategy.calculateSize(node).size;
    final containerRect = Rect.fromLTWH(
      worldPos.dx,
      worldPos.dy,
      nodeSize.width,
      nodeSize.height,
    );
    final screenWidth = nodeSize.width * currentScale;

    if (screenWidth < _zoomInScreenWidthThreshold) return null;
    if (!containerRect.inflate(_zoomInHitAreaInflation).contains(cursorCanvas)) {
      return null;
    }

    final availW = viewportSize.width - 2 * _margin;
    final availH = viewportSize.height - 2 * _margin;
    final nodeCenter = worldPos + Offset(nodeSize.width / 2.0, nodeSize.height / 2.0);
    final targetScale = math.min(availW / nodeSize.width, availH / nodeSize.height)
        .clamp(currentScale, 50.0);
    final targetDx = (viewportSize.width / 2.0) - (nodeCenter.dx * targetScale);
    final targetDy = (viewportSize.height / 2.0) - (nodeCenter.dy * targetScale);
    final targetMatrix = Matrix4.identity()
      ..translateByDouble(targetDx, targetDy, 0, 1)
      ..scaleByDouble(targetScale, targetScale, targetScale, 1);

    final aspectRatio = nodeSize.height / (nodeSize.width > 0 ? nodeSize.width : 1.0);
    final internalW = _internalWidth;
    final internalH = _internalWidth * aspectRatio;
    final containerInitScale = math.min(availW / internalW, availH / internalH).clamp(0.2, 5.0);

    return ContainerZoomResult(
      targetMatrix: targetMatrix,
      nodeSize: nodeSize,
      containerInitScale: containerInitScale,
      internalSize: Size(internalW, internalH),
    );
  }

  @override
  ContainerZoomResult? checkZoomOut({
    required ContainerUiNode node,
    required ContainerViewportScope currentScope,
    required double currentScale,
    required Size viewportSize,
    required Offset cursorCanvas,
    required NodeLayoutStrategy layoutStrategy,
  }) {
    if (currentScope.containerId != node.id) return null;

    final exitScale = currentScope.exitScale;
    if (currentScale > exitScale) return null;

    final nodeSize = (currentScope.outerSize.width > 0 && currentScope.outerSize.height > 0)
        ? currentScope.outerSize
        : layoutStrategy.calculateSize(node).size;
    final aspectRatio = nodeSize.height / (nodeSize.width > 0 ? nodeSize.width : 1.0);
    final internalW = _internalWidth;
    final internalH = _internalWidth * aspectRatio;
    final containerRect = Rect.fromLTWH(0, 0, internalW, internalH);

    if (!containerRect.inflate(_zoomOutHitAreaInflation).contains(cursorCanvas)) return null;

    final availW = viewportSize.width - 2 * _margin;
    final availH = viewportSize.height - 2 * _margin;
    final targetScale = math.min(availW / nodeSize.width, availH / nodeSize.height)
        .clamp(1.0, 50.0);
    final nodeCenter = node.position + Offset(nodeSize.width / 2.0, nodeSize.height / 2.0);
    final targetDx = (viewportSize.width / 2.0) - (nodeCenter.dx * targetScale);
    final targetDy = (viewportSize.height / 2.0) - (nodeCenter.dy * targetScale);
    final targetMatrix = Matrix4.identity()
      ..translateByDouble(targetDx, targetDy, 0, 1)
      ..scaleByDouble(targetScale, targetScale, targetScale, 1);

    return ContainerZoomResult(
      targetMatrix: targetMatrix,
      nodeSize: nodeSize,
      containerInitScale: currentScope.containerInitScale,
      internalSize: Size(internalW, internalH),
    );
  }
}
