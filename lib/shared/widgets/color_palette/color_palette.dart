import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'color_harmony_generator.dart';
import 'package:mycelium/shared/widgets/glass_panel/glass_panel.dart';
import 'package:mycelium/shared/utils/color_utils.dart';

enum ColorPaletteMode {
  compactPresets,
  radial,
  advanced,
}

class UniversalColorPalette extends StatefulWidget {
  final Color initialColor;
  final ValueChanged<Color> onColorSelected;
  final ColorPaletteMode mode;
  final bool showAlpha;
  final List<Color>? customPresets;

  const UniversalColorPalette({
    super.key,
    required this.initialColor,
    required this.onColorSelected,
    this.mode = ColorPaletteMode.advanced,
    this.showAlpha = true,
    this.customPresets,
  });

  @override
  State<UniversalColorPalette> createState() => _UniversalColorPaletteState();
}

class _UniversalColorPaletteState extends State<UniversalColorPalette> {
  late Color _selectedColor;
  late HSVColor _currentHsv;
  ColorHarmonyType _selectedHarmonyType = ColorHarmonyType.analogous;
  List<Color> _shuffledColors = [];

  // Core aesthetic default presets
  static const List<Color> defaultPresets = [
    Color(0xFF818CF8), // Indigo
    Color(0xFF34D399), // Mint/Green
    Color(0xFFFBBF24), // Amber
    Color(0xFFC084FC), // Lavender
    Color(0xFFF472B6), // Rose
    Color(0xFFFB923C), // Orange
    Color(0xFF94A3B8), // Slate
    Color(0xFFE2E8F0), // Off-White
    Color(0xFFEC407A), // Pink
    Color(0xFF7E57C2), // Deep Purple
    Color(0xFF42A5F5), // Blue
    Color(0xFF26A69A), // Teal
  ];

  List<Color> get _presets => widget.customPresets ?? defaultPresets;

  @override
  void initState() {
    super.initState();
    _selectedColor = widget.initialColor;
    _currentHsv = HSVColor.fromColor(widget.initialColor);
    _generateShuffledColors();
  }

