import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../engine/config.dart';
import 'package:centrode/features/graph/presentation/viewport_state.dart';
import 'package:centrode/shared/utils/color_utils.dart';

class GridLayer extends StatefulWidget {
  final ViewportStateGrid viewportState;
  final ValueNotifier<Offset?> mousePositionNotifier;
  final ValueNotifier<Offset>? elasticOverscrollNotifier;

  const GridLayer({
    super.key,
    required this.viewportState,
    required this.mousePositionNotifier,
    this.elasticOverscrollNotifier,
  });

  @override
  State<GridLayer> createState() => _GridLayerState();
}

class _GridLayerState extends State<GridLayer>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<_GlowData?> _glowNotifier = ValueNotifier(null);
  final ValueNotifier<Offset> _overscrollNotifier = ValueNotifier(Offset.zero);
  Ticker? _ticker;
  Duration _lastFrameTime = Duration.zero;

  Offset? _visualGlowPos;
  double _glowOpacity = 0.0;
  Offset _velocity = Offset.zero;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    widget.mousePositionNotifier.addListener(_onMouseMoved);
    widget.elasticOverscrollNotifier?.addListener(_onOverscrollChanged);
  }

  @override
  void didUpdateWidget(covariant GridLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mousePositionNotifier != widget.mousePositionNotifier) {
      oldWidget.mousePositionNotifier.removeListener(_onMouseMoved);
      widget.mousePositionNotifier.addListener(_onMouseMoved);
    }
    if (oldWidget.elasticOverscrollNotifier !=
        widget.elasticOverscrollNotifier) {
      oldWidget.elasticOverscrollNotifier?.removeListener(_onOverscrollChanged);
      widget.elasticOverscrollNotifier?.addListener(_onOverscrollChanged);
    }
  }

  @override
  void dispose() {
    widget.mousePositionNotifier.removeListener(_onMouseMoved);
    widget.elasticOverscrollNotifier?.removeListener(_onOverscrollChanged);
    _ticker?.dispose();
    _glowNotifier.dispose();
    _overscrollNotifier.dispose();
    super.dispose();
  }

  void _onOverscrollChanged() {
    _overscrollNotifier.value =
        widget.elasticOverscrollNotifier?.value ?? Offset.zero;
  }

  void _onMouseMoved() {
    final mousePos = widget.mousePositionNotifier.value;
    if (mousePos != null && !_ticker!.isActive) {
      _lastFrameTime = Duration.zero;
      _ticker!.start();
    } else if (mousePos == null && !_ticker!.isActive && _glowOpacity > 0.0) {
      _lastFrameTime = Duration.zero;
      _ticker!.start();
    }
  }

  void _onTick(Duration elapsed) {
    double dt = 0.016;
    if (_lastFrameTime != Duration.zero) {
      dt = (elapsed - _lastFrameTime).inMicroseconds / 1000000.0;
    }
    _lastFrameTime = elapsed;
    dt = dt.clamp(0.008, 0.033);

    final physicalMousePos = widget.mousePositionNotifier.value;

    if (physicalMousePos == null) {
      _glowOpacity = (_glowOpacity - 4.0 * dt).clamp(0.0, 1.0);
      _velocity = _velocity * (1.0 - 10.0 * dt).clamp(0.0, 1.0);

      if (_glowOpacity <= 0.01) {
        _visualGlowPos = null;
        _glowOpacity = 0.0;
        _velocity = Offset.zero;
        _ticker!.stop();
        _glowNotifier.value = null;
        return;
      }
    } else {
      _glowOpacity = (_glowOpacity + 6.0 * dt).clamp(0.0, 1.0);

      if (_visualGlowPos == null) {
        _visualGlowPos = physicalMousePos;
        _velocity = Offset.zero;
      } else {
        final displacement = physicalMousePos - _visualGlowPos!;
        final dist = displacement.distance;

        final double baseEase = 0.05;
        final double maxAdditionalEase = 0.09;
        final double halfSatDistance = 150.0;
        final double easeFactor =
            baseEase + maxAdditionalEase * (dist / (dist + halfSatDistance));
        final double step = (easeFactor * 60.0 * dt).clamp(0.0, 1.0);

        if (dist < 0.05 && _glowOpacity >= 1.0) {
          _visualGlowPos = physicalMousePos;
          _velocity = Offset.zero;
          _ticker!.stop();
        } else {
          _visualGlowPos = Offset.lerp(_visualGlowPos, physicalMousePos, step);
          _velocity = physicalMousePos - _visualGlowPos!;
        }
      }
    }

    _glowNotifier.value = _GlowData(
      visualGlowPos: _visualGlowPos,
      glowOpacity: _glowOpacity,
      velocity: _velocity,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = !kIsWeb && Platform.isAndroid;
    final theme = Theme.of(context);
    final Color backgroundColor = theme.scaffoldBackgroundColor;
    final isDark = ColorUtils.isDark(backgroundColor);

    final Color dotColor = isAndroid
        ? (isDark
            ? Colors.white.withValues(alpha: 0.28)
            : Colors.black.withValues(alpha: 0.22))
        : (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.12));

    if (isAndroid) {
      return RepaintBoundary(
        child: CustomPaint(
          size: widget.viewportState.viewportSize,
          painter: _StaticGridPainter(
            visibleRect: widget.viewportState.visibleRect,
            scale: widget.viewportState.scale,
            backgroundColor: backgroundColor,
            dotColor: dotColor,
            overscroll:
                widget.elasticOverscrollNotifier?.value ?? Offset.zero,
          ),
        ),
      );
    }

    final Color glowColor = isDark
        ? Colors.white.withValues(alpha: 0.65)
        : const Color(0xFF1E1E1E).withValues(alpha: 0.65);

    return Stack(
      children: [
        RepaintBoundary(
          child: ValueListenableBuilder<Offset>(
            valueListenable: _overscrollNotifier,
            builder: (context, overscroll, _) {
              return CustomPaint(
                size: widget.viewportState.viewportSize,
                painter: _StaticGridPainter(
                  visibleRect: widget.viewportState.visibleRect,
                  scale: widget.viewportState.scale,
                  backgroundColor: backgroundColor,
                  dotColor: dotColor,
                  overscroll: overscroll,
                ),
              );
            },
          ),
        ),
        RepaintBoundary(
          child: ValueListenableBuilder<_GlowData?>(
            valueListenable: _glowNotifier,
            builder: (context, glowData, _) {
              if (glowData == null ||
                  glowData.visualGlowPos == null ||
                  glowData.glowOpacity <= 0.0) {
                return const SizedBox.shrink();
              }
              return CustomPaint(
                size: widget.viewportState.viewportSize,
                painter: _GlowGridPainter(
                  visibleRect: widget.viewportState.visibleRect,
                  scale: widget.viewportState.scale,
                  dotColor: dotColor,
                  glowColor: glowColor,
                  visualGlowPos: glowData.visualGlowPos,
                  glowOpacity: glowData.glowOpacity,
                  velocity: glowData.velocity,
                ),
                willChange: true,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GlowData {
  final Offset? visualGlowPos;
  final double glowOpacity;
  final Offset velocity;

  const _GlowData({
    required this.visualGlowPos,
    required this.glowOpacity,
    required this.velocity,
  });
}

class _StaticGridPainter extends CustomPainter {
  final Rect visibleRect;
  final double scale;
  final Color backgroundColor;
  final Color dotColor;
  final Offset overscroll;

  final List<Offset> _pointsBuffer = [];

  _StaticGridPainter({
    required this.visibleRect,
    required this.scale,
    required this.backgroundColor,
    required this.dotColor,
    this.overscroll = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(visibleRect, Paint()..color = backgroundColor);

    final double effectiveGridSize = calculateEffectiveGridSize(scale);

    final double startX =
        (visibleRect.left / effectiveGridSize).floor() * effectiveGridSize;
    final double startY =
        (visibleRect.top / effectiveGridSize).floor() * effectiveGridSize;

    _pointsBuffer.clear();
    for (
      double x = startX;
      x <= visibleRect.right + effectiveGridSize;
      x += effectiveGridSize
    ) {
      for (
        double y = startY;
        y <= visibleRect.bottom + effectiveGridSize;
        y += effectiveGridSize
      ) {
        _pointsBuffer.add(Offset(x, y));
      }
    }

    final paint = Paint()
      ..color = dotColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (AppConfig.grid.dotRadius * 2) / scale;

    canvas.drawPoints(PointMode.points, _pointsBuffer, paint);
  }

  @override
  bool shouldRepaint(covariant _StaticGridPainter oldDelegate) {
    return oldDelegate.visibleRect != visibleRect ||
        oldDelegate.scale != scale ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.dotColor != dotColor ||
        oldDelegate.overscroll != overscroll;
  }
}

class _GlowGridPainter extends CustomPainter {
  final Rect visibleRect;
  final double scale;
  final Color dotColor;
  final Color glowColor;
  final Offset? visualGlowPos;
  final double glowOpacity;
  final Offset velocity;

  static const int _colorRampSize = 32;
  static Color? _cachedDotColor;
  static Color? _cachedGlowColor;
  static List<Color>? _cachedColorRamp;

  late final List<Color> _colorRamp;

  _GlowGridPainter({
    required this.visibleRect,
    required this.scale,
    required this.dotColor,
    required this.glowColor,
    required this.visualGlowPos,
    required this.glowOpacity,
    required this.velocity,
  }) {
    if (_cachedColorRamp == null ||
        _cachedDotColor != dotColor ||
        _cachedGlowColor != glowColor) {
      _cachedDotColor = dotColor;
      _cachedGlowColor = glowColor;
      _cachedColorRamp = List.generate(_colorRampSize, (i) {
        final t = i / (_colorRampSize - 1);
        return Color.lerp(dotColor, glowColor, t)!;
      });
    }
    _colorRamp = _cachedColorRamp!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final glowPosLocal = visualGlowPos;
    if (glowPosLocal == null || glowOpacity <= 0.0) return;

    final double effectiveGridSize = calculateEffectiveGridSize(scale);

    final Offset glowPos = visibleRect.topLeft + (glowPosLocal / scale);

    final double lagDistanceViewport = velocity.distance;

    const double baseInfluenceRadiusViewport = 120.0;

    double aViewport = baseInfluenceRadiusViewport;
    double bViewport = baseInfluenceRadiusViewport;
    double cosAngle = 1.0;
    double sinAngle = 0.0;

    if (lagDistanceViewport > 2.0) {
      final double saturation =
          lagDistanceViewport / (lagDistanceViewport + 60.0);

      const double maxStretchViewport = 90.0;
      const double maxCompressViewport = 30.0;

      aViewport = baseInfluenceRadiusViewport + maxStretchViewport * saturation;
      bViewport =
          baseInfluenceRadiusViewport - maxCompressViewport * saturation;

      final Offset dir = velocity / lagDistanceViewport;
      cosAngle = dir.dx;
      sinAngle = dir.dy;
    }

    final double a = aViewport / scale;
    final double b = bViewport / scale;

    final double maxDim = a > b ? a : b;
    final double minGlowX =
        ((glowPos.dx - maxDim) / effectiveGridSize).floor() * effectiveGridSize;
    final double maxGlowX =
        ((glowPos.dx + maxDim) / effectiveGridSize).ceil() * effectiveGridSize;
    final double minGlowY =
        ((glowPos.dy - maxDim) / effectiveGridSize).floor() * effectiveGridSize;
    final double maxGlowY =
        ((glowPos.dy + maxDim) / effectiveGridSize).ceil() * effectiveGridSize;

    final glowPaint = Paint()..style = PaintingStyle.fill;

    for (double x = minGlowX; x <= maxGlowX; x += effectiveGridSize) {
      for (double y = minGlowY; y <= maxGlowY; y += effectiveGridSize) {
        final double dx = x - glowPos.dx;
        final double dy = y - glowPos.dy;

        final double rx = dx * cosAngle + dy * sinAngle;
        final double ry = -dx * sinAngle + dy * cosAngle;

        final double ellipseVal = (rx * rx) / (a * a) + (ry * ry) / (b * b);

        if (ellipseVal < 1.0) {
          final double t = (1.0 - math.sqrt(ellipseVal)).clamp(0.0, 1.0);
          final double strength = (3 * t * t - 2 * t * t * t) * glowOpacity;

          final double targetRadius =
              (AppConfig.grid.dotRadius + strength) / scale;

          final int rampIndex = (strength * (_colorRampSize - 1)).round().clamp(
            0,
            _colorRampSize - 1,
          );
          final baseColor = _colorRamp[rampIndex];
          glowPaint.color = baseColor.withValues(
            alpha: baseColor.a * glowOpacity,
          );

          canvas.drawCircle(Offset(x, y), targetRadius, glowPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _GlowGridPainter oldDelegate) {
    return oldDelegate.visibleRect != visibleRect ||
        oldDelegate.scale != scale ||
        oldDelegate.dotColor != dotColor ||
        oldDelegate.glowColor != glowColor ||
        oldDelegate.visualGlowPos != visualGlowPos ||
        oldDelegate.glowOpacity != glowOpacity ||
        oldDelegate.velocity != velocity;
  }
}
