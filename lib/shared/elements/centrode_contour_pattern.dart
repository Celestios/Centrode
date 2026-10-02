import 'dart:math' as math;
import 'package:flutter/material.dart';

enum ContourStyle {
  topographic,
  flowingWaves,
}

enum ContourOrigin {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  bottomCenter,
  centerRight,
  center,
}

@immutable
class ContourConfig {
  final ContourStyle style;
  final ContourOrigin origin;
  final int layerCount;
  final double amplitude;
  final double frequency;
  final double strokeWidth;
  final bool showLines;
  final bool showFills;
  final double fillOpacity;
  final double lineOpacity;
  final int seed;
  final Alignment gradientBegin;
  final Alignment gradientEnd;

  const ContourConfig({
    this.style = ContourStyle.topographic,
    this.origin = ContourOrigin.bottomRight,
    this.layerCount = 5,
    this.amplitude = 0.25,
    this.frequency = 1.5,
    this.strokeWidth = 1.0,
    this.showLines = true,
    this.showFills = true,
    this.fillOpacity = 0.20,
    this.lineOpacity = 0.35,
    this.seed = 42,
    this.gradientBegin = Alignment.topLeft,
    this.gradientEnd = Alignment.bottomRight,
  });

  const ContourConfig.topographic({
    this.origin = ContourOrigin.bottomRight,
    this.layerCount = 6,
    this.amplitude = 0.28,
    this.frequency = 1.6,
    this.strokeWidth = 0.8,
    this.showLines = true,
    this.showFills = true,
    this.fillOpacity = 0.18,
    this.lineOpacity = 0.40,
    this.seed = 42,
    this.gradientBegin = Alignment.topLeft,
    this.gradientEnd = Alignment.bottomRight,
  }) : style = ContourStyle.topographic;

  const ContourConfig.flowingWaves({
    this.origin = ContourOrigin.bottomRight,
    this.layerCount = 4,
    this.amplitude = 0.32,
    this.frequency = 1.2,
    this.strokeWidth = 0.6,
    this.showLines = false,
    this.showFills = true,
    this.fillOpacity = 0.26,
    this.lineOpacity = 0.30,
    this.seed = 42,
    this.gradientBegin = Alignment.topLeft,
    this.gradientEnd = Alignment.bottomRight,
  }) : style = ContourStyle.flowingWaves;

  ContourConfig copyWith({
    ContourStyle? style,
    ContourOrigin? origin,
    int? layerCount,
    double? amplitude,
    double? frequency,
    double? strokeWidth,
    bool? showLines,
    bool? showFills,
    double? fillOpacity,
    double? lineOpacity,
    int? seed,
    Alignment? gradientBegin,
    Alignment? gradientEnd,
  }) {
    return ContourConfig(
      style: style ?? this.style,
      origin: origin ?? this.origin,
      layerCount: layerCount ?? this.layerCount,
      amplitude: amplitude ?? this.amplitude,
      frequency: frequency ?? this.frequency,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      showLines: showLines ?? this.showLines,
      showFills: showFills ?? this.showFills,
      fillOpacity: fillOpacity ?? this.fillOpacity,
      lineOpacity: lineOpacity ?? this.lineOpacity,
      seed: seed ?? this.seed,
      gradientBegin: gradientBegin ?? this.gradientBegin,
      gradientEnd: gradientEnd ?? this.gradientEnd,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContourConfig &&
        other.style == style &&
        other.origin == origin &&
        other.layerCount == layerCount &&
        other.amplitude == amplitude &&
        other.frequency == frequency &&
        other.strokeWidth == strokeWidth &&
        other.showLines == showLines &&
        other.showFills == showFills &&
        other.fillOpacity == fillOpacity &&
        other.lineOpacity == lineOpacity &&
        other.seed == seed &&
        other.gradientBegin == gradientBegin &&
        other.gradientEnd == gradientEnd;
  }

  @override
  int get hashCode => Object.hash(
        style,
        origin,
        layerCount,
        amplitude,
        frequency,
        strokeWidth,
        showLines,
        showFills,
        fillOpacity,
        lineOpacity,
        seed,
        gradientBegin,
        gradientEnd,
      );
}

class CentrodeContourPattern extends StatelessWidget {
  final ContourConfig config;
  final Color? primaryColor;
  final Color? secondaryColor;
  final BorderRadius? borderRadius;
  final Widget? child;

