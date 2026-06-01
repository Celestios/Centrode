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

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  final Duration? duration;
  final Curve curve;

  final GlassMode? mode;

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
    this.shadow,
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
        useQuality && (groupScope == null || groupScope.mode != GlassMode.quality);
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
          shadow: shadow,
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
      shadow: shadow,
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
  final BoxShadow? shadow;
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
    required this.shadow,
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
    final border = theme.colorScheme.primary.withValues(alpha: 0.25);
    final borderRadiusValue = BorderRadius.circular(borderRadius);
    final interactiveChild = _buildInteractiveContent(borderRadiusValue);

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

    final decoration = BoxDecoration(
      color: resolvedColor.withValues(alpha: 0.12),
      borderRadius: borderRadiusValue,
      border: Border.all(color: border, width: 1.0),
      boxShadow: shadow != null ? [shadow!] : null,
    );

    final surface = _buildAnimatedSurface(
      decoration: decoration,
      content: interactiveChild,
    );

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: borderRadiusValue,
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: surface,
        ),
      ),
    );
  }

  Widget _buildInteractiveContent(BorderRadius borderRadiusValue) {
    if (onTap != null || onLongPress != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: borderRadiusValue,
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ),
      );
    }

    return padding != null
        ? Padding(
            padding: padding!,
            child: child,
          )
        : child;
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
    required BoxDecoration decoration,
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
  void updateRenderObject(
    BuildContext context,
    RenderGlassShape renderObject,
  ) {
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
    while (parentRenderObject != null && parentRenderObject is! _RenderGlassGroup) {
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
