import 'package:flutter/material.dart';
import 'package:centrode/shared/widgets/unravel_slider/unravel_slider.dart';
import 'components/glass_section_shell.dart';
import 'components/sub_block_shell.dart';
import 'components/segmented_glass_switcher.dart';
import 'components/compact_slider_box.dart';
import 'components/glass_color_pill_button.dart';
import 'components/relation_shape_definitions.dart';
import 'showcase/relation_showcase_card.dart';

/// Dynamic Top-Level Relations Section Container containing all relation appearance sub-blocks.
class RelationsSectionShell extends StatefulWidget {
  final bool isGlobal;
  final int selectedCount;

  const RelationsSectionShell({
    super.key,
    this.isGlobal = true,
    this.selectedCount = 0,
  });

  @override
  State<RelationsSectionShell> createState() => _RelationsSectionShellState();
}

class _RelationsSectionShellState extends State<RelationsSectionShell> {
  // State variables for Relation Appearance sub-blocks
  String _selectedShape = 'capsule';
  String _selectedFill = 'glass';
  Color? _labelBgColor;
  double _padding = 8.0;
  double _cornerRadius = 6.0;

  String _selectedFont = 'inter';
  double _fontSize = 11.0;

  String _routingStrategy = 'curved';
  double _curveTension = 0.5;

  String _strokePattern = 'solid';
  double _strokeWidth = 2.0;
  Color? _lineColor;
  String _startCap = 'none';
  String _endCap = 'arrow';

  String _crossingStrategy = 'bridge';
  double _bundleGap = 12.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

    final selectedRoutingIndex = kAvailableRoutingStrategies.isEmpty
        ? 0
        : kAvailableRoutingStrategies
            .indexWhere((r) => r.id == _routingStrategy)
            .clamp(0, kAvailableRoutingStrategies.length - 1);

    final badgeText = widget.isGlobal
        ? 'Global'
        : '${widget.selectedCount} Selected';

