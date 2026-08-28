import 'package:flutter/material.dart';
import 'package:centrode/shared/theme/design_tokens.dart';
import 'picker_color_model.dart';

/// Swatch palette grid (merged theme + map colors) plus the anonymous
/// moving auto-recents row (last 6 used colors).
class ColorPickerSwatchGrid extends StatelessWidget {
  final PickerColorModel model;
  final List<Color> swatches;
  final Color borderSubtle;

  const ColorPickerSwatchGrid({
    super.key,
    required this.model,
    required this.swatches,
    required this.borderSubtle,
  });

  @override
  Widget build(BuildContext context) {
    final current = model.currentColor;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SWATCHES',
          style: TextStyle(
            fontSize: UiFont.micro,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: Colors.white54,
          ),
        ),
        const SizedBox(height: UiSpacing.tight),

        // Main Swatches Grid (merged theme + active map colors)
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            mainAxisSpacing: UiSpacing.tight,
            crossAxisSpacing: UiSpacing.tight,
            childAspectRatio: 1.5,
          ),
          itemCount: swatches.length,
          itemBuilder: (context, index) {
            final swatch = swatches[index];
            final isSelected = swatch.toARGB32() == current.toARGB32();
            return GestureDetector(
              onTap: () => model.commitColor(swatch, pushRecent: true),
              child: Container(
                decoration: BoxDecoration(
                  color: swatch,
                  borderRadius: BorderRadius.circular(UiRadius.control),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.white24,
                    width: isSelected ? 2.0 : UiStrokeWidth.subtle,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(color: swatch.withValues(alpha: 0.5), blurRadius: 6)]
                      : null,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Container(height: 1, color: borderSubtle),
        const SizedBox(height: 6),

        // Anonymous Moving Recents Row (Last 6 used colors)
        Row(
          children: List.generate(6, (index) {
            final hasRecent = index < model.recents.length;
            final recentColor = hasRecent ? model.recents[index] : null;
            return Expanded(
              child: Container(
                height: 20,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                child: recentColor != null
                    ? GestureDetector(
                        onTap: () => model.commitColor(recentColor, pushRecent: true),
                        child: Container(
                          decoration: BoxDecoration(
                            color: recentColor,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.white24,
                              width: UiStrokeWidth.subtle,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.white10,
                            width: UiStrokeWidth.subtle,
                          ),
                        ),
                      ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
