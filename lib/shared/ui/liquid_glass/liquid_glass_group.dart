part of 'liquid_glass_menu.dart';

/// Container widget that manages multiple liquid glass shapes and applies the shader effect.
/// This widget loads the fragment shader and creates a render layer that collects
/// all LiquidGlass children and applies the unified glass effect to them.
class LiquidGlassGroup extends StatefulWidget {
  final LiquidGlassSettings settings;
  final Listenable? repaint;
  final ui.Image? backdropImage;
  final Size? backdropLogicalSize;
  final Widget child;

  const LiquidGlassGroup({
    super.key,
    required this.settings,
    required this.child,
    this.repaint,
    this.backdropImage,
    this.backdropLogicalSize,
  });

  @override
  State<LiquidGlassGroup> createState() => _LiquidGlassGroupState();
}

class _LiquidGlassGroupState extends State<LiquidGlassGroup> {
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
  final LiquidGlassSettings settings;
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

  Listenable? _routeAnimations;
  ScrollPosition? _scrollPosition;
  Listenable? _externalRepaint;
  Size _screenSize;

  _RenderLiquidGlassGroup({
    required double devicePixelRatio,
    required Size screenSize,
    required ui.FragmentShader shader,
    required LiquidGlassSettings settings,
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

  LiquidGlassSettings _settings;
  set settings(LiquidGlassSettings v) {
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

    final hasShaderSupport = ui.ImageFilter.isShaderFilterSupported && !_settings.forceCpuFallback;

    if (!hasShaderSupport) {
      final localRects = activeShapes.map((s) => _localRectForShape(s)).toList();
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
        _paintDecorativeSkiaFallback(context, offset, localUnifiedPath, localShapes, localRects);
      }

      super.paint(context, offset);
      return;
    }

    final useLocal = _settings.useLocalCoordinates;

    if (useLocal) {
      final localRects = activeShapes.map((s) => _localRectForShape(s)).toList();
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

      final globalShapes = activeShapes.map((s) => _shapeDataForRect(s, _globalRectForShape(s), _devicePixelRatio)).toList();

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

  ShapeData _shapeDataForRect(RenderLiquidGlass shape, Rect rect, double pixelScale) {
    final scaledBorderRadius = shape.borderRadius * pixelScale;
    final maxRadius = math.min(rect.width, rect.height) / 2.0;
    final clampedRadius = scaledBorderRadius > maxRadius
        ? maxRadius
        : scaledBorderRadius;
    return ShapeData(
      rect.center,
      rect.size,
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
