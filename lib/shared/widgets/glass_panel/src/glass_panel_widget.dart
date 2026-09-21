part of '../glass_panel.dart';

/// A self-contained glassmorphic panel that can render via shader or fallback blur.
class GlassPanel extends StatelessWidget {
  final Widget child;

  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  final double borderRadius;
  final BorderRadiusGeometry? customBorderRadius;
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
    this.customBorderRadius,
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
          customBorderRadius: customBorderRadius,
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
      customBorderRadius: customBorderRadius,
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
  final BorderRadiusGeometry? customBorderRadius;
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
    this.customBorderRadius,
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
    final effectiveRadius =
        customBorderRadius ?? BorderRadius.circular(borderRadius);
    final shape = borderRadius >= 100.0 && customBorderRadius == null
        ? const StadiumBorder()
        : ContinuousRectangleBorder(
            side: BorderSide.none,
            borderRadius: effectiveRadius,
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
    final baseColor = color ?? theme.cardColor.withValues(alpha: isDark ? 0.65 : 0.85);

    const double saturation = 1.5;

    final shadows = <BoxShadow>[
      if (shadow != null) shadow!,
      // Layer 1: Razor contact grounding line
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.16),
        blurRadius: 2.0,
        offset: const Offset(0, 0.5),
        spreadRadius: 0.0,
      ),
      // Layer 2: Tight edge step
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.10),
        blurRadius: 4.0,
        offset: const Offset(0, 1.0),
        spreadRadius: 0.0,
      ),
      // Layer 3: Smooth mid edge step
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.08 : 0.05),
        blurRadius: 8.0,
        offset: const Offset(0, 2.0),
        spreadRadius: 0.0,
      ),
      // Layer 4: Feathered outer edge decay
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.03 : 0.02),
        blurRadius: 14.0,
        offset: const Offset(0, 3.5),
        spreadRadius: 0.0,
      ),
      // Layer 5: Imperceptible outer halo
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.008 : 0.008),
        blurRadius: 20.0,
        offset: const Offset(0, 5.0),
        spreadRadius: -0.5,
      ),
      // Subtle primary backlight glow
      if (isDark)
        BoxShadow(
          color: theme.colorScheme.primary.withValues(alpha: 0.025),
          blurRadius: 20.0,
          spreadRadius: -1.0,
        ),
    ];

    // Flat fill: Real glass doesn't glow across its face; face stays clean and flat.
    final fillDecoration = ShapeDecoration(
      color: baseColor,
      shape: shape,
    );

    final surface = _buildAnimatedSurface(
      decoration: fillDecoration,
      content: interactiveChild,
    );

    final resolvedBorderColor = border?.top.color ??
        (isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.black.withValues(alpha: 0.08));

    final surfaceWithBorder = CustomPaint(
      foregroundPainter: _GlassSpecularBorderPainter(
        shape: shape,
        isDark: isDark,
        strokeWidth: border?.top.width ?? UiStrokeWidth.standard,
        borderColor: resolvedBorderColor,
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
        decoration: ShapeDecoration(
          shape: shape,
          shadows: shadows,
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
  final bool isDark;
  final double strokeWidth;
  final Color borderColor;

  const _GlassSpecularBorderPainter({
    required this.shape,
    required this.isDark,
    this.strokeWidth = 1.0,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rect = (Offset.zero & size).deflate(strokeWidth / 2);
    final path = shape.getOuterPath(rect);

    final alpha = math.atan2(size.height, size.width);
    final brStop = (alpha / (2 * math.pi)).clamp(0.05, 0.45);
    final blStop = 0.5 - brStop;
    final tlStop = 0.5 + brStop;
    final trStop = 1.0 - brStop;

    final List<Color> gradientColors;
    if (isDark) {
      final peakSpecular =
          Color.lerp(borderColor, Colors.white, 0.35)!.withValues(alpha: 0.55);
      final washSpecular =
          Color.lerp(borderColor, Colors.white, 0.15)!.withValues(alpha: 0.35);

      gradientColors = [
        borderColor.withValues(alpha: 0.16), // Right edge
        borderColor.withValues(alpha: 0.28), // BR corner contact grounding
        borderColor.withValues(alpha: 0.16), // Bottom edge
        borderColor.withValues(alpha: 0.08), // BL corner
        washSpecular,                        // Approach TL
        peakSpecular,                        // TL corner peak highlight
        washSpecular,                        // Top edge wash
        borderColor.withValues(alpha: 0.16), // TR corner return
      ];
    } else {
      // Light mode: Physical glass uses Fresnel occlusion and subtle grounding edge shadow,
      // avoiding white specular blowouts that wash out against bright canvases.
      final shadowEdge = borderColor.withValues(alpha: 0.20);
      final subtleRim = borderColor.withValues(alpha: 0.08);
      final lightWash = borderColor.withValues(alpha: 0.05);

      gradientColors = [
        subtleRim,   // Right edge
        shadowEdge,  // BR corner shadow edge
        shadowEdge,  // Bottom edge contact
        subtleRim,   // BL corner
        lightWash,   // Approach TL
        subtleRim,   // TL corner
        lightWash,   // Top edge rim wash
        subtleRim,   // TR corner return
      ];
    }

    final gradient = SweepGradient(
      center: Alignment.center,
      colors: gradientColors,
      stops: [
        0.0,
        brStop,
        0.25,
        blStop,
        (blStop + tlStop) / 2,
        tlStop,
        (tlStop + trStop) / 2,
        1.0,
      ],
    );

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
      old.isDark != isDark ||
      old.strokeWidth != strokeWidth ||
      old.borderColor != borderColor;
}
