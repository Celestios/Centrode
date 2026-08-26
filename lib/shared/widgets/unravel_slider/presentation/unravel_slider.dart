import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../domain/unravel_slider_metrics.dart';
import 'unravel_slider_theme.dart';

/// Item descriptor for standard icon-and-label options in [UnravelSlider].
typedef UnravelOption = ({IconData icon, String label});

/// Signature for custom option cell builders.
typedef UnravelItemBuilder<T> = Widget Function(
  BuildContext context,
  T item,
  double focus,
  bool isSelected,
);

/// A non-linear, sigmoid-unravelling segmented slider.
///
/// Provides a fisheye-style lens effect that expands the active item into full focus
/// while gracefully compressing and fading peripheral options into the margins.
class UnravelSlider<T> extends StatefulWidget {
  final List<T> items;
  final int selectedIndex;
  final ValueChanged<int>? onSelected;
  final ValueChanged<int>? onSelectFinalized;
  final double? trackWidth;
  final bool magnetic;
  final bool autofocus;
  final UnravelItemBuilder<T>? itemBuilder;
  final UnravelSliderThemeData? theme;

  const UnravelSlider({
    super.key,
    required this.items,
    this.selectedIndex = 0,
    this.onSelected,
    this.onSelectFinalized,
    this.trackWidth,
    this.magnetic = false,
    this.autofocus = false,
    this.itemBuilder,
    this.theme,
  });

  @override
  State<UnravelSlider<T>> createState() => _UnravelSliderState<T>();
}

