import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../theme/theme_derived_palette.dart';
import 'surfaces/double_edge_surface.dart';

class CentrodeDropdownItem<T> {
  final T value;
  final String label;
  final IconData? icon;
  final Widget? child;

  const CentrodeDropdownItem({
    required this.value,
    required this.label,
    this.icon,
    this.child,
  });
}

class CentrodeDropdown<T> extends StatefulWidget {
  final T value;
  final List<CentrodeDropdownItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final Color? accentColor;
  final double cornerRadius;
  final double height;
  final double? width;

  final T? selectedValue;
  final ValueChanged<T>? onSelected;

  CentrodeDropdown({
    super.key,
    T? value,
    this.selectedValue,
    required this.items,
    ValueChanged<T?>? onChanged,
    this.onSelected,
    this.accentColor,
    this.cornerRadius = UiRadius.control,
    this.height = UiControlSize.standard,
    this.width,
    String? label,
    double? labelWidth,
    Color? activeColor,
  })  : value = (value ?? selectedValue) as T,
        onChanged = onChanged ?? (onSelected != null ? ((v) { if (v != null) onSelected(v); }) : null);

  @override
  State<CentrodeDropdown<T>> createState() => _CentrodeDropdownState<T>();
}

class _CentrodeDropdownState<T> extends State<CentrodeDropdown<T>>
    with TickerProviderStateMixin {
  final _portalController = OverlayPortalController();
  final _link = LayerLink();
  final _triggerKey = GlobalKey();

  late AnimationController _morphController;

  double _buttonWidth = 220.0;
  double _buttonHeight = UiControlSize.standard;
  bool _isOpen = false;
  bool _isHovered = false;

  int _hoveredIndex = 0;
  late T _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.value;
    _buttonHeight = widget.height;
    _morphController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
      reverseDuration: const Duration(milliseconds: 240),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _measureTrigger());
  }

  @override
  void didUpdateWidget(covariant CentrodeDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _selectedValue = widget.value;
    }
    if (widget.height != oldWidget.height) {
      _buttonHeight = widget.height;
    }
  }

  @override
  void dispose() {
    _morphController.dispose();
    super.dispose();
  }

  void _measureTrigger() {
    final renderBox = _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      if (mounted) {
        setState(() {
          _buttonWidth = renderBox.size.width;
          _buttonHeight = renderBox.size.height;
        });
      }
    }
  }

  void _open() {
    _measureTrigger();
    final selectedIdx = widget.items.indexWhere((it) => it.value == _selectedValue);
    final safeIdx = selectedIdx >= 0 ? selectedIdx : 0;

    setState(() {
      _isOpen = true;
      _hoveredIndex = safeIdx;
    });
    _portalController.show();
    _morphController.forward(from: 0.0);
  }

  void _close() {
    if (!_isOpen && !_morphController.isAnimating) return;
    _morphController.reverse().then((_) {
      if (mounted) {
        _portalController.hide();
        setState(() => _isOpen = false);
      }
    });
  }

  void _toggle() {
    if (_isOpen) {
      _close();
    } else {
      _open();
    }
  }

  void _handleSelect(T newValue) {
    setState(() {
      _selectedValue = newValue;
    });
    widget.onChanged?.call(newValue);
    _close();
  }

  void _onHoverRow(int targetIndex) {
    if (_hoveredIndex == targetIndex) return;
    setState(() {
      _hoveredIndex = targetIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final palette = CentrodeDerivedPalette.of(context);
    final accent = widget.accentColor ?? theme.colorScheme.primary;

    final selectedItem = widget.items.firstWhere(
      (item) => item.value == _selectedValue,
      orElse: () => widget.items.first,
    );

    return CompositedTransformTarget(
      link: _link,
      key: _triggerKey,
      child: OverlayPortal(
        controller: _portalController,
        overlayChildBuilder: (overlayContext) {
          const double itemHeight = UiControlSize.standard;
          const double verticalPadding = 6.0;
          const double horizontalPadding = 4.0;
          final int count = widget.items.length;

          final selectedIdx = widget.items.indexWhere((it) => it.value == _selectedValue);
          final safeSelected = (selectedIdx >= 0 ? selectedIdx : 0).clamp(0, count - 1);

          final double yTopAnchor = (_buttonHeight - itemHeight) / 2;
          final double dAbove = verticalPadding + (safeSelected * itemHeight);
          final double dBelow = verticalPadding + ((count - 1 - safeSelected) * itemHeight);

          final double targetTop = yTopAnchor - dAbove;
          final double targetBottom = yTopAnchor + itemHeight + dBelow;

          final double frameWidth = _buttonWidth;
          final double frameHeight = targetBottom - targetTop;
          final double pillTop = -targetTop;

          return Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: _close,
                ),
              ),
              CompositedTransformFollower(
                link: _link,
                showWhenUnlinked: false,
                targetAnchor: Alignment.topLeft,
                followerAnchor: Alignment.topLeft,
                child: AnimatedBuilder(
                  animation: _morphController,
                  builder: (context, _) {
                    final t = _morphController.value;
                    final isReversing = _morphController.status == AnimationStatus.reverse;

                    final double morph = isReversing
                        ? Curves.easeInOut.transform(t)
                        : (t < 0.25
                            ? Curves.easeOutCubic.transform(t / 0.25)
                            : (t <= 0.65
                                ? 1.0
                                : (1.0 - 0.15 * Curves.easeOutBack.transform((t - 0.65) / 0.35))));

                    double widthSquash = 0.0;
                    if (!isReversing && t >= 0.08 && t <= 0.65) {
                      final st = (t - 0.08) / 0.57;
                      widthSquash = math.sin(st * math.pi) * 3.2;
                    }
                    final double boxLeft = widthSquash / 2.0;
                    final double boxWidth = frameWidth - widthSquash;

                    final double fillLinear = isReversing
                        ? t
                        : ((t - 0.30) / 0.66).clamp(0.0, 1.0);
                    final double fillEase = isReversing
                        ? Curves.easeInOutCubic.transform(fillLinear)
                        : Curves.easeOutCubic.transform(fillLinear);

                    final double boxTop = lerpDouble(pillTop, 0.0, fillEase)!;
                    final double boxBottom = lerpDouble(pillTop + _buttonHeight, frameHeight, fillEase)!;
                    final Rect boxRect = Rect.fromLTWH(boxLeft, boxTop, boxWidth, boxBottom - boxTop);

                    final double startRadius = _buttonHeight / 2;
                    const double endRadius = UiRadius.card;
                    final double radiusT = isReversing
                        ? Curves.easeOutCubic.transform(t)
                        : Curves.easeOutCubic.transform(((t - 0.10) / 0.75).clamp(0.0, 1.0));
                    final double currentRadius = lerpDouble(startRadius, endRadius, radiusT) ?? endRadius;

                    return Transform.translate(
                      offset: Offset(0, targetTop),
                      child: SizedBox(
                        width: frameWidth,
                        height: frameHeight,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fromRect(
                              rect: boxRect,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF1E242B) : Colors.white,
                                  borderRadius: BorderRadius.circular(currentRadius),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.12)
                                        : Colors.black.withValues(alpha: 0.10),
                                    width: 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isDark ? (0.45 * morph) : (0.18 * morph)),
                                      blurRadius: 16.0 * morph,
                                      offset: Offset(0, 4.0 * morph),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              top: verticalPadding,
                              left: horizontalPadding,
                              right: horizontalPadding,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (int i = 0; i < widget.items.length; i++) ...[
                                    Builder(
                                      builder: (context) {
                                        final dist = (i - safeSelected).abs();
                                        double itemOpacity = 1.0;
                                        double itemSlide = 0.0;

                                        if (i != safeSelected) {
                                          if (isReversing) {
                                            itemOpacity = Curves.easeInQuad.transform((t / 0.70).clamp(0.0, 1.0));
                                            itemSlide = (1.0 - itemOpacity) * 8.0;
                                          } else {
                                            final staggerStart = 0.06 + (dist * 0.08);
                                            final itemProgress = ((t - staggerStart) / 0.22).clamp(0.0, 1.0);
                                            itemOpacity = Curves.easeOutCubic.transform(itemProgress);
                                            final dir = (i < safeSelected) ? 1.0 : -1.0;
                                            itemSlide = (1.0 - itemOpacity) * 8.0 * dir;
                                          }
                                        }

                                        final isItemHovered = i == _hoveredIndex && t > 0.15;
                                        final hoverBg = isDark
                                            ? Colors.white.withValues(alpha: 0.10)
                                            : accent.withValues(alpha: 0.12);

                                        return Transform.translate(
                                          offset: Offset(0, itemSlide),
                                          child: Opacity(
                                            opacity: itemOpacity,
                                            child: MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              onEnter: (_) => _onHoverRow(i),
                                              child: GestureDetector(
                                                behavior: HitTestBehavior.opaque,
                                                onTap: () => _handleSelect(widget.items[i].value),
                                                child: Container(
                                                  height: itemHeight,
                                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                                  decoration: BoxDecoration(
                                                    color: isItemHovered ? hoverBg : Colors.transparent,
                                                    borderRadius: BorderRadius.circular(UiRadius.control),
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      if (widget.items[i].icon != null) ...[
                                                        Icon(
                                                          widget.items[i].icon,
                                                          size: UiIconSize.dense,
                                                          color: isItemHovered
                                                              ? accent
                                                              : (isDark
                                                                  ? Colors.white.withValues(alpha: 0.75)
                                                                  : const Color(0xFF1E242B).withValues(alpha: 0.75)),
                                                        ),
                                                        const SizedBox(width: 8.0),
                                                      ],
                                                      Expanded(
                                                        child: widget.items[i].child ??
                                                            Text(
                                                              widget.items[i].label,
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
                                                              style: TextStyle(
                                                                fontSize: UiFont.compact,
                                                                fontWeight: (widget.items[i].value == _selectedValue)
                                                                    ? FontWeight.w700
                                                                    : (isItemHovered
                                                                        ? FontWeight.w600
                                                                        : FontWeight.w500),
                                                                color: isItemHovered
                                                                    ? (isDark ? Colors.white : accent)
                                                                    : (isDark ? Colors.white : const Color(0xFF1E242B)),
                                                              ),
                                                            ),
                                                      ),
                                                      if (i == safeSelected && t < 0.25)
                                                        AnimatedRotation(
                                                          turns: Curves.easeInOutCubic.transform(t) * 0.5,
                                                          duration: Duration.zero,
                                                          child: Icon(
                                                            Icons.keyboard_arrow_down_rounded,
                                                            size: UiIconSize.standard,
                                                            color: accent,
                                                          ),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            onTap: _toggle,
            child: SizedBox(
              width: widget.width,
              height: widget.height,
              child: CentrodeDoubleEdgeSurface(
                cornerRadius: widget.cornerRadius,
                accentColor: _isOpen ? accent : (_isHovered ? accent.withValues(alpha: 0.5) : null),
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  children: [
                    if (selectedItem.icon != null) ...[
                      Icon(
                        selectedItem.icon,
                        size: UiIconSize.dense,
                        color: _isOpen ? accent : palette.surface.controlForeground.withValues(alpha: 0.75),
                      ),
                      const SizedBox(width: 8.0),
                    ],
                    Expanded(
                      child: selectedItem.child ??
                          Text(
                            selectedItem.label,
                            style: TextStyle(
                              fontSize: UiFont.compact,
                              fontWeight: FontWeight.w600,
                              color: palette.surface.controlForeground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                    ),
                    const SizedBox(width: 6.0),
                    AnimatedRotation(
                      turns: _isOpen ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _isOpen ? accent : palette.surface.controlForeground.withValues(alpha: 0.6),
                        size: UiIconSize.standard,
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
