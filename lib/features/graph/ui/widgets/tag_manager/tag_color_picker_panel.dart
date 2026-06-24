import 'package:flutter/material.dart';
import 'package:mycelium/shared/widgets/color_palette/color_palette.dart';

class TagColorPickerPanel extends StatelessWidget {
  final int initialColor;
  final ValueChanged<int> onColorSelected;

  const TagColorPickerPanel({
    super.key,
    required this.initialColor,
    required this.onColorSelected,
  });

  @override
  Widget build(BuildContext context) {
    return UniversalColorPalette(
      initialColor: Color(initialColor),
      mode: ColorPaletteMode.radial,
      showAlpha: false,
      onColorSelected: (color) {
        onColorSelected(color.toARGB32());
      },
    );
  }
}

