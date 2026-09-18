import 'package:centrode/shared/elements/elements.dart';
import 'package:flutter/material.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/features/graph/models/models.dart';
import '../components/sub_block_shell.dart';
import '../components/segmented_glass_switcher.dart';
import '../components/glass_color_pill_button.dart';
import '../components/compact_slider_box.dart';

class NodeShadowSection extends StatelessWidget {
  final NodeRenderState renderState;
  final String shadowMode;
  final double shadowBlur;
  final double shadowDistance;
  final Color? shadowColor;
  final Color accentColor;
  final ValueChanged<String> onShadowModeChanged;
  final ValueChanged<double> onShadowBlurChanged;
  final ValueChanged<double> onShadowDistanceChanged;
  final ValueChanged<Color?> onShadowColorChanged;
  final VoidCallback onReset;

  const NodeShadowSection({
    super.key,
    required this.renderState,
    required this.shadowMode,
    required this.shadowBlur,
    required this.shadowDistance,
    this.shadowColor,
    required this.accentColor,
    required this.onShadowModeChanged,
    required this.onShadowBlurChanged,
    required this.onShadowDistanceChanged,
    required this.onShadowColorChanged,
    required this.onReset,
  });

  List<UiNode> _getSelectedNodes(NodeRenderState rs) {
    return rs.selectedEntities
        .map((id) => rs.getNode(id))
        .whereType<UiNode>()
        .toList();
  }

  int _computeNodeShadowColor(ThemeData theme, String localShadowMode, Color? localShadowColor) {
    if (localShadowMode == 'none') return 0x00000000;
    final base = localShadowColor ??
        (localShadowMode == 'glow' ? theme.colorScheme.primary : Colors.black);
    return base.toARGB32();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRenderState = renderState;
    final theme = Theme.of(context);

    return SubBlockShell(
      title: 'Shadow & Glow',
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
                  selectedValue: shadowMode,
                  onSelected: (val) {
                    onShadowModeChanged(val);
                    final nodeIds =
                        _getSelectedNodes(effectiveRenderState).map((n) => n.id).toList();
                    if (nodeIds.isNotEmpty) {
                      final shadowInt =
                          _computeNodeShadowColor(theme, val, shadowColor);
                      final blur = val == 'none' ? 0.0 : shadowBlur;
                      final dy = (val == 'none' || val == 'glow')
                          ? 0.0
                          : shadowDistance;
                      effectiveRenderState.updateNodesStyle(
                        nodeIds,
                        (s) => s.copyWith(
                          shadowColor: shadowInt,
                          shadowBlur: blur,
                          shadowOffsetY: dy,
                          shadowOffsetX: 0.0,
                        ),
                      );
                    }
                  },
                  segments: const [
                    SegmentData(value: 'none', label: 'None'),
                    SegmentData(value: 'soft', label: 'Soft'),
                    SegmentData(value: 'crisp', label: 'Hard'),
                    SegmentData(value: 'glow', label: 'Glow'),
                  ],
                ),
              ),
              const SizedBox(width: UiSpacing.standard),
              Expanded(
                flex: 1,
                child: GlassColorPillButton<Color?>(
                  label: 'glow',
                  selectedValue: shadowColor,
                  activeColor: accentColor,
                  onSelected: (val) {
                    onShadowColorChanged(val);
                    final nodeIds =
                        _getSelectedNodes(effectiveRenderState).map((n) => n.id).toList();
                    if (nodeIds.isNotEmpty) {
                      final shadowInt =
                          _computeNodeShadowColor(theme, shadowMode, val);
                      effectiveRenderState.updateNodesStyle(
                          nodeIds, (s) => s.copyWith(shadowColor: shadowInt));
                    }
                  },
                  options: const [
                    ColorPillOption(
                        value: null, label: 'Accent', isNone: true),
                    ColorPillOption(
                        value: Color(0xFF00E5FF),
                        color: Color(0xFF00E5FF),
                        label: 'Cyan'),
                    ColorPillOption(
                        value: Color(0xFFFFB703),
                        color: Color(0xFFFFB703),
                        label: 'Amber'),
                    ColorPillOption(
                        value: Color(0xFF10B981),
                        color: Color(0xFF10B981),
                        label: 'Emerald'),
                    ColorPillOption(
                        value: Color(0xFFA855F7),
                        color: Color(0xFFA855F7),
                        label: 'Purple'),
                    ColorPillOption(
                        value: Color(0xFFFF007A),
                        color: Color(0xFFFF007A),
                        label: 'Pink'),
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
                  label: 'Blur',
                  value: shadowBlur,
                  min: 0,
                  max: 32,
                  unit: 'px',
                  activeColor: accentColor,
                  onChanged: (val) {
                    onShadowBlurChanged(val);
                    final nodeIds =
                        _getSelectedNodes(effectiveRenderState).map((n) => n.id).toList();
                    if (nodeIds.isNotEmpty) {
                      effectiveRenderState.updateNodesStyle(
                          nodeIds, (s) => s.copyWith(shadowBlur: val));
                    }
                  },
                ),
              ),
              const SizedBox(width: UiSpacing.tight),
              Expanded(
                child: CompactSliderBox(
                  label: 'Distance',
                  value: shadowDistance,
                  min: 0,
                  max: 16,
                  unit: 'px',
                  activeColor: accentColor,
                  onChanged: (val) {
                    onShadowDistanceChanged(val);
                    final nodeIds =
                        _getSelectedNodes(effectiveRenderState).map((n) => n.id).toList();
                    if (nodeIds.isNotEmpty) {
                      effectiveRenderState.updateNodesStyle(
                          nodeIds, (s) => s.copyWith(shadowOffsetY: val));
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
