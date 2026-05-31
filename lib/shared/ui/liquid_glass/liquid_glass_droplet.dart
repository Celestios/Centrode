part of 'liquid_glass_menu.dart';

/// Widget that wraps any child to make it appear as a liquid glass droplet.
class LiquidGlass extends StatelessWidget {
  final bool enabled;
  final double? width;
  final double? height;
  final Color color;
  final double borderRadius;
  final BoxShadow? shadow;
  final Widget? child;

  const LiquidGlass({
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
      child: _LiquidGlassRenderObjectWidget(
        enabled: enabled,
        borderRadius: borderRadius,
        color: color,
        child: child,
      ),
    );
  }
}

class _LiquidGlassRenderObjectWidget extends SingleChildRenderObjectWidget {
  final bool enabled;
  final double borderRadius;
  final Color color;

  const _LiquidGlassRenderObjectWidget({
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
