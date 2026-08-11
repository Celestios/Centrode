part of '../glass_panel.dart';

/// A self-contained glassmorphic panel that can render via shader or fallback blur.
class GlassPanel extends StatelessWidget {
  final Widget child;

  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  final double borderRadius;
  final Color? color;
  final double blur;
  final BoxShadow? shadow;
  final Border? border;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  final Duration? duration;
  final Curve curve;

  final GlassMode? mode;
  final bool enableBackdrop;

  const GlassPanel({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 16.0,
    this.color,
    this.blur = 10.0,
    this.enableBackdrop = true,
    this.shadow,
    this.border,
    this.onTap,
    this.onLongPress,
    this.duration,
    this.curve = Curves.easeInOut,
    this.mode,
  });

  @override
  Widget build(BuildContext context) {
    final stageScope = _GlassBackdropScope.maybeOf(context);
    final groupScope = _GlassGroupScope.maybeOf(context);
    final resolvedMode =
        mode ?? groupScope?.mode ?? stageScope?.mode ?? GlassMode.performance;
    final hasStage = stageScope != null;
    final useQuality = hasStage && resolvedMode == GlassMode.quality;

    final shouldIsolate =
        useQuality &&
        (groupScope == null || groupScope.mode != GlassMode.quality);
    if (shouldIsolate) {
      final resolvedSettings = groupScope?.settings ?? stageScope.settings;
      return GlassGroup(
        settings: resolvedSettings,
        mode: resolvedMode,
        child: _GlassPanelBody(
          width: width,
          height: height,
          padding: padding,
          margin: margin,
          borderRadius: borderRadius,
          color: color,
          blur: blur,
          enableBackdrop: enableBackdrop,
          shadow: shadow,
          border: border,
          onTap: onTap,
          onLongPress: onLongPress,
          duration: duration,
          curve: curve,
          useQuality: useQuality,
          child: child,
        ),
      );
    }

    return _GlassPanelBody(
      width: width,
      height: height,
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      color: color,
      blur: blur,
      enableBackdrop: enableBackdrop,
      shadow: shadow,
      border: border,
      onTap: onTap,
      onLongPress: onLongPress,
      duration: duration,
      curve: curve,
      useQuality: useQuality,
      child: child,
    );
  }
}

