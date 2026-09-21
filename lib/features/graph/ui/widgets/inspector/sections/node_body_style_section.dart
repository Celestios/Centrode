import 'package:centrode/shared/elements/elements.dart';
import 'package:flutter/material.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/shared/widgets/unravel_slider/unravel_slider.dart';
import '../components/sub_block_shell.dart';
import '../components/glass_color_pill_button.dart';
import '../components/compact_slider_box.dart';
import '../components/node_shape_definitions.dart';

class NodeBodyStyleSection extends StatelessWidget {
  final NodeRenderState renderState;
  final String nodeShape;
  final String fillStyle;
  final Color? fillTint;
  final double opacity;
  final double cornerRadius;
  final Color accentColor;
  final int selectedShapeIndex;
  final ValueChanged<String> onShapeChanged;
  final ValueChanged<String> onFillStyleChanged;
  final ValueChanged<Color?> onFillTintChanged;
  final ValueChanged<double> onOpacityChanged;
  final ValueChanged<double> onCornerRadiusChanged;
  final VoidCallback onReset;

  const NodeBodyStyleSection({
    super.key,
    required this.renderState,
    required this.nodeShape,
    required this.fillStyle,
    this.fillTint,
    required this.opacity,
    required this.cornerRadius,
    required this.accentColor,
    required this.selectedShapeIndex,
    required this.onShapeChanged,
    required this.onFillStyleChanged,
    required this.onFillTintChanged,
    required this.onOpacityChanged,
    required this.onCornerRadiusChanged,
    required this.onReset,
  });

  List<UiNode> _getSelectedNodes(NodeRenderState rs) {
    return rs.selectedEntities
        .map((id) => rs.getNode(id))
        .whereType<UiNode>()
        .toList();
  }

  List<ColorPillOption<Color?>> _buildGlassColorOptions(
    BuildContext context,
    Color primaryAccent,
  ) {
    final swatches = CentrodeDerivedPalette.of(context).swatches;
    return [
      const ColorPillOption(value: null, label: 'Auto (Glass)', isNone: true),
      ColorPillOption(value: primaryAccent, color: primaryAccent, label: 'Accent'),
      ...swatches.take(6).map((c) => ColorPillOption(
            value: c,
            color: c,
            label: ColorTheoryEngine.toHex(c),
          )),
    ];
  }

  int _computeNodeBgColor(ThemeData theme, double localOpacity, String localFillStyle, Color? localFillTint) {
    final base = localFillTint ?? theme.cardColor;
    if (localFillStyle == 'solid') {
      return base.withValues(alpha: (localOpacity / 100).clamp(0.05, 1.0)).toARGB32();
    } else if (localFillStyle == 'glass') {
      return base
          .withValues(alpha: (0.5 * (localOpacity / 100)).clamp(0.05, 0.95))
          .toARGB32();
    } else {
      return 0x00000000;
    }
  }