  const CentrodeContourPattern({
    super.key,
    this.config = const ContourConfig(),
    this.primaryColor,
    this.secondaryColor,
    this.borderRadius,
    this.child,
  });

  const CentrodeContourPattern.topographic({
    Key? key,
    ContourConfig config = const ContourConfig.topographic(),
    Color? primaryColor,
    Color? secondaryColor,
    BorderRadius? borderRadius,
    Widget? child,
  }) : this(
         key: key,
         config: config,
         primaryColor: primaryColor,
         secondaryColor: secondaryColor,
         borderRadius: borderRadius,
         child: child,
       );

  const CentrodeContourPattern.waves({
    Key? key,
    ContourConfig config = const ContourConfig.flowingWaves(),
    Color? primaryColor,
    Color? secondaryColor,
    BorderRadius? borderRadius,
    Widget? child,
  }) : this(
         key: key,
         config: config,
         primaryColor: primaryColor,
         secondaryColor: secondaryColor,
         borderRadius: borderRadius,
         child: child,
       );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectivePrimary = primaryColor ?? theme.colorScheme.primary;
    final effectiveSecondary = secondaryColor ?? theme.colorScheme.secondary;

    final painter = CentrodeContourPainter(
      config: config,
      primaryColor: effectivePrimary,
      secondaryColor: effectiveSecondary,
    );

    Widget content;
    if (child != null) {
      content = CustomPaint(
        painter: painter,
        child: child,
      );
    } else {
      content = CustomPaint(
        painter: painter,
        size: Size.infinite,
      );
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }

    return content;
  }
}

class CentrodeContourPainter extends CustomPainter {
  final ContourConfig config;
  final Color primaryColor;
  final Color secondaryColor;

  const CentrodeContourPainter({
    required this.config,
    required this.primaryColor,
    required this.secondaryColor,
  });

  Offset _resolveOrigin(ContourOrigin origin, Size size) {
    return switch (origin) {
      ContourOrigin.topLeft => Offset.zero,
      ContourOrigin.topRight => Offset(size.width, 0),
      ContourOrigin.bottomLeft => Offset(0, size.height),
      ContourOrigin.bottomRight => Offset(size.width, size.height),
      ContourOrigin.bottomCenter => Offset(size.width * 0.5, size.height),
      ContourOrigin.centerRight => Offset(size.width, size.height * 0.5),
      ContourOrigin.center => Offset(size.width * 0.5, size.height * 0.5),
    };
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    canvas.save();
    canvas.clipRect(Offset.zero & size);

    switch (config.style) {
      case ContourStyle.topographic:
        _paintTopographic(canvas, size);
      case ContourStyle.flowingWaves:
        _paintFlowingWaves(canvas, size);
    }

    canvas.restore();
  }

  void _paintTopographic(Canvas canvas, Size size) {
    final originOffset = _resolveOrigin(config.origin, size);
    final corners = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ];

    double maxDist = 0;
    for (final c in corners) {
      final d = (c - originOffset).distance;
      if (d > maxDist) maxDist = d;
    }

    const sampleCount = 48;
    final phase1 = (config.seed * 0.137) % (2 * math.pi);
    final phase2 = (config.seed * 0.311) % (2 * math.pi);
    final phase3 = (config.seed * 0.523) % (2 * math.pi);

