import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../theme/theme_derived_palette.dart';
import '../utils/color_theory_engine.dart';
import '../widgets/context_menu_overlay.dart';

class CentrodeColorOption<T> {
  final T value;
  final Color? color;
  final String label;
  final bool isNone;

  const CentrodeColorOption({
    required this.value,
    this.color,
    required this.label,
    this.isNone = false,
  });
}

/// Standardized circular color indicator dot.
class CentrodeColorDot extends StatelessWidget {
  final Color? color;
  final bool isNone;
  final double size;
  final bool isSelected;
  final Color? selectedBorderColor;

  const CentrodeColorDot({
    super.key,
    this.color,
    this.isNone = false,
    this.size = 12.0,
    this.isSelected = false,
    this.selectedBorderColor,
  });

  @override
  Widget build(BuildContext context) {
    final palette = CentrodeDerivedPalette.of(context);
    final fallbackSelectedBorder = palette.borderStrong;
    final unselectedBorder = palette.borderSubtle;

    if (isNone || color == null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? (selectedBorderColor ?? fallbackSelectedBorder)
                : unselectedBorder,
            width: isSelected ? UiStrokeWidth.thick : UiStrokeWidth.standard,
          ),
        ),
        child: Center(
          child: Container(
            width: size * 0.7,
            height: 1.0,
            color: palette.semantic.danger,
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected
              ? (selectedBorderColor ?? fallbackSelectedBorder)
              : unselectedBorder,
          width: isSelected ? UiStrokeWidth.thick : UiStrokeWidth.subtle,
        ),
      ),
    );
  }
}

/// Pill-style button that opens a popup color picker menu.
class CentrodeColorPillButton<T> extends StatefulWidget {
  final String label;
  final T selectedValue;
  final List<CentrodeColorOption<T>> options;
  final ValueChanged<T> onSelected;
  final Color activeColor;
  final double height;

  const CentrodeColorPillButton({
    super.key,
    required this.label,
    required this.selectedValue,
    required this.options,
    required this.onSelected,
    required this.activeColor,
    this.height = UiControlSize.dense,
  });

  @override
  State<CentrodeColorPillButton<T>> createState() => _CentrodeColorPillButtonState<T>();
}

class _CentrodeColorPillButtonState<T> extends State<CentrodeColorPillButton<T>> {
  OverlayEntry? _menuEntry;

  void _openMenu(BuildContext btnContext) {
    _menuEntry?.remove();
    _menuEntry = null;

    final renderBox = btnContext.findRenderObject() as RenderBox;
    final rect = renderBox.localToGlobal(Offset.zero) & renderBox.size;

    final palette = CentrodeDerivedPalette.of(context);

    _menuEntry = CentrodeContextMenu.showAt(
      context: btnContext,
      targetRect: rect,
      positioningMode: MenuPositioningMode.below,
      items: widget.options.map((opt) {
        final isSel = opt.value == widget.selectedValue;
        final cardBg = palette.surface.cardBackground;
        final cardText = palette.textOn(cardBg);

        return ContextMenuItem(
          label: opt.label,
          onTap: () {
            _menuEntry?.remove();
            _menuEntry = null;
            widget.onSelected(opt.value);
          },
          builder: (context, isFocused) {
            return Container(
              height: widget.height,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                color: isFocused ? widget.activeColor.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(UiRadius.control),
              ),
              child: Row(
                children: [
                  CentrodeColorDot(
                    color: opt.color,
                    isNone: opt.isNone,
                    size: UiIconSize.dense,
                    isSelected: isSel,
                    selectedBorderColor: widget.activeColor,
                  ),
                  const SizedBox(width: UiSpacing.standard),
                  Expanded(
                    child: Text(
                      opt.label,
                      style: TextStyle(
                        fontSize: UiFont.compact,
                        fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                        color: isSel
                            ? widget.activeColor
                            : cardText.withValues(alpha: 0.85),
                      ),
                    ),
                  ),
                  if (isSel)
                    Icon(
                      Icons.check_rounded,
                      size: UiIconSize.dense,
                      color: widget.activeColor,
                    ),
                ],
              ),
            );
          },
        );
      }).toList(),
      onDismissed: () {
        _menuEntry = null;
      },
    );
  }

  @override
  void dispose() {
    _menuEntry?.remove();
    _menuEntry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = CentrodeDerivedPalette.of(context);
    final matchingOpt = widget.options.cast<CentrodeColorOption<T>?>().firstWhere(
      (opt) => opt?.value == widget.selectedValue,
      orElse: () => null,
    );
    final currentOpt = matchingOpt ??
        CentrodeColorOption<T>(
          value: widget.selectedValue,
          color: widget.selectedValue is Color ? widget.selectedValue as Color : null,
          label: widget.selectedValue is Color
              ? ColorTheoryEngine.toHex(widget.selectedValue as Color)
              : (widget.selectedValue?.toString() ?? 'None'),
          isNone: widget.selectedValue == null || widget.selectedValue == 'none',
        );

    return Tooltip(
      message: '${widget.label}: ${currentOpt.label}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _openMenu(context),
        child: Container(
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: UiSpacing.tight),
          decoration: BoxDecoration(
            color: palette.surface.controlBackground,
            borderRadius: BorderRadius.circular(UiRadius.control),
            border: Border.all(
              color: palette.surface.controlBorder,
              width: UiStrokeWidth.subtle,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CentrodeColorDot(
                color: currentOpt.color,
                isNone: currentOpt.isNone,
                size: UiIconSize.dense,
              ),
              const SizedBox(width: UiSpacing.tight),
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: UiFont.standard,
                    fontWeight: FontWeight.w500,
                    color: palette.surface.controlForeground.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
