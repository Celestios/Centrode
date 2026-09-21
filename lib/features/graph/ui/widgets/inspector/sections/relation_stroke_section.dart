import 'package:centrode/shared/elements/elements.dart';
import 'package:flutter/material.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/features/graph/models/models.dart';
import '../components/sub_block_shell.dart';
import '../components/glass_color_pill_button.dart';
import '../components/compact_slider_box.dart';

class RelationStrokeSection extends StatelessWidget {
  final NodeRenderState renderState;
  final String strokePattern;
  final double strokeWidth;
  final Color? lineColor;
  final String startCap;
  final String endCap;
  final Color accentColor;
  final ValueChanged<String> onStrokePatternChanged;
  final ValueChanged<Color?> onLineColorChanged;
  final ValueChanged<String> onStartCapChanged;
  final ValueChanged<String> onEndCapChanged;
  final ValueChanged<double> onStrokeWidthChanged;
  final VoidCallback onReset;

  const RelationStrokeSection({
    super.key,
    required this.renderState,
    required this.strokePattern,
    required this.strokeWidth,
    this.lineColor,
    required this.startCap,
    required this.endCap,
    required this.accentColor,
    required this.onStrokePatternChanged,
    required this.onLineColorChanged,
    required this.onStartCapChanged,
    required this.onEndCapChanged,
    required this.onStrokeWidthChanged,
    required this.onReset,
  });

  List<UiRelation> _getSelectedRelations(NodeRenderState rs) {
    return rs.selectedEntities
        .where((id) => rs.relationLookup.containsKey(id))
        .map((id) => rs.relationLookup[id]!)
        .toList();
  }

  void _updateRelationsStyle(
    NodeRenderState rs,
    RelationStyle Function(RelationStyle current) updater,
  ) {
    for (final rel in _getSelectedRelations(rs)) {
      final currentStyle = rel.style ?? rel.resolvedStyle;
      if (currentStyle != null) {
        rs.updateRelationStyle(
          rel.id,
          updater(currentStyle),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SubBlockShell(
      title: 'Stroke & Caps',
      accentColor: accentColor,
      onReset: onReset,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: CentrodeSegmentedControl<String>(
                  items: const [
                    (icon: Icons.horizontal_rule, label: 'Solid', mode: 'solid', tooltip: null, accentBadge: null),
                    (icon: Icons.linear_scale, label: 'Dash', mode: 'dashed', tooltip: null, accentBadge: null),
                    (icon: Icons.grain, label: 'Dot', mode: 'dotted', tooltip: null, accentBadge: null),
                  ],
                  currentMode: strokePattern,
                  isCompact: false,
                  onSelected: (val) {
                    onStrokePatternChanged(val);
                    _updateRelationsStyle(
                      renderState,
                      (s) => s.copyWith(strokePattern: val),
                    );
                  },
                ),
              ),
              const SizedBox(width: UiSpacing.standard),
              Expanded(
                flex: 1,
                child: GlassColorPillButton<Color?>(
                  label: 'color',
                  selectedValue: lineColor,
                  activeColor: accentColor,
                  onSelected: (val) {
                    onLineColorChanged(val);
                    _updateRelationsStyle(
                      renderState,
                      (s) => s.copyWith(
                        strokeColor: (val ?? accentColor).toARGB32(),
                      ),
                    );
                  },
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
          const SizedBox(height: UiSpacing.tight),
          Row(
            children: [
              Expanded(
                child: CentrodeSegmentedControl<String>(
                  items: const [
                    (icon: Icons.arrow_back, label: 'None', mode: 'none', tooltip: null, accentBadge: null),
                    (icon: Icons.circle, label: 'Dot', mode: 'circle', tooltip: null, accentBadge: null),
                  ],
                  currentMode: startCap,
                  isCompact: false,
                  onSelected: onStartCapChanged,
                ),
              ),
              const SizedBox(width: UiSpacing.tight),
              Expanded(
                child: CentrodeSegmentedControl<String>(
                  items: const [
                    (icon: Icons.arrow_forward, label: 'Arrow', mode: 'arrow', tooltip: null, accentBadge: null),
                    (icon: Icons.diamond, label: 'Diamond', mode: 'diamond', tooltip: null, accentBadge: null),
                  ],
                  currentMode: endCap,
                  isCompact: false,
                  onSelected: onEndCapChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: UiSpacing.tight),
          CompactSliderBox(
            label: 'Width',
            value: strokeWidth,
            min: 0.5,
            max: 8.0,
            unit: 'px',
            activeColor: accentColor,
            onChanged: (val) {
              onStrokeWidthChanged(val);
              _updateRelationsStyle(
                renderState,
                (s) => s.copyWith(strokeWidth: val.round()),
              );
            },
          ),
        ],
      ),
    );
  }
}
