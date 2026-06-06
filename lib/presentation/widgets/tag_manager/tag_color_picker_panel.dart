import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:mycelium/shared/widgets/glass_panel/glass_panel.dart';

const List<int> presetColors = [
  0xFFEC407A, // Pink
  0xFFAB47BC, // Purple
  0xFF7E57C2, // Deep Purple
  0xFF5C6BC0, // Indigo
  0xFF42A5F5, // Blue
  0xFF26A69A, // Teal
  0xFF66BB6A, // Green
  0xFFD4E157, // Lime
  0xFFFFEE58, // Yellow
  0xFFFFB74D, // Orange
  0xFFFF7043, // Deep Orange
  0xFF8D6E63, // Brown
];

class TagColorPickerPanel extends StatefulWidget {
  final int initialColor;
  final ValueChanged<int> onColorSelected;

  const TagColorPickerPanel({
    super.key,
    required this.initialColor,
    required this.onColorSelected,
  });

  @override
  State<TagColorPickerPanel> createState() => _TagColorPickerPanelState();
}

class _TagColorPickerPanelState extends State<TagColorPickerPanel> {
  late int _selectedColor;
  late List<int> _shuffledColors;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    _generateShuffledColors();
  }

  void _generateShuffledColors() {
    final random = math.Random();
    _shuffledColors = List.generate(5, (_) {
      // Generate a nice vibrant pastel/modern color
      final r = 100 + random.nextInt(120);
      final g = 100 + random.nextInt(120);
      final b = 100 + random.nextInt(120);
      return 0xFF000000 | (r << 16) | (g << 8) | b;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassPanel(
      padding: const EdgeInsets.all(12),
      blur: 16.0,
      mode: GlassMode.performance,
      borderRadius: 16.0,
      width: 176,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'SELECT COLOR',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 12),

          // 12 Preset colors in radial layout
          SizedBox(
            width: 130,
            height: 130,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Center circle showing current selected color
                Positioned(
                  left: 65 - 16,
                  top: 65 - 16,
                  width: 32,
                  height: 32,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color(_selectedColor),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(_selectedColor).withValues(alpha: 0.4),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.local_offer,
                        size: 14,
                        color:
                            ThemeData.estimateBrightnessForColor(
                                  Color(_selectedColor),
                                ) ==
                                Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                ),

                // Radial colors (12 presets at 30 deg intervals, radius 48)
                ...List.generate(12, (index) {
                  final colorVal = presetColors[index];
                  final angle = index * 30.0 * math.pi / 180.0;
                  const radius = 48.0;

                  // Coordinate offset calculation
                  final x = 65.0 + radius * math.cos(angle) - 11.0;
                  final y = 65.0 + radius * math.sin(angle) - 11.0;
                  final isSelected = _selectedColor == colorVal;

                  return Positioned(
                    left: x,
                    top: y,
                    width: 22,
                    height: 22,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = colorVal;
                        });
                        widget.onColorSelected(colorVal);
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: Color(colorVal),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.white24,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check_rounded,
                                  size: 10,
                                  color:
                                      ThemeData.estimateBrightnessForColor(
                                            Color(colorVal),
                                          ) ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black87,
                                )
                              : null,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: theme.dividerColor.withValues(alpha: 0.15)),
          const SizedBox(height: 8),

          // Shuffle section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SHUFFLE',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _generateShuffledColors();
                  });
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Row of 5 shuffled colors
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _shuffledColors.map((colorVal) {
              final isSelected = _selectedColor == colorVal;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedColor = colorVal;
                  });
                  widget.onColorSelected(colorVal);
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: Color(colorVal),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : Colors.white24,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            size: 10,
                            color:
                                ThemeData.estimateBrightnessForColor(
                                      Color(colorVal),
                                    ) ==
                                    Brightness.dark
                                ? Colors.white
                                : Colors.black87,
                          )
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
