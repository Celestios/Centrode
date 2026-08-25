import 'dart:math' as math;
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/gestures.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:centrode/features/graph/engine/config.dart';
import 'package:centrode/shared/widgets/canvas_camera_physics.dart';
import 'package:vector_math/vector_math_64.dart' show Matrix4, Quad, Vector3;

import 'interactive_viewer/canvas_geometry_utils.dart';
import 'interactive_viewer/canvas_viewport_physics.dart';
import 'interactive_viewer/canvas_viewport_transformer.dart';
import 'interactive_viewer/canvas_gesture_classifier.dart';

export 'interactive_viewer/canvas_geometry_utils.dart';
export 'interactive_viewer/canvas_viewport_physics.dart';
export 'interactive_viewer/canvas_viewport_transformer.dart';
export 'interactive_viewer/canvas_gesture_classifier.dart';

typedef InteractiveViewerWidgetBuilder =
    Widget Function(BuildContext context, Quad viewport);

/// A widget that enables pan and zoom interactions with its child.
@immutable
class CanvasInteractiveViewer extends StatefulWidget {
  CanvasInteractiveViewer({
    super.key,
    this.clipBehavior = Clip.hardEdge,
    this.panAxis = PanAxis.free,
    this.boundaryMargin = EdgeInsets.zero,
    this.contentBounds,
    this.constrained = true,
    this.maxScale = 2.5,
    this.minScale = 0.8,
    this.interactionEndFrictionCoefficient = CanvasViewportPhysics.defaultDrag,
    this.onInteractionEnd,
    this.onInteractionStart,
    this.onInteractionUpdate,
    this.panEnabled = true,
    this.scaleEnabled = true,
    this.scaleFactor = kDefaultMouseScrollToScaleFactor,
    this.transformationController,
    this.alignment,
    this.trackpadScrollCausesScale = false,
    this.onElasticOverscroll,
    required Widget this.child,
  })  : assert(minScale > 0),
        assert(interactionEndFrictionCoefficient > 0),
        assert(minScale.isFinite),
        assert(maxScale > 0),
        assert(!maxScale.isNaN),
        assert(maxScale >= minScale),
        assert(
          (boundaryMargin.horizontal.isInfinite &&
                  boundaryMargin.vertical.isInfinite) ||
              (boundaryMargin.top.isFinite &&
                  boundaryMargin.right.isFinite &&
                  boundaryMargin.bottom.isFinite &&
                  boundaryMargin.left.isFinite),
        ),
        builder = null;

  CanvasInteractiveViewer.builder({
    super.key,
    this.clipBehavior = Clip.hardEdge,
    this.panAxis = PanAxis.free,
    this.boundaryMargin = EdgeInsets.zero,
    this.contentBounds,
    this.maxScale = 2.5,
    this.minScale = 0.8,
    this.interactionEndFrictionCoefficient = CanvasViewportPhysics.defaultDrag,
    this.onInteractionEnd,
    this.onInteractionStart,
    this.onInteractionUpdate,
    this.panEnabled = true,
    this.scaleEnabled = true,
    this.scaleFactor = 200.0,
    this.transformationController,
    this.alignment,
    this.trackpadScrollCausesScale = false,
    this.onElasticOverscroll,
    required InteractiveViewerWidgetBuilder this.builder,
  })  : assert(minScale > 0),
        assert(interactionEndFrictionCoefficient > 0),
        assert(minScale.isFinite),
        assert(maxScale > 0),
        assert(!maxScale.isNaN),
        assert(maxScale >= minScale),
        assert(
          (boundaryMargin.horizontal.isInfinite &&
                  boundaryMargin.vertical.isInfinite) ||
              (boundaryMargin.top.isFinite &&
                  boundaryMargin.right.isFinite &&
                  boundaryMargin.bottom.isFinite &&
                  boundaryMargin.left.isFinite),
        ),
        constrained = false,
        child = null;

