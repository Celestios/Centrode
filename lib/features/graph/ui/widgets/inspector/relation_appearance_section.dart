import 'package:flutter/material.dart';

/// Reusable top-level outer shell container for inspector property sections (Stateless & always expanded).
class GlassSectionShell extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final Widget child;

  const GlassSectionShell({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 10.0),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.22),
          width: 0.8,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            child: Row(
              children: [
                Icon(icon, size: 14, color: accentColor),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: child,
          ),
        ],
      ),
    );
  }
}

/// Collapsible sub-block container within a section shell.
class SubBlockShell extends StatefulWidget {
  final String title;
  final Widget child;
  final Color accentColor;
  final bool initiallyExpanded;

  const SubBlockShell({
    super.key,
    required this.title,
    required this.child,
    required this.accentColor,
    this.initiallyExpanded = false,
  });

  @override
  State<SubBlockShell> createState() => _SubBlockShellState();
}

class _SubBlockShellState extends State<SubBlockShell> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6.0),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.accentColor.withValues(alpha: 0.12),
          width: 0.6,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: widget.accentColor.withValues(alpha: 0.95),
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: widget.accentColor.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}

/// Pattern A: Tactile Grid of Visual Preview Tiles for shapes, routing vectors, and caps.
class VisualShapeSelector<T> extends StatelessWidget {
  final List<ShapeTileData<T>> items;
  final T selectedValue;
  final ValueChanged<T> onSelected;
  final Color activeColor;

