import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'liquid_glass_settings.dart';
import 'liquid_glass_shader_provider.dart';

/// Simplified shape data structure used to pass geometry information to the shader.
/// Each LiquidGlass widget gets converted into this format for GPU processing.
class ShapeData {
  final Offset center;
  final Size size;
  final double borderRadius;
  final Color color;

  ShapeData(this.center, this.size, this.borderRadius, this.color);
}

class BridgeData {
  final Offset start;
  final Offset end;
  final double radius;
  final Color color;

  BridgeData(this.start, this.end, this.radius, this.color);
}

/// Renders a backdrop separately from glass controls so Skia can sample the
/// background without recursively capturing the glass itself.
class OCLiquidGlassStage extends StatefulWidget {
  final OCLiquidGlassSettings settings;
  final Widget background;
  final Widget child;
  final Listenable? repaint;
  final Listenable? backdropRepaint;

  const OCLiquidGlassStage({
    super.key,
    required this.settings,
    required this.background,
    required this.child,
    this.repaint,
    this.backdropRepaint,
  });

  @override
  State<OCLiquidGlassStage> createState() => _OCLiquidGlassStageState();
}

class _OCLiquidGlassStageState extends State<OCLiquidGlassStage> {
  static const int _initialWarmupCaptures = 6;

  final GlobalKey _backgroundKey = GlobalKey();
  ui.Image? _backdropImage;
  Size? _backdropLogicalSize;
  bool _captureScheduled = false;
  int _captureSerial = 0;
  int _warmupCapturesRemaining = 0;
  double? _lastDevicePixelRatio;

  @override
  void initState() {
    super.initState();
    widget.backdropRepaint?.addListener(_handleBackdropChanged);
    _scheduleCapture(warmupCaptures: _initialWarmupCaptures);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final dpr = MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0;
    if (_lastDevicePixelRatio != dpr) {
      _lastDevicePixelRatio = dpr;
      _scheduleCapture(warmupCaptures: _initialWarmupCaptures);
    }
  }

  @override
  void didUpdateWidget(OCLiquidGlassStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.backdropRepaint != widget.backdropRepaint) {
      oldWidget.backdropRepaint?.removeListener(_handleBackdropChanged);
      widget.backdropRepaint?.addListener(_handleBackdropChanged);
    }
    if (oldWidget.background != widget.background) {
      _scheduleCapture(warmupCaptures: _initialWarmupCaptures);
    }
  }

  @override
  void dispose() {
    widget.backdropRepaint?.removeListener(_handleBackdropChanged);
    _captureSerial++;
    _backdropImage?.dispose();
    super.dispose();
  }

  void _handleBackdropChanged() {
    _scheduleCapture();
  }

  void _scheduleCapture({int warmupCaptures = 0}) {
    if (ui.ImageFilter.isShaderFilterSupported) return;
    if (warmupCaptures > _warmupCapturesRemaining) {
      _warmupCapturesRemaining = warmupCaptures;
    }
    if (_captureScheduled) return;

    _captureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _captureScheduled = false;
      unawaited(_captureBackdrop());
    });
  }

  Future<void> _captureBackdrop() async {
    if (ui.ImageFilter.isShaderFilterSupported) return;
    if (!mounted) return;

    final boundaryContext = _backgroundKey.currentContext;
    final renderObject = boundaryContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      return;
    }

    if (renderObject.debugNeedsPaint) {
      _scheduleCapture();
      return;
    }

    final logicalSize = renderObject.size;
    if (logicalSize.isEmpty) return;

    final pixelRatio = math.min(1.5, MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1.0);
    final serial = ++_captureSerial;

    try {
      final image = await renderObject.toImage(pixelRatio: pixelRatio);
      if (!mounted || serial != _captureSerial) {
        image.dispose();
        return;
      }

      final oldImage = _backdropImage;
      setState(() {
        _backdropImage = image;
        _backdropLogicalSize = logicalSize;
      });
      oldImage?.dispose();

      if (_warmupCapturesRemaining > 0) {
        _warmupCapturesRemaining--;
        _scheduleCapture();
      }
    } catch (_) {
      if (mounted && _warmupCapturesRemaining > 0) {
        _warmupCapturesRemaining--;
        _scheduleCapture();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(key: _backgroundKey, child: widget.background),
        OCLiquidGlassGroup(
          settings: widget.settings,
          repaint: widget.repaint,
          backdropImage: _backdropImage,
          backdropLogicalSize: _backdropLogicalSize,
          child: widget.child,
        ),
      ],
    );
  }
}

