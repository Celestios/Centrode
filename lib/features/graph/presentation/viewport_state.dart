import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:centrode/shared/logging.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import '../engine/config.dart';
import '../store/graph_data_query.dart';
import '../models/models.dart';
import 'strategies/node_layout_strategy.dart';
import 'strategies/container_zoom_strategy.dart';
import 'viewport_transform_math.dart';

class ViewportStateGrid {
  final Rect visibleRect;
  final double scale;
  final Size viewportSize;

  const ViewportStateGrid({
    required this.visibleRect,
    required this.scale,
    required this.viewportSize,
  });
}

extension RectExtension on Rect {
  bool containsRect(Rect other) =>
      left <= other.left &&
      right >= other.right &&
      top <= other.top &&
      bottom >= other.bottom;
}

class ViewportController {
  final Logger _log = Logger('ViewportController');
  final GraphDataQuery _dataController;
  final ContainerZoomStrategy _zoomStrategy;
  final TransformationController transformController =
      TransformationController();

  final ValueNotifier<ViewportScope> activeScopeNotifier =
      ValueNotifier(const RootViewportScope());

  final ValueNotifier<bool> isTransitioningNotifier = ValueNotifier(false);

  bool isGestureSuppressed = false;

  Rect _overscanBuffer = Rect.zero;
  Size _currentViewportSize = Size.zero;
  bool _isDisposed = false;

  AnimationController? _viewportAnimationController;

  final ValueNotifier<Set<RawUuid>> visibleNodeIds = ValueNotifier({});

  final ValueNotifier<ViewportStateGrid> viewportStateNotifier = ValueNotifier(
    ViewportStateGrid(
      visibleRect: Rect.zero,
      scale: 1.0,
      viewportSize: Size.zero,
    ),
  );

  final ValueNotifier<EdgeInsets> elasticMargins = ValueNotifier(
    EdgeInsets.zero,
  );

  StreamSubscription<GraphEntityUpdate>? _updateSubscription;

  ViewportController(
    this._dataController, {
    ContainerZoomStrategy? zoomStrategy,
  }) : _zoomStrategy = zoomStrategy ?? const DefaultContainerZoomStrategy() {
    _log.info(
      'Initializing ViewportController and tracking transform mutations.',
    );
    transformController.addListener(_handleTransform);
    _updateSubscription = _dataController.onEntityUpdate.listen(
      _handleEntityUpdate,
    );
  }

  void _onCanvasBoundsChanged() {
    recalculateElasticMargins();
  }

  void _handleEntityUpdate(GraphEntityUpdate update) {
    switch (update.type) {
      case GraphUpdateType.boundary:
        _onCanvasBoundsChanged();
        break;
      case GraphUpdateType.position:
      case GraphUpdateType.size:
      case GraphUpdateType.nodeAdded:
      case GraphUpdateType.nodeDeleted:
      case GraphUpdateType.reset:
        if (_overscanBuffer != Rect.zero) {
          updateVisibleSet(_overscanBuffer);
        }
        break;
      default:
        break;
    }
  }

  void updateViewportSize(Size size) {
    if (size == _currentViewportSize) return;

    _log.fine('Viewport dimensions updated: $size');
    _currentViewportSize = size;
    _recalculate();
    recalculateElasticMargins();
  }

  void focusOnBounds(BoundingBox bounds) {
    if (_currentViewportSize == Size.zero) return;

    final offset = ViewportTransformMath.computeCenterOnBounds(
      bounds,
      _currentViewportSize,
    );

    _log.info('Translating Camera Matrix to center bounds');
    transformController.value = Matrix4.identity()
      ..translateByDouble(offset.dx, offset.dy, 0, 1);
    recalculateElasticMargins();
  }

  void centerOnCanvasPoint(Offset canvasPoint) {
    if (_currentViewportSize == Size.zero) return;

    final currentScale =
        transformController.value.getMaxScaleOnAxis();

    _log.finest(
      'Centering Camera Matrix on canvas point: $canvasPoint at scale $currentScale',
    );
    transformController.value = ViewportTransformMath.buildCenterOnPointMatrix(
      canvasPoint,
      _currentViewportSize,
      currentScale,
    );
  }

  void updateScale(double newScale) {
    if (_currentViewportSize == Size.zero) return;

    final canvasCenter = screenToCanvas(
      Offset(_currentViewportSize.width / 2, _currentViewportSize.height / 2),
    );

    transformController.value = ViewportTransformMath.buildScaleAtCenterMatrix(
      newScale,
      canvasCenter,
      _currentViewportSize,
    );
    recalculateElasticMargins();
  }

  Size get viewportSize => _currentViewportSize;

