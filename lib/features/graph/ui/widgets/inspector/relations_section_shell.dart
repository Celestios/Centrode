import 'package:centrode/shared/elements/elements.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/shared/widgets/unravel_slider/unravel_slider.dart';
import 'components/glass_section_shell.dart';
import 'components/sub_block_shell.dart';
import 'components/compact_slider_box.dart';
import 'components/glass_color_pill_button.dart';
import 'components/relation_shape_definitions.dart';
import 'showcase/relation_showcase_card.dart';

class RelationsSectionShell extends StatefulWidget {
  final bool isGlobal;
  final int selectedCount;
  final NodeRenderState? renderState;

  const RelationsSectionShell({
    super.key,
    this.isGlobal = true,
    this.selectedCount = 0,
    this.renderState,
  });

  @override
  State<RelationsSectionShell> createState() => _RelationsSectionShellState();
}

class _RelationsSectionShellState extends State<RelationsSectionShell> {
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

  String? _lastSelectionSignature;

  NodeRenderState _getRenderState(BuildContext context) =>
      widget.renderState ?? context.watch<NodeRenderState>();

  List<UiRelation> _getSelectedRelations(NodeRenderState rs) {
    return rs.selectedEntities
        .where((id) => rs.relationLookup.containsKey(id))
        .map((id) => rs.relationLookup[id]!)
        .toList();
  }

