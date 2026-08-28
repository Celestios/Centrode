import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:flutter/material.dart';
import 'glass_color_pill_button.dart';

/// Compact inline swatch selector with glowing ring indicators.
class GlassColorPickerRow<T> extends StatelessWidget {
  final String label;
  final T selectedValue;
  final List<ColorPillOption<T>> options;
  final ValueChanged<T> onSelected;
  final Color activeColor;

  const GlassColorPickerRow({
    super.key,
    required this.label,
    required this.selectedValue,
    required this.options,
    required this.onSelected,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: UiInsets.verticalTight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 75,
            child: Text(
              label,
              style: TextStyle(
                fontSize: UiFont.compact,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: options.map((opt) {
                  final isSelected = opt.value == selectedValue;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: Tooltip(
                      message: opt.label,
                      child: GestureDetector(
                        onTap: () => onSelected(opt.value),
                        child: AnimatedContainer(
                          duration: UiMotion.fast,
                          width: 20,
                          height: UiControlSize.dense,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: opt.isNone ? Colors.transparent : (opt.color ?? Colors.white),
                            border: Border.all(
                              color: isSelected
                                  ? (opt.color ?? activeColor)
                                  : Colors.white.withValues(alpha: 0.18),
                              width: isSelected ? 2.0 : 0.8,
                            ),
                            boxShadow: isSelected && !opt.isNone && opt.color != null
                                ? [
                                    BoxShadow(
                                      color: opt.color!.withValues(alpha: 0.45),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                          child: opt.isNone
                              ? Center(
                                  child: Icon(
                                    Icons.block_rounded,
                                    size: 11,
                                    color: isSelected ? activeColor : Colors.white38,
                                  ),
                                )
                              : (isSelected
                                  ? Center(
                                      child: Container(
                                        width: 5,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: (opt.color?.computeLuminance() ?? 0.0) > 0.5
                                              ? Colors.black87
                                              : Colors.white,
                                        ),
                                      ),
                                    )
                                  : null),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