  final Rect? contentBounds;
  final Alignment? alignment;
  final Clip clipBehavior;
  final PanAxis panAxis;
  final EdgeInsets boundaryMargin;
  final InteractiveViewerWidgetBuilder? builder;
  final Widget? child;
  final bool constrained;
  final bool panEnabled;
  final bool scaleEnabled;
  final bool trackpadScrollCausesScale;
  final double scaleFactor;
  final double maxScale;
  final double minScale;
  final double interactionEndFrictionCoefficient;
  final GestureScaleEndCallback? onInteractionEnd;
  final GestureScaleStartCallback? onInteractionStart;
  final GestureScaleUpdateCallback? onInteractionUpdate;
  final TransformationController? transformationController;
  final ValueChanged<Offset>? onElasticOverscroll;

  @visibleForTesting
  static Vector3 getNearestPointOnLine(Vector3 point, Vector3 l1, Vector3 l2) =>
      CanvasGeometryUtils.getNearestPointOnLine(point, l1, l2);

  @visibleForTesting
  static Quad getAxisAlignedBoundingBox(Quad quad) =>
      CanvasGeometryUtils.getAxisAlignedBoundingBox(quad);

  @visibleForTesting
  static bool pointIsInside(Vector3 point, Quad quad) =>
      CanvasGeometryUtils.pointIsInside(point, quad);

  @visibleForTesting
  static Vector3 getNearestPointInside(Vector3 point, Quad quad) =>
      CanvasGeometryUtils.getNearestPointInside(point, quad);

  @override
  State<CanvasInteractiveViewer> createState() =>
      _CanvasInteractiveViewerState();
}

