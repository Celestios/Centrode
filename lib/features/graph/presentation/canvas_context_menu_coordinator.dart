import 'dart:ui';
import 'package:centrode/shared/logging.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import '../engine/hit_test_resolver.dart';
import '../engine/interaction_context.dart';
import '../store/graph_data_query_controller.dart';
import 'node_render_state.dart';
import 'viewport_state.dart';
import 'workspace_tabs_controller.dart';

/// Pure data resolution emitted to the Tier 1 presentation layer.
class ContextMenuResolution {
  final Offset screenPosition;
  final Rect? targetNodeRect;
  final Rect? avoidRect;
  final RawUuid? hitNodeId;

  const ContextMenuResolution({
    required this.screenPosition,
    this.targetNodeRect,
    this.avoidRect,
    this.hitNodeId,
  });
}

/// Headless Tier 2 coordinator responsible for right-click coordinate projection,
/// spatial hit-testing, entity selection synchronization, and emitting menu resolutions.
/// Completely decoupled from BuildContext and UI widgets.
class CanvasContextMenuCoordinator {
  final Logger _log = Logger('CanvasContextMenuCoordinator');
  final GraphDataQueryController _queryController;
  final NodeRenderState _renderState;
  final ViewportController _viewportController;
  final TabSession _session;
  final InteractionContext _interactionContext;
  final void Function(ContextMenuResolution resolution) _onContextMenuResolved;

  CanvasContextMenuCoordinator({
    required GraphDataQueryController queryController,
    required NodeRenderState renderState,
    required ViewportController viewportController,
    required TabSession session,
    required InteractionContext interactionContext,
    required void Function(ContextMenuResolution resolution)
    onContextMenuResolved,
  }) : _queryController = queryController,
       _renderState = renderState,
       _viewportController = viewportController,
       _session = session,
       _interactionContext = interactionContext,
       _onContextMenuResolved = onContextMenuResolved;

  void handleContextMenuRequest(Offset screenPosition) {
    if (_renderState.activeEditId != null) {
      _log.fine('Context menu suppressed: active editing in progress.');
      return;
    }
    if (_renderState.dragState.draggingNodes.isNotEmpty) {
      _log.fine('Context menu suppressed: dragging nodes.');
      return;
    }
    if (_session.toolModeNotifier.value == 'draw') {
      _log.fine('Context menu suppressed: active drawing mode.');
      return;
    }

    final canvasPos = _viewportController.screenToCanvas(screenPosition);
    final hitResult = HitTestResolver().resolve(
      canvasPos,
      _interactionContext,
      false,
    );

    Rect? targetNodeRect;

    if (hitResult.hitNodeId != null) {
      final hitId = hitResult.hitNodeId!;
      if (!_renderState.selectedEntities.contains(hitId)) {
        _renderState.selectEntities([hitId]);
      }
      final node = _queryController.nodeLookup[hitId];
      final vs = _renderState.viewStates[hitId];
      final worldPos =
          node?.getAbsoluteWorldPosition(_queryController.nodeLookup) ??
          (vs?.positionNotifier.value ?? Offset.zero);
      final size = Size(
        vs?.dragWidthNotifier.value ??
            vs?.sizeNotifier.value.width ??
            node?.size.width ??
            120.0,
        vs?.sizeNotifier.value.height ?? node?.size.height ?? 60.0,
      );
      final worldRect = Rect.fromLTWH(
        worldPos.dx,
        worldPos.dy,
        size.width,
        size.height,
      );
      targetNodeRect = _viewportController.projectCanvasRectToScreen(worldRect);
    } else {
      _renderState.selectEntity(null);
    }

    final avoidRect = _renderState.floatingToolbarRectNotifier.value;

    _onContextMenuResolved(
      ContextMenuResolution(
        screenPosition: screenPosition,
        targetNodeRect: targetNodeRect,
        avoidRect: avoidRect,
        hitNodeId: hitResult.hitNodeId,
      ),
    );
  }

  void dispose() {}
}