  Offset screenToCanvas(Offset screenPos) {
    return ViewportTransformMath.screenToCanvas(
      transformController.value,
      screenPos,
    );
  }

  void panViewport(Offset deltaScreen) {
    if (_currentViewportSize == Size.zero || deltaScreen == Offset.zero) return;

    transformController.value = ViewportTransformMath.buildPanMatrix(
      transformController.value,
      deltaScreen,
    );

    recalculateElasticMargins();
  }

  TickerProvider? vsync;
  Offset? _lastMouseScreenPos;
  int _lastTransitionTimestamp = 0;
  void Function(RawUuid id, Offset newPosition, Size newSize, bool isClosed)?
      onContainerOpenStateChanged;

  void updateMouseScreenPos(Offset? screenPos) {
    _lastMouseScreenPos = screenPos;
  }

  void _handleTransform() {
    _recalculate();
  }

  void _recalculate() {
    if (_currentViewportSize == Size.zero) return;

    final viewport = ViewportTransformMath.calculateCanvasViewport(
      transformController.value,
      _currentViewportSize,
    );
    if (viewport == Rect.zero) return;

    final scale = transformController.value.getMaxScaleOnAxis();
    viewportStateNotifier.value = ViewportStateGrid(
      visibleRect: viewport,
      scale: scale,
      viewportSize: _currentViewportSize,
    );

    if (!_overscanBuffer.containsRect(viewport)) {
      final inflatedBuffer = viewport.inflate(
        viewport.width * AppConfig.canvas.overscanRatio,
      );
      updateVisibleSet(inflatedBuffer);
    }

    checkContainerZoomTransition(_lastMouseScreenPos);
  }

  double get currentMinScale {
    final scope = activeScopeNotifier.value;
    if (scope is ContainerViewportScope) {
      return scope.minScale;
    }
    return AppConfig.canvas.minScale;
  }

  double get currentMaxScale {
    final scope = activeScopeNotifier.value;
    if (scope is ContainerViewportScope) {
      return scope.maxScale;
    }
    return AppConfig.canvas.maxScale;
  }

  void checkContainerZoomTransition(Offset? mouseScreenPos) {
    if (_currentViewportSize == Size.zero) return;
    if (isGestureSuppressed) return;
    if (_viewportAnimationController != null &&
        _viewportAnimationController!.isAnimating) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastTransitionTimestamp < 800) return;

    final scale = transformController.value.getMaxScaleOnAxis();
    final cursorScreen = mouseScreenPos ??
        Offset(_currentViewportSize.width / 2, _currentViewportSize.height / 2);
    final cursorCanvas = screenToCanvas(cursorScreen);

