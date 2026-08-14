import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:centrode/shared/logging.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import '../engine/config.dart';
import '../../../src/rust/domain/base_models.dart' show BoundingBox;
import '../store/graph_data_query.dart';
import '../models/graph_node.dart';
import 'strategies/node_layout_strategy.dart';

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

/// Extension on Rect to check if one rect fully contains another.
/// Extracted from GraphCanvas for Viewport Math.
extension RectExtension on Rect {
  bool containsRect(Rect other) =>
      left <= other.left &&
      right >= other.right &&
      top <= other.top &&
      bottom >= other.bottom;
}

/// Sealed base class representing an active viewport coordinate scope.
sealed class ViewportScope {
  final ViewportScope? parentScope;
  final RawUuid? scopeId;
  const ViewportScope({this.parentScope, this.scopeId});

  int get depth => parentScope == null ? 0 : parentScope!.depth + 1;
}

/// Root canvas interaction mode.
class RootViewportScope extends ViewportScope {
  const RootViewportScope() : super(parentScope: null, scopeId: null);
}

/// Focused container interaction mode.
class ContainerViewportScope extends ViewportScope {
  final RawUuid containerId;
  final Offset containerPositionInParent;
  final Size outerSize;
  final Matrix4 savedParentTransform;
  final double containerInitScale;

  ContainerViewportScope({
    required ViewportScope parentScope,
    required this.containerId,
    required this.containerPositionInParent,
    required this.outerSize,
    required this.savedParentTransform,
    required this.containerInitScale,
  }) : super(parentScope: parentScope, scopeId: containerId);

  /// Dynamic min scale for this scope allowing zoom-out past exit threshold.
  double get minScale => (containerInitScale * 0.2).clamp(0.05, 1.0);

  /// Dynamic max scale for this scope allowing nested zooming.
  double get maxScale => math.max(containerInitScale * 10.0, 50.0);

  /// Zoom-out exit threshold in container space.
  double get exitScale => containerInitScale * 0.65;
}

/// Sole arbiter of coordinate transformations, hysteresis overscan buffering,
/// viewport boundary math, and visible node culling.
class ViewportController {
  final Logger _log = Logger('ViewportController');
  final GraphDataQuery _dataController;
  final TransformationController transformController =
      TransformationController();

  /// Tracks the active hierarchy scope (Root vs Container level).
  final ValueNotifier<ViewportScope> activeScopeNotifier =
      ValueNotifier(const RootViewportScope());

  /// When true, a scope transition is currently animating (interaction and zooming are disabled/decoupled).
  final ValueNotifier<bool> isTransitioningNotifier = ValueNotifier(false);

  /// When true, auto-zoom transitions are suppressed (e.g. during active drag or drawing gestures).
  bool isGestureSuppressed = false;

  Rect _overscanBuffer = Rect.zero;
  Size _currentViewportSize = Size.zero;
  bool _isDisposed = false;

  AnimationController? _viewportAnimationController;

  /// Notifier exposing the set of node IDs currently residing inside the overscan buffer.
  final ValueNotifier<Set<RawUuid>> visibleNodeIds = ValueNotifier({});

  final ValueNotifier<ViewportStateGrid> viewportStateNotifier = ValueNotifier(
    ViewportStateGrid(
      visibleRect: Rect.zero,
      scale: 1.0,
      viewportSize: Size.zero,
    ),
  );

  /// Notifier exposing the calculated elastic margins for CanvasInteractiveViewer.
  final ValueNotifier<EdgeInsets> elasticMargins = ValueNotifier(
    EdgeInsets.zero,
  );

  StreamSubscription<GraphEntityUpdate>? _updateSubscription;