class _CanvasInteractiveViewerState extends State<CanvasInteractiveViewer>
    with TickerProviderStateMixin {
  late TransformationController _transformer =
      widget.transformationController ?? TransformationController();

  final GlobalKey _childKey = GlobalKey();
  final GlobalKey _parentKey = GlobalKey();
  Animation<Offset>? _animation;
  Animation<double>? _scaleAnimation;
  late Offset _scaleAnimationFocalPoint;
  late AnimationController _controller;
  late AnimationController _scaleController;
  Axis? _currentAxis;
  Offset? _referenceFocalPoint;
  double? _scaleStart;
  double? _rotationStart = 0.0;
  double _currentRotation = 0.0;
  CanvasGestureType? _gestureType;
  Offset? _trackpadFocalPoint;
  PointerDeviceKind? _lastPointerKind;
  int _lastPointerButtons = 0;
  bool _isSecondaryPanning = false;
  Offset? _gestureStartFocalPoint;
  late VelocityTracker _velocityTracker;
  final bool _rotateEnabled = false;

  Offset _currentOverscroll = Offset.zero;
  Offset _baseTranslation = Offset.zero;
  Offset _elasticOffset = Offset.zero;
  Offset? _gestureStartTranslation;
  late final DampedSpring _spring = DampedSpring();
  Ticker? _springTicker;
  Duration _lastSpringTick = Duration.zero;

  void _updatePan(Offset deltaScreen) {
    final Size viewportSize = _viewport.size;
    if (viewportSize == Size.zero || _gestureStartTranslation == null) return;

    final Offset desiredTranslation = _gestureStartTranslation! + deltaScreen;
    final Rect bounds = widget.contentBounds ?? _contentBounds;

    if (bounds.isInfinite) {
      _baseTranslation = desiredTranslation;
      _elasticOffset = Offset.zero;
      _transformer.value = _transformer.value.clone()
        ..setTranslation(Vector3(desiredTranslation.dx, desiredTranslation.dy, 0.0));
      _updateOverscroll(Offset.zero);
      return;
    }

    final double zoom = _transformer.value.getMaxScaleOnAxis();
    final clamped = CanvasViewportTransformer.computePanClamp(
      desiredTranslation: desiredTranslation,
      contentBounds: bounds,
      viewportSize: viewportSize,
      zoom: zoom,
    );

    final double resistance = AppConfig.canvas.elasticResistance;
    final Offset elasticScreen = Offset(
      CanvasViewportPhysics.calculateRubberBand(clamped.overflow.dx, resistance),
      CanvasViewportPhysics.calculateRubberBand(clamped.overflow.dy, resistance),
    );

    _baseTranslation = clamped.baseTranslation;
    _elasticOffset = elasticScreen;
    final Offset actualTranslation = _baseTranslation + _elasticOffset;

    _transformer.value = _transformer.value.clone()
      ..setTranslation(Vector3(actualTranslation.dx, actualTranslation.dy, 0.0));

    _updateOverscroll(elasticScreen);
  }

  void _startSpring() {
    _stopSpring();
    _spring.reset(_elasticOffset);
    _lastSpringTick = Duration.zero;
    _springTicker?.start();
  }

  void _stopSpring() {
    if (_springTicker?.isActive ?? false) {
      _springTicker?.stop();
    }
  }

  void _onSpringTick(Duration elapsed) {
    if (_lastSpringTick == Duration.zero) {
      _lastSpringTick = elapsed;
      return;
    }
    final double dt = ((elapsed - _lastSpringTick).inMicroseconds / 1000000.0)
        .clamp(0.001, 0.032);
    _lastSpringTick = elapsed;

    _spring.update(dt);
    _elasticOffset = _spring.position;

    final Offset actualTranslation = _baseTranslation + _elasticOffset;

    _transformer.value = _transformer.value.clone()
      ..setTranslation(Vector3(actualTranslation.dx, actualTranslation.dy, 0.0));

    _updateOverscroll(_elasticOffset);

    if (_spring.settled) {
      _stopSpring();
      _elasticOffset = Offset.zero;
      _updateOverscroll(Offset.zero);
      _transformer.value = _transformer.value.clone()
        ..setTranslation(Vector3(_baseTranslation.dx, _baseTranslation.dy, 0.0));
    }
  }

  Rect get _contentBounds => widget.contentBounds ?? _boundaryRect;

  Rect get _boundaryRect {
    assert(_childKey.currentContext != null);
    final RenderBox childRenderBox =
        _childKey.currentContext!.findRenderObject()! as RenderBox;
    final Size childSize = childRenderBox.size;
    return widget.boundaryMargin.inflateRect(Offset.zero & childSize);
  }

  Rect get _viewport {
    assert(_parentKey.currentContext != null);
    final RenderBox parentRenderBox =
        _parentKey.currentContext!.findRenderObject()! as RenderBox;
    return Offset.zero & parentRenderBox.size;
  }

  Matrix4 _matrixTranslate(Matrix4 matrix, Offset translation) {
    return CanvasViewportTransformer.matrixTranslate(
      matrix: matrix,
      translation: translation,
      panAxis: widget.panAxis,
      currentAxis: _currentAxis,
      contentBounds: widget.contentBounds ?? _contentBounds,
      viewportSize: _viewport.size,
    );
  }

  Matrix4 _matrixScale(Matrix4 matrix, double scale) {
    return CanvasViewportTransformer.matrixScale(
      matrix: matrix,
      scale: scale,
      minScale: widget.minScale,
      maxScale: widget.maxScale,
    );
  }

  Matrix4 _matrixRotate(Matrix4 matrix, double rotation, Offset focalPoint) {
    return CanvasViewportTransformer.matrixRotate(
      matrix: matrix,
      rotation: rotation,
      focalPointScene: _transformer.toScene(focalPoint),
    );
  }

  bool _gestureIsSupported(CanvasGestureType? gestureType) {
    return CanvasGestureClassifier.isGestureSupported(
      gestureType: gestureType,
      panEnabled: widget.panEnabled,
      scaleEnabled: widget.scaleEnabled,
      rotateEnabled: _rotateEnabled,
      lastPointerKind: _lastPointerKind,
      lastPointerButtons: _lastPointerButtons,
    );
  }

  CanvasGestureType _getGestureType(ScaleUpdateDetails details) {
    return CanvasGestureClassifier.classifyGesture(
      details: details,
      scaleEnabled: widget.scaleEnabled,
      rotateEnabled: _rotateEnabled,
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    widget.onInteractionStart?.call(details);

    _stopSpring();
    if (_controller.isAnimating) {
      _controller.stop();
      _controller.reset();
      _animation?.removeListener(_handleInertiaAnimation);
      _animation = null;
    }
    if (_scaleController.isAnimating) {
      _scaleController.stop();
      _scaleController.reset();
      _scaleAnimation?.removeListener(_handleScaleAnimation);
      _scaleAnimation = null;
    }

    _gestureType = null;
    _currentAxis = null;
    _scaleStart = _transformer.value.getMaxScaleOnAxis();
    final Offset focalPoint = _trackpadFocalPoint ?? details.localFocalPoint;
    _referenceFocalPoint = _transformer.toScene(focalPoint);
    _rotationStart = _currentRotation;

    final Vector3 translationVector = _transformer.value.getTranslation();
    _baseTranslation = Offset(translationVector.x, translationVector.y) - _elasticOffset;
    _gestureStartTranslation = _baseTranslation;
    _gestureStartFocalPoint = focalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    final double scale = _transformer.value.getMaxScaleOnAxis();
    final Offset focalPoint = _trackpadFocalPoint ?? details.localFocalPoint;
    _scaleAnimationFocalPoint = focalPoint;

    if (_gestureType == CanvasGestureType.pan) {
      _gestureType = _getGestureType(details);
    } else {
      _gestureType ??= _getGestureType(details);
    }
    if (!_gestureIsSupported(_gestureType)) {
      widget.onInteractionUpdate?.call(details);
      return;
    }

    switch (_gestureType!) {
      case CanvasGestureType.scale:
        assert(_scaleStart != null);
        final double desiredScale = _scaleStart! * details.scale;
        final double scaleChange = desiredScale / scale;
        _transformer.value = _matrixScale(_transformer.value, scaleChange);

        final Offset focalPointSceneScaled = _transformer.toScene(focalPoint);
        _transformer.value = _matrixTranslate(
          _transformer.value,
          focalPointSceneScaled - _referenceFocalPoint!,
        );

        final Offset focalPointSceneCheck = _transformer.toScene(focalPoint);
        if (CanvasGeometryUtils.roundOffset(_referenceFocalPoint!) !=
            CanvasGeometryUtils.roundOffset(focalPointSceneCheck)) {
          _referenceFocalPoint = focalPointSceneCheck;
        }

      case CanvasGestureType.rotate:
        if (details.rotation == 0.0) {
          widget.onInteractionUpdate?.call(details);
          return;
        }
        final double desiredRotation = _rotationStart! + details.rotation;
        _transformer.value = _matrixRotate(
          _transformer.value,
          _currentRotation - desiredRotation,
          focalPoint,
        );
        _currentRotation = desiredRotation;

      case CanvasGestureType.pan:
        if (details.scale != 1.0) {
          widget.onInteractionUpdate?.call(details);
          return;
        }
        if (_gestureStartFocalPoint != null) {
          final Offset delta = focalPoint - _gestureStartFocalPoint!;
          _updatePan(delta);
        }
    }
    widget.onInteractionUpdate?.call(details);
  }

  void _onScaleEnd(ScaleEndDetails details) {
    widget.onInteractionEnd?.call(details);
    _scaleStart = null;
    _rotationStart = null;
    _referenceFocalPoint = null;
    _gestureStartFocalPoint = null;
    _gestureStartTranslation = null;

    _animation?.removeListener(_handleInertiaAnimation);
    _scaleAnimation?.removeListener(_handleScaleAnimation);
    _controller.reset();
    _scaleController.reset();

    if (!_gestureIsSupported(_gestureType)) {
      _currentAxis = null;
      return;
    }

    switch (_gestureType) {
      case CanvasGestureType.pan:
        if (_elasticOffset != Offset.zero) {
          _startSpring();
        } else {
          _applyFrictionInertia(details.velocity.pixelsPerSecond);
        }
      case CanvasGestureType.scale:
        if (details.scaleVelocity.abs() < 0.1) {
          _currentAxis = null;
          return;
        }
        final double scale = _transformer.value.getMaxScaleOnAxis();
        final FrictionSimulation frictionSimulation = FrictionSimulation(
          widget.interactionEndFrictionCoefficient * widget.scaleFactor,
          scale,
          details.scaleVelocity / 10,
        );
        final double tFinal = CanvasViewportPhysics.getFinalTime(
          details.scaleVelocity.abs(),
          widget.interactionEndFrictionCoefficient,
          effectivelyMotionless: 0.1,
        );
        _scaleAnimation =
            Tween<double>(
              begin: scale,
              end: frictionSimulation.x(tFinal),
            ).animate(
              CurvedAnimation(
                parent: _scaleController,
                curve: Curves.decelerate,
              ),
            );
        _scaleController.duration = Duration(
          milliseconds: (tFinal * 1000).round(),
        );
        _scaleAnimation!.addListener(_handleScaleAnimation);
        _scaleController.forward();
      case CanvasGestureType.rotate || null:
        break;
    }
  }

  void _updateOverscroll(Offset overscroll) {
    if (_currentOverscroll != overscroll) {
      _currentOverscroll = overscroll;
      widget.onElasticOverscroll?.call(overscroll);
    }
  }

  void _applyFrictionInertia(Offset velocity) {
    if (velocity.distance < kMinFlingVelocity) {
      _currentAxis = null;
      return;
    }
    final Vector3 translationVector = _transformer.value.getTranslation();
    final Offset translation = Offset(translationVector.x, translationVector.y);
    final FrictionSimulation frictionSimulationX = FrictionSimulation(
      widget.interactionEndFrictionCoefficient,
      translation.dx,
      velocity.dx,
    );
    final FrictionSimulation frictionSimulationY = FrictionSimulation(
      widget.interactionEndFrictionCoefficient,
      translation.dy,
      velocity.dy,
    );
    final double tFinal = CanvasViewportPhysics.getFinalTime(
      velocity.distance,
      widget.interactionEndFrictionCoefficient,
    );
    _animation = Tween<Offset>(
      begin: translation,
      end: Offset(frictionSimulationX.finalX, frictionSimulationY.finalX),
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.decelerate));
    _controller.duration = Duration(milliseconds: (tFinal * 1000).round());
    _animation!.addListener(_handleInertiaAnimation);
    _controller.forward();
  }

  void _receivedPointerSignal(PointerSignalEvent event) {
    _lastPointerKind = event.kind;
    _lastPointerButtons = event.buttons;
    final Offset local = event.localPosition;
    final Offset global = event.position;
    final double scaleChange;
    if (event is PointerScrollEvent) {
      if (event.kind == PointerDeviceKind.trackpad &&
          !widget.trackpadScrollCausesScale) {
        widget.onInteractionStart?.call(
          ScaleStartDetails(focalPoint: global, localFocalPoint: local),
        );

        final Offset localDelta = PointerEvent.transformDeltaViaPositions(
          untransformedEndPosition: global + event.scrollDelta,
          untransformedDelta: event.scrollDelta,
          transform: event.transform,
        );

        if (!_gestureIsSupported(CanvasGestureType.pan)) {
          widget.onInteractionUpdate?.call(
            ScaleUpdateDetails(
              focalPoint: global - event.scrollDelta,
              localFocalPoint: local - event.scrollDelta,
              focalPointDelta: -localDelta,
            ),
          );
          widget.onInteractionEnd?.call(ScaleEndDetails());
          return;
        }

        final Offset focalPointScene = _transformer.toScene(local);
        final Offset newFocalPointScene = _transformer.toScene(
          local - localDelta,
        );

        _transformer.value = _matrixTranslate(
          _transformer.value,
          newFocalPointScene - focalPointScene,
        );

        widget.onInteractionUpdate?.call(
          ScaleUpdateDetails(
            focalPoint: global - event.scrollDelta,
            localFocalPoint: local - localDelta,
            focalPointDelta: -localDelta,
          ),
        );
        widget.onInteractionEnd?.call(ScaleEndDetails());
        return;
      }
      if (event.scrollDelta.dy == 0.0) {
        return;
      }
      scaleChange = math.exp(-event.scrollDelta.dy / widget.scaleFactor);
    } else if (event is PointerScaleEvent) {
      scaleChange = event.scale;
    } else {
      return;
    }
    widget.onInteractionStart?.call(
      ScaleStartDetails(focalPoint: global, localFocalPoint: local),
    );

    if (!_gestureIsSupported(CanvasGestureType.scale)) {
      widget.onInteractionUpdate?.call(
        ScaleUpdateDetails(
          focalPoint: global,
          localFocalPoint: local,
          scale: scaleChange,
        ),
      );
      widget.onInteractionEnd?.call(ScaleEndDetails());
      return;
    }

    final Offset focalPointScene = _transformer.toScene(local);
    _transformer.value = _matrixScale(_transformer.value, scaleChange);

    final Offset focalPointSceneScaled = _transformer.toScene(local);
    _transformer.value = _matrixTranslate(
      _transformer.value,
      focalPointSceneScaled - focalPointScene,
    );

    widget.onInteractionUpdate?.call(
      ScaleUpdateDetails(
        focalPoint: global,
        localFocalPoint: local,
        scale: scaleChange,
      ),
    );
    widget.onInteractionEnd?.call(ScaleEndDetails());
  }

  void _handleInertiaAnimation() {
    if (!_controller.isAnimating) {
      _currentAxis = null;
      _animation?.removeListener(_handleInertiaAnimation);
      _animation = null;
      _controller.reset();
      return;
    }
    final Vector3 translationVector = _transformer.value.getTranslation();
    final Offset translation = Offset(translationVector.x, translationVector.y);
    _transformer.value = _matrixTranslate(
      _transformer.value,
      _transformer.toScene(_animation!.value) -
          _transformer.toScene(translation),
    );
  }

  void _handleScaleAnimation() {
    if (!_scaleController.isAnimating) {
      _currentAxis = null;
      _scaleAnimation?.removeListener(_handleScaleAnimation);
      _scaleAnimation = null;
      _scaleController.reset();
      return;
    }
    final double desiredScale = _scaleAnimation!.value;
    final double scaleChange =
        desiredScale / _transformer.value.getMaxScaleOnAxis();
    final Offset referenceFocalPoint = _transformer.toScene(
      _scaleAnimationFocalPoint,
    );
    _transformer.value = _matrixScale(_transformer.value, scaleChange);

    final Offset focalPointSceneScaled = _transformer.toScene(
      _scaleAnimationFocalPoint,
    );
    _transformer.value = _matrixTranslate(
      _transformer.value,
      focalPointSceneScaled - referenceFocalPoint,
    );
  }

  void _handleTransformation() {
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _scaleController = AnimationController(vsync: this);
    _springTicker = createTicker(_onSpringTick);
    _velocityTracker = VelocityTracker.withKind(PointerDeviceKind.mouse);
    _transformer.addListener(_handleTransformation);
  }

  @override
  void didUpdateWidget(CanvasInteractiveViewer oldWidget) {
    super.didUpdateWidget(oldWidget);

    final TransformationController? newController =
        widget.transformationController;
    if (newController == oldWidget.transformationController) {
      return;
    }
    _transformer.removeListener(_handleTransformation);
    if (oldWidget.transformationController == null) {
      _transformer.dispose();
    }
    _transformer = newController ?? TransformationController();
    _transformer.addListener(_handleTransformation);
  }

  @override
  void dispose() {
    _springTicker?.dispose();
    _controller.dispose();
    _scaleController.dispose();
    _transformer.removeListener(_handleTransformation);
    if (widget.transformationController == null) {
      _transformer.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (widget.child != null) {
      child = _CentrodeInteractiveViewerBuilt(
        childKey: _childKey,
        clipBehavior: widget.clipBehavior,
        constrained: widget.constrained,
        matrix: _transformer.value,
        alignment: widget.alignment,
        child: widget.child!,
      );
    } else {
      assert(widget.builder != null);
      assert(!widget.constrained);
      child = LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final Matrix4 matrix = _transformer.value;
          return _CentrodeInteractiveViewerBuilt(
            childKey: _childKey,
            clipBehavior: widget.clipBehavior,
            constrained: widget.constrained,
            alignment: widget.alignment,
            matrix: matrix,
            child: widget.builder!(
              context,
              CanvasGeometryUtils.transformViewport(
                matrix,
                Offset.zero & constraints.biggest,
              ),
            ),
          );
        },
      );
    }

    return Listener(
      key: _parentKey,
      onPointerSignal: _receivedPointerSignal,
      onPointerDown: (PointerDownEvent event) {
        _lastPointerKind = event.kind;
        _lastPointerButtons = event.buttons;

        if (widget.panEnabled &&
            event.kind == PointerDeviceKind.mouse &&
            event.buttons == kSecondaryMouseButton) {
          _isSecondaryPanning = true;
          _velocityTracker.addPosition(event.timeStamp, event.position);

          _stopSpring();
          if (_controller.isAnimating) {
            _controller.stop();
            _controller.reset();
            _animation?.removeListener(_handleInertiaAnimation);
            _animation = null;
          }

          final Vector3 translationVector = _transformer.value.getTranslation();
          _baseTranslation = Offset(translationVector.x, translationVector.y) - _elasticOffset;
          _gestureStartTranslation = _baseTranslation;
          _gestureStartFocalPoint = event.localPosition;
          _referenceFocalPoint = _transformer.toScene(event.localPosition);
        }
      },
      onPointerMove: (PointerMoveEvent event) {
        if (_isSecondaryPanning) {
          _velocityTracker.addPosition(event.timeStamp, event.position);

          if (_gestureStartFocalPoint != null) {
            final Offset delta = event.localPosition - _gestureStartFocalPoint!;
            _updatePan(delta);
          }
        }
      },
      onPointerUp: (PointerUpEvent event) {
        _lastPointerKind = event.kind;
        _lastPointerButtons = event.buttons;
        if (_isSecondaryPanning) {
          _isSecondaryPanning = false;
          _gestureStartFocalPoint = null;
          _gestureStartTranslation = null;
          _referenceFocalPoint = null;

          if (_elasticOffset != Offset.zero) {
            _startSpring();
          } else {
            final Velocity velocity = _velocityTracker.getVelocity();
            _applyFrictionInertia(velocity.pixelsPerSecond);
          }
        }
      },
      onPointerCancel: (PointerCancelEvent event) {
        _lastPointerKind = event.kind;
        _lastPointerButtons = event.buttons;
        if (_isSecondaryPanning) {
          _isSecondaryPanning = false;
          _gestureStartFocalPoint = null;
          _gestureStartTranslation = null;
          _referenceFocalPoint = null;
          if (_elasticOffset != Offset.zero) {
            _startSpring();
          }
        }
      },
      onPointerPanZoomStart: (PointerPanZoomStartEvent event) {
        _lastPointerKind = event.kind;
        _lastPointerButtons = event.buttons;
        _trackpadFocalPoint = event.localPosition;
      },
      onPointerPanZoomUpdate: (PointerPanZoomUpdateEvent event) {
        _trackpadFocalPoint = event.localPosition;
      },
      onPointerPanZoomEnd: (PointerPanZoomEndEvent event) {
        _trackpadFocalPoint = null;
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onScaleStart: (widget.panEnabled || widget.scaleEnabled)
            ? _onScaleStart
            : null,
        onScaleUpdate: (widget.panEnabled || widget.scaleEnabled)
            ? _onScaleUpdate
            : null,
        onScaleEnd: (widget.panEnabled || widget.scaleEnabled)
            ? _onScaleEnd
            : null,
        trackpadScrollCausesScale: widget.trackpadScrollCausesScale,
        trackpadScrollToScaleFactor: Offset(0, -1 / widget.scaleFactor),
        child: child,
      ),
    );
  }
}

class _CentrodeInteractiveViewerBuilt extends StatelessWidget {
  const _CentrodeInteractiveViewerBuilt({
    required this.child,
    required this.childKey,
    required this.clipBehavior,
    required this.constrained,
    required this.matrix,
    required this.alignment,
  });

  final Widget child;
  final GlobalKey childKey;
  final Clip clipBehavior;
  final bool constrained;
  final Matrix4 matrix;
  final Alignment? alignment;

  @override
  Widget build(BuildContext context) {
    Widget child = Transform(
      transform: matrix,
      alignment: alignment,
      child: KeyedSubtree(key: childKey, child: this.child),
    );

    if (!constrained) {
      child = OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: 0.0,
        minHeight: 0.0,
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: child,
      );
    }

    return ClipRect(clipBehavior: clipBehavior, child: child);
  }
}
