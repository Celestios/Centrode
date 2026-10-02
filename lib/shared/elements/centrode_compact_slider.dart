import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'surfaces/surface_mode.dart';
import 'surfaces/inset_surface.dart';

class CentrodeCompactSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double min;
  final double max;
  final int? divisions;
  final Color? activeColor;
  final Color? activeSecondaryColor;
  final List<Color>? gradientColors;
  final double height;
  final double trackHeight;
  final double handleRadius;

  const CentrodeCompactSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.divisions,
    this.activeColor,
    this.activeSecondaryColor,
    this.gradientColors,
    this.height = 32.0,
    this.trackHeight = 10.0,
    this.handleRadius = 10.0,
  });

  @override
  State<CentrodeCompactSlider> createState() => _CentrodeCompactSliderState();
}

class _CentrodeCompactSliderState extends State<CentrodeCompactSlider>
    with SingleTickerProviderStateMixin {
  final LiquidGlassViewController _viewController = LiquidGlassViewController();
  late final AnimationController _morphController;
  bool _isDragging = false;
  bool _isCapturing = false;

  @override
  void initState() {
    super.initState();
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      reverseDuration: const Duration(milliseconds: 220),
    );
  }

  @override
  void dispose() {
    _viewController.stopRealtimeCapture();
    _viewController.detach();
    _morphController.dispose();
    super.dispose();
  }

  void _onPointerDown() {
    if (!_isCapturing) {
      _isCapturing = true;
      _viewController.startRealtimeCapture();
      _viewController.captureOnce();
    }
    _morphController.animateTo(1.0, curve: Curves.easeOutCubic);
  }

  void _onPointerUp() {
    _morphController.animateTo(0.0, curve: Curves.easeOutQuad).then((_) {
      if (mounted && !_isDragging && _isCapturing) {
        _viewController.stopRealtimeCapture();
        _isCapturing = false;
      }
    });
  }

  double _quantize(double rawValue) {
    if (widget.divisions == null || widget.divisions! <= 0) return rawValue;
    final step = (widget.max - widget.min) / widget.divisions!;
    final stepsCount = ((rawValue - widget.min) / step).round();
    return (widget.min + (stepsCount * step)).clamp(widget.min, widget.max);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surfaceMode = CentrodeSurfaceScope.modeOf(context);

    final resolvedColor = widget.activeColor ?? theme.colorScheme.primary;
    final resolvedSecondaryColor = widget.activeSecondaryColor ??
        Color.lerp(resolvedColor, Colors.white, isDark ? 0.35 : 0.20)!;

    final fillColors = widget.gradientColors ?? [resolvedSecondaryColor, resolvedColor];

    return SizedBox(
      height: widget.height,
      child: Center(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final trackWidth = constraints.maxWidth;
            final restThumbDiameter = widget.handleRadius * 2;
            final liftedWidth = restThumbDiameter * 1.6;
            final liftedHeight = restThumbDiameter * 1.3;

            final availableWidth = (trackWidth - restThumbDiameter).clamp(1.0, double.infinity);
            final range = widget.max - widget.min;
            final normalizedValue = range > 0
                ? ((widget.value - widget.min) / range).clamp(0.0, 1.0)
                : 0.0;
            final thumbOffset = normalizedValue * availableWidth;

            void updateFromLocalX(double localX) {
              final rawFrac = (localX - restThumbDiameter / 2) / availableWidth;
              final unclampedValue = widget.min + (rawFrac * range);
              final clampedValue = unclampedValue.clamp(widget.min, widget.max);
              final quantized = _quantize(clampedValue);
              if (quantized != widget.value) {
                widget.onChanged(quantized);
              }
            }

            return AnimatedBuilder(
              animation: _morphController,
              builder: (context, _) {
                final morph = _morphController.value;
                final currentThumbWidth =
                    restThumbDiameter + ((liftedWidth - restThumbDiameter) * morph);
                final currentThumbHeight =
                    restThumbDiameter + ((liftedHeight - restThumbDiameter) * morph);
                final currentThumbLeft =
                    thumbOffset - ((currentThumbWidth - restThumbDiameter) / 2);
                final containerHeight = widget.height;

                final trackWidget = _buildTrack(
                  trackWidth: trackWidth,
                  thumbOffset: thumbOffset,
                  restThumbDiameter: restThumbDiameter,
                  fillColors: fillColors,
                  isDark: isDark,
                  accentColor: resolvedColor,
                );

                final handleWidget = _buildHandle(
                  width: currentThumbWidth,
                  height: currentThumbHeight,
                  morph: morph,
                  isDark: isDark,
                  accentColor: resolvedColor,
                  surfaceMode: surfaceMode,
                );

                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragStart: (details) {
                    setState(() => _isDragging = true);
                    _onPointerDown();
                    final box = context.findRenderObject() as RenderBox;
                    updateFromLocalX(box.globalToLocal(details.globalPosition).dx);
                  },
                  onHorizontalDragUpdate: (details) {
                    final box = context.findRenderObject() as RenderBox;
                    updateFromLocalX(box.globalToLocal(details.globalPosition).dx);
                  },
                  onHorizontalDragEnd: (_) {
                    setState(() => _isDragging = false);
                    _onPointerUp();
                  },
                  onHorizontalDragCancel: () {
                    setState(() => _isDragging = false);
                    _onPointerUp();
                  },
                  onTapDown: (details) {
                    _onPointerDown();
                    final box = context.findRenderObject() as RenderBox;
                    updateFromLocalX(box.globalToLocal(details.globalPosition).dx);
                  },
                  onTapUp: (_) => _onPointerUp(),
                  onTapCancel: () => _onPointerUp(),
                  child: SizedBox(
                    height: containerHeight,
                    child: surfaceMode == CentrodeSurfaceMode.quality
                        ? LiquidGlassView(
                            controller: _viewController,
                            batch: false,
                            pixelRatio: 1.0,
                            realTimeCapture: false,
                            useSync: true,
                            adaptiveSampling: const LiquidGlassAdaptiveSampling(),
                            backgroundWidget: trackWidget,
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.centerLeft,
                              children: [
                                Positioned(
                                  left: currentThumbLeft.clamp(
                                    -2.0,
                                    trackWidth - currentThumbWidth + 2.0,
                                  ),
                                  top: (containerHeight - currentThumbHeight) / 2,
                                  width: currentThumbWidth,
                                  height: currentThumbHeight,
                                  child: handleWidget,
                                ),
                              ],
                            ),
                          )
                        : Stack(
                            alignment: Alignment.centerLeft,
                            clipBehavior: Clip.none,
                            children: [
                              trackWidget,
                              Positioned(
                                left: currentThumbLeft.clamp(
                                  -2.0,
                                  trackWidth - currentThumbWidth + 2.0,
                                ),
                                top: (containerHeight - currentThumbHeight) / 2,
                                width: currentThumbWidth,
                                height: currentThumbHeight,
                                child: handleWidget,
                              ),
                            ],
                          ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildTrack({
    required double trackWidth,
    required double thumbOffset,
    required double restThumbDiameter,
    required List<Color> fillColors,
    required bool isDark,
    required Color accentColor,
  }) {
    final activeFillWidth = (thumbOffset + restThumbDiameter / 2).clamp(
      0.0,
      trackWidth,
    );

    return Center(
      child: SizedBox(
        height: widget.trackHeight,
        width: trackWidth,
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            CentrodeInsetSurface(
              height: widget.trackHeight,
              width: trackWidth,
              cornerRadius: widget.trackHeight / 2,
              depth: 1.2,
              accentColor: accentColor,
            ),
            Container(
              height: widget.trackHeight - 2.0,
              margin: const EdgeInsets.only(left: 1.0),
              width: activeFillWidth > 1.0 ? activeFillWidth - 1.0 : 0.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular((widget.trackHeight - 2.0) / 2),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: fillColors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: fillColors.last.withValues(alpha: isDark ? 0.35 : 0.25),
                    blurRadius: 4.0,
                    offset: const Offset(0, 1.0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle({
    required double width,
    required double height,
    required double morph,
    required bool isDark,
    required Color accentColor,
    required CentrodeSurfaceMode surfaceMode,
  }) {
    final solidHandle = Container(
      decoration: BoxDecoration(
        color: accentColor,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.40 : 0.85),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: isDark ? 0.45 : 0.35),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );

    if (surfaceMode == CentrodeSurfaceMode.quality) {
      return Stack(
        fit: StackFit.expand,
        children: [
          LiquidGlassBatch.exclude(
            child: LiquidGlassLens(
              honorBackdropAlpha: true,
              visibility: morph > 0.005,
              touch: const LiquidGlassTouch(
                flex: LiquidGlassFlex.pronounced(),
              ),
              style: LiquidGlassStyle(
                shape: LiquidGlassShape.continuousRoundedRectangle(
                  cornerRadius: height / 2,
                  borderWidth: 1.0,
                  lightDirection: 35,
                  lightColor: Colors.white.withValues(alpha: 0.95),
                  lightIntensity: 1.0 + (0.5 * morph),
                ),
                adaptivity: const LiquidGlassAdaptivity(
                  glassColorOnLight: Color(0x4DFFFFFF),
                  contentColorOnLight: Color(0xFF0F172A),
                  glassColorOnDark: Color(0x33000000),
                  contentColorOnDark: Colors.white,
                  duration: Duration(milliseconds: 180),
                ),
                appearance: LiquidGlassAppearance(
                  color: Colors.transparent,
                  blur: LiquidGlassBlur(
                    sigmaX: 0.5 + (1.5 * morph),
                    sigmaY: 0.5 + (1.5 * morph),
                  ),
                  shadow: LiquidGlassShadow(
                    color: accentColor.withValues(alpha: isDark ? (0.40 * morph) : (0.30 * morph)),
                    blur: 10.0 * morph,
                    offset: Offset(0, 3.0 * morph),
                  ),
                ),
                refraction: LiquidGlassRefraction(
                  distortion: 0.18 + (0.08 * morph),
                  distortionWidth: 24.0 + (10.0 * morph),
                  magnification: 1.25 + (0.10 * morph),
                  chromaticAberration: 0.003 * morph,
                ),
              ),
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(height / 2),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: isDark ? 0.35 : 0.80),
                      width: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: Opacity(
              opacity: (1.0 - morph).clamp(0.0, 1.0),
              child: solidHandle,
            ),
          ),
        ],
      );
    }

    if (morph <= 0.001) {
      return solidHandle;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (morph < 0.999)
          Opacity(
            opacity: (1.0 - morph).clamp(0.0, 1.0),
            child: solidHandle,
          ),
        Opacity(
          opacity: morph.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(height / 2),
              color: accentColor.withValues(alpha: isDark ? 0.60 : 0.80),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.8),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.10),
                  blurRadius: 4.0,
                  offset: const Offset(0, 1.5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
