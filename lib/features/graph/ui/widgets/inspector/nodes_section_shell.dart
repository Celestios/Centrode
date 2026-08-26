import 'package:flutter/material.dart';
import 'components/glass_section_shell.dart';
import 'components/sub_block_shell.dart';
import 'components/visual_shape_selector.dart';
import 'components/segmented_glass_switcher.dart';
import 'components/inline_property_row.dart';
import 'showcase/node_showcase_card.dart';

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

    return ShowcaseSectionShell(
      title: 'Node',
      icon: Icons.account_tree_rounded,
      accentColor: primaryAccent,
      showcase: NodeShowcaseCard(
        shape: _nodeShape,
        fillStyle: _fillStyle,
        opacity: _opacity,
        cornerRadius: _cornerRadius,
        borderStyle: _borderStyle,
        borderWidth: _borderWidth,
        borderOpacity: _borderOpacity,
        fontFamily: _fontFamily,
        fontSize: _fontSize,
        textAlign: _textAlign,
        highlightColor: _highlightColor,
        accentColor: primaryAccent,
      ),
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
    );
  }
}
