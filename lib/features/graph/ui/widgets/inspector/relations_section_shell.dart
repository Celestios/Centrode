import 'package:flutter/material.dart';
import 'components/glass_section_shell.dart';
import 'components/sub_block_shell.dart';
import 'components/visual_shape_selector.dart';
import 'components/segmented_glass_switcher.dart';
import 'components/inline_property_row.dart';
import 'showcase/relation_showcase_card.dart';

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
    return ShowcaseSectionShell(
      title: 'Relation',
      icon: Icons.link_rounded,
      accentColor: _amberAccent,
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
        accentColor: _amberAccent,
      ),
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
    );
  }
}
