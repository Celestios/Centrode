import 'package:centrode/shared/theme/design_tokens.dart';
import 'package:centrode/shared/elements/elements.dart';
import 'package:centrode/shared/utils/color_theory_engine.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/engine/config.dart';
import 'package:centrode/features/graph/ui/canvas/text/text_format_models.dart';
import 'package:centrode/shared/widgets/unravel_slider/unravel_slider.dart';
import 'components/glass_section_shell.dart';
import 'components/sub_block_shell.dart';
import 'components/segmented_glass_switcher.dart';
import 'components/glass_dropdown.dart';
import 'components/square_icon_group.dart';
import 'components/glass_color_pill_button.dart';
import 'components/font_size_unravel_picker.dart';
import 'components/compact_slider_box.dart';
import 'components/node_shape_definitions.dart';
import 'showcase/node_showcase_card.dart';

/// Dynamic Top-Level Nodes Section Container.
class NodesSectionShell extends StatefulWidget {
  final bool isGlobal;
  final int selectedCount;
  final NodeRenderState? renderState;

  const NodesSectionShell({
    super.key,
    this.isGlobal = true,
    this.selectedCount = 0,
    this.renderState,
  });

  @override
  State<NodesSectionShell> createState() => _NodesSectionShellState();
}

class _NodesSectionShellState extends State<NodesSectionShell> {
  static const Map<String, int?> _highlightColorMap = {
    'none': null,
    'yellow': 0xFFFFE600,
    'cyan': 0xFF00E5FF,
    'green': 0xFF00FF66,
    'pink': 0xFFFF007A,
    'orange': 0xFFFF8800,
  };

  // State variables for Text formatting (Subsection 1)
  String _fontFamily = 'outfit';
  double _fontSize = 13.0;
  Color _textColor = Colors.white;
  String _highlightColor = 'none';
  Color? _nodeBgColor;
  bool _isBold = false;
  bool _isItalic = false;
  bool _isStrikethrough = false;
  String _letterCase = 'normal';
  double _letterSpacing = 0.0;
  double _lineHeight = 1.2;
  bool _hasUnderline = false;
  String _underlineStyle = 'solid';
  Color _underlineColor = const Color(0xFF00E5FF);
  String _textAlign = 'center';
  TextDirection _textDirection = TextDirection.ltr;

  // State variables for Body (Subsection 2)
  String _nodeShape = 'rounded';
  String _fillStyle = 'glass';
  Color? _fillTint;
  double _opacity = 85.0;
  double _cornerRadius = 12.0;

  // State variables for Border (Subsection 3)
  double _borderWidth = 1.5;
  String _borderStyle = 'solid';
  double _borderOpacity = 60.0;
  Color? _borderColor;

  // State variables for Shadow & Glow (Subsection 4)
  String _shadowMode = 'none';
  double _shadowBlur = 14.0;
  double _shadowDistance = 4.0;
  Color? _shadowColor;

  String? _lastSelectionSignature;

  NodeRenderState _getRenderState(BuildContext context) =>
      widget.renderState ?? context.watch<NodeRenderState>();

  List<UiNode> _getSelectedNodes(NodeRenderState renderState) {
    return renderState.selectedEntities
        .map((id) => renderState.getNode(id))
        .whereType<UiNode>()
        .toList();
  }

  bool _areNodeAppearancesEqual(List<UiNode> nodes) {
    if (nodes.isEmpty) return true;
    final firstStyle = nodes.first.style;
    for (int i = 1; i < nodes.length; i++) {
      final s = nodes[i].style;
      if (firstStyle != s) {
        if (firstStyle == null || s == null) return false;
        if (firstStyle.shape != s.shape ||
            firstStyle.fontFamily != s.fontFamily ||
            firstStyle.fontSize != s.fontSize ||
            firstStyle.textColor != s.textColor ||
            firstStyle.bgColor != s.bgColor ||
            firstStyle.borderRadius != s.borderRadius ||
            firstStyle.strokeWidth != s.strokeWidth ||
            firstStyle.strokeColor != s.strokeColor ||
            firstStyle.shadowBlur != s.shadowBlur ||
            firstStyle.shadowColor != s.shadowColor ||
            firstStyle.shadowOffsetY != s.shadowOffsetY) {
          return false;
        }
      }
    }
    return true;
  }