  const VisualShapeSelector({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onSelected,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: items.map((item) {
        final isSelected = item.value == selectedValue;
        return GestureDetector(
          onTap: () => onSelected(item.value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? activeColor.withValues(alpha: 0.22)
                  : Colors.black.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? activeColor.withValues(alpha: 0.7)
                    : Colors.white.withValues(alpha: 0.08),
                width: isSelected ? 1.2 : 0.8,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.2),
                        blurRadius: 6,
                        spreadRadius: -1,
                      ),
                    ]
                  : [],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.icon,
                  size: 13,
                  color: isSelected
                      ? activeColor
                      : Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.color
                          ?.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? activeColor
                        : Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class ShapeTileData<T> {
  final T value;
  final String label;
  final IconData icon;

  const ShapeTileData({
    required this.value,
    required this.label,
    required this.icon,
  });
}

/// Pattern B: Glass Segmented Mode Switcher with sliding indicator feel.
class SegmentedGlassSwitcher<T> extends StatelessWidget {
  final List<SegmentData<T>> segments;
  final T selectedValue;
  final ValueChanged<T> onSelected;
  final Color activeColor;

  const SegmentedGlassSwitcher({
    super.key,
    required this.segments,
    required this.selectedValue,
    required this.onSelected,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
          width: 0.8,
        ),
      ),
      child: Row(
        children: segments.map((seg) {
          final isSelected = seg.value == selectedValue;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(seg.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                height: 26,
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.28)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? activeColor.withValues(alpha: 0.5)
                        : Colors.transparent,
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (seg.icon != null) ...[
                      Icon(
                        seg.icon,
                        size: 12,
                        color: isSelected
                            ? activeColor
                            : Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 3),
                    ],
                    Text(
                      seg.label,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? activeColor
                            : Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class SegmentData<T> {
  final T value;
  final String label;
  final IconData? icon;

  const SegmentData({
    required this.value,
    required this.label,
    this.icon,
  });
}

/// Pattern C: Inline Value & Swatch Row combining label, swatch, and micro slider.
class InlinePropertyRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String unit;
  final Color? colorSwatch;
  final Color activeColor;

  const InlinePropertyRow({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.unit = 'px',
    this.colorSwatch,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          SizedBox(
            width: 75,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
              ),
            ),
          ),
          if (colorSwatch != null) ...[
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: colorSwatch,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24, width: 1),
              ),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2.0,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5.0),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10.0),
                activeTrackColor: activeColor,
                inactiveTrackColor: activeColor.withValues(alpha: 0.15),
                thumbColor: activeColor,
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
            width: 32,
            child: Text(
              '${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)}$unit',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 9.0,
                fontWeight: FontWeight.w700,
                color: activeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dynamic Top-Level Relations Section Container containing all relation appearance sub-blocks.
class RelationsSectionShell extends StatefulWidget {
  final bool isGlobal;

  const RelationsSectionShell({
    super.key,
    this.isGlobal = true,
  });

  @override
  State<RelationsSectionShell> createState() => _RelationsSectionShellState();
}

class _RelationsSectionShellState extends State<RelationsSectionShell> {
  // State variables for Relation Appearance sub-blocks
  String _selectedShape = 'capsule';
  String _selectedFill = 'glass';
  double _padding = 8.0;
  double _cornerRadius = 6.0;

  String _selectedFont = 'inter';
  double _fontSize = 11.0;

  String _routingStrategy = 'curved';
  double _curveTension = 0.5;

  String _strokePattern = 'solid';
  double _strokeWidth = 2.0;
  String _startCap = 'none';
  String _endCap = 'arrow';

  String _crossingStrategy = 'bridge';
  double _bundleGap = 12.0;

  final Color _amberAccent = Colors.amber.shade600;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassSectionShell(
          title: 'Relations',
          icon: Icons.link_rounded,
          accentColor: _amberAccent,
          child: Column(
            children: [
              // Sub-block 1: Label Body
              SubBlockShell(
                title: 'Label Body',
                accentColor: _amberAccent,
                initiallyExpanded: false,
                child: Column(
                  children: [
                    VisualShapeSelector<String>(
                      activeColor: _amberAccent,
                      selectedValue: _selectedShape,
                      onSelected: (val) => setState(() => _selectedShape = val),
                      items: const [
                        ShapeTileData(value: 'capsule', label: 'Capsule', icon: Icons.crop_free_rounded),
                        ShapeTileData(value: 'rounded', label: 'Rounded', icon: Icons.rounded_corner_rounded),
                        ShapeTileData(value: 'sharp', label: 'Sharp', icon: Icons.square_outlined),
                        ShapeTileData(value: 'none', label: 'None', icon: Icons.disabled_by_default_outlined),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SegmentedGlassSwitcher<String>(
                      activeColor: _amberAccent,
                      selectedValue: _selectedFill,
                      onSelected: (val) => setState(() => _selectedFill = val),
                      segments: const [
                        SegmentData(value: 'solid', label: 'Solid'),
                        SegmentData(value: 'glass', label: 'Glass'),
                        SegmentData(value: 'outline', label: 'Outline'),
                      ],
                    ),
                    InlinePropertyRow(
                      label: 'Padding',
                      value: _padding,
                      min: 2,
                      max: 20,
                      activeColor: _amberAccent,
                      onChanged: (val) => setState(() => _padding = val),
                    ),
                    InlinePropertyRow(
                      label: 'Corner Radius',
                      value: _cornerRadius,
                      min: 0,
                      max: 16,
                      activeColor: _amberAccent,
                      onChanged: (val) => setState(() => _cornerRadius = val),
                    ),
                  ],
                ),
              ),

              // Sub-block 2: Label Typography
              SubBlockShell(
                title: 'Label Text',
                accentColor: _amberAccent,
                initiallyExpanded: false,
                child: Column(
                  children: [
                    SegmentedGlassSwitcher<String>(
                      activeColor: _amberAccent,
                      selectedValue: _selectedFont,
                      onSelected: (val) => setState(() => _selectedFont = val),
                      segments: const [
                        SegmentData(value: 'inter', label: 'Inter'),
                        SegmentData(value: 'outfit', label: 'Outfit'),
                        SegmentData(value: 'mono', label: 'Mono'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    InlinePropertyRow(
                      label: 'Font Size',
                      value: _fontSize,
                      min: 8,
                      max: 20,
                      activeColor: _amberAccent,
                      onChanged: (val) => setState(() => _fontSize = val),
                    ),
                  ],
                ),
              ),

              // Sub-block 3: Path Routing
              SubBlockShell(
                title: 'Routing',
                accentColor: _amberAccent,
                initiallyExpanded: false,
                child: Column(
                  children: [
                    VisualShapeSelector<String>(
                      activeColor: _amberAccent,
                      selectedValue: _routingStrategy,
                      onSelected: (val) => setState(() => _routingStrategy = val),
                      items: const [
                        ShapeTileData(value: 'straight', label: 'Straight', icon: Icons.show_chart_rounded),
                        ShapeTileData(value: 'curved', label: 'Bézier', icon: Icons.gesture_rounded),
                        ShapeTileData(value: 'ortho', label: 'Orthogonal', icon: Icons.alt_route_rounded),
                        ShapeTileData(value: 'step', label: 'Step', icon: Icons.turn_right_rounded),
                      ],
                    ),
                    if (_routingStrategy == 'curved')
                      InlinePropertyRow(
                        label: 'Tension',
                        value: _curveTension,
                        min: 0.1,
                        max: 1.0,
                        unit: '',
                        activeColor: _amberAccent,
                        onChanged: (val) => setState(() => _curveTension = val),
                      ),
                  ],
                ),
              ),

              // Sub-block 4: Line Body & Arrowcaps
              SubBlockShell(
                title: 'Stroke & Caps',
                accentColor: _amberAccent,
                initiallyExpanded: false,
                child: Column(
                  children: [
                    SegmentedGlassSwitcher<String>(
                      activeColor: _amberAccent,
                      selectedValue: _strokePattern,
                      onSelected: (val) => setState(() => _strokePattern = val),
                      segments: const [
                        SegmentData(value: 'solid', label: 'Solid'),
                        SegmentData(value: 'dashed', label: 'Dashed'),
                        SegmentData(value: 'dotted', label: 'Dotted'),
                      ],
                    ),
                    InlinePropertyRow(
                      label: 'Width',
                      value: _strokeWidth,
                      min: 0.5,
                      max: 8.0,
                      activeColor: _amberAccent,
                      onChanged: (val) => setState(() => _strokeWidth = val),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: VisualShapeSelector<String>(
                            activeColor: _amberAccent,
                            selectedValue: _startCap,
                            onSelected: (val) => setState(() => _startCap = val),
                            items: const [
                              ShapeTileData(value: 'none', label: 'Start: None', icon: Icons.horizontal_rule),
                              ShapeTileData(value: 'circle', label: 'Dot', icon: Icons.circle_outlined),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: VisualShapeSelector<String>(
                            activeColor: _amberAccent,
                            selectedValue: _endCap,
                            onSelected: (val) => setState(() => _endCap = val),
                            items: const [
                              ShapeTileData(value: 'arrow', label: 'End: Arrow', icon: Icons.arrow_forward_rounded),
                              ShapeTileData(value: 'diamond', label: 'Diamond', icon: Icons.diamond_outlined),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Sub-block 5: Topology & Crossing
              SubBlockShell(
                title: 'Topology',
                accentColor: _amberAccent,
                initiallyExpanded: false,
                child: Column(
                  children: [
                    SegmentedGlassSwitcher<String>(
                      activeColor: _amberAccent,
                      selectedValue: _crossingStrategy,
                      onSelected: (val) => setState(() => _crossingStrategy = val),
                      segments: const [
                        SegmentData(value: 'bridge', label: 'Arc Bridge'),
                        SegmentData(value: 'break', label: 'Break Gap'),
                        SegmentData(value: 'blend', label: 'Pass-Through'),
                      ],
                    ),
                    InlinePropertyRow(
                      label: 'Bundle Gap',
                      value: _bundleGap,
                      min: 4,
                      max: 32,
                      activeColor: _amberAccent,
                      onChanged: (val) => setState(() => _bundleGap = val),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Dynamic Top-Level Nodes Section Container.
class NodesSectionShell extends StatefulWidget {
  final bool isGlobal;

  const NodesSectionShell({
    super.key,
    this.isGlobal = true,
  });

  @override
  State<NodesSectionShell> createState() => _NodesSectionShellState();
}

class _NodesSectionShellState extends State<NodesSectionShell> {
  // State variables for Node Appearance sub-blocks
  String _nodeShape = 'rounded';
  String _fillStyle = 'glass';
  double _opacity = 85.0;
  double _cornerRadius = 12.0;

  double _borderWidth = 1.5;
  String _borderStyle = 'solid';
  double _borderOpacity = 60.0;

  String _fontFamily = 'inter';
  double _fontSize = 12.0;
  String _textAlign = 'left';
  String _highlightColor = 'none';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GlassSectionShell(
          title: 'Nodes',
          icon: Icons.account_tree_rounded,
          accentColor: primaryAccent,
          child: Column(
            children: [
              // Sub-block 1: Body Format
              SubBlockShell(
                title: 'Body',
                accentColor: primaryAccent,
                initiallyExpanded: false,
                child: Column(
                  children: [
                    VisualShapeSelector<String>(
                      activeColor: primaryAccent,
                      selectedValue: _nodeShape,
                      onSelected: (val) => setState(() => _nodeShape = val),
                      items: const [
                        ShapeTileData(value: 'rounded', label: 'Rounded', icon: Icons.rounded_corner_rounded),
                        ShapeTileData(value: 'sharp', label: 'Sharp', icon: Icons.square_outlined),
                        ShapeTileData(value: 'capsule', label: 'Capsule', icon: Icons.crop_free_rounded),
                        ShapeTileData(value: 'circle', label: 'Circle', icon: Icons.circle_outlined),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SegmentedGlassSwitcher<String>(
                      activeColor: primaryAccent,
                      selectedValue: _fillStyle,
                      onSelected: (val) => setState(() => _fillStyle = val),
                      segments: const [
                        SegmentData(value: 'solid', label: 'Solid'),
                        SegmentData(value: 'glass', label: 'Glass'),
                        SegmentData(value: 'outline', label: 'Outline'),
                      ],
                    ),
                    InlinePropertyRow(
                      label: 'Opacity',
                      value: _opacity,
                      min: 0,
                      max: 100,
                      unit: '%',
                      activeColor: primaryAccent,
                      onChanged: (val) => setState(() => _opacity = val),
                    ),
                    InlinePropertyRow(
                      label: 'Corner Radius',
                      value: _cornerRadius,
                      min: 0,
                      max: 24,
                      activeColor: primaryAccent,
                      onChanged: (val) => setState(() => _cornerRadius = val),
                    ),
                  ],
                ),
              ),

              // Sub-block 2: Border
              SubBlockShell(
                title: 'Border',
                accentColor: primaryAccent,
                initiallyExpanded: false,
                child: Column(
                  children: [
                    SegmentedGlassSwitcher<String>(
                      activeColor: primaryAccent,
                      selectedValue: _borderStyle,
                      onSelected: (val) => setState(() => _borderStyle = val),
                      segments: const [
                        SegmentData(value: 'solid', label: 'Solid'),
                        SegmentData(value: 'dashed', label: 'Dashed'),
                        SegmentData(value: 'dotted', label: 'Dotted'),
                      ],
                    ),
                    InlinePropertyRow(
                      label: 'Thickness',
                      value: _borderWidth,
                      min: 0,
                      max: 8,
                      activeColor: primaryAccent,
                      onChanged: (val) => setState(() => _borderWidth = val),
                    ),
                    InlinePropertyRow(
                      label: 'Border Opacity',
                      value: _borderOpacity,
                      min: 0,
                      max: 100,
                      unit: '%',
                      activeColor: primaryAccent,
                      onChanged: (val) => setState(() => _borderOpacity = val),
                    ),
                  ],
                ),
              ),

              // Sub-block 3: Text Formatting
              SubBlockShell(
                title: 'Text',
                accentColor: primaryAccent,
                initiallyExpanded: false,
                child: Column(
                  children: [
                    SegmentedGlassSwitcher<String>(
                      activeColor: primaryAccent,
                      selectedValue: _fontFamily,
                      onSelected: (val) => setState(() => _fontFamily = val),
                      segments: const [
                        SegmentData(value: 'inter', label: 'Inter'),
                        SegmentData(value: 'outfit', label: 'Outfit'),
                        SegmentData(value: 'mono', label: 'Mono'),
                      ],
                    ),
                    InlinePropertyRow(
                      label: 'Font Size',
                      value: _fontSize,
                      min: 8,
                      max: 28,
                      activeColor: primaryAccent,
                      onChanged: (val) => setState(() => _fontSize = val),
                    ),
                    const SizedBox(height: 4),
                    SegmentedGlassSwitcher<String>(
                      activeColor: primaryAccent,
                      selectedValue: _textAlign,
                      onSelected: (val) => setState(() => _textAlign = val),
                      segments: const [
                        SegmentData(value: 'left', label: 'Left', icon: Icons.format_align_left_rounded),
                        SegmentData(value: 'center', label: 'Center', icon: Icons.format_align_center_rounded),
                        SegmentData(value: 'right', label: 'Right', icon: Icons.format_align_right_rounded),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SegmentedGlassSwitcher<String>(
                      activeColor: primaryAccent,
                      selectedValue: _highlightColor,
                      onSelected: (val) => setState(() => _highlightColor = val),
                      segments: const [
                        SegmentData(value: 'none', label: 'No Highlight'),
                        SegmentData(value: 'yellow', label: 'Yellow'),
                        SegmentData(value: 'cyan', label: 'Cyan'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