class _GlassPanelBody extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;
  final double blur;
  final bool enableBackdrop;
  final BoxShadow? shadow;
  final Border? border;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Duration? duration;
  final Curve curve;
  final bool useQuality;

  const _GlassPanelBody({
    required this.child,
    required this.width,
    required this.height,
    required this.padding,
    required this.margin,
    required this.borderRadius,
    required this.color,
    required this.blur,
    required this.enableBackdrop,
    required this.shadow,
    this.border,
    required this.onTap,
    required this.onLongPress,
    required this.duration,
    required this.curve,
    required this.useQuality,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final resolvedColor = color ?? theme.cardColor.withValues(alpha: 0.85);
    final shape = borderRadius >= 100.0
        ? const StadiumBorder()
        : ContinuousRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          );
    final interactiveChild = _buildInteractiveContent(shape);

    if (useQuality) {
      final outerShadow = shadow?.copyWith(
        blurStyle: BlurStyle.outer,
        offset: const Offset(0, 0),
      );

      final panelChild = _buildQualityPanel(
        outerShadow: outerShadow,
        content: interactiveChild,
        glassColor: resolvedColor,
      );

      return panelChild;
    }

    final isDark = theme.brightness == Brightness.dark;
    final baseColor = color ??
        (isDark
            ? const Color(0xFF141418).withValues(alpha: 0.65)
            : theme.cardColor.withValues(alpha: 0.85));

    const double saturation = 1.5;

    final shadows = <BoxShadow>[
      if (shadow != null) shadow!,
      // Layer 1: Razor contact grounding line
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.16),
        blurRadius: 1.5,
        offset: const Offset(0, 0.5),
        spreadRadius: 0.0,
      ),
      // Layer 2: Tight edge step
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.10),
        blurRadius: 3.0,
        offset: const Offset(0, 1.0),
        spreadRadius: -0.2,
      ),
      // Layer 3: Smooth mid edge step
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.08 : 0.05),
        blurRadius: 6.0,
        offset: const Offset(0, 2.0),
        spreadRadius: -0.5,
      ),
      // Layer 4: Feathered outer edge decay
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.03 : 0.02),
        blurRadius: 10.0,
        offset: const Offset(0, 3.5),
        spreadRadius: -1.0,
      ),
      // Layer 5: Imperceptible outer halo
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.008 : 0.008),
        blurRadius: 16.0,
        offset: const Offset(0, 5.0),
        spreadRadius: -1.5,
      ),
      // Subtle primary backlight glow
      if (isDark)
        BoxShadow(
          color: theme.colorScheme.primary.withValues(alpha: 0.025),
          blurRadius: 20.0,
          spreadRadius: -3.0,
        ),
    ];

    // Conic sweep border gradient: Monochromatic alpha modulation per theme mode (no color-mix wrinkles)
    final borderGradient = SweepGradient(
      center: Alignment.center,
      colors: isDark
          ? [
              Colors.white.withValues(alpha: 0.10), // 0.00 (Right edge)
              Colors.white.withValues(alpha: 0.22), // 0.125 (Bottom-Right corner echo)
              Colors.white.withValues(alpha: 0.10), // 0.25 (Bottom edge)
              Colors.white.withValues(alpha: 0.04), // 0.45 (Bottom-Left edge)
              Colors.white.withValues(alpha: 0.28), // 0.58 (Approach Top-Left)
              Colors.white.withValues(alpha: 0.48), // 0.65 (Top-Left corner peak!)
              Colors.white.withValues(alpha: 0.30), // 0.78 (Top edge wash)
              Colors.white.withValues(alpha: 0.10), // 1.00 (Right edge return)
            ]
          : [
              Colors.black.withValues(alpha: 0.06), // 0.00 (Right edge)
              Colors.black.withValues(alpha: 0.18), // 0.125 (Bottom-Right shadow edge)
              Colors.black.withValues(alpha: 0.08), // 0.25 (Bottom edge)
              Colors.black.withValues(alpha: 0.03), // 0.45 (Bottom-Left)
              Colors.black.withValues(alpha: 0.14), // 0.58 (Approach Top-Left)
              Colors.black.withValues(alpha: 0.28), // 0.65 (Top-Left corner peak!)
              Colors.black.withValues(alpha: 0.16), // 0.78 (Top edge rim wash)
              Colors.black.withValues(alpha: 0.06), // 1.00 (Right edge return)
            ],
      stops: const [0.0, 0.125, 0.25, 0.45, 0.58, 0.65, 0.78, 1.0],
    );

    // Flat fill: Real glass doesn't glow across its face; face stays clean and flat.
    final fillDecoration = ShapeDecoration(
      color: baseColor,
      shape: shape,
    );

    final surface = _buildAnimatedSurface(
      decoration: fillDecoration,
      content: interactiveChild,
    );

    final surfaceWithBorder = CustomPaint(
      foregroundPainter: _GlassSpecularBorderPainter(
        shape: shape,
        gradient: borderGradient,
        strokeWidth: 1.0,
      ),
      child: surface,
    );

    final shouldFilterBackdrop = enableBackdrop && blur > 0.0;

    final glassContent = ClipPath(
      clipper: ShapeBorderClipper(shape: shape),
      child: shouldFilterBackdrop
          ? BackdropFilter(
              filter: ui.ImageFilter.compose(
                outer: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                inner: ColorFilter.matrix(_saturationMatrix(saturation)),
              ),
              child: surfaceWithBorder,
            )
          : surfaceWithBorder,
    );

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: shadows,
          border: border,
        ),
        child: glassContent,
      ),
    );
  }

  Widget _buildInteractiveContent(ShapeBorder shape) {
    if (onTap != null || onLongPress != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          customBorder: shape,
          child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ),
      );
    }

    return padding != null ? Padding(padding: padding!, child: child) : child;
  }

  Widget _buildQualityPanel({
    required BoxShadow? outerShadow,
    required Widget content,
    required Color glassColor,
  }) {
    final panel = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        boxShadow: outerShadow != null ? [outerShadow] : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: _GlassShapeRenderObjectWidget(
          borderRadius: borderRadius,
          color: glassColor,
          child: content,
        ),
      ),
    );

    return duration != null
        ? AnimatedContainer(
            duration: duration!,
            curve: curve,
            width: width,
            height: height,
            margin: margin,
            decoration: BoxDecoration(
              boxShadow: outerShadow != null ? [outerShadow] : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(borderRadius),
              child: _GlassShapeRenderObjectWidget(
                borderRadius: borderRadius,
                color: glassColor,
                child: content,
              ),
            ),
          )
        : panel;
  }

  Widget _buildAnimatedSurface({
    required Decoration decoration,
    required Widget content,
  }) {
    if (duration != null) {
      return AnimatedContainer(
        duration: duration!,
        curve: curve,
        width: width,
        height: height,
        decoration: decoration,
        child: content,
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: decoration,
      child: content,
    );
  }
}