    for (final node in _dataController.nodeLookup.values) {
      if (node is! ContainerUiNode) continue;

      final currentScope = activeScopeNotifier.value;

      if (node.isClosed) {
        final result = _zoomStrategy.checkZoomIn(
          node: node,
          nodeLookup: _dataController.nodeLookup,
          currentScale: scale,
          viewportSize: _currentViewportSize,
          cursorCanvas: cursorCanvas,
          layoutStrategy: const DefaultNodeLayoutStrategy(),
        );
        if (result == null) continue;

        _lastTransitionTimestamp = DateTime.now().millisecondsSinceEpoch;
        final savedTransform = transformController.value.clone();
        final newScope = ContainerViewportScope(
          parentScope: currentScope,
          containerId: node.id,
          containerPositionInParent: node.position,
          outerSize: result.nodeSize,
          savedParentTransform: savedTransform,
          containerInitScale: result.containerInitScale,
        );

        void applyOpenState() {
          onContainerOpenStateChanged?.call(
              node.id, node.position, node.size, false);
          activeScopeNotifier.value = newScope;
          transformController.value =
              ViewportTransformMath.buildContainerOpenMatrix(
            result.internalSize,
            result.containerInitScale,
            _currentViewportSize,
          );
          _lastTransitionTimestamp = DateTime.now().millisecondsSinceEpoch;
          recalculateVisibleSet();
        }

        if (vsync != null) {
          animateViewportTo(
            result.targetMatrix,
            vsync!,
            duration: const Duration(milliseconds: 700),
            onComplete: applyOpenState,
          );
        } else {
          applyOpenState();
        }
        break;
      } else if (currentScope is ContainerViewportScope &&
          currentScope.containerId == node.id) {
        final result = _zoomStrategy.checkZoomOut(
          node: node,
          currentScope: currentScope,
          currentScale: scale,
          viewportSize: _currentViewportSize,
          cursorCanvas: cursorCanvas,
          layoutStrategy: const DefaultNodeLayoutStrategy(),
        );
        if (result == null) continue;

        _lastTransitionTimestamp = DateTime.now().millisecondsSinceEpoch;
        final Matrix4 parentTransform = currentScope.savedParentTransform;

        activeScopeNotifier.value =
            currentScope.parentScope ?? const RootViewportScope();

        void applyExitState() {
          transformController.value = parentTransform;
          onContainerOpenStateChanged?.call(
              node.id, node.position, node.size, true);
          _lastTransitionTimestamp = DateTime.now().millisecondsSinceEpoch;
          recalculateVisibleSet();
        }

        transformController.value = result.targetMatrix;

        if (vsync != null) {
          animateViewportTo(
            parentTransform,
            vsync!,
            duration: const Duration(milliseconds: 700),
            onComplete: applyExitState,
          );
        } else {
          applyExitState();
        }
        break;
      }
    }
  }

  void openContainer(
    ContainerUiNode node, {
    bool animate = true,
    void Function(double)? onProgress,
    VoidCallback? onComplete,
  }) {
    if (!node.isClosed) return;
    final currentScope = activeScopeNotifier.value;
    final scale = transformController.value.getMaxScaleOnAxis();
    final cursorCanvas = screenToCanvas(
        Offset(_currentViewportSize.width / 2, _currentViewportSize.height / 2));

    final result = _zoomStrategy.checkZoomIn(
      node: node,
      nodeLookup: _dataController.nodeLookup,
      currentScale: scale,
      viewportSize: _currentViewportSize,
      cursorCanvas: cursorCanvas,
      layoutStrategy: const DefaultNodeLayoutStrategy(),
    ) ?? ViewportTransformMath.calculateContainerZoomResult(
      node,
      _currentViewportSize,
      _dataController.nodeLookup,
    );

    _lastTransitionTimestamp = DateTime.now().millisecondsSinceEpoch;
    final savedTransform = transformController.value.clone();
    final newScope = ContainerViewportScope(
      parentScope: currentScope,
      containerId: node.id,
      containerPositionInParent: node.position,
      outerSize: result.nodeSize,
      savedParentTransform: savedTransform,
      containerInitScale: result.containerInitScale,
    );

    void applyOpenState() {
      activeScopeNotifier.value = newScope;
      transformController.value =
          ViewportTransformMath.buildContainerOpenMatrix(
        result.internalSize,
        result.containerInitScale,
        _currentViewportSize,
      );
      onContainerOpenStateChanged?.call(node.id, node.position, node.size, false);
      _lastTransitionTimestamp = DateTime.now().millisecondsSinceEpoch;
      recalculateVisibleSet();
      onComplete?.call();
    }

    if (animate && vsync != null) {
      animateViewportTo(
        result.targetMatrix,
        vsync!,
        duration: const Duration(milliseconds: 600),
        onProgress: onProgress,
        onComplete: applyOpenState,
      );
    } else {
      applyOpenState();
    }
  }

  void closeContainer(
    ContainerUiNode node, {
    bool animate = true,
    void Function(double)? onProgress,
    VoidCallback? onComplete,
  }) {
    final currentScope = activeScopeNotifier.value;
    if (currentScope is! ContainerViewportScope ||
        currentScope.containerId != node.id) {
      return;
    }

    final parentScope = currentScope.parentScope ?? const RootViewportScope();
    final Matrix4 parentTransform = currentScope.savedParentTransform;

    const layoutStrategy = DefaultNodeLayoutStrategy();
    final nodeSize = (currentScope.outerSize.width > 0 &&
            currentScope.outerSize.height > 0)
        ? currentScope.outerSize
        : layoutStrategy.calculateSize(node).size;
    final nodeCenter = currentScope.containerPositionInParent +
        Offset(nodeSize.width / 2.0, nodeSize.height / 2.0);
    final targetScale = ViewportTransformMath.computeContainerExitScale(
      nodeSize,
      _currentViewportSize,
    );
    final startZoomedMatrix =
        ViewportTransformMath.buildContainerExitStartMatrix(
      nodeCenter,
      targetScale,
      _currentViewportSize,
    );

    _lastTransitionTimestamp = DateTime.now().millisecondsSinceEpoch;
    activeScopeNotifier.value = parentScope;

    void applyExitState() {
      transformController.value = parentTransform;
      onContainerOpenStateChanged?.call(node.id, node.position, node.size, true);
      _lastTransitionTimestamp = DateTime.now().millisecondsSinceEpoch;
      recalculateVisibleSet();
      onComplete?.call();
    }

    if (animate && vsync != null) {
      transformController.value = startZoomedMatrix;
      animateViewportTo(
        parentTransform,
        vsync!,
        duration: const Duration(milliseconds: 600),
        onProgress: onProgress,
        onComplete: applyExitState,
      );
    } else {
      applyExitState();
    }
  }

  Rect get contentBounds {
    final bounds = _dataController.canvasBounds;
    final padding = AppConfig.canvas.boundaryMargin;
    final initialPadding = AppConfig.canvas.initialBoundaryMargin;

    return ViewportTransformMath.computeContentBounds(bounds, padding, initialPadding);
  }

  void recalculateElasticMargins() {
    if (_currentViewportSize == Size.zero) return;

    final cb = contentBounds;

    final calculatedMargins = ViewportTransformMath.computeElasticMargins(
      cb,
      _currentViewportSize,
    );

    if (elasticMargins.value != calculatedMargins) {
      elasticMargins.value = calculatedMargins;
    }
  }

  void recalculateVisibleSet() {
    final currentViewport = ViewportTransformMath.calculateCanvasViewport(
      transformController.value,
      _currentViewportSize,
    );
    if (currentViewport == Rect.zero) return;
    final inflatedBuffer = currentViewport.inflate(
      currentViewport.width * AppConfig.canvas.overscanRatio,
    );
    updateVisibleSet(inflatedBuffer);
  }

  void updateVisibleSet(Rect bufferRect) {
    _overscanBuffer = bufferRect;
    final currentOverscan = bufferRect;

    Future(() {
      if (_isDisposed) return;
      final scale = transformController.value.getMaxScaleOnAxis();
      final activeScope = activeScopeNotifier.value;
      final activeContainerId =
          activeScope is ContainerViewportScope ? activeScope.containerId : null;
      final newVisible = _dataController.spatialIndex.queryViewport(
        currentOverscan,
        scale,
        _dataController.nodeLookup,
        activeContainerId,
      );
      if (_isDisposed) return;
      if (_overscanBuffer == currentOverscan) {
        _log.fine(
          'updateVisibleSet: scale=$scale, Spatial index returned ${newVisible.length} visible nodes.',
        );
        if (!setEquals(visibleNodeIds.value, newVisible)) {
          visibleNodeIds.value = newVisible;
        }
      }
    });
  }

  void animateViewportTo(
    Matrix4 targetMatrix,
    TickerProvider vsync, {
    Duration duration = const Duration(milliseconds: 350),
    void Function(double)? onProgress,
    VoidCallback? onComplete,
  }) {
    _viewportAnimationController?.stop();
    _viewportAnimationController?.dispose();

    isTransitioningNotifier.value = true;

    final startScale = transformController.value.getMaxScaleOnAxis();
    final targetScale = targetMatrix.getMaxScaleOnAxis();
    final startTranslation = transformController.value.getTranslation();
    final targetTranslation = targetMatrix.getTranslation();

    _viewportAnimationController = AnimationController(
      vsync: vsync,
      duration: duration,
    );

    _viewportAnimationController!.addListener(() {
      final t = Curves.easeInOutCubic
          .transform(_viewportAnimationController!.value);
      final interpScale = startScale + (targetScale - startScale) * t;
      final interpTranslation = Offset.lerp(
        Offset(startTranslation.x, startTranslation.y),
        Offset(targetTranslation.x, targetTranslation.y),
        t,
      )!;

      transformController.value = Matrix4.identity()
        ..translateByDouble(interpTranslation.dx, interpTranslation.dy, 0, 1)
        ..scaleByDouble(interpScale, interpScale, interpScale, 1);

      onProgress?.call(t);

      if (_viewportAnimationController!.value == 1.0) {
        onComplete?.call();
        isTransitioningNotifier.value = false;
        recalculateElasticMargins();
        final controllerToDispose = _viewportAnimationController;
        Future.microtask(() {
          if (controllerToDispose == _viewportAnimationController) {
            _viewportAnimationController?.dispose();
            _viewportAnimationController = null;
          }
        });
      }
    });
    _viewportAnimationController!.forward();
  }

  Offset projectCanvasToScreen(Offset canvasPos) {
    return ViewportTransformMath.projectCanvasToScreen(
      transformController.value,
      canvasPos,
    );
  }

  Rect projectCanvasRectToScreen(Rect canvasRect) {
    return ViewportTransformMath.projectCanvasRectToScreen(
      transformController.value,
      canvasRect,
    );
  }

  void dispose() {
    _log.fine('Disposing ViewportController.');
    _isDisposed = true;
    _viewportAnimationController?.stop();
    _viewportAnimationController?.dispose();
    transformController.removeListener(_handleTransform);
    _updateSubscription?.cancel();
    transformController.dispose();
    viewportStateNotifier.dispose();
    activeScopeNotifier.dispose();
    isTransitioningNotifier.dispose();
    visibleNodeIds.dispose();
    elasticMargins.dispose();
  }
}
