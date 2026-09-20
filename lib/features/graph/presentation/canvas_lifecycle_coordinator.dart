import 'dart:async';
import 'package:flutter/widgets.dart';

import 'package:centrode/shared/logging.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import '../models/left_panel_type.dart';
import '../store/graph_data_query_controller.dart';
import '../store/command_queue_processor.dart';
import '../engine/interaction_facade.dart';
import '../engine/interaction_engine.dart';
import '../engine/drawing_interceptor.dart';
import 'node_render_state.dart';
import 'viewport_state.dart';
import 'workspace_tabs_controller.dart';

enum CanvasLifecyclePhase {
  uninitialized,
  awaitingDataOrLayout,
  restoredFromSaved,
  autoFramed,
  disposed,
}

class CanvasLifecycleCoordinator with ChangeNotifier {
  final Logger _log = Logger('CanvasLifecycleCoordinator');
  final TabSession _session;
  final GraphDataQueryController _queryController;
  final CommandQueueProcessor _commandProcessor;
  final NodeRenderState _renderState;
  final Future<void> Function(List<RawUuid> nodeIds, List<RawUuid> relationIds)?
  _onSaveTemplateRequest;

  late final ViewportController _viewportController;
  late final CanvasInteractionEnvironment _interactionEnv;
  late final InteractionController _interactionController;
  late final DrawingGestureInterceptor _drawingInterceptor;

  final ValueNotifier<CanvasLifecyclePhase> phaseNotifier = ValueNotifier(
    CanvasLifecyclePhase.awaitingDataOrLayout,
  );

  Size _lastKnownSize = Size.zero;
  TickerProvider? _vsync;
  bool _isDisposed = false;

  CanvasLifecycleCoordinator({
    required TabSession session,
    required GraphDataQueryController queryController,
    required CommandQueueProcessor commandProcessor,
    required NodeRenderState renderState,
    Future<void> Function(List<RawUuid> nodeIds, List<RawUuid> relationIds)?
    onSaveTemplateRequest,
  }) : _session = session,
       _queryController = queryController,
       _commandProcessor = commandProcessor,
       _renderState = renderState,
       _onSaveTemplateRequest = onSaveTemplateRequest {
    _initCoordinator();
  }

  void _initCoordinator() {
    _viewportController = ViewportController(_queryController);
    _viewportController.onContainerOpenStateChanged =
        (id, newPosition, newSize, isClosed) {
          _renderState.hoveredNodeNotifier.value = null;
          _renderState.hoveredPortNotifier.value = null;
          _commandProcessor.nodeMutations.setContainerClosed(id, isClosed);
          _queryController.relationEngine.onNodeMoved(id);
        };

    _interactionEnv = CanvasInteractionEnvironment(
      queryController: _queryController,
      commandProcessor: _commandProcessor,
      renderState: _renderState,
      viewportController: _viewportController,
      getScale: () =>
          _viewportController.transformController.value.getMaxScaleOnAxis(),
      boundSession: _session,
      onSaveTemplate: _onSaveTemplateRequest != null
          ? (nodeIds, relationIds) =>
                _onSaveTemplateRequest(nodeIds, relationIds)
          : null,
    );

    _interactionController = InteractionController(
      transformController: _viewportController.transformController,
      environment: _interactionEnv,
    );

    _drawingInterceptor = DrawingGestureInterceptor(
      session: _session,
      viewportController: _viewportController,
    );
    _interactionController.registerInterceptor(_drawingInterceptor);

    _session.viewportController = _viewportController;

    _renderState.dragState.addListener(_onDragStateChanged);
    _session.toolModeNotifier.addListener(_onToolModeChanged);
    _queryController.isLoadingNotifier.addListener(_onLoadingChanged);

    _evaluateFramingOrRestoration();
  }

  void attachVsync(TickerProvider vsync) {
    _vsync = vsync;
    _viewportController.vsync = vsync;
  }

  void detachVsync() {
    _vsync = null;
    _viewportController.vsync = null;
  }

  void updateViewportDimensions(Size size) {
    if (_isDisposed || size == Size.zero) return;
    _lastKnownSize = size;
    _viewportController.updateViewportSize(size);
    _evaluateFramingOrRestoration();
  }

  void _onLoadingChanged() {
    _evaluateFramingOrRestoration();
  }

  void _evaluateFramingOrRestoration() {
    if (phaseNotifier.value != CanvasLifecyclePhase.awaitingDataOrLayout) {
      return;
    }
    if (_queryController.isLoading || _lastKnownSize == Size.zero) {
      return;
    }

    final saved = _commandProcessor.getSavedViewportState();
    if (saved != null && saved.zoomLevel > 0) {
      final targetMatrix = Matrix4.identity()
        ..translateByDouble(saved.xOffset, saved.yOffset, 0, 1)
        ..scaleByDouble(saved.zoomLevel, saved.zoomLevel, saved.zoomLevel, 1);

      if (_vsync != null) {
        _viewportController.animateViewportTo(targetMatrix, _vsync!);
      } else {
        _viewportController.transformController.value = targetMatrix;
      }
      _viewportController.recalculateElasticMargins();
      phaseNotifier.value = CanvasLifecyclePhase.restoredFromSaved;
      _log.info(
        'Restored viewport: offset(${saved.xOffset}, ${saved.yOffset}), zoom ${saved.zoomLevel}',
      );
    } else {
      _viewportController.focusOnBounds(_queryController.canvasBounds);
      _viewportController.recalculateElasticMargins();
      phaseNotifier.value = CanvasLifecyclePhase.autoFramed;
      _log.info('Auto-framed viewport to canvas bounds.');
    }

    _queryController.isLoadingNotifier.removeListener(_onLoadingChanged);
  }

  void _onDragStateChanged() {
    _viewportController.isGestureSuppressed =
        _renderState.dragState.draggingNodes.isNotEmpty;
  }

  void _onToolModeChanged() {
    final mode = _session.toolModeNotifier.value;
    if (mode != 'draw' &&
        _renderState.activeLeftPanelNotifier.value == LeftPanelType.draw) {
      _renderState.activeLeftPanelNotifier.value = LeftPanelType.none;
    }
  }

  Future<void> flushPendingSave() async {
    await _session.saveViewportState();
  }

  ViewportController get viewportController => _viewportController;
  CanvasInteractionEnvironment get interactionEnv => _interactionEnv;
  InteractionController get interactionController => _interactionController;
  DrawingGestureInterceptor get drawingInterceptor => _drawingInterceptor;
  CanvasLifecyclePhase get phase => phaseNotifier.value;

  @override
  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    phaseNotifier.value = CanvasLifecyclePhase.disposed;

    unawaited(_session.saveViewportState());
    if (_session.viewportController == _viewportController) {
      _session.viewportController = null;
    }

    _queryController.isLoadingNotifier.removeListener(_onLoadingChanged);
    _renderState.dragState.removeListener(_onDragStateChanged);
    _session.toolModeNotifier.removeListener(_onToolModeChanged);

    _interactionController.unregisterInterceptor(_drawingInterceptor);
    _drawingInterceptor.dispose();
    _interactionController.dispose();
    _viewportController.dispose();
    phaseNotifier.dispose();

    super.dispose();
  }
}