/// Container widget that manages multiple liquid glass shapes and applies the shader effect.
/// This widget loads the fragment shader and creates a render layer that collects
/// all LiquidGlass children and applies the unified glass effect to them.
class OCLiquidGlassGroup extends StatefulWidget {
  final OCLiquidGlassSettings settings;
  final Listenable? repaint;
  final ui.Image? backdropImage;
  final Size? backdropLogicalSize;
  final Widget child;

  const OCLiquidGlassGroup({
    super.key,
    required this.settings,
    required this.child,
    this.repaint,
    this.backdropImage,
    this.backdropLogicalSize,
  });

  @override
  State<OCLiquidGlassGroup> createState() => _OCLiquidGlassGroupState();
}

class _OCLiquidGlassGroupState extends State<OCLiquidGlassGroup> {
  ui.FragmentProgram? _program;

  @override
  void initState() {
    super.initState();
    if (LiquidGlassShaderProvider.shaderProgram != null) {
      _program = LiquidGlassShaderProvider.shaderProgram;
    } else {
      ui.FragmentProgram.fromAsset(LiquidGlassShaderProvider.shaderAssetPath).then((p) {
        if (mounted) {
          setState(() => _program = p);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_program == null) {
      return widget.child;
    }
    return _LiquidGlassGroupRenderObject(
      shader: _program!.fragmentShader(),
      settings: widget.settings,
      repaint: widget.repaint,
      backdropImage: widget.backdropImage,
      backdropLogicalSize: widget.backdropLogicalSize,
      child: widget.child,
    );
  }
}

class _LiquidGlassGroupRenderObject extends SingleChildRenderObjectWidget {
  final ui.FragmentShader shader;
  final OCLiquidGlassSettings settings;
  final Listenable? repaint;
  final ui.Image? backdropImage;
  final Size? backdropLogicalSize;

  const _LiquidGlassGroupRenderObject({
    required this.shader,
    required this.settings,
    this.repaint,
    this.backdropImage,
    this.backdropLogicalSize,
    super.child,
  });

  @override
  _RenderLiquidGlassGroup createRenderObject(BuildContext context) {
    final position = Scrollable.maybeOf(context)?.position;
    final mediaQuery = MediaQuery.of(context);
    final renderObject = _RenderLiquidGlassGroup(
      devicePixelRatio: mediaQuery.devicePixelRatio,
      screenSize: mediaQuery.size,
      shader: shader,
      settings: settings,
      position: position,
      externalRepaint: repaint,
      backdropImage: backdropImage,
      backdropLogicalSize: backdropLogicalSize,
    );

    _attachRouteAnimation(context, renderObject);
    return renderObject;
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderLiquidGlassGroup renderObject,
  ) {
    final position = Scrollable.maybeOf(context)?.position;
    final mediaQuery = MediaQuery.of(context);
    renderObject
      ..devicePixelRatio = mediaQuery.devicePixelRatio
      ..screenSize = mediaQuery.size
      ..settings = settings
      ..scrollPosition = position
      ..externalRepaint = repaint
      ..backdropImage = backdropImage
      ..backdropLogicalSize = backdropLogicalSize;

    _attachRouteAnimation(context, renderObject);
  }

  void _attachRouteAnimation(BuildContext ctx, _RenderLiquidGlassGroup rb) {
    final listenables = <Listenable>[];

    final rLocal = ModalRoute.of(ctx);
    if (rLocal?.animation != null) {
      listenables.add(rLocal!.animation!);
    }
    if (rLocal?.secondaryAnimation != null) {
      listenables.add(rLocal!.secondaryAnimation!);
    }

    final rootNav = Navigator.maybeOf(ctx);
    if (rootNav != null) {
      final rRoot = ModalRoute.of(rootNav.context);
      if (rRoot?.animation != null) {
        listenables.add(rRoot!.animation!);
      }
      if (rRoot?.secondaryAnimation != null) {
        listenables.add(rRoot!.secondaryAnimation!);
      }
    }

    final mergedRouteAnimations = listenables.isNotEmpty
        ? Listenable.merge(listenables)
        : null;

    rb.setRouteAnimations(mergedRouteAnimations);
  }

  @override
  void didUnmountRenderObject(_RenderLiquidGlassGroup rb) {
    rb.detachRepaintSources();
  }
}

class _RenderLiquidGlassGroup extends RenderProxyBox {
  static const int maxRects = 4;
  static const int maxBridges = 6;

  // Code Hygiene Constants (Tuning parameters & scaling factors)  // Constants removed: moved to OCLiquidGlassSettings

  Listenable? _routeAnimations;
  ScrollPosition? _scrollPosition;
  Listenable? _externalRepaint;
  Size _screenSize;

  _RenderLiquidGlassGroup({
    required double devicePixelRatio,
    required Size screenSize,
    required ui.FragmentShader shader,
    required OCLiquidGlassSettings settings,
    ScrollPosition? position,
    Listenable? externalRepaint,
    ui.Image? backdropImage,
    Size? backdropLogicalSize,
  }) : _devicePixelRatio = devicePixelRatio,
       _screenSize = screenSize,
       _shader = shader,
       _settings = settings,
       _scrollPosition = position,
       _externalRepaint = externalRepaint,
       _backdropImage = backdropImage,
       _backdropLogicalSize = backdropLogicalSize;

  set screenSize(Size v) {
    if (_screenSize == v) return;
    _screenSize = v;
    markNeedsPaint();
  }

  set externalRepaint(Listenable? v) {
    if (identical(v, _externalRepaint)) return;
    if (attached) {
      _externalRepaint?.removeListener(markNeedsPaint);
    }
    _externalRepaint = v;
    if (attached) {
      _externalRepaint?.addListener(markNeedsPaint);
    }
    markNeedsPaint();
  }

  set scrollPosition(ScrollPosition? value) {
    if (value == _scrollPosition) return;
    if (attached) {
      _scrollPosition?.removeListener(_onScroll);
    }
    _scrollPosition = value;
    if (attached) {
      _scrollPosition?.addListener(_onScroll);
    }
    markNeedsPaint();
  }

  void _onScroll() => markNeedsPaint();

  double _devicePixelRatio;
  set devicePixelRatio(double v) {
    if (_devicePixelRatio == v) return;
    _devicePixelRatio = v;
    markNeedsPaint();
  }

  OCLiquidGlassSettings _settings;
  set settings(OCLiquidGlassSettings v) {
    _settings = v;
    markNeedsPaint();
  }

  ui.Image? _backdropImage;
  set backdropImage(ui.Image? v) {
    if (identical(_backdropImage, v)) return;
    _backdropImage = v;
    markNeedsPaint();
  }

  Size? _backdropLogicalSize;
  set backdropLogicalSize(Size? v) {
    if (_backdropLogicalSize == v) return;
    _backdropLogicalSize = v;
    markNeedsPaint();
  }

  final ui.FragmentShader _shader;
  final Set<RenderLiquidGlass> registeredShapes = {};

  void setRouteAnimations(Listenable? routeAnimations) {
    if (identical(routeAnimations, _routeAnimations)) return;
    if (attached) {
      _routeAnimations?.removeListener(markNeedsPaint);
    }
    _routeAnimations = routeAnimations;
    if (attached) {
      _routeAnimations?.addListener(markNeedsPaint);
    }
  }

  void detachRepaintSources() {
    _routeAnimations?.removeListener(markNeedsPaint);
    _scrollPosition?.removeListener(_onScroll);
    _externalRepaint?.removeListener(markNeedsPaint);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    _routeAnimations?.addListener(markNeedsPaint);
    _scrollPosition?.addListener(_onScroll);
    _externalRepaint?.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  @override
  void detach() {
    detachRepaintSources();
    super.detach();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  bool get _hasUsableBackdrop {
    final image = _backdropImage;
    final logicalSize = _backdropLogicalSize;
    if (image == null || logicalSize == null || logicalSize.isEmpty) {
      return false;
    }

    return (logicalSize.width - size.width).abs() < 0.5 &&
        (logicalSize.height - size.height).abs() < 0.5;
  }

  ui.Path? _cachedLocalUnifiedPath;
  List<Rect>? _cachedLocalRects;
  double? _cachedBlendPx;

  bool _isLocalPathCacheValid(List<Rect> currentRects) {
    final cached = _cachedLocalRects;
    if (cached == null || _cachedLocalUnifiedPath == null || _cachedBlendPx != _settings.blendPx) {
      return false;
    }
    if (cached.length != currentRects.length) {
      return false;
    }
    for (var i = 0; i < cached.length; i++) {
      if (cached[i] != currentRects[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final activeShapes = registeredShapes.where((s) => s.attached && !s.size.isEmpty).toList();
    if (activeShapes.isEmpty) {
      super.paint(context, offset);
      return;
    }

    final hasShaderSupport = ui.ImageFilter.isShaderFilterSupported;

    if (!hasShaderSupport) {
      final localRects = activeShapes.map((s) => _localRectForShape(s)).toList();
      final localShapes = <ShapeData>[];
      for (var i = 0; i < activeShapes.length; i++) {
        localShapes.add(_shapeDataForRect(activeShapes[i], localRects[i]));
      }

      final ui.Path localUnifiedPath;
      if (_isLocalPathCacheValid(localRects)) {
        localUnifiedPath = _cachedLocalUnifiedPath!;
      } else {
        localUnifiedPath = _buildLocalUnifiedPath(localShapes, localRects);
        _cachedLocalUnifiedPath = localUnifiedPath;
        _cachedLocalRects = localRects;
        _cachedBlendPx = _settings.blendPx;
      }

      if (_hasUsableBackdrop) {
        _paintCapturedSkiaShader(context, offset, localShapes);
      } else {
        _paintDecorativeSkiaFallback(context, offset, localUnifiedPath, localShapes, localRects);
      }

      super.paint(context, offset);
      return;
    }

    final useLocal = _settings.renderBackend == LiquidGlassRendererBackend.impeller;

    if (useLocal) {
      final localRects = activeShapes.map((s) => _localRectForShape(s)).toList();
      final localShapes = <ShapeData>[];
      for (var i = 0; i < activeShapes.length; i++) {
        localShapes.add(_shapeDataForRect(activeShapes[i], localRects[i]));
      }

      _configureShader(
        _shader,
        shaderSize: size,
        bounds: Offset.zero & size,
        shapes: localShapes,
        bridges: const [],
        pixelScale: 1.0,
      );
    } else {
      final boundaryTransform = getTransformTo(null);
      final boundary = MatrixUtils.transformRect(
        boundaryTransform,
        Offset.zero & size,
      );

      final globalShapes = activeShapes.map((s) => _shapeDataForRect(s, _globalRectForShape(s))).toList();

      _configureShader(
        _shader,
        shaderSize: _screenSize,
        bounds: boundary,
        shapes: globalShapes,
        bridges: const [],
        pixelScale: _devicePixelRatio,
      );
    }

    context.pushLayer(
      BackdropFilterLayer(filter: ui.ImageFilter.shader(_shader)),
      super.paint,
      offset,
    );
  }

  Rect _globalRectForShape(RenderLiquidGlass shape) {
    return MatrixUtils.transformRect(
      shape.getTransformTo(null),
      Offset.zero & shape.size,
    );
  }

  Rect _localRectForShape(RenderLiquidGlass shape) {
    return MatrixUtils.transformRect(
      shape.getTransformTo(this),
      Offset.zero & shape.size,
    );
  }

  ShapeData _shapeDataForRect(RenderLiquidGlass shape, Rect rect) {
    final maxRadius = math.min(rect.width, rect.height) / 2.0;
    final clampedRadius = shape.borderRadius > maxRadius
        ? maxRadius
        : shape.borderRadius;
    return ShapeData(
      rect.center,
      rect.size,
      math.max(0.0, clampedRadius),
      shape.color,
    );
  }

  // Pre-configured shader math uniform mappings are set directly.
  void _configureShader(
    ui.FragmentShader shader, {
    required Size shaderSize,
    required Rect bounds,
    required List<ShapeData> shapes,
    required List<BridgeData> bridges,
    required double pixelScale,
  }) {
    shader.setFloat(0, shaderSize.width * pixelScale);
    shader.setFloat(1, shaderSize.height * pixelScale);

    var idx = 2;
    final rectCount = shapes.length < maxRects ? shapes.length : maxRects;
    final bridgeCount = bridges.length < maxBridges
        ? bridges.length
        : maxBridges;

    shader
      ..setFloat(idx++, bounds.left * pixelScale)
      ..setFloat(idx++, bounds.top * pixelScale)
      ..setFloat(idx++, bounds.right * pixelScale)
      ..setFloat(idx++, bounds.bottom * pixelScale)
      ..setFloat(idx++, _settings.blendPx * pixelScale)
      ..setFloat(idx++, _settings.refractStrength)
      ..setFloat(idx++, _settings.distortFalloffPx * pixelScale)
      ..setFloat(idx++, _settings.distortExponent)
      ..setFloat(idx++, _settings.blurRadiusPx * pixelScale)
      ..setFloat(idx++, _settings.specAngle)
      ..setFloat(idx++, _settings.specStrength)
      ..setFloat(idx++, _settings.specPower)
      ..setFloat(idx++, _settings.specWidth * pixelScale)
      ..setFloat(idx++, _settings.lightbandOffsetPx * pixelScale)
      ..setFloat(idx++, _settings.lightbandWidthPx * pixelScale)
      ..setFloat(idx++, _settings.lightbandStrength)
      ..setFloat(idx++, _settings.lightbandColor.r)
      ..setFloat(idx++, _settings.lightbandColor.g)
      ..setFloat(idx++, _settings.lightbandColor.b)
      ..setFloat(idx++, 1.0 * pixelScale)
      ..setFloat(idx++, rectCount.toDouble())
      ..setFloat(idx++, _settings.bridgeThicknessFactor);

    final safeRy = math.max(shaderSize.height, 0.001);

    for (var i = 0; i < maxRects; i++) {
      final shape = i < rectCount ? shapes[i] : null;
      if (shape != null) {
        final posNdx = (shape.center.dx - shaderSize.width * 0.5) / safeRy;
        final posNdy = (shape.center.dy - shaderSize.height * 0.5) / safeRy;
        final hszW = shape.size.width * 0.5 / safeRy;
        final hszH = shape.size.height * 0.5 / safeRy;
        final corner = shape.borderRadius / safeRy;
        shader
          ..setFloat(idx++, posNdx)
          ..setFloat(idx++, posNdy)
          ..setFloat(idx++, hszW)
          ..setFloat(idx++, hszH)
          ..setFloat(idx++, corner)
          ..setFloat(idx++, shape.color.r)
          ..setFloat(idx++, shape.color.g)
          ..setFloat(idx++, shape.color.b)
          ..setFloat(idx++, shape.color.a);
      } else {
        shader
          ..setFloat(idx++, 0.0)
          ..setFloat(idx++, 0.0)
          ..setFloat(idx++, 0.0)
          ..setFloat(idx++, 0.0)
          ..setFloat(idx++, 0.0)
          ..setFloat(idx++, 0.0)
          ..setFloat(idx++, 0.0)
          ..setFloat(idx++, 0.0)
          ..setFloat(idx++, 0.0);
      }
    }

    shader.setFloat(idx++, bridgeCount.toDouble());
    for (var i = 0; i < maxBridges; i++) {
      final bridge = i < bridgeCount ? bridges[i] : null;
      if (bridge != null) {
        final aX = (bridge.start.dx - shaderSize.width * 0.5) / safeRy;
        final aY = (bridge.start.dy - shaderSize.height * 0.5) / safeRy;
        final bX = (bridge.end.dx - shaderSize.width * 0.5) / safeRy;
        final bY = (bridge.end.dy - shaderSize.height * 0.5) / safeRy;
        final radius = bridge.radius / safeRy;
        shader
          ..setFloat(idx++, aX)
          ..setFloat(idx++, aY)
          ..setFloat(idx++, bX)
          ..setFloat(idx++, bY)
          ..setFloat(idx++, radius)
          ..setFloat(idx++, bridge.color.r)
          ..setFloat(idx++, bridge.color.g)
          ..setFloat(idx++, bridge.color.b)
          ..setFloat(idx++, bridge.color.a);
      } else {
        shader
          ..setFloat(idx++, 0.0)
          ..setFloat(idx++, 0.0)
          ..setFloat(idx++, 0.0)
          ..setFloat(idx++, 0.0)
          ..setFloat(idx++, 0.0)
          ..setFloat(idx++, 0.0)
          ..setFloat(idx++, 0.0)
          ..setFloat(idx++, 0.0)
          ..setFloat(idx++, 0.0);
      }
    }
  }

  Offset _getMidpointClosestPoint(ShapeData shape, Offset midpoint) {
    final halfWidth = shape.size.width / 2.0;
    final halfHeight = shape.size.height / 2.0;
    
    // Calculate the bounds of the inner rectangle (recessed by borderRadius)
    final innerMinX = shape.center.dx - halfWidth + shape.borderRadius;
    final innerMaxX = shape.center.dx + halfWidth - shape.borderRadius;
    final innerMinY = shape.center.dy - halfHeight + shape.borderRadius;
    final innerMaxY = shape.center.dy + halfHeight - shape.borderRadius;
    
    // Clamp midpoint to the inner rectangle bounds
    final clampX = innerMinX > innerMaxX 
        ? shape.center.dx 
        : midpoint.dx.clamp(innerMinX, innerMaxX);
    final clampY = innerMinY > innerMaxY 
        ? shape.center.dy 
        : midpoint.dy.clamp(innerMinY, innerMaxY);
        
    return Offset(clampX, clampY);
  }



  ui.Path _buildLocalUnifiedPath(List<ShapeData> localShapes, List<Rect> localRects) {
    var localUnifiedPath = ui.Path();

    for (var i = 0; i < localShapes.length; i++) {
      final shapeData = localShapes[i];
      final rect = localRects[i];
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(shapeData.borderRadius),
      );
      final path = ui.Path()..addRRect(rrect);
      localUnifiedPath = ui.Path.combine(
        ui.PathOperation.union,
        localUnifiedPath,
        path,
      );
    }

    final count = localShapes.length;
    final reach = _settings.blendPx * _settings.bridgeReachFactor;

    for (var i = 0; i < count; i++) {
      final shapeA = localShapes[i];
      for (var j = i + 1; j < count; j++) {
        final shapeB = localShapes[j];

        final midpoint = (shapeA.center + shapeB.center) / 2.0;
        final innerClosestA = _getMidpointClosestPoint(shapeA, midpoint);
        final innerClosestB = _getMidpointClosestPoint(shapeB, midpoint);

        final v = innerClosestB - innerClosestA;
        final d = v.distance;
        final direction = d > 0.001 ? v / d : Offset.zero;

        final edgeDistance = d - shapeA.borderRadius - shapeB.borderRadius;
        if (edgeDistance >= reach) {
          continue;
        }

        final t = 1.0 - edgeDistance / reach;
        final maxRadius = math.min(
          math.min(shapeA.size.width, shapeA.size.height),
          math.min(shapeB.size.width, shapeB.size.height),
        ) / 2.0;
        final width = math.min(
          _settings.blendPx * _settings.bridgeThicknessFactor,
          maxRadius,
        );

        if (edgeDistance <= 0.0) {
          // Overlapping case: draw a circle at the midpoint of the overlap to smooth the crease
          final pA = innerClosestA + direction * shapeA.borderRadius;
          final pB = innerClosestB - direction * shapeB.borderRadius;
          final overlapMidpoint = (pA + pB) / 2.0;
          final bridgeRadius = width * t;
          final bridgePath = ui.Path()
            ..addOval(Rect.fromCircle(center: overlapMidpoint, radius: bridgeRadius));
          localUnifiedPath = ui.Path.combine(
            ui.PathOperation.union,
            localUnifiedPath,
            bridgePath,
          );
          continue;
        }

        final pA = innerClosestA + direction * shapeA.borderRadius;
        final pB = innerClosestB - direction * shapeB.borderRadius;
        final mid = (pA + pB) / 2.0;

        const tc = 0.5;
        if (t <= tc) {
          // Separated phase: draw two separate circles moving towards each other
          final factor = t / tc;
          final r = width * factor;
          final dTravel = (edgeDistance * 0.5) * factor;
          final cA = pA + direction * dTravel;
          final cB = pB - direction * dTravel;
          
          if (r > 0.0) {
            final bridgePath = ui.Path()
              ..addOval(Rect.fromCircle(center: cA, radius: r))
              ..addOval(Rect.fromCircle(center: cB, radius: r));
            localUnifiedPath = ui.Path.combine(
              ui.PathOperation.union,
              localUnifiedPath,
              bridgePath,
            );
          }
        } else {
          // Merged phase: draw the Bezier curve bridge between cA and cB
          final r = width * t;
          final u = (t - tc) / (1.0 - tc);
          final dTravel = (edgeDistance * 0.5) * u;
          final cA = mid - direction * dTravel;
          final cB = mid + direction * dTravel;

          final perpendicular = Offset(-direction.dy, direction.dx);
          final a1 = cA + perpendicular * r;
          final a2 = cA - perpendicular * r;
          final b1 = cB + perpendicular * r;
          final b2 = cB - perpendicular * r;
          final cp1 = (a1 + b1) / 2.0 - perpendicular * (r * 0.5);
          final cp2 = (a2 + b2) / 2.0 + perpendicular * (r * 0.5);

          final bridgePath = ui.Path()
            ..moveTo(a1.dx, a1.dy)
            ..quadraticBezierTo(cp1.dx, cp1.dy, b1.dx, b1.dy)
            ..lineTo(b2.dx, b2.dy)
            ..quadraticBezierTo(cp2.dx, cp2.dy, a2.dx, a2.dy)
            ..close();

          localUnifiedPath = ui.Path.combine(
            ui.PathOperation.union,
            localUnifiedPath,
            bridgePath,
          );
        }
      }
    }

    return localUnifiedPath;
  }

  void _paintCapturedSkiaShader(
    PaintingContext context,
    Offset offset,
    List<ShapeData> localShapes,
  ) {
    final image = _backdropImage;
    if (image == null) return;

    _configureShader(
      _shader,
      shaderSize: size,
      bounds: Offset.zero & size,
      shapes: localShapes,
      bridges: const [],
      pixelScale: 1.0,
    );
    _shader.setImageSampler(0, image);

    context.canvas.save();
    context.canvas.translate(offset.dx, offset.dy);
    context.canvas.drawRect(Offset.zero & size, Paint()..shader = _shader);
    context.canvas.restore();
  }

  void _paintDecorativeSkiaFallback(
    PaintingContext context,
    Offset offset,
    ui.Path localUnifiedPath,
    List<ShapeData> localShapes,
    List<Rect> localRects,
  ) {
    final localBounds = localUnifiedPath.getBounds();
    final blurRadius = _settings.blurRadiusPx;

    context.pushClipPath(true, offset, localBounds, localUnifiedPath, (
      context,
      offset,
    ) {
      if (blurRadius > 0) {
        context.pushLayer(
          BackdropFilterLayer(
            filter: ui.ImageFilter.blur(sigmaX: blurRadius, sigmaY: blurRadius),
          ),
          (context, offset) {
            _drawTints(context, offset, localShapes, localRects);
          },
          offset,
        );
      } else {
        _drawTints(context, offset, localShapes, localRects);
      }
    });

    final globalUnifiedPath = localUnifiedPath.shift(offset);
    context.canvas.save();
    context.canvas.clipPath(globalUnifiedPath);
    _drawDirectionalSpecular(context.canvas, offset, globalUnifiedPath, localRects);
    context.canvas.restore();
    _drawRimHighlight(context.canvas, globalUnifiedPath);
  }

  void _drawTints(PaintingContext context, Offset offset, List<ShapeData> localShapes, List<Rect> localRects) {
    for (var i = 0; i < localShapes.length; i++) {
      final shapeData = localShapes[i];
      final rect = localRects[i].shift(offset);
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(shapeData.borderRadius),
      );
      final paint = Paint()..color = shapeData.color.withValues(alpha: _settings.fallbackTintAlpha);

      context.canvas.drawRRect(rrect, paint);
    }
  }

  void _drawDirectionalSpecular(
    Canvas canvas,
    Offset offset,
    ui.Path globalUnifiedPath,
    List<Rect> localRects,
  ) {
    final specAlpha = (_settings.specStrength / _settings.specularStrengthDivisor).clamp(0.0, _settings.maxSpecularAlpha);
    if (specAlpha <= 0.0) return;

    for (var i = 0; i < localRects.length; i++) {
      final rect = localRects[i].shift(offset);
      final shortestSide = math.max(1.0, math.min(rect.width, rect.height));
      final angularWidth = (_settings.specWidth / shortestSide * math.pi).clamp(
        _settings.minSpecularAngularWidth,
        _settings.maxSpecularAngularWidth,
      );
      final strokeWidth = (_settings.lightbandWidthPx * _settings.specularStrokeWidthScale).clamp(1.0, 4.0);

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          center: Alignment.center,
          startAngle: _settings.specAngle - angularWidth,
          endAngle: _settings.specAngle + angularWidth,
          colors: [
            Colors.transparent,
            Colors.white.withValues(alpha: specAlpha),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(rect);

      canvas.save();
      canvas.clipRect(rect.inflate(_settings.blendPx + strokeWidth * 2.0));
      canvas.drawPath(globalUnifiedPath, paint);
      canvas.restore();
    }
  }

  void _drawRimHighlight(Canvas canvas, ui.Path globalUnifiedPath) {
    final alpha = _settings.lightbandStrength.clamp(0.0, 1.0);
    if (alpha <= 0.0) return;

    final bounds = globalUnifiedPath.getBounds();
    if (bounds.isEmpty) return;

    final strokeWidth = (_settings.lightbandWidthPx * _settings.rimHighlightStrokeWidthScale).clamp(1.0, 3.0);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _settings.lightbandColor.withValues(alpha: alpha * 0.7),
          _settings.lightbandColor.withValues(alpha: alpha * 0.2),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 1.0],
      ).createShader(bounds);

    canvas.drawPath(globalUnifiedPath, paint);
  }
}

/// Widget that wraps any child to make it appear as a liquid glass droplet.
class OCLiquidGlass extends StatelessWidget {
  final bool enabled;
  final double? width;
  final double? height;
  final Color color;
  final double borderRadius;
  final BoxShadow? shadow;
  final Widget? child;

  const OCLiquidGlass({
    super.key,
    this.enabled = true,
    this.width,
    this.height,
    this.color = Colors.transparent,
    this.borderRadius = 0.0,
    this.shadow,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final outerShadow = shadow?.copyWith(
      blurStyle: BlurStyle.outer,
      offset: const Offset(0, 0),
    );

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: outerShadow != null ? [outerShadow] : null,
      ),
      child: _OCLiquidGlassRenderObjectWidget(
        enabled: enabled,
        borderRadius: borderRadius,
        color: color,
        child: child,
      ),
    );
  }
}

class _OCLiquidGlassRenderObjectWidget extends SingleChildRenderObjectWidget {
  final bool enabled;
  final double borderRadius;
  final Color color;

  const _OCLiquidGlassRenderObjectWidget({
    required this.enabled,
    required this.borderRadius,
    required this.color,
    super.child,
  });

  @override
  RenderLiquidGlass createRenderObject(BuildContext context) =>
      RenderLiquidGlass(enabled, borderRadius, color);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderLiquidGlass renderObject,
  ) {
    renderObject
      ..enabled = enabled
      ..color = color
      ..borderRadius = borderRadius;
  }
}

class RenderLiquidGlass extends RenderProxyBox {
  bool _enabled;
  double _borderRadius;
  Color _color;

  RenderLiquidGlass(this._enabled, this._borderRadius, this._color);

  bool get enabled => _enabled;
  set enabled(bool value) {
    if (_enabled == value) return;
    _enabled = value;

    final layer = _findLayer();
    if (layer != null) {
      if (_enabled) {
        layer.registeredShapes.add(this);
      } else {
        layer.registeredShapes.remove(this);
      }
      layer.markNeedsPaint();
    }
  }

  double get borderRadius => _borderRadius;
  set borderRadius(double value) {
    if (_borderRadius == value) return;
    _borderRadius = value;
    _findLayer()?.markNeedsPaint();
    markNeedsPaint();
  }

  Color get color => _color;
  set color(Color value) {
    if (_color == value) return;
    _color = value;
    _findLayer()?.markNeedsPaint();
    markNeedsPaint();
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    if (_enabled) {
      _findLayer()?.registeredShapes.add(this);
    }
  }

  @override
  void detach() {
    _findLayer()?.registeredShapes.remove(this);
    super.detach();
  }

  @override
  bool get alwaysNeedsCompositing => _enabled;

  _RenderLiquidGlassGroup? _findLayer() {
    var pr = parent;
    while (pr != null && pr is! _RenderLiquidGlassGroup) {
      pr = pr.parent;
    }
    return pr as _RenderLiquidGlassGroup?;
  }
}

/// A backwards-compatible single-rect glass widget that uses [OCLiquidGlassGroup]
/// and [OCLiquidGlass] internally to preserve existing codebase references.
class LiquidGlassMenu extends StatelessWidget {
  final bool enabled;
  final double? width;
  final double? height;
  final Color color;
  final double borderRadius;
  final BoxShadow? shadow;
  final Widget? child;
  final OCLiquidGlassSettings settings;

  const LiquidGlassMenu({
    super.key,
    this.enabled = true,
    this.width,
    this.height,
    this.color = const Color(0x1AFFFFFF),
    this.borderRadius = 16.0,
    this.shadow,
    this.child,
    this.settings = const OCLiquidGlassSettings(),
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return SizedBox(width: width, height: height, child: child);
    }

    return OCLiquidGlassGroup(
      settings: settings,
      child: OCLiquidGlass(
        width: width,
        height: height,
        borderRadius: borderRadius,
        color: color,
        shadow: shadow,
        child: child,
      ),
    );
  }
}

typedef LiquidGlass = OCLiquidGlass;
typedef LiquidGlassGroup = OCLiquidGlassGroup;
typedef LiquidGlassStage = OCLiquidGlassStage;
