import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import '../theme/design_tokens.dart';
import '../theme/theme_derived_palette.dart';
import 'surfaces/inset_surface.dart';
import 'surfaces/surface_mode.dart';

typedef SegmentItem<T> = ({
  IconData? icon,
  String label,
  T mode,
  String? tooltip,
  String? accentBadge,
});

class CentrodeSegmentedControl<T> extends StatefulWidget {
  final List<SegmentItem<T>> items;
  final T currentMode;
  final ValueChanged<T> onSelected;
  final bool isCompact;
  final bool expandActive;
  final double? height;
  final Color? accentColor;

  static const defaultCompactItemWidth = 34.0;
  static const defaultExpandedItemWidth = 88.0;

  const CentrodeSegmentedControl({
    super.key,
    required this.items,
    required this.currentMode,
    required this.onSelected,
    required this.isCompact,
    this.expandActive = false,
    this.height,
    this.accentColor,
  });

  @override
  State<CentrodeSegmentedControl<T>> createState() =>
      _CentrodeSegmentedControlState<T>();
}

class _CentrodeSegmentedControlState<T> extends State<CentrodeSegmentedControl<T>>
    with TickerProviderStateMixin {
  final LiquidGlassViewController _viewController = LiquidGlassViewController();
  bool _isCapturing = false;

  late AnimationController _clickController;
  late AnimationController _dragPosController;
  late AnimationController _dragMorphController;
  late Animation<double> _dragPosAnim;

  bool _isDragging = false;
  bool _isClickTransitioning = false;
  double _dragPositionFraction = 0.0;
  double _currentPositionFraction = 0.0;
  double _fromFraction = 0.0;
  double _toFraction = 0.0;
  double _startMorph = 0.0;
  int _targetIndex = 0;

  static const Duration _switchDuration = Duration(milliseconds: 440);

  double _calculateMorph(double T, double startMorph) {
    if (T < 0.25) {
      final t = Curves.easeOutCubic.transform(T / 0.25);
      return startMorph + (1.0 - startMorph) * t;
    } else if (T <= 0.60) {
      return 1.0;
    } else {
      final t = Curves.easeInOut.transform((T - 0.60) / 0.40);
      return 1.0 - t;
    }
  }

  double _calculateStretch(double T) {
    if (T < 0.32) {
      return Curves.easeOutCubic.transform(T / 0.32);
    } else if (T <= 0.52) {
      return 1.0;
    } else if (T < 0.85) {
      final t = Curves.easeOutBack.transform((T - 0.52) / 0.33);
      return (1.0 - t).clamp(-0.08, 1.0);
    } else {
      return 0.0;
    }
  }

  double _calculatePosProgress(double T) {
    if (T < 0.06) {
      return 0.0;
    } else if (T < 0.75) {
      final t = Curves.easeInOutCubic.transform((T - 0.06) / 0.69);
      return t;
    } else {
      return 1.0;
    }
  }

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.items.indexWhere((it) => it.mode == widget.currentMode);
    final initialPos = (initialIndex >= 0 ? initialIndex : 0).toDouble();

    _currentPositionFraction = initialPos;
    _dragPositionFraction = initialPos;
    _targetIndex = initialIndex >= 0 ? initialIndex : 0;
    _fromFraction = initialPos;
    _toFraction = initialPos;

    _clickController = AnimationController(
      vsync: this,
      duration: _switchDuration,
    );
    _clickController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) {
          _dragMorphController.value = 0.0;
          setState(() {
            _isClickTransitioning = false;
            _currentPositionFraction = _targetIndex.toDouble();
            _dragPositionFraction = _targetIndex.toDouble();
          });
          _stopCapture();
        }
      }
    });

    _dragMorphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 260),
    );

    _dragPosController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _dragPosAnim = Tween<double>(begin: _dragPositionFraction, end: _dragPositionFraction)
        .animate(CurvedAnimation(parent: _dragPosController, curve: Curves.easeOutBack));
  }

  @override
  void didUpdateWidget(covariant CentrodeSegmentedControl<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentMode != widget.currentMode && !_isDragging) {
      final targetIndex = widget.items.indexWhere((it) => it.mode == widget.currentMode);
      if (targetIndex >= 0 && _targetIndex != targetIndex) {
        _startClickTransition(targetIndex: targetIndex, notify: false);
      }
    }
  }

  @override
  void dispose() {
    _viewController.stopRealtimeCapture();
    _viewController.detach();
    _clickController.dispose();
    _dragPosController.dispose();
    _dragMorphController.dispose();
    super.dispose();
  }

  double _getCurrentPositionFraction() {
    if (_isDragging) return _dragPositionFraction;
    if (_isClickTransitioning) {
      final posProgress = _calculatePosProgress(_clickController.value);
      return _fromFraction + (_toFraction - _fromFraction) * posProgress;
    }
    if (_dragPosController.isAnimating) return _dragPosAnim.value;
    return _currentPositionFraction;
  }

  double _getCurrentMorph() {
    if (_isClickTransitioning) {
      return _calculateMorph(_clickController.value, _startMorph);
    }
    return _dragMorphController.value;
  }

  void _startCapture() {
    if (!_isCapturing) {
      _isCapturing = true;
      _viewController.startRealtimeCapture();
      _viewController.captureOnce();
    }
  }

  void _stopCapture() {
    if (_isCapturing && !_isDragging && !_isClickTransitioning) {
      _viewController.stopRealtimeCapture();
      _isCapturing = false;
    }
  }

  void _startClickTransition({required int targetIndex, bool notify = true}) {
    if (notify) {
      widget.onSelected(widget.items[targetIndex].mode);
    }
    final startPos = _getCurrentPositionFraction();
    final startMorph = _getCurrentMorph();

    _dragPosController.stop();
    _dragMorphController.stop();
    _dragMorphController.value = 0.0;

    setState(() {
      _isClickTransitioning = true;
      _isDragging = false;
      _fromFraction = startPos;
      _toFraction = targetIndex.toDouble();
      _targetIndex = targetIndex;
      _startMorph = startMorph;
    });

    _startCapture();
    _clickController.forward(from: 0.0);
  }

  void _onPointerDown() {
    _startCapture();
    if (_isClickTransitioning) {
      _clickController.stop();
      _isClickTransitioning = false;
      _currentPositionFraction = _getCurrentPositionFraction();
      _dragPositionFraction = _currentPositionFraction;
    }
    _dragMorphController.animateTo(1.0, curve: Curves.easeOutCubic);
  }

  void _onTapSameIndex() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && !_isDragging && !_isClickTransitioning) {
        _dragMorphController.animateTo(0.0, curve: Curves.easeOutQuad).then((_) {
          _stopCapture();
        });
      }
    });
  }

  void _onDragRelease(int targetIndex) {
    widget.onSelected(widget.items[targetIndex].mode);
    final startPos = _dragPositionFraction;
    _currentPositionFraction = targetIndex.toDouble();
    _dragPosAnim = Tween<double>(
      begin: startPos,
      end: targetIndex.toDouble(),
    ).animate(CurvedAnimation(parent: _dragPosController, curve: Curves.easeOutBack));
    _dragPosController.forward(from: 0.0);

    Future.delayed(const Duration(milliseconds: 140), () {
      if (mounted && !_isDragging && !_isClickTransitioning) {
        _dragMorphController.animateTo(0.0, curve: Curves.easeOutQuad).then((_) {
          _stopCapture();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final palette = CentrodeDerivedPalette.of(context);
    final effectiveAccent = widget.accentColor ?? theme.colorScheme.primary;
    final surfaceMode = CentrodeSurfaceScope.modeOf(context);
    final isQuality = surfaceMode == CentrodeSurfaceMode.quality;
    final count = widget.items.length;

    final controlHeight = widget.height ?? (widget.isCompact ? UiControlSize.dense : UiControlSize.standard);
    const outerPadding = 3.0;
    final cornerRadius = controlHeight / 2;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : ((widget.isCompact
                    ? CentrodeSegmentedControl.defaultCompactItemWidth
                    : CentrodeSegmentedControl.defaultExpandedItemWidth) *
                count);

        final trackInnerWidth = availableWidth - (outerPadding * 2);

        List<double> itemWidths = [];
        List<double> itemOffsets = [];

        final activeIndex = widget.items.indexWhere((it) => it.mode == widget.currentMode);

        if (widget.expandActive && count > 1) {
          final totalWeight = (count - 1) * 1.0 + 1.45;
          final baseUnit = trackInnerWidth / totalWeight;
          double currentOffset = outerPadding;
          for (int i = 0; i < count; i++) {
            final isItemActive = (i == activeIndex);
            final w = baseUnit * (isItemActive ? 1.45 : 1.0);
            itemWidths.add(w);
            itemOffsets.add(currentOffset);
            currentOffset += w;
          }
        } else {
          final uniformWidth = trackInnerWidth / count;
          for (int i = 0; i < count; i++) {
            itemWidths.add(uniformWidth);
            itemOffsets.add(outerPadding + (i * uniformWidth));
          }
        }

        final segmentWidth = trackInnerWidth / count;

        return AnimatedBuilder(
          animation: Listenable.merge([_clickController, _dragPosController, _dragMorphController]),
          builder: (context, child) {
            double morph;
            double stretch = 0.0;
            double activePosFraction;
            double posProgress = 0.0;

            if (_isClickTransitioning) {
              final T = _clickController.value;
              morph = _calculateMorph(T, _startMorph);
              stretch = _calculateStretch(T);
              posProgress = _calculatePosProgress(T);
              activePosFraction = _fromFraction + (_toFraction - _fromFraction) * posProgress;
            } else if (_isDragging) {
              morph = _dragMorphController.value;
              activePosFraction = _dragPositionFraction;
              stretch = 0.0;
            } else {
              morph = _dragMorphController.value;
              activePosFraction = _dragPosController.isAnimating ? _dragPosAnim.value : _currentPositionFraction;
              stretch = 0.0;
            }

            final clampedPos = activePosFraction.clamp(0.0, (count - 1).toDouble());
            final leftIdx = clampedPos.floor();
            final rightIdx = clampedPos.ceil();
            final t = clampedPos - leftIdx;

            final baseHandleWidth = (leftIdx == rightIdx)
                ? itemWidths[leftIdx]
                : (itemWidths[leftIdx] * (1.0 - t) + itemWidths[rightIdx] * t);

            final baseHandleLeft = (leftIdx == rightIdx)
                ? itemOffsets[leftIdx]
                : (itemOffsets[leftIdx] * (1.0 - t) + itemOffsets[rightIdx] * t);

            final distance = (_toFraction - _fromFraction).abs();
            final stretchMultiplier = (distance > 1.5) ? 1.25 : 1.0;
            final maxStretchWidth = (segmentWidth * 0.42 * stretchMultiplier).clamp(16.0, 52.0);
            final currentStretch = stretch * maxStretchWidth;
            final heightSquash = (currentStretch.clamp(0.0, maxStretchWidth) / maxStretchWidth) * 2.5;

            final restHeight = controlHeight - (outerPadding * 2);
            final currentWidth = baseHandleWidth + (8.0 * morph) + currentStretch;
            final currentHeight = restHeight + (4.0 * morph) - heightSquash;
            final top = outerPadding + (restHeight - currentHeight) / 2;

            double currentLeft;
            if (_isClickTransitioning) {
              final baseCenterX = baseHandleLeft + (baseHandleWidth / 2);
              final dir = (_toFraction >= _fromFraction) ? 1.0 : -1.0;
              final leadBias = (1.0 - (2.0 * posProgress).clamp(0.0, 1.0)) * 0.44 * dir * currentStretch;
              final centerX = baseCenterX + leadBias;
              currentLeft = (centerX - (currentWidth / 2)).clamp(1.0, availableWidth - 1.0 - currentWidth);
            } else {
              currentLeft = baseHandleLeft - (4.0 * morph);
            }

            final handleRadius = (currentHeight / 2).clamp(4.0, 999.0);

            final int displayTextIndex;
            if (_isClickTransitioning) {
              displayTextIndex = (posProgress < 0.5) ? _fromFraction.round() : _targetIndex;
            } else {
              displayTextIndex = activePosFraction.round();
            }
            final safeIndex = displayTextIndex.clamp(0, count - 1);

            return SizedBox(
              width: availableWidth,
              height: controlHeight,
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: (_) => _onPointerDown(),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    final localX = (details.localPosition.dx - outerPadding).clamp(0.0, trackInnerWidth);
                    int tappedIndex = 0;
                    for (int i = 0; i < count; i++) {
                      if (localX >= (itemOffsets[i] - outerPadding) &&
                          localX < (itemOffsets[i] + itemWidths[i] - outerPadding)) {
                        tappedIndex = i;
                        break;
                      }
                    }
                    if (tappedIndex == activeIndex && !_isClickTransitioning) {
                      _onTapSameIndex();
                    } else {
                      _startClickTransition(targetIndex: tappedIndex, notify: true);
                    }
                  },
                  onTapCancel: () {
                    if (!_isDragging && !_isClickTransitioning) {
                      _dragMorphController.animateTo(0.0, curve: Curves.easeOutQuad).then((_) {
                        _stopCapture();
                      });
                    }
                  },
                  onHorizontalDragStart: (details) {
                    if (_isClickTransitioning) {
                      _clickController.stop();
                      _isClickTransitioning = false;
                    }
                    _dragPosController.stop();
                    final currentPos = _getCurrentPositionFraction();
                    setState(() {
                      _isDragging = true;
                      _dragPositionFraction = currentPos;
                    });
                    _startCapture();
                    _dragMorphController.animateTo(1.0, curve: Curves.easeOutCubic);
                  },
                  onHorizontalDragUpdate: (details) {
                    setState(() {
                      _dragPositionFraction = (_dragPositionFraction + details.primaryDelta! / segmentWidth)
                          .clamp(0.0, (count - 1).toDouble());
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    final targetIndex = _dragPositionFraction.round().clamp(0, count - 1);
                    setState(() {
                      _isDragging = false;
                      _targetIndex = targetIndex;
                    });
                    _onDragRelease(targetIndex);
                  },
                  onHorizontalDragCancel: () {
                    setState(() {
                      _isDragging = false;
                    });
                    _onDragRelease(activeIndex >= 0 ? activeIndex : 0);
                  },
                  child: LiquidGlassView(
                    controller: _viewController,
                    batch: false,
                    pixelRatio: 1.0,
                    realTimeCapture: false,
                    useSync: true,
                    backgroundWidget: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: CentrodeInsetPainter(
                              cornerRadius: cornerRadius,
                              isDark: isDark,
                              depth: 1.1,
                              accentColor: effectiveAccent,
                            ),
                          ),
                        ),
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Row(
                              children: [
                                for (int i = 0; i < count; i++)
                                  SizedBox(
                                    width: itemWidths[i],
                                    child: Center(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          if (widget.items[i].icon != null) ...[
                                            Icon(
                                              widget.items[i].icon!,
                                              size: UiIconSize.dense,
                                              color: palette.surface.controlForeground.withValues(alpha: 0.65),
                                            ),
                                            if (!widget.isCompact)
                                              const SizedBox(width: UiSpacing.tight),
                                          ],
                                          if (!widget.isCompact)
                                            Flexible(
                                              child: Text(
                                                widget.items[i].label,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: UiFont.compact,
                                                  fontWeight: FontWeight.w500,
                                                  color: palette.surface.controlForeground.withValues(alpha: 0.70),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned(
                          left: currentLeft,
                          top: top,
                          width: currentWidth,
                          height: currentHeight,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (isQuality)
                                LiquidGlassBatch.exclude(
                                  child: LiquidGlassLens(
                                    honorBackdropAlpha: true,
                                    visibility: morph > 0.005,
                                    touch: const LiquidGlassTouch(
                                      flex: LiquidGlassFlex.pronounced(),
                                    ),
                                    style: LiquidGlassStyle(
                                      shape: LiquidGlassShape.continuousRoundedRectangle(
                                        cornerRadius: handleRadius,
                                        borderWidth: 1.0,
                                        lightDirection: 35,
                                        lightColor: Colors.white.withValues(alpha: 0.95),
                                        lightIntensity: 1.0 + (0.5 * morph),
                                      ),
                                      appearance: LiquidGlassAppearance(
                                        color: Colors.transparent,
                                        blur: LiquidGlassBlur(
                                          sigmaX: 0.5 + (1.5 * morph),
                                          sigmaY: 0.5 + (1.5 * morph),
                                        ),
                                        shadow: LiquidGlassShadow(
                                          color: effectiveAccent.withValues(
                                            alpha: isDark ? (0.35 * morph) : (0.25 * morph),
                                          ),
                                          blur: 8.0 * morph,
                                          offset: Offset(0, 2.0 * morph),
                                        ),
                                      ),
                                      refraction: LiquidGlassRefraction(
                                        distortion: 0.18 + (0.08 * morph),
                                        distortionWidth: 26.0 + (10.0 * morph),
                                        magnification: 1.15 + (0.10 * morph),
                                        chromaticAberration: 0.003 * morph,
                                      ),
                                    ),
                                    child: IgnorePointer(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(handleRadius),
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [
                                              effectiveAccent.withValues(alpha: isDark ? 0.38 : 0.28),
                                              effectiveAccent.withValues(alpha: isDark ? 0.12 : 0.06),
                                              Colors.transparent,
                                            ],
                                            stops: const [0.0, 0.50, 1.0],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              IgnorePointer(
                                child: Opacity(
                                  opacity: (1.0 - morph).clamp(0.0, 1.0),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: effectiveAccent,
                                      borderRadius: BorderRadius.circular(handleRadius),
                                      border: Border.all(
                                        color: Colors.white.withValues(alpha: isDark ? 0.35 : 0.65),
                                        width: 1.0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: effectiveAccent.withValues(alpha: isDark ? 0.40 : 0.30),
                                          blurRadius: 8.0,
                                          offset: const Offset(0, 2.0),
                                        ),
                                      ],
                                    ),
                                    child: (morph < 0.35)
                                        ? Center(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                if (widget.items[safeIndex].icon != null) ...[
                                                  Icon(
                                                    widget.items[safeIndex].icon!,
                                                    size: UiIconSize.dense,
                                                    color: palette.textOn(effectiveAccent),
                                                  ),
                                                  if (!widget.isCompact)
                                                    const SizedBox(width: UiSpacing.tight),
                                                ],
                                                if (!widget.isCompact)
                                                  Flexible(
                                                    child: Text(
                                                      widget.items[safeIndex].label,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        fontSize: UiFont.compact,
                                                        fontWeight: FontWeight.w700,
                                                        color: palette.textOn(effectiveAccent),
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