  void _syncFromSelection(List<UiNode> nodes, ThemeData theme) {
    if (nodes.isEmpty) {
      _resetToDefaults(theme);
      return;
    }

    if (nodes.length > 1 && !_areNodeAppearancesEqual(nodes)) {
      // Multiple nodes with different presets: keep state as-is
      return;
    }

    final node = nodes.first;
    final style = node.style;
    if (style != null) {
      // Text
      _fontFamily = style.fontFamily.isNotEmpty ? style.fontFamily : 'outfit';
      _fontSize = style.fontSize > 0 ? style.fontSize : 13.0;
      _textColor = style.textColor != 0 ? Color(style.textColor) : Colors.white;

      // Body
      _nodeShape = style.shape.isNotEmpty ? style.shape : 'rounded';
      _cornerRadius = style.borderRadius >= 0 ? style.borderRadius : 12.0;
      if (style.bgColor == 0) {
        _fillStyle = 'outline';
        _nodeBgColor = null;
        _fillTint = null;
      } else {
        final col = Color(style.bgColor);
        final alphaVal = ((style.bgColor >> 24) & 0xFF);
        _opacity = (alphaVal / 255.0 * 100).clamp(10.0, 100.0);
        _nodeBgColor = col.withAlpha(255);
        _fillTint = col.withAlpha(255);
        _fillStyle = alphaVal < 240 ? 'glass' : 'solid';
      }

      // Border
      _borderWidth = style.strokeWidth.toDouble();
      if (style.strokeColor != 0) {
        final sc = Color(style.strokeColor);
        final sAlpha = ((style.strokeColor >> 24) & 0xFF);
        _borderOpacity = (sAlpha / 255.0 * 100).clamp(0.0, 100.0);
        _borderColor = sc.withAlpha(255);
      } else {
        _borderColor = null;
        _borderOpacity = 60.0;
      }

      // Shadow
      _shadowBlur = style.shadowBlur;
      _shadowDistance = style.shadowOffsetY;
      if (style.shadowColor != 0) {
        _shadowColor = Color(style.shadowColor);
        if (_shadowDistance == 0 && _shadowBlur > 0) {
          _shadowMode = 'glow';
        } else if (_shadowBlur <= 6 && _shadowBlur > 0) {
          _shadowMode = 'crisp';
        } else if (_shadowBlur > 6) {
          _shadowMode = 'soft';
        } else {
          _shadowMode = 'none';
        }
      } else {
        _shadowColor = null;
        _shadowMode = 'none';
      }
    }

    // Text formatting from content
    final content = node.content;
    if (content.blocks.isNotEmpty) {
      final firstBlock = content.blocks.first;
      _textAlign = firstBlock.attrs?.textAlign ?? 'center';
      final allInlines = content.blocks.expand((b) => b.content);
      _isBold = allInlines.any((i) => i.marks?.any((m) => m.markType == MarkType.bold) == true);
      _isItalic = allInlines.any((i) => i.marks?.any((m) => m.markType == MarkType.italic) == true);
      _hasUnderline = allInlines.any((i) => i.marks?.any((m) => m.markType == MarkType.underline) == true);
      _isStrikethrough = allInlines.any((i) => i.marks?.any((m) => m.markType == MarkType.strikethrough) == true);

      TextMark? hlMark;
      for (final inline in allInlines) {
        if (inline.marks != null) {
          for (final m in inline.marks!) {
            if (m.markType == MarkType.highlight) {
              hlMark = m;
              break;
            }
          }
          if (hlMark != null) break;
        }
      }

      if (hlMark?.attrs?.color != null) {
        final c = hlMark!.attrs!.color!;
        _highlightColor = _highlightColorMap.entries
            .firstWhere(
              (e) => e.value == c,
              orElse: () => const MapEntry('none', null),
            )
            .key;
      } else {
        _highlightColor = 'none';
      }
    }
  }

  void _resetToDefaults(ThemeData theme) {
    _fontFamily = 'outfit';
    _fontSize = 13.0;
    _textColor = Colors.white;
    _highlightColor = 'none';
    _nodeBgColor = null;
    _isBold = false;
    _isItalic = false;
    _isStrikethrough = false;
    _letterCase = 'normal';
    _letterSpacing = 0.0;
    _lineHeight = 1.2;
    _hasUnderline = false;
    _underlineStyle = 'solid';
    _underlineColor = const Color(0xFF00E5FF);
    _textAlign = 'center';
    _textDirection = TextDirection.ltr;
    _nodeShape = 'rounded';
    _fillStyle = 'glass';
    _fillTint = null;
    _opacity = 85.0;
    _cornerRadius = 12.0;
    _borderWidth = 1.5;
    _borderStyle = 'solid';
    _borderOpacity = 60.0;
    _borderColor = null;
    _shadowMode = 'none';
    _shadowBlur = 14.0;
    _shadowDistance = 4.0;
    _shadowColor = null;
  }

  int _computeNodeBgColor(ThemeData theme) {
    final base = _fillTint ?? _nodeBgColor ?? theme.cardColor;
    if (_fillStyle == 'solid') {
      return base.withValues(alpha: (_opacity / 100).clamp(0.05, 1.0)).toARGB32();
    } else if (_fillStyle == 'glass') {
      return base.withValues(alpha: (0.5 * (_opacity / 100)).clamp(0.05, 0.95)).toARGB32();
    } else {
      return 0x00000000;
    }
  }

  int _computeNodeStrokeColor(ThemeData theme) {
    final base = _borderColor ?? theme.colorScheme.primary;
    return base.withValues(alpha: (_borderOpacity / 100).clamp(0.0, 1.0)).toARGB32();
  }

