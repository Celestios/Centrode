import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

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

typedef _UnravelOption = ({IconData icon, String label});

const _optionPool = <_UnravelOption>[
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

class _UnravelSliderLabState extends State<UnravelSliderLab>
    with SingleTickerProviderStateMixin {
  static const _baseCellWidth = 72.0;
  static const _baseCellHeight = 48.0;
  static const _tapSlack = 8.0;

  late final AnimationController _settle;
  double _settleFrom = 0;
  double _settleTo = 0;

  // Primary variant inputs
  int _itemCount = 6;
  double _trackWidth = 230;

  // Modes & overrides
  bool _magnetic = false;
  bool _autoDerive = true;

  // Manual overrides (used when _autoDerive is false)
  double _manualSigma = 140;
  double _manualHandleTravel = 140;
  double _manualValueMax = 640;
  double _manualCellScale = 1.15;

  // State
  double _u = 0;
  double _rawU = 0;
  int? _activePointer;
  Offset? _downPos;
  List<double> _itemXs = const [];

  // Mathematical Derivations based on (trackWidth, itemCount)
  // Margin ensures fixed 15.2px clearance between handle and track edge
  double get _margin => (_handleBoxWidth / 2.0) + 15.2;
  double get _handleTravel => _autoDerive
      ? (_trackWidth - 2.0 * _margin).clamp(40.0, double.infinity)
      : _manualHandleTravel;
  double get _sigma => _autoDerive ? _handleTravel : _manualSigma;
  double get _unitsPerPx =>
      _autoDerive ? (32.0 / 7.0) : (_manualValueMax / _handleTravel);
  double get _valueMax =>
      _autoDerive ? (_sigma * 32.0 / 7.0) : _manualValueMax;
  double get _cellScale =>
      _autoDerive ? 1.15 : _manualCellScale;

  // Natural element dimensions (independent of track width)
  double get _cellWidth => _baseCellWidth * _cellScale;
  double get _cellHeight => _baseCellHeight * _cellScale;
  double get _handleBoxWidth => _cellWidth * 0.72;
  double get _trackHeight => _cellHeight + 24.0;

  @override
  void initState() {
    super.initState();
    _settle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addListener(_onSettleTick);
  }

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  void _onSettleTick() {
    setState(() {
      _u =
          _settleFrom +
          (_settleTo - _settleFrom) *
              Curves.easeOutCubic.transform(_settle.value);
    });
  }

  void _animateTo(double target) {
    _settleFrom = _u;
    _settleTo = target.clamp(0.0, _handleTravel);
    _settle.duration = Duration(
      milliseconds: (80 + (_settleTo - _settleFrom).abs() * 1.4)
          .round()
          .clamp(90, 260),
    );
    _settle.forward(from: 0);
  }

  double _snapU(double raw) {
    final n = _itemCount;
    return n > 1
        ? ((raw / _handleTravel) * (n - 1)).round() * _handleTravel / (n - 1)
        : 0.0;
  }

  void _applyDragDelta(double dx) {
    _rawU = (_rawU + dx).clamp(0.0, _handleTravel);
    if (_magnetic) {
      final target = _snapU(_rawU);
      final headingThere =
          _settle.isAnimating && (_settleTo - target).abs() < 0.01;
      if ((target - _u).abs() > 0.01 && !headingThere) {
        _animateTo(target);
      }
    } else {
      _u = _rawU;
    }
  }

  double _anchorU(int i, int n) =>
      n > 1 ? (_handleTravel * i / (n - 1)) : 0.0;

  double _logit(double p) => math.log(p / (1.0 - p));

  double _sigmoid(double z) => 1.0 / (1.0 + math.exp(-z));

  List<double> _optionValues(int n) {
    final unitsPerPx = _unitsPerPx;
    final margin = _margin;
    final sigma = _sigma;
    final width = _trackWidth;

    return [
      for (var i = 0; i < n; i++)
        unitsPerPx * _anchorU(i, n) +
            sigma * _logit((margin + _anchorU(i, n)) / width),
    ];
  }

  List<double> _optionXs(List<double> values, double value) {
    final width = _trackWidth;
    final sigma = _sigma;
    return [
      for (final v in values) width * _sigmoid((v - value) / sigma),
    ];
  }

  void _onPointerDown(PointerDownEvent e) {
    _activePointer = e.pointer;
    _downPos = e.position;
    _settle.stop();
    _rawU = _u;
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (_activePointer != e.pointer) return;
    setState(() => _applyDragDelta(e.delta.dx));
  }

  void _onPointerUp(PointerUpEvent e) {
    if (_activePointer != e.pointer) return;
    _activePointer = null;
    final moved = (e.position - _downPos!).distance;
    if (moved < _tapSlack) {
      _selectAt(e.position);
    } else if (!_magnetic) {
      final handleCenter = _margin + _u;
      _animateTo(_anchorU(_nearestIndexTo(handleCenter), _itemCount));
    }
  }

  void _onPointerCancel(PointerCancelEvent e) {
    if (_activePointer != e.pointer) return;
    _activePointer = null;
  }

  int _nearestIndexTo(double handleCenter) {
    var best = 0;
    var bestDist = double.infinity;
    for (var i = 0; i < _itemXs.length; i++) {
      final d = (_itemXs[i] - handleCenter).abs();
      if (d < bestDist) {
        bestDist = d;
        best = i;
      }
    }
    return best;
  }

  void _selectAt(Offset globalPosition) {
    final box = context.findRenderObject() as RenderBox;
    final x = box.globalToLocal(globalPosition).dx;
    final cw = _cellWidth;
    var hit = -1;
    for (var i = _itemXs.length - 1; i >= 0; i--) {
      if (x >= _itemXs[i] - cw / 2 && x < _itemXs[i] + cw / 2) {
        hit = i;
        break;
      }
    }
    if (hit >= 0) {
      _animateTo(_anchorU(hit, _itemCount));
    }
  }

  /// Spatial focus: continuous gradual fall-off as items enter and exit the handle zone
  double _spatialFocus(double itemX, double handleCenter, double radius) {
    final d = (itemX - handleCenter).abs();
    return (1.0 - d / radius).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textColor = theme.textTheme.bodyMedium?.color ?? Colors.white;
    final options = _optionPool.take(_itemCount).toList();
    final n = options.length;

    final cellW = _cellWidth;
    final handleBoxW = _handleBoxWidth;
    final handleCenter = _margin + _u;

    final value = _u * _unitsPerPx;
    final values = _optionValues(n);
    final xs = _optionXs(values, value);
    _itemXs = xs;

    final selectedIndex = _nearestIndexTo(handleCenter).clamp(0, n - 1);
    final focusRadius = handleBoxW * 1.15;

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
            child: MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: Container(
                key: const Key('unravel-track'),
                width: _trackWidth,
                height: _trackHeight,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.07),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: _onPointerDown,
                    onPointerMove: _onPointerMove,
                    onPointerUp: _onPointerUp,
                    onPointerCancel: _onPointerCancel,
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Positioned(
                          left: handleCenter - handleBoxW / 2,
                          top: 0,
                          bottom: 0,
                          width: handleBoxW,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: scheme.primary.withValues(alpha: 0.75),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: scheme.primary.withValues(alpha: 0.22),
                                  blurRadius: 14,
                                  spreadRadius: -1,
                                ),
                              ],
                            ),
                          ),
                        ),
                        for (var i = 0; i < n; i++)
                          Positioned(
                            key: ValueKey(options[i].label),
                            left: xs[i] - cellW / 2,
                            top: 0,
                            bottom: 0,
                            width: cellW,
                            child: _UnravelCell(
                              option: options[i],
                              focus: _spatialFocus(
                                xs[i],
                                handleCenter,
                                focusRadius,
                              ),
                              textColor: textColor,
                              accentColor: scheme.primary,
                              iconSize: 22 * _cellScale,
                              labelFontSize: 11 * _cellScale,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                options[selectedIndex].icon,
                size: 18,
                color: scheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                options[selectedIndex].label.toUpperCase(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const Spacer(),
              Text(
                'u=${_u.toStringAsFixed(0)}px  v=${value.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 12,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: textColor.withValues(alpha: 0.45),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
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
                setState(() {
                  _magnetic = true;
                  _animateTo(_snapU(_u));
                });
              }),
              const Spacer(),
              _modeChip(
                _autoDerive ? 'AUTO RATIOS (ON)' : 'MANUAL TUNING',
                _autoDerive,
                theme,
                () {
                  setState(() {
                    _autoDerive = !_autoDerive;
                    if (_autoDerive) {
                      _u = _rawU = _rawU.clamp(0.0, _handleTravel);
                    }
                  });
                },
              ),
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
              _u = _rawU = _rawU.clamp(0.0, _handleTravel);
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
            onChanged: (v) => setState(() {
              _trackWidth = v;
              if (!_autoDerive && _manualHandleTravel > _trackWidth - 40) {
                _manualHandleTravel = _trackWidth - 40;
              }
              _u = _rawU = _rawU.clamp(0.0, _handleTravel);
            }),
            theme: theme,
          ),
          if (!_autoDerive) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, color: Colors.white12),
            ),
            _knob(
              label: 'EDGE FALL-OFF',
              value: _manualSigma,
              min: 20,
              max: 300,
              divisions: 28,
              display: 's=${_manualSigma.round()}',
              onChanged: (v) => setState(() => _manualSigma = v),
              theme: theme,
            ),
            _knob(
              label: 'HANDLE RANGE',
              value: _manualHandleTravel,
              min: 40,
              max: (_trackWidth - 40).clamp(40.0, 520.0),
              divisions: ((_trackWidth - 40) / 10).floor().clamp(4, 100),
              display: '${_manualHandleTravel.round()}px',
              onChanged: (v) => setState(() {
                _manualHandleTravel = v;
                _u = _rawU = _rawU.clamp(0.0, _handleTravel);
              }),
              theme: theme,
            ),
            _knob(
              label: 'VALUE SPAN',
              value: _manualValueMax,
              min: 200,
              max: 3000,
              divisions: 28,
              display: '${_manualValueMax.round()}',
              onChanged: (v) => setState(() => _manualValueMax = v),
              theme: theme,
            ),
            _knob(
              label: 'ELEMENT SIZE',
              value: _manualCellScale,
              min: 0.5,
              max: 2.5,
              divisions: 40,
              display: 'x${_manualCellScale.toStringAsFixed(2)}',
              onChanged: (v) => setState(() => _manualCellScale = v),
              theme: theme,
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Travel: ${_handleTravel.toStringAsFixed(0)}px | Margin: ${_margin.toStringAsFixed(0)}px | σ: ${_sigma.toStringAsFixed(0)} | Span: ${_valueMax.toStringAsFixed(0)} | Step: ${(_handleTravel / (_itemCount - 1)).toStringAsFixed(1)}px',
                style: TextStyle(
                  fontSize: 11,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: scheme.primary.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
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

class _UnravelCell extends StatelessWidget {
  final _UnravelOption option;
  final double focus;
  final Color textColor;
  final Color accentColor;
  final double iconSize;
  final double labelFontSize;

  const _UnravelCell({
    required this.option,
    required this.focus,
    required this.textColor,
    required this.accentColor,
    required this.iconSize,
    required this.labelFontSize,
  });

  @override
  Widget build(BuildContext context) {
    final easedFocus = Curves.easeOutCubic.transform(focus);
    final scale = 0.74 + 0.26 * easedFocus;
    final opacity = 0.22 + 0.78 * easedFocus;

    // Smooth continuous color blend from ambient text to vibrant accent
    final itemColor = Color.lerp(
      textColor.withValues(alpha: 0.45),
      accentColor,
      easedFocus,
    )!;

    final fontWeight = FontWeight.lerp(
      FontWeight.w500,
      FontWeight.w800,
      easedFocus,
    )!;

    return Center(
      child: Transform.scale(
        scale: scale,
        child: Opacity(
          opacity: opacity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                option.icon,
                size: iconSize,
                color: itemColor,
              ),
              const SizedBox(height: 2),
              Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  fontSize: labelFontSize,
                  fontWeight: fontWeight,
                  color: itemColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