  @override
  Widget build(BuildContext context) {
    final effectiveRenderState = renderState;
    final theme = Theme.of(context);

    return SubBlockShell(
      title: 'Body',
      accentColor: accentColor,
      onReset: onReset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 6.0),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return SizedBox(
                  width: constraints.maxWidth,
                  child: UnravelSlider<NodeShapeDefinition>(
                    trackWidth: constraints.maxWidth,
                    items: kAvailableNodeShapes,
                    selectedIndex: selectedShapeIndex,
                    onSelected: (idx) {
                      final newShape = kAvailableNodeShapes[idx].id;
                      onShapeChanged(newShape);
                      final nodeIds =
                          _getSelectedNodes(effectiveRenderState).map((n) => n.id).toList();
                      if (nodeIds.isNotEmpty) {
                        effectiveRenderState.updateNodesStyle(
                            nodeIds, (s) => s.copyWith(shape: newShape));
                      }
                    },
                    theme: UnravelSliderThemeData(
                      accentColor: accentColor,
                      cellWidth: 60.0,
                      cellHeight: 46.0,
                      trackBorderRadius:
                          const BorderRadius.all(Radius.circular(8)),
                      handleBorderRadius:
                          const BorderRadius.all(Radius.circular(6)),
                      trackBackgroundColor:
                          CentrodeDerivedPalette.of(context).surface.controlBackground,
                    ),
                    itemBuilder: (context, item, focus, isSelected) {
                      final iconColor = isSelected
                          ? accentColor
                          : theme.textTheme.bodyMedium?.color
                                  ?.withValues(
                                      alpha: (0.35 + 0.65 * focus)
                                          .clamp(0.0, 1.0)) ??
                              Colors.white70;
                      return Center(
                        child: NodeShapeVectorIcon(
                          shape: item.id,
                          color: iconColor,
                          size: 32.0 + (focus * 8.0),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),

          Row(
            children: [
              Expanded(
                flex: 2,
                child: CentrodeSegmentedControl<String>(
                  items: const [
                    (icon: Icons.circle, label: 'Solid', mode: 'solid', tooltip: null, accentBadge: null),
                    (icon: Icons.circle_outlined, label: 'Glass', mode: 'glass', tooltip: null, accentBadge: null),
                    (icon: Icons.rectangle_outlined, label: 'Outline', mode: 'outline', tooltip: null, accentBadge: null),
                  ],
                  currentMode: fillStyle,
                  isCompact: false,
                  onSelected: (val) {
                    onFillStyleChanged(val);
                    final nodeIds =
                        _getSelectedNodes(effectiveRenderState).map((n) => n.id).toList();
                    if (nodeIds.isNotEmpty) {
                      final bgInt =
                          _computeNodeBgColor(theme, opacity, val, fillTint);
                      effectiveRenderState.updateNodesStyle(
                          nodeIds, (s) => s.copyWith(bgColor: bgInt));
                    }
                  },
                ),
              ),
              const SizedBox(width: UiSpacing.standard),
              Expanded(
                flex: 1,
                child: GlassColorPillButton<Color?>(
                  label: 'tint',
                  selectedValue: fillTint,
                  activeColor: accentColor,
                  onSelected: (val) {
                    onFillTintChanged(val);
                    final nodeIds =
                        _getSelectedNodes(effectiveRenderState).map((n) => n.id).toList();
                    if (nodeIds.isNotEmpty) {
                      final bgInt =
                          _computeNodeBgColor(theme, opacity, fillStyle, val);
                      effectiveRenderState.updateNodesStyle(
                          nodeIds, (s) => s.copyWith(bgColor: bgInt));
                    }
                  },
                  options: _buildGlassColorOptions(context, accentColor),
                ),
              ),
            ],
          ),

          const SizedBox(height: UiSpacing.tight),

          Row(
            children: [
              Expanded(
                child: CompactSliderBox(
                  label: 'Opacity',
                  value: opacity,
                  min: 10,
                  max: 100,
                  unit: '%',
                  activeColor: accentColor,
                  onChanged: (val) {
                    onOpacityChanged(val);
                    final nodeIds =
                        _getSelectedNodes(effectiveRenderState).map((n) => n.id).toList();
                    if (nodeIds.isNotEmpty) {
                      final bgInt =
                          _computeNodeBgColor(theme, val, fillStyle, fillTint);
                      effectiveRenderState.updateNodesStyle(
                          nodeIds, (s) => s.copyWith(bgColor: bgInt));
                    }
                  },
                ),
              ),
              const SizedBox(width: UiSpacing.tight),
              Expanded(
                child: CompactSliderBox(
                  label: 'Radius',
                  value: cornerRadius,
                  min: 0,
                  max: 24,
                  unit: 'px',
                  activeColor: accentColor,
                  onChanged: (val) {
                    onCornerRadiusChanged(val);
                    final nodeIds =
                        _getSelectedNodes(effectiveRenderState).map((n) => n.id).toList();
                    if (nodeIds.isNotEmpty) {
                      effectiveRenderState.updateNodesStyle(
                          nodeIds, (s) => s.copyWith(borderRadius: val));
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
