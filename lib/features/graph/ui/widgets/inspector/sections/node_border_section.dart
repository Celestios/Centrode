import 'package:centrode/shared/elements/elements.dart';
import 'package:flutter/material.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/features/graph/models/models.dart';
import '../components/sub_block_shell.dart';
import '../components/segmented_glass_switcher.dart';
import '../components/glass_color_pill_button.dart';
import '../components/compact_slider_box.dart';

class NodeBorderSection extends StatelessWidget {
  final NodeRenderState renderState;
  final double borderWidth;
  final String borderStyle;
  final double borderOpacity;
  final Color? borderColor;
  final Color accentColor;
  final ValueChanged<double> onBorderWidthChanged;
  final ValueChanged<String> onBorderStyleChanged;
  final ValueChanged<double> onBorderOpacityChanged;
  final ValueChanged<Color?> onBorderColorChanged;
  final VoidCallback onReset;

  const NodeBorderSection({
    super.key,
    required this.renderState,
    required this.borderWidth,
    required this.borderStyle,
    required this.borderOpacity,
    this.borderColor,
    required this.accentColor,
    required this.onBorderWidthChanged,
    required this.onBorderStyleChanged,
    required this.onBorderOpacityChanged,
    required this.onBorderColorChanged,
    required this.onReset,
  });

  List<UiNode> _getSelectedNodes(NodeRenderState rs) {
    return rs.selectedEntities
        .map((id) => rs.getNode(id))
        .whereType<UiNode>()
        .toList();
  }

  int _computeNodeStrokeColor(ThemeData theme, Color? localBorderColor, double localBorderOpacity) {
    final base = localBorderColor ?? theme.colorScheme.primary;
    return base.withValues(alpha: (localBorderOpacity / 100).clamp(0.0, 1.0)).toARGB32();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRenderState = renderState;
    final theme = Theme.of(context);

    return SubBlockShell(
      title: 'Border',
      accentColor: accentColor,
      onReset: onReset,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SegmentedGlassSwitcher<String>(
                  height: UiControlSize.standard,
                  activeColor: accentColor,
                  selectedValue: borderStyle,
                  onSelected: onBorderStyleChanged,
                  segments: const [
                    SegmentData(
                        value: 'solid',
                        label: '━ Solid',
                        style: TextStyle(fontSize: UiFont.compact)),
                    SegmentData(
                        value: 'dashed',
                        label: '┅ Dash',
                        style: TextStyle(fontSize: UiFont.compact)),
                    SegmentData(
                        value: 'dotted',
                        label: '┈ Dot',
                        style: TextStyle(fontSize: UiFont.compact)),
                  ],
                ),
              ),
              const SizedBox(width: UiSpacing.standard),
              Expanded(
                flex: 1,
                child: GlassColorPillButton<Color?>(
                  label: 'color',
                  selectedValue: borderColor,
                  activeColor: accentColor,
                  onSelected: (val) {
                    onBorderColorChanged(val);
                    final nodeIds =
                        _getSelectedNodes(effectiveRenderState).map((n) => n.id).toList();
                    if (nodeIds.isNotEmpty) {
                      final strokeInt =
                          _computeNodeStrokeColor(theme, val, borderOpacity);
                      effectiveRenderState.updateNodesStyle(
                          nodeIds, (s) => s.copyWith(strokeColor: strokeInt));
                    }
                  },
                  options: const [
                    ColorPillOption(
                        value: null, label: 'Accent', isNone: true),
                    ColorPillOption(
                        value: Colors.white,
                        color: Colors.white,
                        label: 'White'),
                    ColorPillOption(
                        value: Color(0xFF00E5FF),
                        color: Color(0xFF00E5FF),
                        label: 'Cyan'),
                    ColorPillOption(
                        value: Color(0xFFFFB703),
                        color: Color(0xFFFFB703),
                        label: 'Amber'),
                    ColorPillOption(
                        value: Color(0xFFFF007A),
                        color: Color(0xFFFF007A),
                        label: 'Pink'),
                    ColorPillOption(
                        value: Color(0xFF00FF66),
                        color: Color(0xFF00FF66),
                        label: 'Emerald'),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: UiSpacing.tight),

          Row(
            children: [
              Expanded(
                child: CompactSliderBox(
                  label: 'Thickness',
                  value: borderWidth,
                  min: 0,
                  max: 8,
                  unit: 'px',
                  activeColor: accentColor,
                  onChanged: (val) {
                    onBorderWidthChanged(val);
                    final nodeIds =
                        _getSelectedNodes(effectiveRenderState).map((n) => n.id).toList();
                    if (nodeIds.isNotEmpty) {
                      effectiveRenderState.updateNodesStyle(
                          nodeIds, (s) => s.copyWith(strokeWidth: val.round()));
                    }
                  },
                ),
              ),
              const SizedBox(width: UiSpacing.tight),
              Expanded(
                child: CompactSliderBox(
                  label: 'Opacity',
                  value: borderOpacity,
                  min: 0,
                  max: 100,
                  unit: '%',
                  activeColor: accentColor,
                  onChanged: (val) {
                    onBorderOpacityChanged(val);
                    final nodeIds =
                        _getSelectedNodes(effectiveRenderState).map((n) => n.id).toList();
                    if (nodeIds.isNotEmpty) {
                      final strokeInt =
                          _computeNodeStrokeColor(theme, borderColor, val);
                      effectiveRenderState.updateNodesStyle(
                          nodeIds, (s) => s.copyWith(strokeColor: strokeInt));
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
