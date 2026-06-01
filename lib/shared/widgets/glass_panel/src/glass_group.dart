part of '../glass_panel.dart';

/// Explicit scope for bridge blending between descendant glass panels.
class GlassGroup extends StatefulWidget {
  final Widget child;
  final GlassSettings? settings;
  final GlassMode? mode;

  const GlassGroup({
    super.key,
    required this.child,
    this.settings,
    this.mode,
  });

  @override
  State<GlassGroup> createState() => _GlassGroupState();
}

class _GlassGroupState extends State<GlassGroup> {
  ui.FragmentProgram? _program;

  @override
  void initState() {
    super.initState();
    if (GlassShaderProvider.shaderProgram != null) {
      _program = GlassShaderProvider.shaderProgram;
    } else {
      ui.FragmentProgram.fromAsset(GlassShaderProvider.shaderAssetPath).then((program) {
        if (mounted) {
          setState(() => _program = program);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stageScope = _GlassBackdropScope.maybeOf(context);
    final resolvedSettings = widget.settings ?? stageScope?.settings ?? const GlassSettings();
    final resolvedMode = widget.mode ?? stageScope?.mode ?? GlassMode.performance;

    final body = _GlassGroupScope(
      settings: resolvedSettings,
      mode: resolvedMode,
      child: _buildGroupBody(
        context,
        stageScope,
        resolvedSettings,
        resolvedMode,
      ),
    );

    return body;
  }

  Widget _buildGroupBody(
    BuildContext context,
    _GlassBackdropScope? stageScope,
    GlassSettings resolvedSettings,
    GlassMode resolvedMode,
  ) {
    if (_program == null || stageScope == null || resolvedMode == GlassMode.performance) {
      return widget.child;
    }

    return _GlassGroupRenderObject(
      shader: _program!.fragmentShader(),
      settings: resolvedSettings,
      repaint: stageScope.repaint,
      backdropImage: stageScope.backdropImage,
      backdropLogicalSize: stageScope.backdropLogicalSize,
      child: widget.child,
    );
  }
}

class _GlassGroupScope extends InheritedWidget {
  final GlassSettings settings;
  final GlassMode mode;

  const _GlassGroupScope({
    required this.settings,
    required this.mode,
    required super.child,
  });

  static _GlassGroupScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_GlassGroupScope>();
  }

  @override
  bool updateShouldNotify(_GlassGroupScope oldWidget) {
    return oldWidget.settings != settings || oldWidget.mode != mode;
  }
}

class _GlassGroupRenderObject extends SingleChildRenderObjectWidget {
  final ui.FragmentShader shader;
  final GlassSettings settings;
  final Listenable? repaint;
  final ui.Image? backdropImage;
  final Size? backdropLogicalSize;

  const _GlassGroupRenderObject({
    required this.shader,
    required this.settings,
    this.repaint,
    this.backdropImage,
    this.backdropLogicalSize,
    super.child,
  });

  @override
  _RenderGlassGroup createRenderObject(BuildContext context) {
    final position = Scrollable.maybeOf(context)?.position;
    final mediaQuery = MediaQuery.of(context);
    final renderObject = _RenderGlassGroup(
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
    _RenderGlassGroup renderObject,
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

  void _attachRouteAnimation(BuildContext ctx, _RenderGlassGroup rb) {
    final listenables = <Listenable>[];

    final routeLocal = ModalRoute.of(ctx);
    if (routeLocal?.animation != null) {
      listenables.add(routeLocal!.animation!);
    }
    if (routeLocal?.secondaryAnimation != null) {
      listenables.add(routeLocal!.secondaryAnimation!);
    }

    final rootNav = Navigator.maybeOf(ctx);
    if (rootNav != null) {
      final routeRoot = ModalRoute.of(rootNav.context);
      if (routeRoot?.animation != null) {
        listenables.add(routeRoot!.animation!);
      }
      if (routeRoot?.secondaryAnimation != null) {
        listenables.add(routeRoot!.secondaryAnimation!);
      }
    }

    final mergedRouteAnimations = listenables.isNotEmpty
        ? Listenable.merge(listenables)
        : null;

    rb.setRouteAnimations(mergedRouteAnimations);
  }

  @override
  void didUnmountRenderObject(_RenderGlassGroup renderObject) {
    renderObject.detachRepaintSources();
  }
}

class _RenderGlassGroup extends RenderProxyBox {
  static const int maxRects = 4;

  Listenable? _routeAnimations;
  ScrollPosition? _scrollPosition;
  Listenable? _externalRepaint;
  Size _screenSize;

  _RenderGlassGroup({
    required double devicePixelRatio,
    required Size screenSize,
    required ui.FragmentShader shader,
    required GlassSettings settings,
    ScrollPosition? position,
    Listenable? externalRepaint,
    ui.Image? backdropImage,
    Size? backdropLogicalSize,
  })  : _devicePixelRatio = devicePixelRatio,
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

  GlassSettings _settings;
  set settings(GlassSettings v) {
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
  final Set<RenderGlassShape> registeredShapes = {};

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
    if (cached == null ||
        _cachedLocalUnifiedPath == null ||
        _cachedBlendPx != _settings.blendPx) {
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
    final activeShapes = registeredShapes
        .where((shape) => shape.attached && !shape.size.isEmpty)
        .toList();
    if (activeShapes.isEmpty) {
      super.paint(context, offset);
      return;
    }

    final hasShaderSupport =
        ui.ImageFilter.isShaderFilterSupported && !_settings.forceCpuFallback;

    if (!hasShaderSupport) {
      final localRects = activeShapes.map(_localRectForShape).toList();
      final localShapes = <ShapeData>[];
      for (var i = 0; i < activeShapes.length; i++) {
        localShapes.add(_shapeDataForRect(activeShapes[i], localRects[i], 1.0));
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

      if (_hasUsableBackdrop && !_settings.forceCpuFallback) {
        _paintCapturedSkiaShader(context, offset, localShapes);
      } else {
        _paintDecorativeSkiaFallback(
          context,
          offset,
          localUnifiedPath,
          localShapes,
          localRects,
        );
      }

      super.paint(context, offset);
      return;
    }

    final useLocal = _settings.useLocalCoordinates;

    if (useLocal) {
      final localRects = activeShapes.map(_localRectForShape).toList();
      final localShapes = <ShapeData>[];
      for (var i = 0; i < activeShapes.length; i++) {
        localShapes.add(_shapeDataForRect(activeShapes[i], localRects[i], 1.0));
      }

      _configureShader(
        _shader,
        shaderSize: size,
        bounds: Offset.zero & size,
        shapes: localShapes,
        pixelScale: 1.0,
      );
    } else {
      final boundaryTransform = getTransformTo(null);
      final boundary = MatrixUtils.transformRect(
        boundaryTransform,
        Offset.zero & size,
      );

      final globalShapes = activeShapes
          .map((shape) => _shapeDataForRect(
                shape,
                _globalRectForShape(shape),
                _devicePixelRatio,
              ))
          .toList();

      _configureShader(
        _shader,
        shaderSize: _screenSize,
        bounds: boundary,
        shapes: globalShapes,
        pixelScale: _devicePixelRatio,
      );
    }

    context.pushLayer(
      BackdropFilterLayer(filter: ui.ImageFilter.shader(_shader)),
      super.paint,
      offset,
    );
  }

  Rect _globalRectForShape(RenderGlassShape shape) {
    return MatrixUtils.transformRect(
      shape.getTransformTo(null),
      Offset.zero & shape.size,
    );
  }

  Rect _localRectForShape(RenderGlassShape shape) {
    return MatrixUtils.transformRect(
      shape.getTransformTo(this),
      Offset.zero & shape.size,
    );
  }

  ShapeData _shapeDataForRect(
    RenderGlassShape shape,
    Rect rect,
    double pixelScale,
  ) {
    final scaledBorderRadius = shape.borderRadius * pixelScale;
    final maxRadius = math.min(rect.width * pixelScale, rect.height * pixelScale) / 2.0;
    final clampedRadius = scaledBorderRadius > maxRadius ? maxRadius : scaledBorderRadius;
    return ShapeData(
      rect.center * pixelScale,
      rect.size * pixelScale,
      math.max(0.0, clampedRadius),
      shape.color,
    );
  }

  void _configureShader(
    ui.FragmentShader shader, {
    required Size shaderSize,
    required Rect bounds,
    required List<ShapeData> shapes,
    required double pixelScale,
  }) {
    shader.setFloat(0, shaderSize.width * pixelScale);
    shader.setFloat(1, shaderSize.height * pixelScale);

    var idx = 2;
    final rectCount = shapes.length < maxRects ? shapes.length : maxRects;

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

    final safeRy = math.max(shaderSize.height * pixelScale, 0.001);

    for (var i = 0; i < maxRects; i++) {
      final shape = i < rectCount ? shapes[i] : null;
      if (shape != null) {
        final posNdx = (shape.center.dx - (shaderSize.width * pixelScale) * 0.5) / safeRy;
        final posNdy = (shape.center.dy - (shaderSize.height * pixelScale) * 0.5) / safeRy;
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

  void _drawTints(
    PaintingContext context,
    Offset offset,
    List<ShapeData> localShapes,
    List<Rect> localRects,
  ) {
    for (var i = 0; i < localShapes.length; i++) {
      final shapeData = localShapes[i];
      final rect = localRects[i].shift(offset);
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(shapeData.borderRadius),
      );
      final paint = Paint()
        ..color = shapeData.color.withValues(alpha: _settings.fallbackTintAlpha);

      context.canvas.drawRRect(rrect, paint);
    }
  }

  void _drawDirectionalSpecular(
    Canvas canvas,
    Offset offset,
    ui.Path globalUnifiedPath,
    List<Rect> localRects,
  ) {
    final specAlpha = (_settings.specStrength / _settings.specularStrengthDivisor)
        .clamp(0.0, _settings.maxSpecularAlpha);
    if (specAlpha <= 0.0) return;

    for (var i = 0; i < localRects.length; i++) {
      final rect = localRects[i].shift(offset);
      final shortestSide = math.max(1.0, math.min(rect.width, rect.height));
      final angularWidth = (_settings.specWidth / shortestSide * math.pi).clamp(
        _settings.minSpecularAngularWidth,
        _settings.maxSpecularAngularWidth,
      );
      final strokeWidth =
          (_settings.lightbandWidthPx * _settings.specularStrokeWidthScale).clamp(1.0, 4.0);

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

    final strokeWidth =
        (_settings.lightbandWidthPx * _settings.rimHighlightStrokeWidthScale).clamp(1.0, 3.0);
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
