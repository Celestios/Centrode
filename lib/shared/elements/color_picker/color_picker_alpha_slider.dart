import 'package:flutter/material.dart';
import 'package:centrode/shared/theme/design_tokens.dart';
import 'picker_color_model.dart';

/// Alpha slider (0–1). Horizontal drag sets the alpha. Rendered as a base-color
/// transparency gradient matching the original inline gradient.
class ColorPickerAlphaSlider extends StatelessWidget {
  final PickerColorModel model;
  final Color borderSubtle;

  const ColorPickerAlphaSlider({
    super.key,
    required this.model,
    required this.borderSubtle,
  });

  @override
  Widget build(BuildContext context) {
    final baseOpaque = model.hsvColor.toColor();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const height = 12.0;
        return GestureDetector(
          onPanDown: (d) => model.setAlpha(d.localPosition.dx / width),
          onPanUpdate: (d) => model.setAlpha(d.localPosition.dx / width),
          child: Container(
            height: height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(UiRadius.pill),
              border: Border.all(color: borderSubtle, width: UiStrokeWidth.subtle),
              gradient: LinearGradient(
                colors: [
                  baseOpaque.withValues(alpha: 0.0),
                  baseOpaque.withValues(alpha: 1.0),
                ],
              ),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: model.alpha * width - 6,
                  top: -2,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black26, width: 1),
                      boxShadow: const [
                        BoxShadow(color: Colors.black45, blurRadius: 2),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