  ViewportController(this._dataController) {
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

  /// Guarded dimension update injected by the Passive View's LayoutBuilder.
  /// Guarantees O(1) performance by rejecting identical subsequent layouts.
  void updateViewportSize(Size size) {
    if (size == _currentViewportSize) return;

    _log.fine('Viewport dimensions updated: $size');
    _currentViewportSize = size;
    _recalculate();
    recalculateElasticMargins();
  }

  /// Mutates the Transformation Matrix to center the camera on the provided bounds.
  void focusOnBounds(BoundingBox bounds) {
    if (_currentViewportSize == Size.zero) return;

    // Calculate the mathematical center of the nodes
    final double centerX = (bounds.minX + bounds.maxX) / 2.0;
    final double centerY = (bounds.minY + bounds.maxY) / 2.0;

    // Calculate translation required to place the center point in the middle of the InteractiveViewer widget
    final double dx = (_currentViewportSize.width / 2) - centerX;
    final double dy = (_currentViewportSize.height / 2) - centerY;

    _log.info('Translating Camera Matrix to center: ($centerX, $centerY)');
    transformController.value = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1);
    recalculateElasticMargins();
  }

  /// Mutates the Transformation Matrix to center the camera on a specific canvas coordinate.
  void centerOnCanvasPoint(Offset canvasPoint) {
    if (_currentViewportSize == Size.zero) return;

    final currentMatrix = transformController.value;
    final double currentScale = currentMatrix.getMaxScaleOnAxis();

    final double dx =
        (_currentViewportSize.width / 2) - (canvasPoint.dx * currentScale);
    final double dy =
        (_currentViewportSize.height / 2) - (canvasPoint.dy * currentScale);

    _log.finest(
      'Centering Camera Matrix on canvas point: $canvasPoint at scale $currentScale',
    );
    transformController.value = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(currentScale, currentScale, currentScale, 1);
  }

  /// Updates the zoom scale while keeping the current viewport center fixed.
  void updateScale(double newScale) {
    if (_currentViewportSize == Size.zero) return;

    final canvasCenter = screenToCanvas(
      Offset(_currentViewportSize.width / 2, _currentViewportSize.height / 2),
    );

    final dx = (_currentViewportSize.width / 2) - (canvasCenter.dx * newScale);
    final dy = (_currentViewportSize.height / 2) - (canvasCenter.dy * newScale);

    transformController.value = Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(newScale, newScale, newScale, 1);
    recalculateElasticMargins();
  }

  /// Gets the current logical viewport size.
  Size get viewportSize => _currentViewportSize;

  /// Converts a screen position to canvas coordinates based on the current transform matrix.
  Offset screenToCanvas(Offset screenPos) {
    final transform = transformController.value;
    if (transform.determinant() == 0.0) return screenPos;
    return MatrixUtils.transformPoint(Matrix4.inverted(transform), screenPos);
  }

  /// Translates the camera viewport matrix by a screen delta.
  void panViewport(Offset deltaScreen) {
    if (_currentViewportSize == Size.zero || deltaScreen == Offset.zero) return;
    final currentMatrix = transformController.value;
    final double currentScale = currentMatrix.getMaxScaleOnAxis();
    final translation = currentMatrix.getTranslation();

    transformController.value = Matrix4.identity()
      ..translateByDouble(
        translation.x + deltaScreen.dx,
        translation.y + deltaScreen.dy,
        0,
        1,
      )
      ..scaleByDouble(currentScale, currentScale, currentScale, 1);

    recalculateElasticMargins();
  }

  TickerProvider? vsync;
  Offset? _lastMouseScreenPos;
  int _lastTransitionTimestamp = 0;
  void Function(RawUuid id, Offset newPosition, Size newSize, bool isClosed)? onContainerOpenStateChanged;

  void updateMouseScreenPos(Offset? screenPos) {
    _lastMouseScreenPos = screenPos;
  }

  void _handleTransform() {
    _recalculate();
  }

  void _recalculate() {
    // Prevent math execution before initial layout constraints are fed
    if (_currentViewportSize == Size.zero) return;

    final viewport = _calculateCanvasViewport();
    if (viewport == Rect.zero) return;

    final scale = transformController.value.getMaxScaleOnAxis();
    viewportStateNotifier.value = ViewportStateGrid(
      visibleRect: viewport,
      scale: scale,
      viewportSize: _currentViewportSize,
    );

    // Viewport Hysteresis Logic
    if (!_overscanBuffer.containsRect(viewport)) {
      final inflatedBuffer = viewport.inflate(
        viewport.width * AppConfig.canvas.overscanRatio,
      );
      updateVisibleSet(inflatedBuffer);
    }

    checkContainerZoomTransition(_lastMouseScreenPos);
  }

