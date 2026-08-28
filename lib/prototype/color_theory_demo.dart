import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'package:centrode/shared/elements/elements.dart';
import 'package:centrode/presentation/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const windowOptions = WindowOptions(
    size: Size(980, 960),
    center: true,
    backgroundColor: Color(0xFF101216),
    title: 'Centrode Color Theory Studio',
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const ColorTheoryStudioApp());
}

class ColorTheoryStudioApp extends StatefulWidget {
  const ColorTheoryStudioApp({super.key});

  @override
  State<ColorTheoryStudioApp> createState() => _ColorTheoryStudioAppState();
}

class _ColorTheoryStudioAppState extends State<ColorTheoryStudioApp> {
  Color _baseColor = const Color(0xFF6366F1); // Indigo
  ColorHarmonyType _selectedHarmony = ColorHarmonyType.analogous;
  PaletteMood _selectedMood = PaletteMood.auto;
  List<Color> _explorationPalette = [];
  List<bool> _lockedSlots = [false, false, false, false, false];
  double _alpha = 1.0;

  // Active theme simulation
  int _themeIndex = 0;
  final List<AppTheme> _sampleThemes = const [
    AppTheme(
      primaryColor: Color(0xFF6366F1), // Indigo
      secondaryColor: Color(0xFF4F46E5),
      accentColor: Color(0xFFEC4899), // Pink
      canvasAccentColor: Color(0xFF10B981), // Emerald
      scaffoldBackgroundColor: Color(0xFF0F172A),
      cardColor: Color(0xFF1E293B),
      dividerColor: Color(0xFF334155),
      textColor: Color(0xFFF8FAFC),
      fontFamily: 'Inter',
      bodyFontSize: 14.0,
      bodyFontWeight: FontWeight.w400,
      bodyTextColor: Color(0xFFF8FAFC),
      borderRadius: 8.0,
      appBarBackgroundColor: Color(0xFF0F172A),
      appBarForegroundColor: Color(0xFFF8FAFC),
      appBarElevation: 0.0,
      appBarTitleFontSize: 16.0,
      appBarTitleFontWeight: FontWeight.w600,
      useMaterial3: true,
      brightness: Brightness.dark,
    ),
    AppTheme(
      primaryColor: Color(0xFF0284C7), // Sky Blue
      secondaryColor: Color(0xFF0369A1),
      accentColor: Color(0xFFF59E0B), // Amber
      canvasAccentColor: Color(0xFF8B5CF6), // Purple
      scaffoldBackgroundColor: Color(0xFF18181B),
      cardColor: Color(0xFF27272A),
      dividerColor: Color(0xFF3F3F46),
      textColor: Color(0xFFFAFAFA),
      fontFamily: 'Inter',
      bodyFontSize: 14.0,
      bodyFontWeight: FontWeight.w400,
      bodyTextColor: Color(0xFFFAFAFA),
      borderRadius: 8.0,
      appBarBackgroundColor: Color(0xFF18181B),
      appBarForegroundColor: Color(0xFFFAFAFA),
      appBarElevation: 0.0,
      appBarTitleFontSize: 16.0,
      appBarTitleFontWeight: FontWeight.w600,
      useMaterial3: true,
      brightness: Brightness.dark,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _generateExplorationPalette();
  }

  void _shuffleColor() {
    setState(() {
      _baseColor = ColorTheoryEngine.generateHarmonicRandomColor();
      _generateExplorationPalette();
    });
  }

  void _generateExplorationPalette() {
    setState(() {
      _explorationPalette = ColorTheoryEngine.generateThemedExplorationPalette(
        primaryAnchor: _lockedSlots.contains(true) ? null : _baseColor,
        existingPalette: _explorationPalette.isEmpty ? null : _explorationPalette,
        lockedSlots: _lockedSlots,
        mood: _selectedMood,
        count: 5,
      );
      if (!_lockedSlots.contains(true) && _explorationPalette.isNotEmpty) {
        _baseColor = _explorationPalette[2]; // Focus center accent
      }
    });
  }

  void _toggleLock(int index) {
    setState(() {
      _lockedSlots[index] = !_lockedSlots[index];
    });
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = _sampleThemes[_themeIndex];
    final derivedPalette = CentrodeDerivedPalette.fromTheme(activeTheme);
    final harmonyColors = ColorTheoryEngine.generateHarmony(_baseColor, _selectedHarmony);
    final hsv = HSVColor.fromColor(_baseColor);

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.space): _generateExplorationPalette,
      },
      child: Focus(
        autofocus: true,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF101216),
            fontFamily: 'Inter',
          ),
          home: Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  // --- Custom Title Bar ---
                  CentrodeWindowTitleBar(
                    title: 'COLOR THEORY STUDIO',
                    actions: [
                      DropdownButton<int>(
                        value: _themeIndex,
                        dropdownColor: const Color(0xFF1E222B),
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: 0, child: Text('Theme: Obsidian Indigo', style: TextStyle(fontSize: UiFont.compact))),
                          DropdownMenuItem(value: 1, child: Text('Theme: Midnight Sky', style: TextStyle(fontSize: UiFont.compact))),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _themeIndex = val;
                              _generateExplorationPalette();
                            });
                          }
                        },
                      ),
                      const SizedBox(width: UiSpacing.standard),
                      CentrodeButton(
                        onTap: _shuffleColor,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: activeTheme.primaryColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(UiRadius.control),
                            border: Border.all(color: activeTheme.primaryColor.withValues(alpha: 0.4)),
                          ),
                          child: const Text('🎲 Shuffle Color', style: TextStyle(fontSize: UiFont.compact, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),

                  // --- Main Scrollable Studio Content ---
                  Expanded(
                    child: SingleChildScrollView(
                      padding: UiInsets.container,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Live Canonical Elements Showcase
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 1. Opaque Color Control Box
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '1. OPAQUE COLOR CONTROL BOX (CentrodeColorPicker)',
                                    style: TextStyle(
                                      fontSize: UiFont.compact,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF818CF8),
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                  const SizedBox(height: UiSpacing.tight),
                                  CentrodeColorPicker(
                                    initialColor: _baseColor,
                                    originalColor: const Color(0xFF475569),
                                    mapColors: const [
                                      Color(0xFF38BDF8),
                                      Color(0xFFA855F7),
                                      Color(0xFF22C55E),
                                      Color(0xFFE11D48),
                                    ],
                                    onColorChanged: (newCol) {
                                      setState(() => _baseColor = newCol);
                                    },
                                  ),
                                ],
                              ),

                              const SizedBox(width: UiSpacing.gutter),

                              // 2. Interlocking Puzzle Generative Palette Explorer
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      '2. GENERATIVE PALETTE EXPLORER (CentrodePaletteGenerator)',
                                      style: TextStyle(
                                        fontSize: UiFont.compact,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF818CF8),
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                    const SizedBox(height: UiSpacing.tight),
                                    CentrodePaletteGenerator(
                                      primaryAnchor: _baseColor,
                                      onColorSelected: (c) {
                                        setState(() => _baseColor = c);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: UiSpacing.gutter),

                          // 1. Master Active Color Header Box
                          _buildActiveColorCard(hsv),

                          const SizedBox(height: UiSpacing.gutter),

                          // 2. Generative Palette Exploration (Coolors Spacebar Experience + Locking)
                          _buildGenerativeExplorationSection(),

                          const SizedBox(height: UiSpacing.gutter),

                          // 3. Theme-Derived Deterministic Canonical Swatches
                          _buildThemeSwatchesSection(derivedPalette),

                          const SizedBox(height: UiSpacing.gutter),

                          // 4. Live Color Theory Harmonies
                          _buildHarmonySection(harmonyColors),

                          const SizedBox(height: UiSpacing.gutter),

                          // 5. Precision HSV & Alpha Controls
                          _buildPrecisionControls(hsv),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveColorCard(HSVColor hsv) {
    final hex = ColorTheoryEngine.toHex(_baseColor, includeAlpha: _alpha < 1.0);
    final lum = ColorTheoryEngine.relativeLuminance(_baseColor);
    final textColor = ColorTheoryEngine.bestContrastingTextColor(_baseColor);

    return Container(
      padding: UiInsets.container,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D24),
        borderRadius: BorderRadius.circular(UiRadius.panel),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: UiStrokeWidth.standard),
      ),
      child: Row(
        children: [
          // Large Swatch Box
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: _baseColor.withValues(alpha: _alpha),
              borderRadius: BorderRadius.circular(UiRadius.card),
              border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: UiStrokeWidth.thick),
              boxShadow: [
                BoxShadow(
                  color: _baseColor.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                'L: ${(lum * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: UiFont.compact,
                ),
              ),
            ),
          ),
          const SizedBox(width: UiSpacing.container),

          // Metadata & Quick Actions
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      hex,
                      style: const TextStyle(
                        fontSize: UiFont.title + 4,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(width: UiSpacing.standard),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(UiRadius.control),
                      ),
                      child: Text(
                        'Hue: ${hsv.hue.toStringAsFixed(0)}°',
                        style: const TextStyle(fontSize: UiFont.compact, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: UiSpacing.tight),
                Text(
                  'Saturation: ${(hsv.saturation * 100).toStringAsFixed(0)}%  •  Brightness: ${(hsv.value * 100).toStringAsFixed(0)}%  •  Alpha: ${(_alpha * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: UiFont.standard,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGenerativeExplorationSection() {
    return Container(
      padding: UiInsets.container,
      decoration: BoxDecoration(
        color: const Color(0xFF16181E),
        borderRadius: BorderRadius.circular(UiRadius.card),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'GENERATIVE PALETTE EXPLORATION (SPACEBAR)',
                style: TextStyle(
                  fontSize: UiFont.compact,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Colors.white54,
                ),
              ),
              Row(
                children: [
                  DropdownButton<PaletteMood>(
                    value: _selectedMood,
                    dropdownColor: const Color(0xFF1E222B),
                    underline: const SizedBox(),
                    items: PaletteMood.values.map((mood) {
                      return DropdownMenuItem(
                        value: mood,
                        child: Text(
                          'Mood: ${mood.name.toUpperCase()}',
                          style: const TextStyle(fontSize: UiFont.compact, fontWeight: FontWeight.w600),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedMood = val;
                          _generateExplorationPalette();
                        });
                      }
                    },
                  ),
                  const SizedBox(width: UiSpacing.standard),
                  ElevatedButton.icon(
                    onPressed: _generateExplorationPalette,
                    icon: const Icon(Icons.auto_awesome_rounded, size: UiIconSize.dense),
                    label: const Text('Generate Palette (Spacebar)'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.1),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: UiSpacing.standard),
          Row(
            children: List.generate(_explorationPalette.length, (i) {
              final color = _explorationPalette[i];
              final isLocked = _lockedSlots[i];
              final hex = ColorTheoryEngine.toHex(color);
              final textColor = ColorTheoryEngine.bestContrastingTextColor(color);

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _baseColor = color),
                  child: Container(
                    height: 110,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(UiRadius.control),
                      border: Border.all(
                        color: isLocked ? Colors.white : Colors.white.withValues(alpha: 0.15),
                        width: isLocked ? UiStrokeWidth.thick : UiStrokeWidth.standard,
                      ),
                      boxShadow: [
                        BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            hex,
                            style: TextStyle(
                              color: textColor,
                              fontSize: UiFont.compact,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            iconSize: UiIconSize.dense,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                            icon: Icon(
                              isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                              color: textColor.withValues(alpha: isLocked ? 1.0 : 0.6),
                            ),
                            tooltip: isLocked ? 'Unlock Color' : 'Lock Color',
                            onPressed: () => _toggleLock(i),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSwatchesSection(CentrodeDerivedPalette palette) {
    return Container(
      padding: UiInsets.container,
      decoration: BoxDecoration(
        color: const Color(0xFF16181E),
        borderRadius: BorderRadius.circular(UiRadius.card),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'THEME-DERIVED CANONICAL SWATCHES (12)',
            style: TextStyle(
              fontSize: UiFont.compact,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: UiSpacing.standard),
          Wrap(
            spacing: UiSpacing.standard,
            runSpacing: UiSpacing.standard,
            children: palette.swatches.map((color) {
              final isSelected = color.value == _baseColor.value;
              return GestureDetector(
                onTap: () => setState(() {
                  _baseColor = color;
                  _generateExplorationPalette();
                }),
                child: AnimatedContainer(
                  duration: UiMotion.fast,
                  width: 52,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(UiRadius.control),
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: isSelected ? UiStrokeWidth.thick : UiStrokeWidth.standard,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 10)]
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

  Widget _buildHarmonySection(List<Color> harmonyColors) {
    return Container(
      padding: UiInsets.container,
      decoration: BoxDecoration(
        color: const Color(0xFF16181E),
        borderRadius: BorderRadius.circular(UiRadius.card),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'COLOR THEORY HARMONIES (OKLCH)',
                style: TextStyle(
                  fontSize: UiFont.compact,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: Colors.white54,
                ),
              ),
              DropdownButton<ColorHarmonyType>(
                value: _selectedHarmony,
                dropdownColor: const Color(0xFF1E222B),
                underline: const SizedBox(),
                items: ColorHarmonyType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(
                      type.name.toUpperCase(),
                      style: const TextStyle(fontSize: UiFont.compact, fontWeight: FontWeight.w600),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedHarmony = val);
                },
              ),
            ],
          ),
          const SizedBox(height: UiSpacing.standard),
          Row(
            children: harmonyColors.map((color) {
              final hex = ColorTheoryEngine.toHex(color);
              final textColor = ColorTheoryEngine.bestContrastingTextColor(color);
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _baseColor = color;
                    _generateExplorationPalette();
                  }),
                  child: Container(
                    height: 80,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(UiRadius.control),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          hex,
                          style: TextStyle(
                            color: textColor,
                            fontSize: UiFont.micro,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPrecisionControls(HSVColor hsv) {
    return Container(
      padding: UiInsets.container,
      decoration: BoxDecoration(
        color: const Color(0xFF16181E),
        borderRadius: BorderRadius.circular(UiRadius.card),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PRECISION TUNING SLIDERS',
            style: TextStyle(
              fontSize: UiFont.compact,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
              color: Colors.white54,
            ),
          ),
          const SizedBox(height: UiSpacing.standard),

          // Hue Slider
          _buildSliderRow(
            label: 'Hue',
            valueText: '${hsv.hue.toStringAsFixed(0)}°',
            value: hsv.hue,
            min: 0.0,
            max: 360.0,
            onChanged: (val) => setState(() {
              _baseColor = hsv.withHue(val).toColor();
              _generateExplorationPalette();
            }),
          ),

          // Saturation Slider
          _buildSliderRow(
            label: 'Saturation',
            valueText: '${(hsv.saturation * 100).toStringAsFixed(0)}%',
            value: hsv.saturation,
            min: 0.0,
            max: 1.0,
            onChanged: (val) => setState(() {
              _baseColor = hsv.withSaturation(val).toColor();
              _generateExplorationPalette();
            }),
          ),

          // Brightness Slider
          _buildSliderRow(
            label: 'Brightness',
            valueText: '${(hsv.value * 100).toStringAsFixed(0)}%',
            value: hsv.value,
            min: 0.0,
            max: 1.0,
            onChanged: (val) => setState(() {
              _baseColor = hsv.withValue(val).toColor();
              _generateExplorationPalette();
            }),
          ),

          // Alpha Slider
          _buildSliderRow(
            label: 'Alpha',
            valueText: '${(_alpha * 100).toStringAsFixed(0)}%',
            value: _alpha,
            min: 0.0,
            max: 1.0,
            onChanged: (val) => setState(() => _alpha = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderRow({
    required String label,
    required String valueText,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label, style: const TextStyle(fontSize: UiFont.standard)),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                activeTrackColor: _baseColor,
                inactiveTrackColor: Colors.white10,
                thumbColor: Colors.white,
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: value.clamp(min, max),
                min: min,
                max: max,
                onChanged: onChanged,
              ),
            ),
          ),
          SizedBox(
            width: 50,
            child: Text(
              valueText,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: UiFont.compact, color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }
}