    return ShowcaseSectionShell(
      title: 'Relation',
      icon: Icons.link_rounded,
      accentColor: primaryAccent,
      badgeText: badgeText,
      showcase: RelationShowcaseCard(
        labelShape: _selectedShape,
        labelFill: _selectedFill,
        padding: _padding,
        cornerRadius: _cornerRadius,
        font: _selectedFont,
        fontSize: _fontSize,
        routingStrategy: _routingStrategy,
        curveTension: _curveTension,
        strokePattern: _strokePattern,
        strokeWidth: _strokeWidth,
        startCap: _startCap,
        endCap: _endCap,
        crossingStrategy: _crossingStrategy,
        accentColor: _lineColor ?? primaryAccent,
      ),
      child: Column(
        children: [
          // Sub-block 1: Label Body
          SubBlockShell(
            title: 'Label Body',
            accentColor: primaryAccent,
            onReset: () {
              setState(() {
                _selectedShape = 'capsule';
                _selectedFill = 'glass';
                _labelBgColor = null;
                _padding = 8.0;
                _cornerRadius = 6.0;
              });
            },
            child: Column(
              children: [
                SegmentedGlassSwitcher<String>(
                  height: 30.0,
                  activeColor: primaryAccent,
                  selectedValue: _selectedShape,
                  onSelected: (val) => setState(() => _selectedShape = val),
                  segments: const [
                    SegmentData(value: 'capsule', label: 'Capsule'),
                    SegmentData(value: 'rounded', label: 'Rounded'),
                    SegmentData(value: 'sharp', label: 'Sharp'),
                    SegmentData(value: 'none', label: 'None'),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SegmentedGlassSwitcher<String>(
                        height: 30.0,
                        activeColor: primaryAccent,
                        selectedValue: _selectedFill,
                        onSelected: (val) => setState(() => _selectedFill = val),
                        segments: const [
                          SegmentData(value: 'solid', label: 'Solid'),
                          SegmentData(value: 'glass', label: 'Glass'),
                          SegmentData(value: 'outline', label: 'Outline'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: GlassColorPillButton<Color?>(
                        label: 'bg',
                        selectedValue: _labelBgColor,
                        activeColor: primaryAccent,
                        onSelected: (val) => setState(() => _labelBgColor = val),
                        options: [
                          const ColorPillOption(value: null, label: 'Accent', isNone: true),
                          const ColorPillOption(value: Color(0xFF1E293B), color: Color(0xFF1E293B), label: 'Slate'),
                          const ColorPillOption(value: Color(0xFF0F172A), color: Color(0xFF0F172A), label: 'Midnight'),
                          const ColorPillOption(value: Color(0xFF00E5FF), color: Color(0xFF00E5FF), label: 'Cyan'),
                          const ColorPillOption(value: Color(0xFFFFB703), color: Color(0xFFFFB703), label: 'Amber'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: CompactSliderBox(
                        label: 'Padding',
                        value: _padding,
                        min: 2,
                        max: 20,
                        unit: 'px',
                        activeColor: primaryAccent,
                        onChanged: (val) => setState(() => _padding = val),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: CompactSliderBox(
                        label: 'Radius',
                        value: _cornerRadius,
                        min: 0,
                        max: 16,
                        unit: 'px',
                        activeColor: primaryAccent,
                        onChanged: (val) => setState(() => _cornerRadius = val),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sub-block 2: Label Typography
          SubBlockShell(
            title: 'Label Text',
            accentColor: primaryAccent,
            onReset: () {
              setState(() {
                _selectedFont = 'inter';
                _fontSize = 11.0;
              });
            },
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SegmentedGlassSwitcher<String>(
                        height: 30.0,
                        activeColor: primaryAccent,
                        selectedValue: _selectedFont,
                        onSelected: (val) => setState(() => _selectedFont = val),
                        segments: const [
                          SegmentData(value: 'inter', label: 'Inter'),
                          SegmentData(value: 'outfit', label: 'Outfit'),
                          SegmentData(value: 'mono', label: 'Mono'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 1,
                      child: CompactSliderBox(
                        label: 'Size',
                        value: _fontSize,
                        min: 8,
                        max: 20,
                        unit: 'pt',
                        activeColor: primaryAccent,
                        onChanged: (val) => setState(() => _fontSize = val),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sub-block 3: Path Routing
          SubBlockShell(
            title: 'Routing',
            accentColor: primaryAccent,
            onReset: () {
              setState(() {
                _routingStrategy = 'curved';
                _curveTension = 0.5;
              });
            },
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: LayoutBuilder(
                    builder: (BuildContext context, BoxConstraints constraints) {
                      return SizedBox(
                        width: constraints.maxWidth,
                        child: UnravelSlider<RelationRoutingDefinition>(
                          trackWidth: constraints.maxWidth,
                          items: kAvailableRoutingStrategies,
                          selectedIndex: selectedRoutingIndex,
                          onSelected: (idx) {
                            setState(() {
                              _routingStrategy = kAvailableRoutingStrategies[idx].id;
                            });
                          },
                          theme: UnravelSliderThemeData(
                            accentColor: primaryAccent,
                            cellWidth: 60.0,
                            cellHeight: 46.0,
                            trackBorderRadius: const BorderRadius.all(Radius.circular(8)),
                            handleBorderRadius: const BorderRadius.all(Radius.circular(6)),
                            trackBackgroundColor: Colors.black.withValues(alpha: 0.22),
                          ),
                          itemBuilder: (context, item, focus, isSelected) {
                            final iconColor = isSelected
                                ? primaryAccent
                                : theme.textTheme.bodyMedium?.color
                                        ?.withValues(alpha: (0.35 + 0.65 * focus).clamp(0.0, 1.0)) ??
                                    Colors.white70;

                            return Center(
                              child: Icon(
                                item.icon,
                                size: 24.0 + (focus * 8.0),
                                color: iconColor,
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
                if (_routingStrategy == 'curved')
                  CompactSliderBox(
                    label: 'Tension',
                    value: _curveTension,
                    min: 0.1,
                    max: 1.0,
                    unit: '',
                    activeColor: primaryAccent,
                    onChanged: (val) => setState(() => _curveTension = val),
                  ),
              ],
            ),
          ),

          // Sub-block 4: Line Body & Arrowcaps
          SubBlockShell(
            title: 'Stroke & Caps',
            accentColor: primaryAccent,
            onReset: () {
              setState(() {
                _strokePattern = 'solid';
                _strokeWidth = 2.0;
                _lineColor = null;
                _startCap = 'none';
                _endCap = 'arrow';
              });
            },
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SegmentedGlassSwitcher<String>(
                        height: 30.0,
                        activeColor: primaryAccent,
                        selectedValue: _strokePattern,
                        onSelected: (val) => setState(() => _strokePattern = val),
                        segments: const [
                          SegmentData(value: 'solid', label: '━ Solid', style: TextStyle(fontSize: 10.5)),
                          SegmentData(value: 'dashed', label: '┅ Dash', style: TextStyle(fontSize: 10.5)),
                          SegmentData(value: 'dotted', label: '┈ Dot', style: TextStyle(fontSize: 10.5)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: GlassColorPillButton<Color?>(
                        label: 'color',
                        selectedValue: _lineColor,
                        activeColor: primaryAccent,
                        onSelected: (val) => setState(() => _lineColor = val),
                        options: [
                          const ColorPillOption(value: null, label: 'Accent', isNone: true),
                          const ColorPillOption(value: Colors.white, color: Colors.white, label: 'White'),
                          const ColorPillOption(value: Color(0xFF00E5FF), color: Color(0xFF00E5FF), label: 'Cyan'),
                          const ColorPillOption(value: Color(0xFFFFB703), color: Color(0xFFFFB703), label: 'Amber'),
                          const ColorPillOption(value: Color(0xFF10B981), color: Color(0xFF10B981), label: 'Emerald'),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: SegmentedGlassSwitcher<String>(
                        height: 30.0,
                        activeColor: primaryAccent,
                        selectedValue: _startCap,
                        onSelected: (val) => setState(() => _startCap = val),
                        segments: const [
                          SegmentData(value: 'none', label: 'Start: ⊸ None', style: TextStyle(fontSize: 10.0)),
                          SegmentData(value: 'circle', label: 'Dot ●', style: TextStyle(fontSize: 10.0)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: SegmentedGlassSwitcher<String>(
                        height: 30.0,
                        activeColor: primaryAccent,
                        selectedValue: _endCap,
                        onSelected: (val) => setState(() => _endCap = val),
                        segments: const [
                          SegmentData(value: 'arrow', label: 'End: ➔ Arrow', style: TextStyle(fontSize: 10.0)),
                          SegmentData(value: 'diamond', label: 'Diamond ◆', style: TextStyle(fontSize: 10.0)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                CompactSliderBox(
                  label: 'Width',
                  value: _strokeWidth,
                  min: 0.5,
                  max: 8.0,
                  unit: 'px',
                  activeColor: primaryAccent,
                  onChanged: (val) => setState(() => _strokeWidth = val),
                ),
              ],
            ),
          ),

          // Sub-block 5: Topology & Crossing
          SubBlockShell(
            title: 'Topology',
            accentColor: primaryAccent,
            onReset: () {
              setState(() {
                _crossingStrategy = 'bridge';
                _bundleGap = 12.0;
              });
            },
            child: Column(
              children: [
                SegmentedGlassSwitcher<String>(
                  height: 30.0,
                  activeColor: primaryAccent,
                  selectedValue: _crossingStrategy,
                  onSelected: (val) => setState(() => _crossingStrategy = val),
                  segments: const [
                    SegmentData(value: 'bridge', label: 'Arc Bridge'),
                    SegmentData(value: 'break', label: 'Break Gap'),
                    SegmentData(value: 'blend', label: 'Pass-Through'),
                  ],
                ),
                const SizedBox(height: 6),
                CompactSliderBox(
                  label: 'Bundle Gap',
                  value: _bundleGap,
                  min: 4,
                  max: 32,
                  unit: 'px',
                  activeColor: primaryAccent,
                  onChanged: (val) => setState(() => _bundleGap = val),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
