import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../theme/theme_derived_palette.dart';
import 'surfaces/double_edge_painter.dart';
import 'surfaces/inset_surface.dart';

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
    with SingleTickerProviderStateMixin {
  bool _isDragging = false;
  double _dragPositionFraction = 0.0;
  late AnimationController _animController;
  late Animation<double> _animPosition;

  @override
  void initState() {
    super.initState();
    final initialIndex = widget.items.indexWhere((it) => it.mode == widget.currentMode);
    _dragPositionFraction = (initialIndex >= 0 ? initialIndex : 0).toDouble();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _animPosition = Tween<double>(
      begin: _dragPositionFraction,
      end: _dragPositionFraction,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
  }

  @override
  void didUpdateWidget(covariant CentrodeSegmentedControl<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentMode != widget.currentMode && !_isDragging) {
      final targetIndex = widget.items.indexWhere((it) => it.mode == widget.currentMode);
      if (targetIndex >= 0) {
        _animPosition = Tween<double>(
          begin: _animPosition.value,
          end: targetIndex.toDouble(),
        ).animate(
          CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
        );
        _animController.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final palette = CentrodeDerivedPalette.of(context);
    final effectiveAccent = widget.accentColor ?? theme.colorScheme.primary;
    final count = widget.items.length;
    final activeIndex = widget.items.indexWhere((it) => it.mode == widget.currentMode);

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

        return AnimatedBuilder(
          animation: _animController,
          builder: (context, _) {
            final activePos = _isDragging ? _dragPositionFraction : _animPosition.value;
            final clampedPos = activePos.clamp(0.0, (count - 1).toDouble());

            final leftIdx = clampedPos.floor();
            final rightIdx = clampedPos.ceil();
            final t = clampedPos - leftIdx;

            final handleLeft = (leftIdx == rightIdx)
                ? itemOffsets[leftIdx]
                : (itemOffsets[leftIdx] * (1.0 - t) + itemOffsets[rightIdx] * t);

            final handleWidth = (leftIdx == rightIdx)
                ? itemWidths[leftIdx]
                : (itemWidths[leftIdx] * (1.0 - t) + itemWidths[rightIdx] * t);

            final morphStretch = _isDragging ? 8.0 : 0.0;
            final handleHeight = (controlHeight - (outerPadding * 2));
            final handleRadius = (handleHeight / 2).clamp(4.0, 999.0);

            return SizedBox(
              width: availableWidth,
              height: controlHeight,
              child: Stack(
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
                  Positioned(
                    left: handleLeft - (morphStretch / 2),
                    top: outerPadding,
                    width: handleWidth + morphStretch,
                    height: handleHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(handleRadius),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            effectiveAccent.withValues(alpha: isDark ? 0.32 : 0.22),
                            effectiveAccent.withValues(alpha: isDark ? 0.16 : 0.08),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: effectiveAccent.withValues(alpha: _isDragging ? 0.40 : 0.25),
                            blurRadius: _isDragging ? 12.0 : 6.0,
                            offset: Offset(0, _isDragging ? 2.5 : 1.0),
                          ),
                        ],
                      ),
                      child: CustomPaint(
                        painter: CentrodeDoubleEdgePainter(
                          cornerRadius: handleRadius,
                          stepWidth: 1.2,
                          lightIntensity: isDark ? 1.0 : 0.8,
                          shadowIntensity: isDark ? 0.6 : 0.35,
                          accentColor: effectiveAccent,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Row(
                      children: [
                        for (int i = 0; i < count; i++)
                          SizedBox(
                            width: itemWidths[i],
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (widget.items[i].mode != widget.currentMode) {
                                  widget.onSelected(widget.items[i].mode);
                                }
                              },
                              onHorizontalDragStart: (details) {
                                setState(() {
                                  _isDragging = true;
                                  _dragPositionFraction = i.toDouble();
                                });
                              },
                              onHorizontalDragUpdate: (details) {
                                setState(() {
                                  final currentItemWidth = itemWidths[i];
                                  _dragPositionFraction += details.primaryDelta! / currentItemWidth;
                                  _dragPositionFraction = _dragPositionFraction.clamp(
                                    0.0,
                                    (count - 1).toDouble(),
                                  );
                                });
                              },
                              onHorizontalDragEnd: (details) {
                                final targetIndex = _dragPositionFraction.round().clamp(0, count - 1);
                                setState(() {
                                  _isDragging = false;
                                });
                                widget.onSelected(widget.items[targetIndex].mode);
                              },
                              onHorizontalDragCancel: () {
                                setState(() {
                                  _isDragging = false;
                                });
                              },
                              child: Tooltip(
                                message: widget.items[i].tooltip ?? widget.items[i].label,
                                child: Center(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (widget.items[i].icon != null) ...[
                                        Icon(
                                          widget.items[i].icon!,
                                          size: UiIconSize.dense,
                                          color: (i == activeIndex)
                                              ? (isDark ? Colors.white : effectiveAccent)
                                              : palette.surface.controlForeground.withValues(alpha: 0.65),
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
                                              fontWeight: (i == activeIndex)
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              color: (i == activeIndex)
                                                  ? (isDark ? Colors.white : effectiveAccent)
                                                  : palette.surface.controlForeground.withValues(alpha: 0.70),
                                            ),
                                          ),
                                        ),
                                      if (!widget.isCompact && widget.items[i].accentBadge != null) ...[
                                        const SizedBox(width: 3.0),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
                                          decoration: BoxDecoration(
                                            color: effectiveAccent,
                                            borderRadius: BorderRadius.circular(4.0),
                                          ),
                                          child: Text(
                                            widget.items[i].accentBadge!,
                                            style: TextStyle(
                                              fontSize: 7.5,
                                              fontWeight: FontWeight.w800,
                                              color: palette.textOn(effectiveAccent),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
