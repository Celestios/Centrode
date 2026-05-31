import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'liquid_glass_settings.dart';
import 'liquid_glass_shader_provider.dart';

/// Simplified shape data structure used to pass geometry information to the shader.
/// Each LiquidGlass widget gets converted into this format for GPU processing.
class ShapeData {
  final Offset center;        // Center position of the glass shape
  final Size size;           // Width and height of the glass shape
  final double borderRadius; // Border radius (clamped to half of smaller dimension)
  final Color color;         // Optional tint color for the glass shape
  ShapeData(this.center, this.size, this.borderRadius, this.color);
}

/// Container widget that manages multiple liquid glass shapes and applies the shader effect.
/// This widget loads the fragment shader and creates a render layer that collects
/// all LiquidGlass children and applies the unified glass effect to them.
class OCLiquidGlassGroup extends StatefulWidget {
  final OCLiquidGlassSettings settings;
  final Listenable? repaint;
  final Widget child;

  const OCLiquidGlassGroup({
    super.key,
    required this.settings,
    required this.child,
    this.repaint,
  });

  @override
  State<OCLiquidGlassGroup> createState() => _OCLiquidGlassGroupState();
}

class _OCLiquidGlassGroupState extends State<OCLiquidGlassGroup> {
  ui.FragmentProgram? _program;

  @override
  void initState() {
    super.initState();
    // Check if shader is already preloaded by the provider
    if (LiquidGlassShaderProvider.shaderProgram != null) {
      _program = LiquidGlassShaderProvider.shaderProgram;
    } else {
      // Fallback: load asynchronously if not preloaded
      ui.FragmentProgram.fromAsset(
        'shaders/liquid_glass.frag',
      ).then((p) => setState(() => _program = p));
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
      child: widget.child,
    );
  }
}

class _LiquidGlassGroupRenderObject extends SingleChildRenderObjectWidget {
  final ui.FragmentShader shader;
  final OCLiquidGlassSettings settings;
  final Listenable? repaint;

  const _LiquidGlassGroupRenderObject({
    required this.shader,
    required this.settings,
    this.repaint,
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
      ..externalRepaint = repaint;

    _attachRouteAnimation(context, renderObject);
  }

  void _attachRouteAnimation(BuildContext ctx, _RenderLiquidGlassGroup rb) {
    final List<Listenable> listenables = [];

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
    required OCLiquidGlassSettings settings,
    ScrollPosition? position,
    Listenable? externalRepaint,
  }) : _devicePixelRatio = devicePixelRatio,
        _screenSize = screenSize,
        _shader = shader,
        _settings = settings,
        _scrollPosition = position,
        _externalRepaint = externalRepaint
  {
    _scrollPosition?.addListener(_onScroll);
    _externalRepaint?.addListener(markNeedsPaint);
  }

  set screenSize(Size v) {
    if (_screenSize == v) return;
    _screenSize = v;
    markNeedsPaint();
  }

  set externalRepaint(Listenable? v) {
    if (identical(v, _externalRepaint)) return;
    _externalRepaint?.removeListener(markNeedsPaint);
    _externalRepaint = v;
    _externalRepaint?.addListener(markNeedsPaint);
  }

