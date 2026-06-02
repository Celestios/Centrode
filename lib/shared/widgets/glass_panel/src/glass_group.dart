part of '../glass_panel.dart';

/// Explicit scope for bridge blending between descendant glass panels.
class GlassGroup extends StatefulWidget {
  final Widget child;
  final GlassSettings? settings;
  final GlassMode? mode;

  const GlassGroup({super.key, required this.child, this.settings, this.mode});

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
      ui.FragmentProgram.fromAsset(GlassShaderProvider.shaderAssetPath).then((
        program,
      ) {
        if (mounted) {
          setState(() => _program = program);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stageScope = _GlassBackdropScope.maybeOf(context);
    final resolvedSettings =
        widget.settings ?? stageScope?.settings ?? const GlassSettings();
    final resolvedMode =
        widget.mode ?? stageScope?.mode ?? GlassMode.performance;

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
    if (_program == null || resolvedMode == GlassMode.performance) {
      return widget.child;
    }

    final bool nativeShaderSupported = ui.ImageFilter.isShaderFilterSupported &&
        !resolvedSettings.forceCpuFallback;

    if (stageScope == null && !nativeShaderSupported) {
      return widget.child;
    }

    return _GlassGroupRenderObject(
      shader: _program!.fragmentShader(),
      settings: resolvedSettings,
      repaint: null, // Stage now drives repaints via setState→updateRenderObject
      backdropImage: stageScope?.backdropImage,
      backdropLogicalSize: stageScope?.backdropLogicalSize,
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

    final bool nativeShaderSupported = ui.ImageFilter.isShaderFilterSupported &&
        !_settings.forceCpuFallback;

    final inflatedBounds = _inflatedBoundsForPaint();
    final localShapes = activeShapes.map((shape) {
      final localRect = _localRectForShape(shape);
      return _shapeDataForRect(shape, localRect, _devicePixelRatio);
    }).toList();

    final boundaryTransform = getTransformTo(null);
    final globalTopLeft = MatrixUtils.transformPoint(
      boundaryTransform,
      Offset.zero,
    );

    final uLayerSize = inflatedBounds.size * _devicePixelRatio;
    final uInflatedOffset = inflatedBounds.topLeft * _devicePixelRatio;
    final uGlobalOffset = _settings.useLocalCoordinates
        ? Offset.zero
        : (globalTopLeft * _devicePixelRatio);

    if (nativeShaderSupported) {
      _configureShader(
        _shader,
        pathMode: 0.0,
        layerSize: uLayerSize,
        inflatedOffset: uInflatedOffset,
        globalOffset: uGlobalOffset,
        bgSize: uLayerSize,
        shapes: localShapes,
        pixelScale: _devicePixelRatio,
      );

      context.pushClipRect(
        true,
        offset,
        inflatedBounds,
        (innerCtx, innerOffset) {
          innerCtx.pushLayer(
            BackdropFilterLayer(filter: ui.ImageFilter.shader(_shader)),
            (filterCtx, filterOffset) {
              filterCtx.canvas.drawRect(
                inflatedBounds.shift(filterOffset),
                Paint()..color = const Color(0x01000000),
              );
              super.paint(filterCtx, filterOffset);
            },
            innerOffset,
          );
        },
      );
      return;
    }

    final backdropImage = _backdropImage;
    final backdropLogicalSize = _backdropLogicalSize;

    if (backdropImage != null && backdropLogicalSize != null) {
      final physicalScreenSize = backdropLogicalSize * _devicePixelRatio;

      // BUG FIX: The CPU snapshot path samples a full-screen buffer. UV mapping
      // fundamentally requires absolute physical screen coordinates — useLocalCoordinates
      // must not zero-out the origin or every panel maps to the same (0,0) pixel.
      final absoluteGlobalOffset = globalTopLeft * _devicePixelRatio;

      _configureShader(
        _shader,
        pathMode: 1.0,
        layerSize: uLayerSize,
        inflatedOffset: uInflatedOffset,
        globalOffset: absoluteGlobalOffset,
        bgSize: physicalScreenSize,
        shapes: localShapes,
        pixelScale: _devicePixelRatio,
      );

      _shader.setImageSampler(0, backdropImage);

      final drawBounds = inflatedBounds.shift(offset);
      final localDrawBounds = Offset.zero & drawBounds.size;

      context.canvas.save();
      context.canvas.translate(drawBounds.left, drawBounds.top);
      context.canvas.clipRect(localDrawBounds);
      context.canvas.saveLayer(localDrawBounds, Paint());
      context.canvas.drawRect(localDrawBounds, Paint()..shader = _shader);
      context.canvas.restore();
      context.canvas.restore();

      super.paint(context, offset);
      return;
    }

    // =========================================================================
    // PATH C: PURE CPU FALLBACK (If image capture is not initialized yet)
    // =========================================================================
    final localRects = activeShapes.map(_localRectForShape).toList();
    final fallbackLocalShapes = <ShapeData>[];
    for (var i = 0; i < activeShapes.length; i++) {
      fallbackLocalShapes.add(_shapeDataForRect(activeShapes[i], localRects[i], 1.0));
    }

    final ui.Path localUnifiedPath;
    if (_isLocalPathCacheValid(localRects)) {
      localUnifiedPath = _cachedLocalUnifiedPath!;
    } else {
      localUnifiedPath = _buildLocalUnifiedPath(fallbackLocalShapes, localRects);
      _cachedLocalUnifiedPath = localUnifiedPath;
      _cachedLocalRects = localRects;
      _cachedBlendPx = _settings.blendPx;
    }

    _paintDecorativeSkiaFallback(
      context,
      offset,
      localUnifiedPath,
      fallbackLocalShapes,
      localRects,
    );

    super.paint(context, offset);
  }


  /// Returns the widget's logical bounds inflated by enough margin for the
  /// refraction and blur vectors to always land on valid texture memory.
  /// Note: blurRadiusPx is intentionally excluded — it samples existing pixels
  /// centripetally and does not need outward texture headroom.
  Rect _inflatedBoundsForPaint() {
    final inflation = _settings.distortFalloffPx + _settings.blendPx;
    return (Offset.zero & size).inflate(inflation);
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
    final maxRadius =
        math.min(rect.width * pixelScale, rect.height * pixelScale) / 2.0;
    final clampedRadius = scaledBorderRadius > maxRadius
        ? maxRadius
        : scaledBorderRadius;
    return ShapeData(
      rect.center * pixelScale,
      rect.size * pixelScale,
      math.max(0.0, clampedRadius),
      shape.color,
    );
  }

  void _configureShader(
    ui.FragmentShader shader, {
    required double pathMode,
    required Size layerSize,
    required Offset inflatedOffset,
    required Offset globalOffset,
    required Size bgSize,
    required List<ShapeData> shapes,
    required double pixelScale,
  }) {
    var idx = 0;
    shader.setFloat(idx++, pathMode);
    shader.setFloat(idx++, layerSize.width);
    shader.setFloat(idx++, layerSize.height);
    shader.setFloat(idx++, inflatedOffset.dx);
    shader.setFloat(idx++, inflatedOffset.dy);
    shader.setFloat(idx++, globalOffset.dx);
    shader.setFloat(idx++, globalOffset.dy);
    shader.setFloat(idx++, bgSize.width);
    shader.setFloat(idx++, bgSize.height);

    shader.setFloat(idx++, _settings.blendPx * pixelScale);
    shader.setFloat(idx++, _settings.refractStrength);
    shader.setFloat(idx++, _settings.distortFalloffPx * pixelScale);
    shader.setFloat(idx++, _settings.distortExponent);
    shader.setFloat(idx++, _settings.blurRadiusPx * pixelScale);
    shader.setFloat(idx++, _settings.specAngle);
    shader.setFloat(idx++, _settings.specStrength);
    shader.setFloat(idx++, _settings.specPower);
    shader.setFloat(idx++, _settings.specWidth * pixelScale);
    shader.setFloat(idx++, _settings.lightbandOffsetPx * pixelScale);
    shader.setFloat(idx++, _settings.lightbandWidthPx * pixelScale);
    shader.setFloat(idx++, _settings.lightbandStrength);
    shader.setFloat(idx++, _settings.lightbandColor.r);
    shader.setFloat(idx++, _settings.lightbandColor.g);
    shader.setFloat(idx++, _settings.lightbandColor.b);
    shader.setFloat(idx++, _settings.aaPx * pixelScale);

    final rectCount = shapes.length < maxRects ? shapes.length : maxRects;
    shader.setFloat(idx++, rectCount.toDouble());
    shader.setFloat(idx++, _settings.bridgeThicknessFactor);

    for (var i = 0; i < maxRects; i++) {
      final shape = i < rectCount ? shapes[i] : null;
      if (shape != null) {
        shader.setFloat(idx++, shape.center.dx);
        shader.setFloat(idx++, shape.center.dy);
        shader.setFloat(idx++, shape.size.width * 0.5);
        shader.setFloat(idx++, shape.size.height * 0.5);
        shader.setFloat(idx++, shape.borderRadius);
        shader.setFloat(idx++, shape.color.r);
        shader.setFloat(idx++, shape.color.g);
        shader.setFloat(idx++, shape.color.b);
        shader.setFloat(idx++, shape.color.a);
      } else {
        for (var j = 0; j < 9; j++) {
          shader.setFloat(idx++, 0.0);
        }
      }
    }
  }

  ui.Path _buildLocalUnifiedPath(
    List<ShapeData> localShapes,
    List<Rect> localRects,
  ) {
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
    _drawDirectionalSpecular(
      context.canvas,
      offset,
      globalUnifiedPath,
      localRects,
    );
    context.canvas.restore();
    // FIX: Pass local geometry so the rim highlight can project per-shape
    _drawRimHighlight(context.canvas, offset, globalUnifiedPath, localRects, localShapes);
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
        ..color = shapeData.color.withValues(
          alpha: _settings.fallbackTintAlpha,
        );

      context.canvas.drawRRect(rrect, paint);
    }
  }

  void _drawDirectionalSpecular(
    Canvas canvas,
    Offset offset,
    ui.Path globalUnifiedPath,
    List<Rect> localRects,
  ) {
    final specAlpha =
        (_settings.specStrength / _settings.specularStrengthDivisor).clamp(
          0.0,
          _settings.maxSpecularAlpha,
        );
    if (specAlpha <= 0.0) return;

    for (var i = 0; i < localRects.length; i++) {
      final rect = localRects[i].shift(offset);
      final shortestSide = math.max(1.0, math.min(rect.width, rect.height));
      final angularWidth = (_settings.specWidth / shortestSide * math.pi).clamp(
        _settings.minSpecularAngularWidth,
        _settings.maxSpecularAngularWidth,
      );
      final strokeWidth =
          (_settings.lightbandWidthPx * _settings.specularStrokeWidthScale)
              .clamp(1.0, 4.0);

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

  void _drawRimHighlight(
    Canvas canvas,
    Offset offset,
    ui.Path globalUnifiedPath,
    List<Rect> localRects,
    List<ShapeData> localShapes,
  ) {
    final alpha = _settings.lightbandStrength.clamp(0.0, 1.0);
    if (alpha <= 0.0) return;

    final strokeWidth =
        (_settings.lightbandWidthPx * _settings.rimHighlightStrokeWidthScale)
            .clamp(1.0, 3.0);

    canvas.save();
    // Clip to the unified path so only the inner half of each doubled stroke
    // is visible — equivalent to an inner stroke without a dedicated path op.
    canvas.clipPath(globalUnifiedPath);

    for (var i = 0; i < localRects.length; i++) {
      final rect = localRects[i].shift(offset);
      final shapeData = localShapes[i];

      // Anchor the SweepGradient to each individual shape rect so the
      // gradient centre and radius are local — the correct fix for the
      // macro-gradient corner clipping that affected the unified-bounds approach.
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 2.0 // doubled; outer half clipped above
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round
        ..shader = SweepGradient(
          center: Alignment.center,
          colors: [
            _settings.lightbandColor.withValues(alpha: alpha * 0.7),
            _settings.lightbandColor.withValues(alpha: 0.0),
            _settings.lightbandColor.withValues(alpha: 0.0),
            _settings.lightbandColor.withValues(alpha: alpha * 0.7),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
          transform: GradientRotation(_settings.specAngle),
        ).createShader(rect);

      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(shapeData.borderRadius),
      );
      canvas.drawRRect(rrect, paint);
    }

    canvas.restore();
  }
}