  void _syncFromSelection(List<UiRelation> relations) {
    if (relations.isEmpty) return;
    if (relations.length > 1) return;

    final rel = relations.first;
    final style = rel.style ?? rel.resolvedStyle;
    if (style != null) {
      _selectedShape = style.bodyStrategy.isNotEmpty ? style.bodyStrategy : 'capsule';
      _selectedFill = style.bodyStrategy.isNotEmpty ? style.bodyStrategy : 'glass';
      if (style.bgColor != 0) {
        final col = Color(style.bgColor);
        final alphaVal = ((style.bgColor >> 24) & 0xFF);
        if (alphaVal > 0) {
          _labelBgColor = col.withAlpha(255);
        } else {
          _labelBgColor = null;
        }
      } else {
        _labelBgColor = null;
      }
      _strokeWidth = style.strokeWidth.toDouble().clamp(0.5, 8.0);
      if (style.strokeColor != 0) {
        _lineColor = Color(style.strokeColor).withAlpha(255);
      } else {
        _lineColor = null;
      }
      _selectedFont = style.fontFamily.isNotEmpty ? style.fontFamily : 'inter';
      _fontSize = style.fontSize > 0 ? style.fontSize : 11.0;
      _strokePattern = style.strokePattern.isNotEmpty ? style.strokePattern : 'solid';
      _routingStrategy = style.strategyType.isNotEmpty ? style.strategyType : 'curved';
    }

    final layout = rel.layout ?? rel.resolvedLayout;
    if (layout != null) {
      _startCap = 'none';
      _endCap = 'arrow';
    }
    if (style != null) {
      if (style.startShape != null) {
        _startCap = style.startShape!.name;
      }
      if (style.endShape != null) {
        _endCap = style.endShape!.name;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final effectiveRenderState = _getRenderState(context);

    final selectedRelations = _getSelectedRelations(effectiveRenderState);

    final currentSignature = selectedRelations.isEmpty
        ? '__EMPTY__'
        : selectedRelations
            .map((r) => '${r.id}_${r.style?.hashCode}')
            .join(';');

    if (_lastSelectionSignature != currentSignature) {
      _lastSelectionSignature = currentSignature;
      _syncFromSelection(selectedRelations);
    }

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
                CentrodeSegmentedControl<String>(
                  items: const [
                    (icon: Icons.circle_outlined, label: 'Capsule', mode: 'capsule', tooltip: null, accentBadge: null),
                    (icon: Icons.circle_outlined, label: 'Rounded', mode: 'rounded', tooltip: null, accentBadge: null),
                    (icon: Icons.square_outlined, label: 'Sharp', mode: 'sharp', tooltip: null, accentBadge: null),
                    (icon: Icons.close, label: 'None', mode: 'none', tooltip: null, accentBadge: null),
                  ],
                  currentMode: _selectedShape,
                  isCompact: false,
                  onSelected: (val) {
                    setState(() => _selectedShape = val);
                    for (final rel in selectedRelations) {
                      final currentStyle = rel.style ?? rel.resolvedStyle;
                      if (currentStyle != null) {
                        effectiveRenderState.updateRelationStyle(
                          rel.id,
                          currentStyle.copyWith(bodyStrategy: val),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: UiSpacing.tight),
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
                        currentMode: _selectedFill,
                        isCompact: false,
                        onSelected: (val) {
                          setState(() => _selectedFill = val);
                          for (final rel in selectedRelations) {
                            final currentStyle = rel.style ?? rel.resolvedStyle;
                            if (currentStyle != null) {
                              effectiveRenderState.updateRelationStyle(
                                rel.id,
                                currentStyle.copyWith(bodyStrategy: val),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: UiSpacing.standard),
                    Expanded(
                      flex: 1,
                      child: GlassColorPillButton<Color?>(
                        label: 'bg',
                        selectedValue: _labelBgColor,
                        activeColor: primaryAccent,
                        onSelected: (val) {
                          setState(() => _labelBgColor = val);
                          for (final rel in selectedRelations) {
                            final currentStyle = rel.style ?? rel.resolvedStyle;
                            if (currentStyle != null) {
                              effectiveRenderState.updateRelationStyle(
                                rel.id,
                                currentStyle.copyWith(
                                  bgColor: (val ?? primaryAccent).toARGB32(),
                                ),
                              );
                            }
                          }
                        },
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
                const SizedBox(height: UiSpacing.tight),
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
                    const SizedBox(width: UiSpacing.tight),
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
                      child: CentrodeSegmentedControl<String>(
                        items: const [
                          (icon: Icons.font_download, label: 'Inter', mode: 'inter', tooltip: null, accentBadge: null),
                          (icon: Icons.font_download, label: 'Outfit', mode: 'outfit', tooltip: null, accentBadge: null),
                          (icon: Icons.font_download, label: 'Mono', mode: 'mono', tooltip: null, accentBadge: null),
                        ],
                        currentMode: _selectedFont,
                        isCompact: false,
                        onSelected: (val) {
                          setState(() => _selectedFont = val);
                          for (final rel in selectedRelations) {
                            final currentStyle = rel.style ?? rel.resolvedStyle;
                            if (currentStyle != null) {
                              effectiveRenderState.updateRelationStyle(
                                rel.id,
                                currentStyle.copyWith(fontFamily: val),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: UiSpacing.tight),
                    Expanded(
                      flex: 1,
                      child: CompactSliderBox(
                        label: 'Size',
                        value: _fontSize,
                        min: 8,
                        max: 20,
                        unit: 'pt',
                        activeColor: primaryAccent,
                        onChanged: (val) {
                          setState(() => _fontSize = val);
                          for (final rel in selectedRelations) {
                            final currentStyle = rel.style ?? rel.resolvedStyle;
                            if (currentStyle != null) {
                              effectiveRenderState.updateRelationStyle(
                                rel.id,
                                currentStyle.copyWith(fontSize: val),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

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
                            final newStrategy = kAvailableRoutingStrategies[idx].id;
                            setState(() => _routingStrategy = newStrategy);
                            for (final rel in selectedRelations) {
                              final currentStyle = rel.style ?? rel.resolvedStyle;
                              if (currentStyle != null) {
                                effectiveRenderState.updateRelationStyle(
                                  rel.id,
                                  currentStyle.copyWith(strategyType: newStrategy),
                                );
                              }
                            }
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
                                size: UiIconSize.header + (focus * 8.0),
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
                      child: CentrodeSegmentedControl<String>(
                        items: const [
                          (icon: Icons.horizontal_rule, label: 'Solid', mode: 'solid', tooltip: null, accentBadge: null),
                          (icon: Icons.linear_scale, label: 'Dash', mode: 'dashed', tooltip: null, accentBadge: null),
                          (icon: Icons.grain, label: 'Dot', mode: 'dotted', tooltip: null, accentBadge: null),
                        ],
                        currentMode: _strokePattern,
                        isCompact: false,
                        onSelected: (val) {
                          setState(() => _strokePattern = val);
                          for (final rel in selectedRelations) {
                            final currentStyle = rel.style ?? rel.resolvedStyle;
                            if (currentStyle != null) {
                              effectiveRenderState.updateRelationStyle(
                                rel.id,
                                currentStyle.copyWith(strokePattern: val),
                              );
                            }
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: UiSpacing.standard),
                    Expanded(
                      flex: 1,
                      child: GlassColorPillButton<Color?>(
                        label: 'color',
                        selectedValue: _lineColor,
                        activeColor: primaryAccent,
                        onSelected: (val) {
                          setState(() => _lineColor = val);
                          for (final rel in selectedRelations) {
                            final currentStyle = rel.style ?? rel.resolvedStyle;
                            if (currentStyle != null) {
                              effectiveRenderState.updateRelationStyle(
                                rel.id,
                                currentStyle.copyWith(
                                  strokeColor: (val ?? primaryAccent).toARGB32(),
                                ),
                              );
                            }
                          }
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
                        currentMode: _startCap,
                        isCompact: false,
                        onSelected: (val) => setState(() => _startCap = val),
                      ),
                    ),
                    const SizedBox(width: UiSpacing.tight),
                    Expanded(
                      child: CentrodeSegmentedControl<String>(
                        items: const [
                          (icon: Icons.arrow_forward, label: 'Arrow', mode: 'arrow', tooltip: null, accentBadge: null),
                          (icon: Icons.diamond, label: 'Diamond', mode: 'diamond', tooltip: null, accentBadge: null),
                        ],
                        currentMode: _endCap,
                        isCompact: false,
                        onSelected: (val) => setState(() => _endCap = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: UiSpacing.tight),
                CompactSliderBox(
                  label: 'Width',
                  value: _strokeWidth,
                  min: 0.5,
                  max: 8.0,
                  unit: 'px',
                  activeColor: primaryAccent,
                  onChanged: (val) {
                    setState(() => _strokeWidth = val);
                    for (final rel in selectedRelations) {
                      final currentStyle = rel.style ?? rel.resolvedStyle;
                      if (currentStyle != null) {
                        effectiveRenderState.updateRelationStyle(
                          rel.id,
                          currentStyle.copyWith(strokeWidth: val.round()),
                        );
                      }
                    }
                  },
                ),
              ],
            ),
          ),

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
                CentrodeSegmentedControl<String>(
                  items: const [
                    (icon: Icons.route, label: 'Arc Bridge', mode: 'bridge', tooltip: null, accentBadge: null),
                    (icon: Icons.cut, label: 'Break Gap', mode: 'break', tooltip: null, accentBadge: null),
                    (icon: Icons.merge, label: 'Pass-Through', mode: 'blend', tooltip: null, accentBadge: null),
                  ],
                  currentMode: _crossingStrategy,
                  isCompact: false,
                  onSelected: (val) => setState(() => _crossingStrategy = val),
                ),
                const SizedBox(height: UiSpacing.tight),
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