  /// Gets the current minimum scale floor for the active scope.
  double get currentMinScale {
    final scope = activeScopeNotifier.value;
    if (scope is ContainerViewportScope) {
      return scope.minScale;
    }
    return AppConfig.canvas.minScale;
  }

  /// Gets the current maximum scale ceiling for the active scope.
  double get currentMaxScale {
    final scope = activeScopeNotifier.value;
    if (scope is ContainerViewportScope) {
      return scope.maxScale;
    }
    return AppConfig.canvas.maxScale;
  }

  /// Checks whether a container crossed the transition threshold during zoom-in or zoom-out and triggers the state toggle.
  void checkContainerZoomTransition(Offset? mouseScreenPos) {
    if (_currentViewportSize == Size.zero) return;
    if (isGestureSuppressed) return;
    if (_viewportAnimationController != null && _viewportAnimationController!.isAnimating) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastTransitionTimestamp < 800) return;

    final scale = transformController.value.getMaxScaleOnAxis();
    final cursorScreen = mouseScreenPos ?? Offset(_currentViewportSize.width / 2, _currentViewportSize.height / 2);
    final cursorCanvas = screenToCanvas(cursorScreen);

    for (final node in _dataController.nodeLookup.values) {
      if (node is! ContainerUiNode) continue;

      final worldPos = node.getAbsoluteWorldPosition(_dataController.nodeLookup);

      // 1. ZOOM IN: Closed container scaled past 180px threshold -> Optical fly-in takeover
      if (node.isClosed) {
        final nodeSize = const DefaultNodeLayoutStrategy().calculateSize(node).size;
        final containerRect = Rect.fromLTWH(worldPos.dx, worldPos.dy, nodeSize.width, nodeSize.height);
        final screenWidth = nodeSize.width * scale;

        if (screenWidth >= 180.0 && containerRect.inflate(60.0).contains(cursorCanvas)) {
          _lastTransitionTimestamp = DateTime.now().millisecondsSinceEpoch;
          final currentScope = activeScopeNotifier.value;
          final savedTransform = transformController.value.clone();

          final nodeCenter = worldPos + Offset(nodeSize.width / 2.0, nodeSize.height / 2.0);

          const margin = 80.0;
          final availW = _currentViewportSize.width - 2 * margin;
          final availH = _currentViewportSize.height - 2 * margin;
          final targetScale = math.min(availW / nodeSize.width, availH / nodeSize.height).clamp(scale, 50.0);
          final targetDx = (_currentViewportSize.width / 2.0) - (nodeCenter.dx * targetScale);
          final targetDy = (_currentViewportSize.height / 2.0) - (nodeCenter.dy * targetScale);
          final targetMatrix = Matrix4.identity()
            ..translateByDouble(targetDx, targetDy, 0, 1)
            ..scaleByDouble(targetScale, targetScale, targetScale, 1);

          final aspectRatio = nodeSize.height / (nodeSize.width > 0 ? nodeSize.width : 1.0);
          final internalW = 1600.0;
          final internalH = 1600.0 * aspectRatio;
          final containerInitScale = math.min(availW / internalW, availH / internalH).clamp(0.2, 5.0);
          final newScope = ContainerViewportScope(
            parentScope: currentScope,
            containerId: node.id,
            containerPositionInParent: node.position,
            outerSize: nodeSize,
            savedParentTransform: savedTransform,
            containerInitScale: containerInitScale,
          );

          void applyOpenState() {
            node.isClosed = false;
            activeScopeNotifier.value = newScope;
            final containerDx = (_currentViewportSize.width / 2.0) - ((internalW / 2.0) * containerInitScale);
            final containerDy = (_currentViewportSize.height / 2.0) - ((internalH / 2.0) * containerInitScale);
            transformController.value = Matrix4.identity()
              ..translateByDouble(containerDx, containerDy, 0, 1)
              ..scaleByDouble(containerInitScale, containerInitScale, containerInitScale, 1);
            onContainerOpenStateChanged?.call(node.id, node.position, node.size, false);
            _lastTransitionTimestamp = DateTime.now().millisecondsSinceEpoch;
          }

          if (vsync != null) {
            animateViewportTo(
              targetMatrix,
              vsync!,
              duration: const Duration(milliseconds: 700),
              onComplete: applyOpenState,
            );
          } else {
            applyOpenState();
          }
          break;
        }
      }
      // 2. ZOOM OUT: Inside container, zoomed out past exit threshold -> Optical fly-out takeover
      else if (!node.isClosed) {
        final currentScope = activeScopeNotifier.value;
        if (currentScope is! ContainerViewportScope || currentScope.containerId != node.id) continue;

        final exitScale = currentScope.exitScale;
        final nodeSize = (currentScope.outerSize.width > 0 && currentScope.outerSize.height > 0)
            ? currentScope.outerSize
            : const DefaultNodeLayoutStrategy().calculateSize(node).size;
        final aspectRatio = nodeSize.height / (nodeSize.width > 0 ? nodeSize.width : 1.0);
        final internalW = 1600.0;
        final internalH = 1600.0 * aspectRatio;
        final containerRect = Rect.fromLTWH(0, 0, internalW, internalH);

        if (scale <= exitScale && containerRect.inflate(200.0).contains(cursorCanvas)) {
          _lastTransitionTimestamp = DateTime.now().millisecondsSinceEpoch;
          final Matrix4 parentTransform = currentScope.savedParentTransform;

          node.isClosed = true;
          activeScopeNotifier.value = currentScope.parentScope ?? const RootViewportScope();

          const margin = 80.0;
          final availW = _currentViewportSize.width - 2 * margin;
          final availH = _currentViewportSize.height - 2 * margin;
          final targetScale = math.min(availW / nodeSize.width, availH / nodeSize.height).clamp(1.0, 50.0);
          final nodeCenter = node.position + Offset(nodeSize.width / 2.0, nodeSize.height / 2.0);
          final targetDx = (_currentViewportSize.width / 2.0) - (nodeCenter.dx * targetScale);
          final targetDy = (_currentViewportSize.height / 2.0) - (nodeCenter.dy * targetScale);
          final zoomedInRootMatrix = Matrix4.identity()
            ..translateByDouble(targetDx, targetDy, 0, 1)
            ..scaleByDouble(targetScale, targetScale, targetScale, 1);

          transformController.value = zoomedInRootMatrix;

          if (vsync != null) {
            animateViewportTo(
              parentTransform,
              vsync!,
              duration: const Duration(milliseconds: 700),
              onComplete: () {
                onContainerOpenStateChanged?.call(node.id, node.position, node.size, true);
                _lastTransitionTimestamp = DateTime.now().millisecondsSinceEpoch;
              },
            );
          } else {
            transformController.value = parentTransform;
            onContainerOpenStateChanged?.call(node.id, node.position, node.size, true);
          }
          break;
        }
      }
    }
  }

  /// Calculates and updates the elastic margins boundaries.
  /// Decoupled from the high-frequency transform controller tick to prevent
  /// layout rebuild jitter during active panning/scaling.
  void recalculateElasticMargins() {
    if (_currentViewportSize == Size.zero) return;

    final viewport = _calculateCanvasViewport();
    if (viewport == Rect.zero) return;

    // Scale-Aware Geometric Decoupling & Elastic Margin calculation.
    final bounds = _dataController.canvasBounds;
    final padding = AppConfig.canvas.boundaryMargin;
    final initialPadding = AppConfig.canvas.initialBoundaryMargin;

    // 1. Calculate boundaries based on graph node coordinates
    final nodeLeftBound = -bounds.minX.toDouble() + padding;
    final nodeTopBound = -bounds.minY.toDouble() + padding;
    final nodeRightBound = bounds.maxX.toDouble() + padding;
    final nodeBottomBound = bounds.maxY.toDouble() + padding;

    // 2. Adjust boundaries to guarantee they enclose the current camera viewport
    // to prevent sudden snap backs when the nodes boundary shrinks.
    final leftBound = math.max(
      math.max(initialPadding, nodeLeftBound),
      viewport != Rect.zero ? -viewport.left : 0.0,
    );
    final topBound = math.max(
      math.max(initialPadding, nodeTopBound),
      viewport != Rect.zero ? -viewport.top : 0.0,
    );
    final rightBound = math.max(
      math.max(initialPadding, nodeRightBound),
      viewport != Rect.zero ? viewport.right - _currentViewportSize.width : 0.0,
    );
    final bottomBound = math.max(
      math.max(initialPadding, nodeBottomBound),
      viewport != Rect.zero
          ? viewport.bottom - _currentViewportSize.height
          : 0.0,
    );

    final calculatedMargins = EdgeInsets.fromLTRB(
      leftBound,
      topBound,
      rightBound,
      bottomBound,
    );

    if (elasticMargins.value != calculatedMargins) {
      elasticMargins.value = calculatedMargins;
    }
  }

  void updateVisibleSet(Rect bufferRect) {
    _overscanBuffer = bufferRect;
    final currentOverscan = bufferRect;

    // Dispatch the spatial grid query asynchronously on the event loop
    Future(() {
      if (_isDisposed) return;
      if (_overscanBuffer != currentOverscan) return;
      final scale = transformController.value.getMaxScaleOnAxis();
      final newVisible = _dataController.spatialIndex.queryViewport(
        currentOverscan,
        scale,
        _dataController.nodeLookup,
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

  Rect _calculateCanvasViewport() {
    final Matrix4 transform = transformController.value;

    // Guard against singular matrix to prevent unhandled render exceptions
    if (transform.determinant() == 0.0) {
      _log.severe(
        'Singular matrix detected in canvas transform (Scale = 0). Aborting viewport calculation.',
      );
      return Rect.zero;
    }

    final Matrix4 inverse = Matrix4.inverted(transform);
    final Offset topLeft = MatrixUtils.transformPoint(inverse, Offset.zero);
    final Offset bottomRight = MatrixUtils.transformPoint(
      inverse,
      Offset(_currentViewportSize.width, _currentViewportSize.height),
    );

    return Rect.fromPoints(topLeft, bottomRight);
  }

  /// Animates the viewport translation and scale dynamically using a [vsync] ticker.
  void animateViewportTo(
    Matrix4 targetMatrix,
    TickerProvider vsync, {
    Duration duration = const Duration(milliseconds: 350),
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
      final t = Curves.easeInOutCubic.transform(_viewportAnimationController!.value);
      final interpScale = startScale + (targetScale - startScale) * t;
      final interpTranslation = Offset.lerp(
        Offset(startTranslation.x, startTranslation.y),
        Offset(targetTranslation.x, targetTranslation.y),
        t,
      )!;

      transformController.value = Matrix4.identity()
        ..translateByDouble(interpTranslation.dx, interpTranslation.dy, 0, 1)
        ..scaleByDouble(interpScale, interpScale, interpScale, 1);

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

  /// Projects canvas coordinates to screen-space coordinates.
  Offset projectCanvasToScreen(Offset canvasPos) {
    final Matrix4 transform = transformController.value;
    if (transform.determinant() == 0.0) return canvasPos;
    return MatrixUtils.transformPoint(transform, canvasPos);
  }

  /// Projects a canvas Rect to a screen-space Rect.
  Rect projectCanvasRectToScreen(Rect canvasRect) {
    final topLeft = projectCanvasToScreen(canvasRect.topLeft);
    final bottomRight = projectCanvasToScreen(canvasRect.bottomRight);
    return Rect.fromPoints(topLeft, bottomRight);
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
