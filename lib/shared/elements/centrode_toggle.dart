import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

class CentrodeToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? activeColor;
  final double width;
  final double height;

  const CentrodeToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.activeColor,
    this.width = 54.0,
    this.height = 26.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveColor = activeColor ?? theme.colorScheme.primary;

    return LiquidGlassSwitch(
      value: value,
      onChanged: onChanged,
      activeColor: effectiveColor,
      width: width,
      height: height,
    );
  }
}