    for (int i = config.layerCount; i >= 1; i--) {
      final t = i / config.layerCount;
      final radius = maxDist * (0.12 + 0.88 * t);

      final points = <Offset>[];
      for (int j = 0; j < sampleCount; j++) {
        final theta = (j / sampleCount) * 2 * math.pi;
        final h1 = math.sin(2 * theta + phase1) * 0.45;
        final h2 = math.cos(3 * theta * config.frequency + phase2) * 0.35;
        final h3 = math.sin(5 * theta + phase3) * 0.20;
        final wobble = 1.0 + config.amplitude * (h1 + h2 + h3);
        final r = radius * wobble;
        points.add(originOffset + Offset(r * math.cos(theta), r * math.sin(theta)));
      }

      final path = Path();
      final mid0 = Offset(
        (points[0].dx + points[sampleCount - 1].dx) / 2,
        (points[0].dy + points[sampleCount - 1].dy) / 2,
      );
      path.moveTo(mid0.dx, mid0.dy);
      for (int j = 0; j < sampleCount; j++) {
        final next = points[(j + 1) % sampleCount];
        final mid = Offset((points[j].dx + next.dx) / 2, (points[j].dy + next.dy) / 2);
        path.quadraticBezierTo(points[j].dx, points[j].dy, mid.dx, mid.dy);
      }
      path.close();

      if (config.showFills) {
        final fillPaint = Paint()
          ..style = PaintingStyle.fill
          ..shader = LinearGradient(
            begin: config.gradientBegin,
            end: config.gradientEnd,
            colors: [
              primaryColor.withValues(alpha: config.fillOpacity * t),
              secondaryColor.withValues(alpha: config.fillOpacity * t * 0.65),
            ],
          ).createShader(Offset.zero & size);
        canvas.drawPath(path, fillPaint);
      }

      if (config.showLines && config.strokeWidth > 0) {
        final linePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = config.strokeWidth
          ..color = primaryColor.withValues(
            alpha: config.lineOpacity * (0.3 + 0.7 * t),
          );
        canvas.drawPath(path, linePaint);
      }
    }
  }

  void _paintFlowingWaves(Canvas canvas, Size size) {
    const sampleCount = 32;

    for (int i = 0; i < config.layerCount; i++) {
      final t = (i + 1) / config.layerCount;
      final wavePhase = (config.seed * 0.211 + i * 1.45) % (2 * math.pi);
      final baseHeight = size.height * (1.0 - t * 0.65);

      final points = <Offset>[];
      for (int j = 0; j <= sampleCount; j++) {
        final normX = j / sampleCount;
        final x = normX * size.width;
        final h1 = math.sin(normX * config.frequency * math.pi + wavePhase) * 0.7;
        final h2 = math.cos(normX * config.frequency * 2 * math.pi + wavePhase * 1.3) * 0.3;

        final cornerWeight = config.origin == ContourOrigin.bottomRight
            ? (1.0 - 0.35 * normX)
            : (config.origin == ContourOrigin.bottomLeft ? (0.65 + 0.35 * normX) : 1.0);

        final y = (baseHeight + config.amplitude * size.height * 0.25 * (h1 + h2)) * cornerWeight;
        points.add(Offset(x, y.clamp(0.0, size.height)));
      }

      final path = Path();
      path.moveTo(0, size.height);
      path.lineTo(points.first.dx, points.first.dy);
      for (int j = 0; j < points.length - 1; j++) {
        final current = points[j];
        final next = points[j + 1];
        final midX = (current.dx + next.dx) / 2;
        final midY = (current.dy + next.dy) / 2;
        path.quadraticBezierTo(current.dx, current.dy, midX, midY);
      }
      path.lineTo(points.last.dx, points.last.dy);
      path.lineTo(size.width, size.height);
      path.close();

      if (config.showFills) {
        final fillPaint = Paint()
          ..style = PaintingStyle.fill
          ..shader = LinearGradient(
            begin: config.gradientBegin,
            end: config.gradientEnd,
            colors: [
              primaryColor.withValues(alpha: config.fillOpacity * (0.4 + 0.6 * t)),
              secondaryColor.withValues(
                alpha: config.fillOpacity * (0.3 + 0.7 * (1.0 - t)),
              ),
            ],
          ).createShader(Offset.zero & size);
        canvas.drawPath(path, fillPaint);
      }

      if (config.showLines && config.strokeWidth > 0) {
        final crestPath = Path();
        crestPath.moveTo(points.first.dx, points.first.dy);
        for (int j = 0; j < points.length - 1; j++) {
          final current = points[j];
          final next = points[j + 1];
          final midX = (current.dx + next.dx) / 2;
          final midY = (current.dy + next.dy) / 2;
          crestPath.quadraticBezierTo(current.dx, current.dy, midX, midY);
        }
        crestPath.lineTo(points.last.dx, points.last.dy);

        final linePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = config.strokeWidth
          ..color = primaryColor.withValues(
            alpha: config.lineOpacity * (0.4 + 0.6 * t),
          );
        canvas.drawPath(crestPath, linePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CentrodeContourPainter oldDelegate) {
    return oldDelegate.config != config ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor;
  }
}