class _UnravelSliderState<T> extends State<UnravelSlider<T>>
    with SingleTickerProviderStateMixin {
  static const _tapSlack = 6.0;

  late final AnimationController _settleController;
  late final FocusNode _focusNode;
  Timer? _scrollSettleTimer;

  double _settleFrom = 0.0;
  double _settleTo = 0.0;
  double _u = 0.0;
  double _rawU = 0.0;

  int? _activePointer;
  Offset? _downPos;
  bool _isInteracting = false;
  int? _lastReportedIndex;
  late UnravelSliderMetrics _metrics;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _settleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(_onSettleTick);

    _updateMetrics(widget.trackWidth ?? 230.0);
    _u = _rawU = _metrics.anchorU(widget.selectedIndex);
    _lastReportedIndex = widget.selectedIndex;
  }

  @override
  void didUpdateWidget(covariant UnravelSlider<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length ||
        oldWidget.trackWidth != widget.trackWidth ||
        oldWidget.theme != widget.theme) {
      _updateMetrics(widget.trackWidth ?? _metrics.trackWidth);
      _u = _rawU = _rawU.clamp(0.0, _metrics.handleTravel);
    }

    if (oldWidget.selectedIndex != widget.selectedIndex) {
      // Only animate if the change was triggered externally, not from active local interaction
      if (widget.selectedIndex != _lastReportedIndex && !_isInteracting) {
        _lastReportedIndex = widget.selectedIndex;
        _animateTo(_metrics.anchorU(widget.selectedIndex));
      }
    }
  }

  @override
  void dispose() {
    _scrollSettleTimer?.cancel();
    _focusNode.dispose();
    _settleController.dispose();
    super.dispose();
  }

  void _updateMetrics(double width) {
    final style = widget.theme ?? const UnravelSliderThemeData();
    _metrics = UnravelSliderMetrics(
      trackWidth: width,
      itemCount: widget.items.length,
      cellWidth: style.cellWidth,
      cellHeight: style.cellHeight,
    );
  }

  void _onSettleTick() {
    setState(() {
      _u = _settleFrom +
          (_settleTo - _settleFrom) *
              Curves.easeOutCubic.transform(_settleController.value);
    });
  }

  void _animateTo(double target) {
    _settleFrom = _u;
    _settleTo = target.clamp(0.0, _metrics.handleTravel);
    _settleController.duration = Duration(
      milliseconds: (80 + (_settleTo - _settleFrom).abs() * 1.4)
          .round()
          .clamp(90, 260),
    );
    _settleController.forward(from: 0);
  }

  void _applyDragDelta(double dx) {
    _rawU = (_rawU + dx).clamp(0.0, _metrics.handleTravel);
    if (widget.magnetic) {
      final target = _metrics.snapU(_rawU);
      final headingThere = _settleController.isAnimating &&
          (_settleTo - target).abs() < 0.01;
      if ((target - _u).abs() > 0.01 && !headingThere) {
        _animateTo(target);
      }
    } else {
      _u = _rawU;
    }

    final handleCenter = _metrics.margin + _u;
    final xs = _metrics.computeXs(_u);
    final nearest = _metrics.nearestIndex(handleCenter, xs);
    if (nearest != widget.selectedIndex && nearest != _lastReportedIndex) {
      _lastReportedIndex = nearest;
      widget.onSelected?.call(nearest);
    }
  }

  void _onPointerDown(PointerDownEvent e) {
    _focusNode.requestFocus();
    _isInteracting = true;
    _scrollSettleTimer?.cancel();
    _activePointer = e.pointer;
    _downPos = e.position;
    _settleController.stop();
    _rawU = _u;
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (_activePointer != e.pointer) return;
    setState(() => _applyDragDelta(e.delta.dx));
  }

  void _onPointerUp(PointerUpEvent e) {
    if (_activePointer != e.pointer) return;
    _activePointer = null;
    _isInteracting = false;
    final moved = (e.position - _downPos!).distance;
    if (moved < _tapSlack) {
      _selectAt(e.localPosition.dx);
    } else if (!widget.magnetic) {
      final handleCenter = _metrics.margin + _u;
      final xs = _metrics.computeXs(_u);
      final targetIndex = _metrics.nearestIndex(handleCenter, xs);
      _lastReportedIndex = targetIndex;
      _animateTo(_metrics.anchorU(targetIndex));
      widget.onSelectFinalized?.call(targetIndex);
    } else {
      final targetIndex = _metrics.nearestIndex(_metrics.margin + _u, _metrics.computeXs(_u));
      _lastReportedIndex = targetIndex;
      widget.onSelectFinalized?.call(targetIndex);
    }
  }

  void _onPointerCancel(PointerCancelEvent e) {
    if (_activePointer != e.pointer) return;
    _activePointer = null;
    _isInteracting = false;
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      _settleController.stop();
      _isInteracting = true;
      _scrollSettleTimer?.cancel();

      final delta = event.scrollDelta.dx != 0 ? event.scrollDelta.dx : event.scrollDelta.dy;
      if (delta.abs() > 0.1) {
        setState(() => _applyDragDelta(delta * 0.4));
      }

      _scrollSettleTimer = Timer(const Duration(milliseconds: 140), () {
        if (!mounted) return;
        _isInteracting = false;
        if (!widget.magnetic) {
          final handleCenter = _metrics.margin + _u;
          final xs = _metrics.computeXs(_u);
          final targetIndex = _metrics.nearestIndex(handleCenter, xs);
          _lastReportedIndex = targetIndex;
          _animateTo(_metrics.anchorU(targetIndex));
          widget.onSelectFinalized?.call(targetIndex);
        } else {
          final targetIndex = _metrics.nearestIndex(_metrics.margin + _u, _metrics.computeXs(_u));
          _lastReportedIndex = targetIndex;
          widget.onSelectFinalized?.call(targetIndex);
        }
      });
    }
  }

  void _selectAt(double localX) {
    final xs = _metrics.computeXs(_u);
    final hitIndex = _metrics.hitTest(localX, xs);
    if (hitIndex >= 0) {
      _lastReportedIndex = hitIndex;
      _animateTo(_metrics.anchorU(hitIndex));
      widget.onSelected?.call(hitIndex);
      widget.onSelectFinalized?.call(hitIndex);
    }
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      final prev = (widget.selectedIndex - 1).clamp(0, widget.items.length - 1);
      _lastReportedIndex = prev;
      _animateTo(_metrics.anchorU(prev));
      widget.onSelected?.call(prev);
      widget.onSelectFinalized?.call(prev);
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      final next = (widget.selectedIndex + 1).clamp(0, widget.items.length - 1);
      _lastReportedIndex = next;
      _animateTo(_metrics.anchorU(next));
      widget.onSelected?.call(next);
      widget.onSelectFinalized?.call(next);
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.home) {
      _lastReportedIndex = 0;
      _animateTo(_metrics.anchorU(0));
      widget.onSelected?.call(0);
      widget.onSelectFinalized?.call(0);
      return KeyEventResult.handled;
    } else if (event.logicalKey == LogicalKeyboardKey.end) {
      final last = widget.items.length - 1;
      _lastReportedIndex = last;
      _animateTo(_metrics.anchorU(last));
      widget.onSelected?.call(last);
      widget.onSelectFinalized?.call(last);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final style = (widget.theme ?? const UnravelSliderThemeData()).resolve(context);
    final width = widget.trackWidth ?? _metrics.trackWidth;

    if ((width - _metrics.trackWidth).abs() > 0.5) {
      _updateMetrics(width);
    }

    final handleCenter = _metrics.margin + _u;
    final xs = _metrics.computeXs(_u);
    final handleBoxW = _metrics.handleBoxWidth;
    final cellW = _metrics.cellWidth;
    final n = widget.items.length;
    final selected = _metrics.nearestIndex(handleCenter, xs).clamp(0, n - 1);

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: _onKeyEvent,
      child: MouseRegion(
        cursor: SystemMouseCursors.grab,
        child: RepaintBoundary(
          child: Container(
            width: _metrics.trackWidth,
            height: _metrics.trackHeight,
            decoration: BoxDecoration(
              color: style.trackBackgroundColor,
              borderRadius: style.trackBorderRadius,
              border: Border.all(color: style.trackBorderColor!),
            ),
            child: ClipRRect(
              borderRadius: style.trackBorderRadius,
              child: Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: _onPointerDown,
                onPointerMove: _onPointerMove,
                onPointerUp: _onPointerUp,
                onPointerCancel: _onPointerCancel,
                onPointerSignal: _onPointerSignal,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // Moving handle indicator box
                    Positioned(
                      left: handleCenter - handleBoxW / 2,
                      top: 0,
                      bottom: 0,
                      width: handleBoxW,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: style.handleBorderRadius,
                          border: Border.all(
                            color: style.handleBorderColor!,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: style.handleShadowColor!,
                              blurRadius: 14,
                              spreadRadius: -1,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Unravelling options
                    for (var i = 0; i < n; i++)
                      Positioned(
                        key: ValueKey(i),
                        left: xs[i] - cellW / 2,
                        top: 0,
                        bottom: 0,
                        width: cellW,
                        child: widget.itemBuilder != null
                            ? widget.itemBuilder!(
                                context,
                                widget.items[i],
                                _metrics.spatialFocus(xs[i], handleCenter),
                                i == selected,
                              )
                            : _DefaultUnravelCell(
                                item: widget.items[i],
                                focus: _metrics.spatialFocus(xs[i], handleCenter),
                                style: style,
                              ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DefaultUnravelCell extends StatelessWidget {
  final dynamic item;
  final double focus;
  final UnravelSliderThemeData style;

  const _DefaultUnravelCell({
    required this.item,
    required this.focus,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final icon = item is UnravelOption
        ? item.icon
        : (item is IconData ? item : Icons.circle_outlined);
    final label = item is UnravelOption
        ? item.label
        : (item is String ? item : item.toString());

    final easedFocus = Curves.easeOutCubic.transform(focus);
    final scale = 0.74 + 0.26 * easedFocus;
    final opacity = 0.22 + 0.78 * easedFocus;

    final itemColor = Color.lerp(
      style.textColor!.withValues(alpha: 0.45),
      style.accentColor!,
      easedFocus,
    )!;

    final fontWeight = FontWeight.lerp(
      FontWeight.w500,
      FontWeight.w800,
      easedFocus,
    )!;

    return Center(
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: style.iconSize,
                color: itemColor,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  fontSize: style.labelFontSize,
                  fontWeight: fontWeight,
                  color: itemColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