  int _computeNodeShadowColor(ThemeData theme) {
    if (_shadowMode == 'none') return 0x00000000;
    final base = _shadowColor ?? (_shadowMode == 'glow' ? theme.colorScheme.primary : Colors.black);
    return base.toARGB32();
  }

  List<ColorPillOption<Color?>> _buildGlassColorOptions(BuildContext context, Color primaryAccent) {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;
    final effectiveRenderState = _getRenderState(context);

    final selectedNodes = _getSelectedNodes(effectiveRenderState);

    final currentSignature = selectedNodes.isEmpty
        ? '__EMPTY__'
        : selectedNodes
            .map((n) => '${n.id}_${n.style?.hashCode}_${n.content.hashCode}')
            .join(';');

    if (_lastSelectionSignature != currentSignature) {
      _lastSelectionSignature = currentSignature;
      _syncFromSelection(selectedNodes, theme);
    }

    final selectedShapeIndex = kAvailableNodeShapes
        .indexWhere((s) => s.id == _nodeShape)
        .clamp(0, kAvailableNodeShapes.length - 1);

    final badgeText = widget.isGlobal
        ? 'Global'
        : '${widget.selectedCount} Selected';

    return ShowcaseSectionShell(
      title: 'Node',
      icon: Icons.account_tree_rounded,
      accentColor: primaryAccent,
      badgeText: badgeText,
      showcase: NodeShowcaseCard(
        shape: _nodeShape,
        fillStyle: _fillStyle,
        opacity: _opacity,
        cornerRadius: _cornerRadius,
        borderStyle: _borderStyle,
        borderWidth: _borderWidth,
        borderOpacity: _borderOpacity,
        customBorderColor: _borderColor,
        fontFamily: _fontFamily,
        fontSize: _fontSize,
        textAlign: _textAlign,
        highlightColor: _highlightColor,
        textColor: _textColor,
        underlineStyle: _hasUnderline ? _underlineStyle : 'none',
        underlineColor: _underlineColor,
        textDirection: _textDirection,
        isBold: _isBold,
        isItalic: _isItalic,
        isStrikethrough: _isStrikethrough,
        letterCase: _letterCase,
        letterSpacing: _letterSpacing,
        lineHeight: _lineHeight,
        customBgColor: _fillTint ?? _nodeBgColor,
        shadowMode: _shadowMode,
        shadowBlur: _shadowBlur,
        shadowDistance: _shadowDistance,
        customShadowColor: _shadowColor,
        topicText: 'Topic',
        accentColor: primaryAccent,
      ),
      child: Column(
        children: [
          // Sub-block 1: Text Formatting (First Subsection)
          SubBlockShell(
            title: 'Text',
            accentColor: primaryAccent,
            onReset: () {
              setState(() {
                _fontFamily = 'outfit';
                _fontSize = 13.0;
                _textColor = Colors.white;
                _highlightColor = 'none';
                _nodeBgColor = null;
                _isBold = false;
                _isItalic = false;
                _isStrikethrough = false;
                _letterCase = 'normal';
                _letterSpacing = 0.0;
                _lineHeight = 1.2;
                _hasUnderline = false;
                _underlineStyle = 'solid';
                _underlineColor = const Color(0xFF00E5FF);
                _textAlign = 'center';
                _textDirection = TextDirection.ltr;
              });
              final rs = effectiveRenderState;
              final nodes = _getSelectedNodes(rs);
              final nodeIds = nodes.map((n) => n.id).toList();
              if (nodeIds.isNotEmpty) {
                rs.updateNodesStyle(
                  nodeIds,
                  (style) => style.copyWith(
                    fontFamily: 'outfit',
                    fontSize: 13.0,
                    textColor: Colors.white.toARGB32(),
                    bgColor: theme.cardColor.toARGB32(),
                  ),
                );
                for (final node in nodes) {
                  final resetContent = node.content.resetFormatting();
                  rs.commitEntityText(node.id, resetContent);
                }
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Font Family (flex: 1) + Font Size Unravel Picker Dropdown (72px)
                Row(
                  children: [
                    Expanded(
                      child: GlassDropdown<String>(
                        selectedValue: _fontFamily,
                        activeColor: primaryAccent,
                        height: UiControlSize.standard,
                        onSelected: (val) {
                          setState(() => _fontFamily = val);
                          final rs = effectiveRenderState;
                          final nodeIds = _getSelectedNodes(rs).map((n) => n.id).toList();
                          if (nodeIds.isNotEmpty) {
                            rs.updateNodesStyle(
                              nodeIds,
                              (style) => style.copyWith(fontFamily: val),
                            );
                            if (rs.activeEditId != null) {
                              rs.setFontFamilyCallback?.call(val);
                            }
                          }
                        },
                        items: const [
                          GlassDropdownItem(value: 'outfit', label: 'Outfit'),
                          GlassDropdownItem(value: 'inter', label: 'Inter'),
                          GlassDropdownItem(value: 'mono', label: 'JetBrains Mono'),
                          GlassDropdownItem(value: 'fira_code', label: 'Fira Code'),
                          GlassDropdownItem(value: 'roboto', label: 'Roboto'),
                          GlassDropdownItem(value: 'cinzel', label: 'Cinzel'),
                          GlassDropdownItem(value: 'caveat', label: 'Caveat'),
                        ],
                      ),
                    ),
                    const SizedBox(width: UiSpacing.standard),
                    FontSizeUnravelPicker(
                      fontSize: _fontSize,
                      activeColor: primaryAccent,
                      onChanged: (val) {
                        final clamped = val.clamp(AppConfig.node.minFontSize, AppConfig.node.maxFontSize);
                        setState(() => _fontSize = clamped);
                        final rs = effectiveRenderState;
                        final nodeIds = _getSelectedNodes(rs).map((n) => n.id).toList();
                        if (nodeIds.isNotEmpty) {
                          rs.updateNodesStyle(
                            nodeIds,
                            (style) => style.copyWith(fontSize: clamped),
                          );
                        }
                      },
                    ),
                  ],
                ),

                const SizedBox(height: UiSpacing.standard),

                // Row 2: Styles [ B | I | U | S ] (flex: 1) | Divider | Alignment [ Left | Center | Right | Justify ] (flex: 1)
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: SquareToggleButton(
                              label: 'B',
                              labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                              tooltip: 'Bold',
                              isActive: _isBold,
                              activeColor: primaryAccent,
                              onTap: () {
                                final next = !_isBold;
                                setState(() => _isBold = next);
                                final rs = effectiveRenderState;
                                if (rs.activeEditId != null) {
                                  rs.applyFormatCallback?.call(TextFormatType.bold);
                                }
                                for (final node in _getSelectedNodes(rs)) {
                                  final newContent = node.content.toggleMark(MarkType.bold, forceState: next);
                                  rs.commitEntityText(node.id, newContent);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: UiSpacing.tight),
                          Expanded(
                            child: SquareToggleButton(
                              label: 'I',
                              labelStyle: const TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
                              tooltip: 'Italic',
                              isActive: _isItalic,
                              activeColor: primaryAccent,
                              onTap: () {
                                final next = !_isItalic;
                                setState(() => _isItalic = next);
                                final rs = effectiveRenderState;
                                if (rs.activeEditId != null) {
                                  rs.applyFormatCallback?.call(TextFormatType.italic);
                                }
                                for (final node in _getSelectedNodes(rs)) {
                                  final newContent = node.content.toggleMark(MarkType.italic, forceState: next);
                                  rs.commitEntityText(node.id, newContent);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: UiSpacing.tight),
                          Expanded(
                            child: SquareToggleButton(
                              label: 'U',
                              labelStyle: const TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.w600),
                              tooltip: 'Underline',
                              isActive: _hasUnderline,
                              activeColor: primaryAccent,
                              onTap: () {
                                final next = !_hasUnderline;
                                setState(() => _hasUnderline = next);
                                final rs = effectiveRenderState;
                                if (rs.activeEditId != null) {
                                  rs.applyFormatCallback?.call(TextFormatType.underline);
                                }
                                for (final node in _getSelectedNodes(rs)) {
                                  final newContent = node.content.toggleMark(MarkType.underline, forceState: next);
                                  rs.commitEntityText(node.id, newContent);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: UiSpacing.tight),
                          Expanded(
                            child: SquareToggleButton(
                              label: 'S',
                              labelStyle: const TextStyle(decoration: TextDecoration.lineThrough, fontWeight: FontWeight.w600),
                              tooltip: 'Strikethrough',
                              isActive: _isStrikethrough,
                              activeColor: primaryAccent,
                              onTap: () {
                                final next = !_isStrikethrough;
                                setState(() => _isStrikethrough = next);
                                final rs = effectiveRenderState;
                                for (final node in _getSelectedNodes(rs)) {
                                  final newContent = node.content.toggleMark(MarkType.strikethrough, forceState: next);
                                  rs.commitEntityText(node.id, newContent);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: UiStrokeWidth.subtle,
                      height: 18,
                      margin: UiInsets.horizontalStandard,
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: SquareToggleButton(
                              icon: Icons.format_align_left_rounded,
                              tooltip: 'Align Left',
                              isActive: _textAlign == 'left',
                              activeColor: primaryAccent,
                              onTap: () {
                                setState(() => _textAlign = 'left');
                                final rs = effectiveRenderState;
                                for (final node in _getSelectedNodes(rs)) {
                                  final newContent = node.content.setTextAlign('left');
                                  rs.commitEntityText(node.id, newContent);
                                }
                                if (rs.activeEditId != null) {
                                  rs.currentTextAlignNotifier.value = TextAlign.left;
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: UiSpacing.tight),
                          Expanded(
                            child: SquareToggleButton(
                              icon: Icons.format_align_center_rounded,
                              tooltip: 'Align Center',
                              isActive: _textAlign == 'center',
                              activeColor: primaryAccent,
                              onTap: () {
                                setState(() => _textAlign = 'center');
                                final rs = effectiveRenderState;
                                for (final node in _getSelectedNodes(rs)) {
                                  final newContent = node.content.setTextAlign('center');
                                  rs.commitEntityText(node.id, newContent);
                                }
                                if (rs.activeEditId != null) {
                                  rs.currentTextAlignNotifier.value = TextAlign.center;
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: UiSpacing.tight),
                          Expanded(
                            child: SquareToggleButton(
                              icon: Icons.format_align_right_rounded,
                              tooltip: 'Align Right',
                              isActive: _textAlign == 'right',
                              activeColor: primaryAccent,
                              onTap: () {
                                setState(() => _textAlign = 'right');
                                final rs = effectiveRenderState;
                                for (final node in _getSelectedNodes(rs)) {
                                  final newContent = node.content.setTextAlign('right');
                                  rs.commitEntityText(node.id, newContent);
                                }
                                if (rs.activeEditId != null) {
                                  rs.currentTextAlignNotifier.value = TextAlign.right;
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: UiSpacing.tight),
                          Expanded(
                            child: SquareToggleButton(
                              icon: Icons.format_align_justify_rounded,
                              tooltip: 'Justify',
                              isActive: _textAlign == 'justify',
                              activeColor: primaryAccent,
                              onTap: () {
                                setState(() => _textAlign = 'justify');
                                final rs = effectiveRenderState;
                                for (final node in _getSelectedNodes(rs)) {
                                  final newContent = node.content.setTextAlign('justify');
                                  rs.commitEntityText(node.id, newContent);
                                }
                                if (rs.activeEditId != null) {
                                  rs.currentTextAlignNotifier.value = TextAlign.justify;
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: UiSpacing.standard),

                // Row 3: Visual Case Segmented Switcher (flex: 2) + Direction Buttons (flex: 1)
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SegmentedGlassSwitcher<String>(
                        height: UiControlSize.standard,
                        selectedValue: _letterCase,
                        activeColor: primaryAccent,
                        onSelected: (val) {
                          setState(() => _letterCase = val);
                          final rs = effectiveRenderState;
                          for (final node in _getSelectedNodes(rs)) {
                            final newContent = node.content.transformLetterCase(val);
                            rs.commitEntityText(node.id, newContent);
                          }
                        },
                        segments: const [
                          SegmentData(
                            value: 'normal',
                            label: 'Aa',
                            tooltip: 'Normal: Aa',
                            style: TextStyle(fontSize: UiFont.standard),
                          ),
                          SegmentData(
                            value: 'uppercase',
                            label: 'AA',
                            tooltip: 'UPPERCASE: AA',
                            style: TextStyle(fontSize: UiFont.standard),
                          ),
                          SegmentData(
                            value: 'lowercase',
                            label: 'aa',
                            tooltip: 'lowercase: aa',
                            style: TextStyle(fontSize: UiFont.standard),
                          ),
                          SegmentData(
                            value: 'capitalize',
                            label: 'Ab',
                            tooltip: 'Capitalize: Ab',
                            style: TextStyle(fontSize: UiFont.standard),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: UiSpacing.standard),
                    Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          Expanded(
                            child: SquareToggleButton(
                              label: 'LTR',
                              labelStyle: const TextStyle(fontSize: UiFont.compact, fontWeight: FontWeight.w600),
                              tooltip: 'Left to Right',
                              isActive: _textDirection == TextDirection.ltr,
                              activeColor: primaryAccent,
                              onTap: () => setState(() => _textDirection = TextDirection.ltr),
                            ),
                          ),
                          const SizedBox(width: UiSpacing.tight),
                          Expanded(
                            child: SquareToggleButton(
                              label: 'RTL',
                              labelStyle: const TextStyle(fontSize: UiFont.compact, fontWeight: FontWeight.w600),
                              tooltip: 'Right to Left',
                              isActive: _textDirection == TextDirection.rtl,
                              activeColor: primaryAccent,
                              onTap: () => setState(() => _textDirection = TextDirection.rtl),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: UiSpacing.standard),

                // Row 4: Three Flat Full-Width Color Swatch Pill Buttons [ text | mark | node bg ]
                Row(
                  children: [
                    Expanded(
                      child: GlassColorPillButton<Color>(
                        label: 'text',
                        selectedValue: _textColor,
                        activeColor: primaryAccent,
                        onSelected: (val) {
                          setState(() => _textColor = val);
                          final rs = effectiveRenderState;
                          final nodeIds = _getSelectedNodes(rs).map((n) => n.id).toList();
                          if (nodeIds.isNotEmpty) {
                            rs.updateNodesStyle(
                              nodeIds,
                              (style) => style.copyWith(textColor: val.toARGB32()),
                            );
                          }
                        },
                        options: [
                          const ColorPillOption(value: Colors.white, color: Colors.white, label: 'White'),
                          ColorPillOption(value: primaryAccent, color: primaryAccent, label: 'Accent'),
                          ...CentrodeDerivedPalette.of(context).swatches.take(6).map((c) => ColorPillOption(
                                value: c,
                                color: c,
                                label: ColorTheoryEngine.toHex(c),
                              )),
                        ],
                      ),
                    ),
                    const SizedBox(width: UiSpacing.standard),
                    Expanded(
                      child: GlassColorPillButton<String>(
                        label: 'mark',
                        selectedValue: _highlightColor,
                        activeColor: primaryAccent,
                        onSelected: (val) {
                          setState(() => _highlightColor = val);
                          final int? colorInt = _highlightColorMap[val];
                          final rs = effectiveRenderState;
                          for (final node in _getSelectedNodes(rs)) {
                            final newContent = node.content.setHighlightColor(colorInt);
                            rs.commitEntityText(node.id, newContent);
                          }
                          if (rs.activeEditId != null) {
                            final hexStr = colorInt != null
                                ? '#${colorInt.toRadixString(16).padLeft(8, '0').substring(2)}'
                                : null;
                            rs.toggleHighlightCallback?.call(colorUrl: hexStr);
                          }
                        },
                        options: const [
                          ColorPillOption(value: 'none', label: 'None', isNone: true),
                          ColorPillOption(value: 'yellow', color: Color(0xFFFFE600), label: 'Yellow'),
                          ColorPillOption(value: 'cyan', color: Color(0xFF00E5FF), label: 'Cyan'),
                          ColorPillOption(value: 'green', color: Color(0xFF00FF66), label: 'Green'),
                          ColorPillOption(value: 'pink', color: Color(0xFFFF007A), label: 'Pink'),
                          ColorPillOption(value: 'orange', color: Color(0xFFFF8800), label: 'Orange'),
                        ],
                      ),
                    ),
                    const SizedBox(width: UiSpacing.standard),
                    Expanded(
                      child: GlassColorPillButton<Color?>(
                        label: 'node bg',
                        selectedValue: _nodeBgColor,
                        activeColor: primaryAccent,
                        onSelected: (val) {
                          setState(() => _nodeBgColor = val);
                          final rs = effectiveRenderState;
                          final nodeIds = _getSelectedNodes(rs).map((n) => n.id).toList();
                          if (nodeIds.isNotEmpty) {
                            final bgInt = (val ?? theme.cardColor).toARGB32();
                            rs.updateNodesStyle(
                              nodeIds,
                              (style) => style.copyWith(bgColor: bgInt),
                            );
                          }
                        },
                        options: _buildGlassColorOptions(context, primaryAccent),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sub-block 2: Body Format
          SubBlockShell(
            title: 'Body',
            accentColor: primaryAccent,
            onReset: () {
              setState(() {
                _nodeShape = 'rounded';
                _fillStyle = 'glass';
                _fillTint = null;
                _opacity = 85.0;
                _cornerRadius = 12.0;
              });
              final rs = effectiveRenderState;
              final nodeIds = _getSelectedNodes(rs).map((n) => n.id).toList();
              if (nodeIds.isNotEmpty) {
                final bgInt = _computeNodeBgColor(theme);
                rs.updateNodesStyle(
                  nodeIds,
                  (style) => style.copyWith(
                    shape: 'rounded',
                    borderRadius: 12.0,
                    bgColor: bgInt,
                  ),
                );
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Row 1: Shapes Unravel Slider
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
                            setState(() {
                              _nodeShape = newShape;
                            });
                            final rs = effectiveRenderState;
                            final nodeIds = _getSelectedNodes(rs).map((n) => n.id).toList();
                            if (nodeIds.isNotEmpty) {
                              rs.updateNodesStyle(nodeIds, (s) => s.copyWith(shape: newShape));
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

                // Row 2: Fill Style Switcher (flex: 2) + Fill Color Pill (flex: 1)
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SegmentedGlassSwitcher<String>(
                        height: UiControlSize.standard,
                        activeColor: primaryAccent,
                        selectedValue: _fillStyle,
                        onSelected: (val) {
                          setState(() => _fillStyle = val);
                          final rs = effectiveRenderState;
                          final nodeIds = _getSelectedNodes(rs).map((n) => n.id).toList();
                          if (nodeIds.isNotEmpty) {
                            final bgInt = _computeNodeBgColor(theme);
                            rs.updateNodesStyle(nodeIds, (s) => s.copyWith(bgColor: bgInt));
                          }
                        },
                        segments: const [
                          SegmentData(value: 'solid', label: 'Solid'),
                          SegmentData(value: 'glass', label: 'Glass'),
                          SegmentData(value: 'outline', label: 'Outline'),
                        ],
                      ),
                    ),
                    const SizedBox(width: UiSpacing.standard),
                    Expanded(
                      flex: 1,
                      child: GlassColorPillButton<Color?>(
                        label: 'tint',
                        selectedValue: _fillTint,
                        activeColor: primaryAccent,
                        onSelected: (val) {
                          setState(() => _fillTint = val);
                          final rs = effectiveRenderState;
                          final nodeIds = _getSelectedNodes(rs).map((n) => n.id).toList();
                          if (nodeIds.isNotEmpty) {
                            final bgInt = _computeNodeBgColor(theme);
                            rs.updateNodesStyle(nodeIds, (s) => s.copyWith(bgColor: bgInt));
                          }
                        },
                        options: _buildGlassColorOptions(context, primaryAccent),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: UiSpacing.tight),

                // Row 3: Dual Compact Sliders (Opacity & Corner Radius)
                Row(
                  children: [
                    Expanded(
                      child: CompactSliderBox(
                        label: 'Opacity',
                        value: _opacity,
                        min: 10,
                        max: 100,
                        unit: '%',
                        activeColor: primaryAccent,
                        onChanged: (val) {
                          setState(() => _opacity = val);
                          final rs = effectiveRenderState;
                          final nodeIds = _getSelectedNodes(rs).map((n) => n.id).toList();
                          if (nodeIds.isNotEmpty) {
                            final bgInt = _computeNodeBgColor(theme);
                            rs.updateNodesStyle(nodeIds, (s) => s.copyWith(bgColor: bgInt));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: UiSpacing.tight),
                    Expanded(
                      child: CompactSliderBox(
                        label: 'Radius',
                        value: _cornerRadius,
                        min: 0,
                        max: 24,
                        unit: 'px',
                        activeColor: primaryAccent,
                        onChanged: (val) {
                          setState(() => _cornerRadius = val);
                          final rs = effectiveRenderState;
                          final nodeIds = _getSelectedNodes(rs).map((n) => n.id).toList();
                          if (nodeIds.isNotEmpty) {
                            rs.updateNodesStyle(nodeIds, (s) => s.copyWith(borderRadius: val));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sub-block 3: Border
          SubBlockShell(
            title: 'Border',
            accentColor: primaryAccent,
            onReset: () {
              setState(() {
                _borderWidth = 1.5;
                _borderStyle = 'solid';
                _borderOpacity = 60.0;
                _borderColor = null;
              });
              final rs = effectiveRenderState;
              final nodeIds = _getSelectedNodes(rs).map((n) => n.id).toList();
              if (nodeIds.isNotEmpty) {
                final strokeInt = _computeNodeStrokeColor(theme);
                rs.updateNodesStyle(
                  nodeIds,
                  (style) => style.copyWith(
                    strokeWidth: UiStrokeWidth.thick.toInt(),
                    strokeColor: strokeInt,
                  ),
                );
              }
            },
            child: Column(
              children: [
                // Row 1: Stroke Pattern Switcher (flex: 2) + Border Color Pill (flex: 1)
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SegmentedGlassSwitcher<String>(
                        height: UiControlSize.standard,
                        activeColor: primaryAccent,
                        selectedValue: _borderStyle,
                        onSelected: (val) => setState(() => _borderStyle = val),
                        segments: const [
                          SegmentData(value: 'solid', label: '━ Solid', style: TextStyle(fontSize: UiFont.compact)),
                          SegmentData(value: 'dashed', label: '┅ Dash', style: TextStyle(fontSize: UiFont.compact)),
                          SegmentData(value: 'dotted', label: '┈ Dot', style: TextStyle(fontSize: UiFont.compact)),
                        ],
                      ),
                    ),
                    const SizedBox(width: UiSpacing.standard),
                    Expanded(
                      flex: 1,
                      child: GlassColorPillButton<Color?>(
                        label: 'color',
                        selectedValue: _borderColor,
                        activeColor: primaryAccent,
                        onSelected: (val) {
                          setState(() => _borderColor = val);
                          final rs = effectiveRenderState;
                          final nodeIds = _getSelectedNodes(rs).map((n) => n.id).toList();
                          if (nodeIds.isNotEmpty) {
                            final strokeInt = _computeNodeStrokeColor(theme);
                            rs.updateNodesStyle(nodeIds, (s) => s.copyWith(strokeColor: strokeInt));
                          }
                        },
                        options: [
                          const ColorPillOption(value: null, label: 'Accent', isNone: true),
                          const ColorPillOption(value: Colors.white, color: Colors.white, label: 'White'),
                          const ColorPillOption(value: Color(0xFF00E5FF), color: Color(0xFF00E5FF), label: 'Cyan'),
                          const ColorPillOption(value: Color(0xFFFFB703), color: Color(0xFFFFB703), label: 'Amber'),
                          const ColorPillOption(value: Color(0xFFFF007A), color: Color(0xFFFF007A), label: 'Pink'),
                          const ColorPillOption(value: Color(0xFF00FF66), color: Color(0xFF00FF66), label: 'Emerald'),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: UiSpacing.tight),

                // Row 2: Dual Compact Sliders (Thickness & Border Opacity)
                Row(
                  children: [
                    Expanded(
                      child: CompactSliderBox(
                        label: 'Thickness',
                        value: _borderWidth,
                        min: 0,
                        max: 8,
                        unit: 'px',
                        activeColor: primaryAccent,
                        onChanged: (val) {
                          setState(() => _borderWidth = val);
                          final rs = effectiveRenderState;
                          final nodeIds = _getSelectedNodes(rs).map((n) => n.id).toList();
                          if (nodeIds.isNotEmpty) {
                            rs.updateNodesStyle(nodeIds, (s) => s.copyWith(strokeWidth: val.round()));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: UiSpacing.tight),
                    Expanded(
                      child: CompactSliderBox(
                        label: 'Opacity',
                        value: _borderOpacity,
                        min: 0,
                        max: 100,
                        unit: '%',
                        activeColor: primaryAccent,
                        onChanged: (val) {
                          setState(() => _borderOpacity = val);
                          final rs = effectiveRenderState;
                          final nodeIds = _getSelectedNodes(rs).map((n) => n.id).toList();
                          if (nodeIds.isNotEmpty) {
                            final strokeInt = _computeNodeStrokeColor(theme);
                            rs.updateNodesStyle(nodeIds, (s) => s.copyWith(strokeColor: strokeInt));
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Sub-block 4: Shadow & Glow
          SubBlockShell(
            title: 'Shadow & Glow',
            accentColor: primaryAccent,
            onReset: () {
              setState(() {
                _shadowMode = 'none';
                _shadowBlur = 14.0;
                _shadowDistance = 4.0;
                _shadowColor = null;
              });
              final rs = effectiveRenderState;
              final nodeIds = _getSelectedNodes(rs).map((n) => n.id).toList();
              if (nodeIds.isNotEmpty) {
                rs.updateNodesStyle(
                  nodeIds,
                  (style) => style.copyWith(
                    shadowColor: 0x00000000,
                    shadowBlur: 0.0,
                    shadowOffsetY: 0.0,
                    shadowOffsetX: 0.0,
                  ),
                );
              }
            },
            child: Column(
              children: [
                // Row 1: Shadow Mode Switcher (flex: 2) + Glow Color Pill (flex: 1)
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SegmentedGlassSwitcher<String>(
                        height: UiControlSize.standard,
                        activeColor: primaryAccent,
                        selectedValue: _shadowMode,
                        onSelected: (val) {
                          setState(() => _shadowMode = val);
                          final rs = effectiveRenderState;
                          final nodeIds = _getSelectedNodes(rs).map((n) => n.id).toList();
                          if (nodeIds.isNotEmpty) {
                            final shadowInt = _computeNodeShadowColor(theme);
                            final blur = val == 'none' ? 0.0 : _shadowBlur;
                            final dy = (val == 'none' || val == 'glow') ? 0.0 : _shadowDistance;
                            rs.updateNodesStyle(
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
                        selectedValue: _shadowColor,
                        activeColor: primaryAccent,
                        onSelected: (val) {
                          setState(() => _shadowColor = val);
                          final rs = effectiveRenderState;
                          final nodeIds = _getSelectedNodes(rs).map((n) => n.id).toList();
                          if (nodeIds.isNotEmpty) {
                            final shadowInt = _computeNodeShadowColor(theme);
                            rs.updateNodesStyle(nodeIds, (s) => s.copyWith(shadowColor: shadowInt));
                          }
                        },
                        options: [
                          const ColorPillOption(value: null, label: 'Accent', isNone: true),
                          const ColorPillOption(value: Color(0xFF00E5FF), color: Color(0xFF00E5FF), label: 'Cyan'),
                          const ColorPillOption(value: Color(0xFFFFB703), color: Color(0xFFFFB703), label: 'Amber'),
                          const ColorPillOption(value: Color(0xFF10B981), color: Color(0xFF10B981), label: 'Emerald'),
                          const ColorPillOption(value: Color(0xFFA855F7), color: Color(0xFFA855F7), label: 'Purple'),
                          const ColorPillOption(value: Color(0xFFFF007A), color: Color(0xFFFF007A), label: 'Pink'),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: UiSpacing.tight),

                // Row 2: Dual Compact Sliders (Blur & Distance)
                Row(
                  children: [
                    Expanded(
                      child: CompactSliderBox(
                        label: 'Blur',
                        value: _shadowBlur,
                        min: 0,
                        max: 32,
                        unit: 'px',
                        activeColor: primaryAccent,
                        onChanged: (val) {
                          setState(() => _shadowBlur = val);
                          final rs = effectiveRenderState;
                          final nodeIds = _getSelectedNodes(rs).map((n) => n.id).toList();
                          if (nodeIds.isNotEmpty) {
                            rs.updateNodesStyle(nodeIds, (s) => s.copyWith(shadowBlur: val));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: UiSpacing.tight),
                    Expanded(
                      child: CompactSliderBox(
                        label: 'Distance',
                        value: _shadowDistance,
                        min: 0,
                        max: 16,
                        unit: 'px',
                        activeColor: primaryAccent,
                        onChanged: (val) {
                          setState(() => _shadowDistance = val);
                          final rs = effectiveRenderState;
                          final nodeIds = _getSelectedNodes(rs).map((n) => n.id).toList();
                          if (nodeIds.isNotEmpty) {
                            rs.updateNodesStyle(nodeIds, (s) => s.copyWith(shadowOffsetY: val));
                          }
                        },
                      ),
                    ),
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
