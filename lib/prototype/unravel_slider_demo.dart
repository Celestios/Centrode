import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import '../shared/widgets/unravel_slider/unravel_slider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();
  const windowOptions = WindowOptions(
    size: Size(720, 920),
    center: true,
    backgroundColor: Color(0xFF131519),
  );
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  runApp(const UnravelSliderDemoApp());
}

const _optionPool = <UnravelOption>[
  (icon: Icons.near_me_rounded, label: 'Select'),
  (icon: Icons.crop_square_rounded, label: 'Frame'),
  (icon: Icons.draw_rounded, label: 'Draw'),
  (icon: Icons.circle_outlined, label: 'Circle'),
  (icon: Icons.polyline_rounded, label: 'Diagonal'),
  (icon: Icons.auto_fix_high_rounded, label: 'Optimize'),
  (icon: Icons.hub_rounded, label: 'Connect'),
  (icon: Icons.text_fields_rounded, label: 'Text'),
  (icon: Icons.image_rounded, label: 'Image'),
  (icon: Icons.brush_rounded, label: 'Brush'),
  (icon: Icons.palette_rounded, label: 'Color'),
  (icon: Icons.layers_rounded, label: 'Layer'),
  (icon: Icons.grid_view_rounded, label: 'Grid'),
  (icon: Icons.push_pin_rounded, label: 'Pin'),
  (icon: Icons.auto_awesome_rounded, label: 'Magic'),
  (icon: Icons.delete_outline_rounded, label: 'Delete'),
];

class UnravelSliderDemoApp extends StatelessWidget {
  const UnravelSliderDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF26C6AA),
      ),
      home: const Scaffold(
        backgroundColor: Color(0xFF131519),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: UnravelSliderLab(),
            ),
          ),
        ),
      ),
    );
  }
}

class UnravelSliderLab extends StatefulWidget {
  const UnravelSliderLab({super.key});

  @override
  State<UnravelSliderLab> createState() => _UnravelSliderLabState();
}

class _UnravelSliderLabState extends State<UnravelSliderLab> {
  int _itemCount = 6;
  int _selectedIndex = 0;
  double _trackWidth = 230;
  bool _magnetic = false;
  double _cellScale = 1.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.white;
    final options = _optionPool.take(_itemCount).toList();

    final customTheme = UnravelSliderThemeData(
      cellWidth: 82.8 * _cellScale,
      cellHeight: 55.2 * _cellScale,
      iconSize: 25.3 * _cellScale,
      labelFontSize: 12.6 * _cellScale,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SIGMOID UNRAVEL SLIDER',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
              color: scheme.primary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: UnravelSlider<UnravelOption>(
              items: options,
              selectedIndex: _selectedIndex,
              trackWidth: _trackWidth,
              magnetic: _magnetic,
              autofocus: true,
              theme: customTheme,
              onSelected: (idx) => setState(() => _selectedIndex = idx),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                options[_selectedIndex.clamp(0, options.length - 1)].icon,
                size: 18,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                options[_selectedIndex.clamp(0, options.length - 1)].label.toUpperCase(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const Spacer(),
              Text(
                'Selected Index: $_selectedIndex',
                style: TextStyle(
                  fontSize: 12,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: textColor.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'HANDLE MODE',
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 12),
              _modeChip('FREE', !_magnetic, theme, () {
                setState(() => _magnetic = false);
              }),
              const SizedBox(width: 6),
              _modeChip('MAGNETIC', _magnetic, theme, () {
                setState(() => _magnetic = true);
              }),
            ],
          ),
          const SizedBox(height: 14),
          _knob(
            label: 'ITEM COUNT',
            value: _itemCount.toDouble(),
            min: 2,
            max: _optionPool.length.toDouble(),
            divisions: _optionPool.length - 2,
            display: '$_itemCount',
            onChanged: (v) => setState(() {
              _itemCount = v.round();
              if (_selectedIndex >= _itemCount) {
                _selectedIndex = _itemCount - 1;
              }
            }),
            theme: theme,
          ),
          _knob(
            label: 'TRACK WIDTH',
            value: _trackWidth,
            min: 140,
            max: 560,
            divisions: 42,
            display: '${_trackWidth.round()}px',
            onChanged: (v) => setState(() => _trackWidth = v),
            theme: theme,
          ),
          _knob(
            label: 'ELEMENT SCALE',
            value: _cellScale,
            min: 0.6,
            max: 1.6,
            divisions: 20,
            display: 'x${_cellScale.toStringAsFixed(2)}',
            onChanged: (v) => setState(() => _cellScale = v),
            theme: theme,
          ),
        ],
      ),
    );
  }

  Widget _modeChip(
    String label,
    bool active,
    ThemeData theme,
    VoidCallback onTap,
  ) {
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? scheme.primary.withValues(alpha: 0.22)
              : Colors.black.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? scheme.primary.withValues(alpha: 0.65)
                : Colors.white.withValues(alpha: 0.08),
            width: 1.1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.bold : FontWeight.w500,
            color: active
                ? scheme.primary
                : scheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _knob({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String display,
    required ValueChanged<double> onChanged,
    required ThemeData theme,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 112,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ),
        Expanded(
          child: SliderTheme(
            data: const SliderThemeData(
              trackHeight: 3,
              overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions > 0 ? divisions : null,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 64,
          child: Text(
            display,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11.5,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      ],
    );
  }
}

