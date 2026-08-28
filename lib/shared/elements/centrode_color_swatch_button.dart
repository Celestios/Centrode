import 'package:flutter/material.dart';
import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:centrode/shared/theme/theme_derived_palette.dart';
import 'package:centrode/shared/utils/color_theory_engine.dart';
import 'centrode_color_picker.dart';

/// Compact Swatch Button trigger that displays the active color preview
/// and opens the [CentrodeColorPicker] in a popover overlay when tapped.
class CentrodeColorSwatchButton extends StatelessWidget {
  /// The active color, or `null` / `Colors.transparent` for none.
  final Color? color;

  /// Optional label or tooltip.
  final String? tooltip;

  /// Callback invoked when a new color is selected.
  final ValueChanged<Color>? onColorChanged;

  /// Optional map-persisted custom swatches.
  final List<Color> mapColors;

  /// Optional recent colors list.
  final List<Color> recentColors;

  /// Size of the square swatch button.
  final double size;

  const CentrodeColorSwatchButton({
    super.key,
    required this.color,
    this.tooltip,
    this.onColorChanged,
    this.mapColors = const [],
    this.recentColors = const [],
    this.size = UiControlSize.standard,
  });

  @override
  Widget build(BuildContext context) {
    final palette = CentrodeDerivedPalette.of(context);
    final isNone = color == null || color == Colors.transparent;
    final hexString = color != null ? ColorTheoryEngine.toHex(color!) : 'None';

    return Tooltip(
      message: tooltip ?? hexString,
      child: InkWell(
        onTap: () => _openPanelPopover(context),
        borderRadius: BorderRadius.circular(UiRadius.control),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: isNone ? palette.surface.cardBackground : color,
            borderRadius: BorderRadius.circular(UiRadius.control),
            border: Border.all(
              color: palette.border(Colors.white, strong: true),
              width: UiStrokeWidth.standard,
            ),
          ),
          child: isNone
              ? Center(
                  child: Container(
                    width: size * 0.7,
                    height: 1.5,
                    color: palette.semantic.danger,
                    transform: Matrix4.rotationZ(-0.785398),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  void _openPanelPopover(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: UiAlpha.micro),
      builder: (dialogCtx) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: CentrodeColorPicker(
              initialColor: color ?? Colors.white,
              originalColor: color,
              mapColors: mapColors,
              recentColors: recentColors,
              onColorChanged: onColorChanged,
              onClose: () => Navigator.of(dialogCtx).pop(),
            ),
          ),
        );
      },
    );
  }
}