  set scrollPosition(ScrollPosition? value) {
    if (value == _scrollPosition) return;
    _scrollPosition?.removeListener(_onScroll);
    _scrollPosition = value;
    _scrollPosition?.addListener(_onScroll);
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

  final ui.FragmentShader _shader;
  final Set<RenderLiquidGlass> registeredShapes = {};

  void setRouteAnimations(Listenable? routeAnimations) {
    _routeAnimations?.removeListener(markNeedsPaint);
    _routeAnimations = routeAnimations;
    _routeAnimations?.addListener(markNeedsPaint);
  }

  void detachRepaintSources() {
    _routeAnimations?.removeListener(markNeedsPaint);
    _routeAnimations = null;
    _scrollPosition?.removeListener(_onScroll);
    _externalRepaint?.removeListener(markNeedsPaint);
  }

  @override
  void attach(PipelineOwner owner) {
    super.attach(owner);
    markNeedsPaint();
  }

  @override
  void detach() {
    detachRepaintSources();
    super.detach();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  @override
  void paint(PaintingContext context, Offset offset) {
    final shapes = <ShapeData>[];
    
    // Debug print boundary information
    final boundaryTransform = getTransformTo(null);
    final boundary = MatrixUtils.transformRect(
      boundaryTransform,
      Offset.zero & size,
    );
    
    debugPrint('--- [LiquidGlass Debug] Group Paint ---');
    debugPrint('Device Pixel Ratio: $_devicePixelRatio');
    debugPrint('Screen Size: $_screenSize');
    debugPrint('Group Boundary (logical): $boundary');
    debugPrint('Group Boundary (physical): L:${boundary.left * _devicePixelRatio}, T:${boundary.top * _devicePixelRatio}, R:${boundary.right * _devicePixelRatio}, B:${boundary.bottom * _devicePixelRatio}');
    debugPrint('Group paint offset: $offset');
    debugPrint('Group globalToLocal: ${localToGlobal(Offset.zero)}');

    for (var shape in registeredShapes) {
      if (!shape.attached || shape.size.isEmpty) continue;
      
      final transform = shape.getTransformTo(null);
      final rect = MatrixUtils.transformRect(
        transform,
        Offset.zero & shape.size,
      );
      
      final maxRadius = (rect.size.width < rect.size.height 
          ? rect.size.width 
          : rect.size.height) / 2.0;
      final clampedRadius = shape.borderRadius > maxRadius 
          ? maxRadius 
          : shape.borderRadius;

      final shapeLocalOffset = shape.localToGlobal(Offset.zero) - localToGlobal(Offset.zero);
      debugPrint('  Shape:');
      debugPrint('    Local Offset: $shapeLocalOffset');
      debugPrint('    Size: ${shape.size}');
      debugPrint('    Border Radius: ${shape.borderRadius}');
      debugPrint('    Global Rect: $rect');
      debugPrint('    Physical Center: ${rect.center * _devicePixelRatio}');
      debugPrint('    Physical Size: ${Size(rect.size.width * _devicePixelRatio, rect.size.height * _devicePixelRatio)}');

      shapes.add(ShapeData(rect.center, rect.size, clampedRadius, shape.color));
    }

    if (shapes.isEmpty) {
      debugPrint('  No shapes registered.');
      super.paint(context, offset);
      return;
    }

    final hasShaderSupport = ui.ImageFilter.isShaderFilterSupported;
    debugPrint('  Active Pipeline: ${hasShaderSupport ? "Pipeline A (GPU Shader)" : "Pipeline B (Skia Fallback)"}');

    if (!hasShaderSupport) {
      // Pipeline B: Skia Fallback mode (unified combined path union with a single BackdropFilter blur)
      ui.Path localUnifiedPath = ui.Path();
      
      // Collect shapes to build path union and add liquid "metaball" bridges between close buttons
      for (var shape in registeredShapes) {
        if (!shape.attached || shape.size.isEmpty) continue;
        
        final shapeOffset = shape.localToGlobal(Offset.zero) - localToGlobal(Offset.zero);
        final rect = shapeOffset & shape.size;
        final rrect = RRect.fromRectAndRadius(rect, Radius.circular(shape.borderRadius));
        final path = ui.Path()..addRRect(rrect);
        
        localUnifiedPath = ui.Path.combine(ui.PathOperation.union, localUnifiedPath, path);
      }

      // Add fluid vector metaball bridges (sticky oil/water link animation) when buttons are close to each other
      final shapeList = registeredShapes.toList();
      for (int i = 0; i < shapeList.length; i++) {
        final shapeA = shapeList[i];
        if (!shapeA.attached || shapeA.size.isEmpty) continue;
        final offsetA = shapeA.localToGlobal(Offset.zero) - localToGlobal(Offset.zero);
        final rectA = offsetA & shapeA.size;
        final cA = rectA.center;
        final rA = (rectA.width + rectA.height) / 4.0; // average radius approximation

        for (int j = i + 1; j < shapeList.length; j++) {
          final shapeB = shapeList[j];
          if (!shapeB.attached || shapeB.size.isEmpty) continue;
          final offsetB = shapeB.localToGlobal(Offset.zero) - localToGlobal(Offset.zero);
          final rectB = offsetB & shapeB.size;
          final cB = rectB.center;
          final rB = (rectB.width + rectB.height) / 4.0;

          final dir = cB - cA;
          final d = dir.distance;
          if (d == 0.0) continue;

          final db = d - (rA + rB);
          final maxBridgeDist = _settings.blendPx * 1.5;

          if (db > 0.0 && db < maxBridgeDist) {
            final v = dir / d; // direction vector
            final p = Offset(-v.dy, v.dx); // perpendicular vector
            
            final w = _settings.blendPx * 0.8 * (1.0 - db / maxBridgeDist);
            if (w <= 0.0) continue;

            final pA = cA + v * rA;
            final pB = cB - v * rB;

            final a1 = pA + p * w;
            final a2 = pA - p * w;
            final b1 = pB + p * w;
            final b2 = pB - p * w;

            final cp1 = (a1 + b1) / 2.0 - p * (w * 0.5);
            final cp2 = (a2 + b2) / 2.0 + p * (w * 0.5);

            final bridgePath = ui.Path()
              ..moveTo(a1.dx, a1.dy)
              ..quadraticBezierTo(cp1.dx, cp1.dy, b1.dx, b1.dy)
              ..lineTo(b2.dx, b2.dy)
              ..quadraticBezierTo(cp2.dx, cp2.dy, a2.dx, a2.dy)
              ..close();

            localUnifiedPath = ui.Path.combine(ui.PathOperation.union, localUnifiedPath, bridgePath);
          }
        }
      }
      
      final globalUnifiedPath = localUnifiedPath.shift(offset);
      final bounds = globalUnifiedPath.getBounds();
      final localBounds = localUnifiedPath.getBounds();

      // 1. Unified Blur & Tint (Clipped using pushClipPath to restrict blur to shapes)
      final blurRadius = _settings.blurRadiusPx;
      if (blurRadius > 0) {
        context.pushClipPath(
          true, // needsCompositing
          offset,
          localBounds,
          localUnifiedPath,
          (context, offset) {
            context.pushLayer(
              BackdropFilterLayer(
                filter: ui.ImageFilter.blur(sigmaX: blurRadius, sigmaY: blurRadius),
              ),
              (context, offset) {
                // Draw individual tints inside the blurred area
                for (var shape in registeredShapes) {
                  if (!shape.attached || shape.size.isEmpty) continue;
                  final shapeOffset = shape.localToGlobal(Offset.zero) - localToGlobal(Offset.zero);
                  final rect = (offset + shapeOffset) & shape.size;
                  final rrect = RRect.fromRectAndRadius(rect, Radius.circular(shape.borderRadius));
                  final paintBg = Paint()..color = shape.color.withValues(alpha: 0.12);
                  context.canvas.drawRRect(rrect, paintBg);
                }
              },
              offset,
            );
          },
        );
      } else {
        context.pushClipPath(
          true,
          offset,
          localBounds,
          localUnifiedPath,
          (context, offset) {
            // Just draw individual tints without blur
            for (var shape in registeredShapes) {
              if (!shape.attached || shape.size.isEmpty) continue;
              final shapeOffset = shape.localToGlobal(Offset.zero) - localToGlobal(Offset.zero);
              final rect = (offset + shapeOffset) & shape.size;
              final rrect = RRect.fromRectAndRadius(rect, Radius.circular(shape.borderRadius));
              final paintBg = Paint()..color = shape.color.withValues(alpha: 0.12);
              context.canvas.drawRRect(rrect, paintBg);
            }
          },
        );
      }

      // Draw refraction globally on the unified path to prevent rigid internal borders!
      final refractAlpha = (_settings.refractStrength.abs() * 3.0).clamp(0.0, 1.0);
      final specAlpha = (_settings.specStrength / 5.0).clamp(0.0, 1.0);
      final blendScale = (_settings.blendPx / 20.0).clamp(0.3, 2.5);

      context.canvas.save();
      // Clip to the global unified path so refraction/highlights only draw inside the merged shape
      context.canvas.clipPath(globalUnifiedPath);

      // A. Simulated Refraction (Inner shadow gradient in bottom-right of the entire combined shape)
      final refractPaint = Paint()
        ..shader = LinearGradient(
          colors: [Colors.black.withValues(alpha: refractAlpha), Colors.transparent],
          begin: Alignment(1.0 * blendScale, 1.0 * blendScale),
          end: Alignment(-0.2 * blendScale, -0.2 * blendScale),
        ).createShader(bounds)
        ..blendMode = BlendMode.multiply;
      context.canvas.drawPath(globalUnifiedPath, refractPaint);

      context.canvas.restore();

      final borderWidth = (_settings.lightbandWidthPx * 0.08).clamp(1.0, 4.0);

      // B. Specular Highlight (Stroke-drawn along the top-left boundary, localized to each button)
      // This behaves like a sharp metal edge that refracts light, only affecting the border.
      // As specStrength increases, it spreads and covers more of the border.
      // We clip to the vicinity of each shape to localize the LinearGradient, but without drawing internal borders.
      for (var shape in registeredShapes) {
        if (!shape.attached || shape.size.isEmpty) continue;

        final shapeOffset = shape.localToGlobal(Offset.zero) - localToGlobal(Offset.zero);
        final rect = (offset + shapeOffset) & shape.size;

        context.canvas.save();
        context.canvas.clipRect(rect.inflate(borderWidth * 2.0 + _settings.blendPx));

        final specPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth * 1.5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(
            colors: [
              Colors.white.withValues(alpha: specAlpha),
              Colors.white.withValues(alpha: specAlpha * 0.5),
              Colors.transparent,
            ],
            stops: [
              0.0,
              (0.1 + (_settings.specStrength / 10.0) * blendScale).clamp(0.1, 0.8),
              (0.3 + (_settings.specStrength / 5.0) * blendScale).clamp(0.3, 1.0),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(rect);

        context.canvas.drawPath(globalUnifiedPath, specPaint);
        context.canvas.restore();
      }

      // C. Unified flowing rim border locally for each shape so the light source is local to each button
      for (var shape in registeredShapes) {
        if (!shape.attached || shape.size.isEmpty) continue;

        final shapeOffset = shape.localToGlobal(Offset.zero) - localToGlobal(Offset.zero);
        final rect = (offset + shapeOffset) & shape.size;

        context.canvas.save();
        context.canvas.clipRect(rect.inflate(borderWidth * 2.0 + _settings.blendPx));

        final rimPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..shader = LinearGradient(
            colors: [
              _settings.lightbandColor.withValues(alpha: _settings.lightbandStrength),
              _settings.lightbandColor.withValues(alpha: _settings.lightbandStrength * 0.4),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ).createShader(rect);

        context.canvas.drawPath(globalUnifiedPath, rimPaint);
        context.canvas.restore();
      }
      
      // Draw actual children on top
      super.paint(context, offset);
      return;
    }

    // Pipeline A: GPU Shader Path

    final sh = _shader;
    
    // Bind u_size (indices 0 and 1)
    sh.setFloat(0, _screenSize.width * _devicePixelRatio);
    sh.setFloat(1, _screenSize.height * _devicePixelRatio);

    var idx = 2;

    // Global shader parameters
    sh
      ..setFloat(idx++, boundary.left * _devicePixelRatio)
      ..setFloat(idx++, boundary.top * _devicePixelRatio)
      ..setFloat(idx++, boundary.right * _devicePixelRatio)
      ..setFloat(idx++, boundary.bottom * _devicePixelRatio)
      
      ..setFloat(idx++, _settings.blendPx * _devicePixelRatio)
      ..setFloat(idx++, _settings.refractStrength)
      ..setFloat(idx++, _settings.distortFalloffPx * _devicePixelRatio)
      ..setFloat(idx++, _settings.distortExponent)
      
      ..setFloat(idx++, _settings.blurRadiusPx * _devicePixelRatio)
      
      ..setFloat(idx++, _settings.specAngle)
      ..setFloat(idx++, _settings.specStrength)
      ..setFloat(idx++, _settings.specPower)
      ..setFloat(idx++, _settings.specWidth * _devicePixelRatio)
      
      ..setFloat(idx++, _settings.lightbandOffsetPx * _devicePixelRatio)
      ..setFloat(idx++, _settings.lightbandWidthPx * _devicePixelRatio)
      ..setFloat(idx++, _settings.lightbandStrength)
      ..setFloat(idx++, _settings.lightbandColor.r)
      ..setFloat(idx++, _settings.lightbandColor.g)
      ..setFloat(idx++, _settings.lightbandColor.b)
      
      ..setFloat(idx++, 1.0 * _devicePixelRatio) // 1px AA
      ..setFloat(idx++, shapes.length.toDouble());

    for (var i = 0; i < shapes.length && i < maxRects; i++) {
      final s = shapes[i];
      sh
        ..setFloat(idx++, s.center.dx * _devicePixelRatio)
        ..setFloat(idx++, s.center.dy * _devicePixelRatio)
        ..setFloat(idx++, s.size.width * _devicePixelRatio)
        ..setFloat(idx++, s.size.height * _devicePixelRatio)
        ..setFloat(idx++, s.borderRadius * _devicePixelRatio)
        ..setFloat(idx++, s.color.r)
        ..setFloat(idx++, s.color.g)
        ..setFloat(idx++, s.color.b)
        ..setFloat(idx++, s.color.a);
    }

    context.pushLayer(
      BackdropFilterLayer(
        filter: ui.ImageFilter.shader(sh),
      ),
      super.paint,
      offset,
    );
  }
}

/// Widget that wraps any child to make it appear as a liquid glass droplet.
class OCLiquidGlass extends SingleChildRenderObjectWidget {
  final bool enabled;
  final double? width;
  final double? height;
  final Color color;
  final double borderRadius;
  final BoxShadow? shadow;
  
  const OCLiquidGlass({
    super.key,
    this.enabled = true,
    this.width,
    this.height,
    this.color = Colors.transparent,
    this.borderRadius = 0.0,
    this.shadow,
    super.child,
  });

  @override
  RenderLiquidGlass createRenderObject(BuildContext context) =>
      RenderLiquidGlass(enabled, borderRadius, color);

  @override
  void updateRenderObject(BuildContext context, RenderLiquidGlass renderObject) {
    renderObject
      ..enabled = enabled
      ..color = color
      ..borderRadius = borderRadius;
  }

  @override
  Widget? get child {
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
      child: super.child,
    );
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