  @override
  void didUpdateWidget(covariant UniversalColorPalette oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialColor != widget.initialColor) {
      _selectedColor = widget.initialColor;
      _currentHsv = HSVColor.fromColor(widget.initialColor);
    }
  }

  void _generateShuffledColors() {
    final random = math.Random();
    _shuffledColors = List.generate(6, (_) {
      final hue = random.nextDouble() * 360.0;
      final saturation = 0.5 + random.nextDouble() * 0.4; // vibrant
      final value = 0.7 + random.nextDouble() * 0.2; // bright
      return HSVColor.fromAHSV(1.0, hue, saturation, value).toColor();
    });
  }

  void _updateColor(Color newColor) {
    setState(() {
      _selectedColor = newColor;
      _currentHsv = HSVColor.fromColor(newColor);
    });
    widget.onColorSelected(newColor);
  }

  void _updateHsv(HSVColor newHsv) {
    final newColor = newHsv.toColor();
    setState(() {
      _currentHsv = newHsv;
      _selectedColor = newColor;
    });
    widget.onColorSelected(newColor);
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.mode) {
      case ColorPaletteMode.compactPresets:
        return _buildCompactPresets(context);
      case ColorPaletteMode.radial:
        return _buildRadial(context);
      case ColorPaletteMode.advanced:
        return _buildAdvanced(context);
    }
  }

  // ─── 1. COMPACT PRESETS MODE ───
  Widget _buildCompactPresets(BuildContext context) {
    final theme = Theme.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _presets.map((c) {
        final isActive = _selectedColor.toARGB32() == c.toARGB32();
        return GestureDetector(
          onTap: () => _updateColor(c),
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c,
                border: Border.all(
                  color: isActive ? theme.colorScheme.primary : Colors.white24,
                  width: isActive ? 2.5 : 1,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: c.withValues(alpha: 0.4),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : [],
              ),
              child: isActive
                  ? Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: ColorUtils.getContrastTextColor(c),
                    )
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─── 2. RADIAL MODE ───
  Widget _buildRadial(BuildContext context) {
    final theme = Theme.of(context);
    final displayedPresets = _presets.take(12).toList();

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
                      color: _selectedColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _selectedColor.withValues(alpha: 0.4),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        Icons.palette_rounded,
                        size: 14,
                        color: ColorUtils.getContrastTextColor(_selectedColor),
                      ),
                    ),
                  ),
                ),
                // Radial colors
                ...List.generate(displayedPresets.length, (index) {
                  final c = displayedPresets[index];
                  final angle = index * (360.0 / displayedPresets.length) * math.pi / 180.0;
                  const radius = 48.0;
                  final x = 65.0 + radius * math.cos(angle) - 11.0;
                  final y = 65.0 + radius * math.sin(angle) - 11.0;
                  final isSelected = _selectedColor.toARGB32() == c.toARGB32();

                  return Positioned(
                    left: x,
                    top: y,
                    width: 22,
                    height: 22,
                    child: GestureDetector(
                      onTap: () => _updateColor(c),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            color: c,
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
                                  color: ColorUtils.getContrastTextColor(c),
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
                onTap: () => setState(_generateShuffledColors),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _shuffledColors.take(5).map((c) {
              final isSelected = _selectedColor.toARGB32() == c.toARGB32();
              return GestureDetector(
                onTap: () => _updateColor(c),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : Colors.white24,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check_rounded,
                            size: 10,
                            color: ColorUtils.getContrastTextColor(c),
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

  // ─── 3. ADVANCED MODE (Presets, Harmonizer, Sliders, Opacity, Shuffle) ───
  Widget _buildAdvanced(BuildContext context) {
    final theme = Theme.of(context);
    final baseColorNoAlpha = _selectedColor.withValues(alpha: 1.0);
    final harmonyColors = ColorHarmonyGenerator.generateHarmony(baseColorNoAlpha, _selectedHarmonyType);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Presets Swatch Section
        Text(
          'PRESETS',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 10,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 6),
        _buildCompactPresets(context),
        const SizedBox(height: 14),

        // Color Theory Harmony picker
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'HARMONIES',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            DropdownButton<ColorHarmonyType>(
              value: _selectedHarmonyType,
              dropdownColor: theme.cardColor,
              underline: const SizedBox(),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
              icon: Icon(Icons.arrow_drop_down, size: 14, color: theme.colorScheme.primary),
              items: ColorHarmonyType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.name.toUpperCase()),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedHarmonyType = val);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 6),
        
        // Harmony Swatch Display
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: harmonyColors.map((c) {
            final targetColor = c.withValues(alpha: _selectedColor.a);
            final isActive = _selectedColor.toARGB32() == targetColor.toARGB32();
            return GestureDetector(
              onTap: () => _updateColor(targetColor),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c,
                    border: Border.all(
                      color: isActive ? theme.colorScheme.primary : Colors.white24,
                      width: isActive ? 2.5 : 1,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: c.withValues(alpha: 0.4),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : [],
                  ),
                  child: isActive
                      ? Icon(
                          Icons.check_rounded,
                          size: 12,
                          color: ColorUtils.getContrastTextColor(c),
                        )
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 14),

        // Sliders (Hue)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'HUE',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            Text(
              '${_currentHsv.hue.toInt()}°',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6,
            activeTrackColor: Colors.transparent,
            inactiveTrackColor: Colors.transparent,
            thumbColor: Colors.white,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7, elevation: 2),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            height: 12,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFFF0000),
                  Color(0xFFFFFF00),
                  Color(0xFF00FF00),
                  Color(0xFF00FFFF),
                  Color(0xFF0000FF),
                  Color(0xFFFF00FF),
                  Color(0xFFFF0000),
                ],
              ),
            ),
            child: Slider(
              value: _currentHsv.hue,
              min: 0.0,
              max: 360.0,
              onChanged: (val) {
                _updateHsv(_currentHsv.withHue(val));
              },
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Sliders (Opacity / Alpha)
        if (widget.showAlpha) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'TRANSPARENCY',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              Text(
                '${(_selectedColor.a * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              activeTrackColor: Colors.transparent,
              inactiveTrackColor: Colors.transparent,
              thumbColor: Colors.white,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7, elevation: 2),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              height: 12,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  colors: [
                    _selectedColor.withValues(alpha: 0.0),
                    _selectedColor.withValues(alpha: 1.0),
                  ],
                ),
              ),
              child: Slider(
                value: _selectedColor.a,
                min: 0.0,
                max: 1.0,
                onChanged: (val) {
                  _updateColor(_selectedColor.withValues(alpha: val));
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],

        // Shuffle Section
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'QUICK SHUFFLE',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(_generateShuffledColors);
              },
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: Row(
                  children: [
                    Text(
                      'SHUFFLE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.shuffle_rounded,
                      size: 12,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: _shuffledColors.map((c) {
            final targetColor = c.withValues(alpha: _selectedColor.a);
            final isSelected = _selectedColor.toARGB32() == targetColor.toARGB32();
            return GestureDetector(
              onTap: () => _updateColor(targetColor),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? theme.colorScheme.primary : Colors.white24,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          size: 10,
                          color: ColorUtils.getContrastTextColor(c),
                        )
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
