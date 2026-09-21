import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../theme/theme_derived_palette.dart';
import '../widgets/context_menu_overlay.dart';

class CentrodeDropdownItem<T> {
  final T value;
  final String label;
  final String? subtitle;
  final TextStyle? previewStyle;

  const CentrodeDropdownItem({
    required this.value,
    required this.label,
    this.subtitle,
    this.previewStyle,
  });
}

class CentrodeGlassDropdown<T> extends StatefulWidget {
  final String label;
  final T selectedValue;
  final List<CentrodeDropdownItem<T>> items;
  final ValueChanged<T> onSelected;
  final Color activeColor;
  final double height;
  final double labelWidth;

  const CentrodeGlassDropdown({
    super.key,
    this.label = '',
    required this.selectedValue,
    required this.items,
    required this.onSelected,
    required this.activeColor,
    this.height = UiControlSize.standard,
    this.labelWidth = 75.0,
  });

  @override
  State<CentrodeGlassDropdown<T>> createState() => _CentrodeGlassDropdownState<T>();
}

class _CentrodeGlassDropdownState<T> extends State<CentrodeGlassDropdown<T>> {
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
      menuWidth: rect.width,
      items: widget.items.map((item) {
        final isSel = item.value == widget.selectedValue;
        final itemColor = isSel
            ? widget.activeColor
            : palette.textOn(palette.surface.cardBackground).withValues(alpha: 0.85);

        return ContextMenuItem(
          label: item.label,
          onTap: () {
            _menuEntry?.remove();
            _menuEntry = null;
            widget.onSelected(item.value);
          },
          builder: (context, isFocused) {
            final text = item.previewStyle != null
                ? DefaultTextStyle(
                    style: item.previewStyle!.copyWith(color: itemColor),
                    child: Text(item.label),
                  )
                : Text(
                    item.label,
                    style: TextStyle(
                      fontSize: UiFont.compact,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: itemColor,
                    ),
                  );

            return Container(
              height: UiControlSize.standard,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              decoration: BoxDecoration(
                color: isFocused ? widget.activeColor.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(UiRadius.control),
              ),
              child: Row(
                children: [
                  Expanded(child: text),
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

    final dropdownBox = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openMenu(context),
      child: Container(
        height: widget.height,
        padding: const EdgeInsets.symmetric(horizontal: UiSpacing.standard),
        decoration: BoxDecoration(
          color: palette.surface.controlBackground,
          borderRadius: BorderRadius.circular(UiRadius.control),
          border: Border.all(
            color: palette.surface.controlBorder,
            width: UiStrokeWidth.subtle,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.items
                    .where((i) => i.value == widget.selectedValue)
                    .map((i) => i.label)
                    .firstOrNull ??
                    '',
                style: TextStyle(
                  fontSize: UiFont.micro,
                  fontWeight: FontWeight.w600,
                  color: palette.surface.controlForeground,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: UiIconSize.dense,
              color: palette.surface.controlForeground.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );

    if (widget.label.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2.0),
        child: dropdownBox,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          SizedBox(
            width: widget.labelWidth,
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: UiFont.micro,
                fontWeight: FontWeight.w500,
                color: palette.surface.controlForeground
                    .withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(child: dropdownBox),
        ],
      ),
    );
  }
}
