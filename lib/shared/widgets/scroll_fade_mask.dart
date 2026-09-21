import 'dart:ui';
import 'package:flutter/material.dart';

class ScrollFadeMask extends StatefulWidget {
  final ScrollController scrollController;
  final double topFadeHeight;
  final double bottomFadeHeight;
  final Color surfaceColor;
  final bool enableTopFade;
  final bool enableBottomFade;
  final bool enableBlur;
  final double blurSigma;
  final ShapeBorder? clipShape;
  final Widget child;

  const ScrollFadeMask({
    super.key,
    required this.scrollController,
    required this.surfaceColor,
    required this.child,
    this.topFadeHeight = 96.0,
    this.bottomFadeHeight = 48.0,
    this.enableTopFade = true,
    this.enableBottomFade = true,
    this.enableBlur = false,
    this.blurSigma = 24.0,
    this.clipShape,
  });

  @override
  State<ScrollFadeMask> createState() => _ScrollFadeMaskState();
}

class _ScrollFadeMaskState extends State<ScrollFadeMask> {
  bool _showTopFade = false;
  bool _showBottomFade = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_updateFadeState);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateFadeState());
  }

  @override
  void didUpdateWidget(ScrollFadeMask oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scrollController != widget.scrollController) {
      oldWidget.scrollController.removeListener(_updateFadeState);
      widget.scrollController.addListener(_updateFadeState);
      WidgetsBinding.instance.addPostFrameCallback((_) => _updateFadeState());
    }
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_updateFadeState);
    super.dispose();
  }

  void _updateFadeState() {
    if (!widget.scrollController.hasClients) return;
    final position = widget.scrollController.position;

    final showTop = widget.enableTopFade && position.pixels > 0.0;
    final showBottom = widget.enableBottomFade &&
        position.pixels < position.maxScrollExtent;

    if (showTop != _showTopFade || showBottom != _showBottomFade) {
      setState(() {
        _showTopFade = showTop;
        _showBottomFade = showBottom;
      });
    }
  }

  static const _fadeStops = [
    0.0, 0.20, 0.40, 0.58, 0.72, 0.84, 0.93, 1.0,
  ];

  static const _maskAlphas = [
    0xFF, 0xFF, 0xFA, 0xCC, 0x8C, 0x47, 0x14, 0x00,
  ];

  static const _surfaceAlphas = [
    0.98, 0.96, 0.90, 0.72, 0.48, 0.24, 0.08, 0.0,
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: widget.child),
        if (_showTopFade) _buildFadeEdge(_FadeEdge.top),
        if (_showBottomFade) _buildFadeEdge(_FadeEdge.bottom),
      ],
    );
  }

  Widget _buildFadeEdge(_FadeEdge edge) {
    final isTop = edge == _FadeEdge.top;
    final begin = isTop ? Alignment.topCenter : Alignment.bottomCenter;
    final end = isTop ? Alignment.bottomCenter : Alignment.topCenter;
    final height = isTop ? widget.topFadeHeight : widget.bottomFadeHeight;

    final maskGradient = LinearGradient(
      begin: begin,
      end: end,
      stops: _fadeStops,
      colors: [
        for (final a in _maskAlphas) Color.fromARGB(a, 0, 0, 0),
      ],
    );

    final surfaceGradient = LinearGradient(
      begin: begin,
      end: end,
      stops: _fadeStops,
      colors: [
        for (final a in _surfaceAlphas)
          widget.surfaceColor.withValues(alpha: a),
      ],
    );

    Widget fadeLayer;

    if (widget.enableBlur) {
      fadeLayer = ShaderMask(
        shaderCallback: (bounds) => maskGradient.createShader(bounds),
        blendMode: BlendMode.dstIn,
        child: _optionalClip(
          BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: widget.blurSigma,
              sigmaY: widget.blurSigma,
            ),
            child: Container(
              decoration: BoxDecoration(gradient: surfaceGradient),
            ),
          ),
        ),
      );
    } else {
      fadeLayer = IgnorePointer(
        child: Container(
          decoration: BoxDecoration(gradient: surfaceGradient),
        ),
      );
    }

    return Positioned(
      top: isTop ? 0.0 : null,
      bottom: isTop ? null : 0.0,
      left: 0.0,
      right: 0.0,
      height: height,
      child: fadeLayer,
    );
  }

  Widget _optionalClip(Widget child) {
    if (widget.clipShape != null) {
      return ClipPath(
        clipper: ShapeBorderClipper(shape: widget.clipShape!),
        child: child,
      );
    }
    return child;
  }
}

enum _FadeEdge { top, bottom }