class _GlassShapeRenderObjectWidget extends SingleChildRenderObjectWidget {
  final double borderRadius;
  final Color color;

  const _GlassShapeRenderObjectWidget({
    required this.borderRadius,
    required this.color,
    super.child,
  });

  @override
  RenderGlassShape createRenderObject(BuildContext context) =>
      RenderGlassShape(borderRadius, color);

  @override
  void updateRenderObject(BuildContext context, RenderGlassShape renderObject) {
    renderObject
      ..borderRadius = borderRadius
      ..color = color;
  }
}

class RenderGlassShape extends RenderProxyBox {
  double _borderRadius;
  Color _color;

  RenderGlassShape(this._borderRadius, this._color);

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
    _findLayer()?.registeredShapes.add(this);
  }

  @override
  void detach() {
    _findLayer()?.registeredShapes.remove(this);
    super.detach();
  }

  @override
  bool get alwaysNeedsCompositing => true;

  _RenderGlassGroup? _findLayer() {
    var parentRenderObject = parent;
    while (parentRenderObject != null &&
        parentRenderObject is! _RenderGlassGroup) {
      parentRenderObject = parentRenderObject.parent;
    }
    return parentRenderObject as _RenderGlassGroup?;
  }
}

class ShapeData {
  final Offset center;
  final Size size;
  final double borderRadius;
  final Color color;

  const ShapeData(this.center, this.size, this.borderRadius, this.color);
}

List<double> _saturationMatrix(double s) {
  const lumR = 0.213, lumG = 0.715, lumB = 0.072;
  return <double>[
    lumR + (1 - lumR) * s, lumG - lumG * s, lumB - lumB * s, 0, 0,
    lumR - lumR * s, lumG + (1 - lumG) * s, lumB - lumB * s, 0, 0,
    lumR - lumR * s, lumG - lumG * s, lumB + (1 - lumB) * s, 0, 0,
    0, 0, 0, 1, 0,
  ];
}

class _GlassSpecularBorderPainter extends CustomPainter {
  final ShapeBorder shape;
  final Gradient gradient;
  final double strokeWidth;

  const _GlassSpecularBorderPainter({
    required this.shape,
    required this.gradient,
    this.strokeWidth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final path = shape.getOuterPath(rect);
    canvas.drawPath(
      path,
      Paint()
        ..shader = gradient.createShader(Offset.zero & size)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant _GlassSpecularBorderPainter old) =>
      old.shape != shape ||
      old.gradient != gradient ||
      old.strokeWidth != strokeWidth;
}
