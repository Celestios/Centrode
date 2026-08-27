import 'package:flutter/material.dart';
import 'package:centrode/shared/widgets/unravel_slider/unravel_slider.dart';
import 'components/glass_section_shell.dart';
import 'components/sub_block_shell.dart';
import 'components/segmented_glass_switcher.dart';
import 'components/inline_property_row.dart';
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

  const NodesSectionShell({
    super.key,
    this.isGlobal = true,
    this.selectedCount = 0,
  });

  @override
  State<NodesSectionShell> createState() => _NodesSectionShellState();
}

class _NodesSectionShellState extends State<NodesSectionShell> {
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryAccent = theme.colorScheme.primary;

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
                        height: 32.0,
                        onSelected: (val) => setState(() => _fontFamily = val),
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
                    const SizedBox(width: 8),
                    FontSizeUnravelPicker(
                      fontSize: _fontSize,
                      activeColor: primaryAccent,
                      onChanged: (val) => setState(() => _fontSize = val),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

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
                              onTap: () => setState(() => _isBold = !_isBold),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: SquareToggleButton(
                              label: 'I',
                              labelStyle: const TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
                              tooltip: 'Italic',
                              isActive: _isItalic,
                              activeColor: primaryAccent,
                              onTap: () => setState(() => _isItalic = !_isItalic),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: SquareToggleButton(
                              label: 'U',
                              labelStyle: const TextStyle(decoration: TextDecoration.underline, fontWeight: FontWeight.w600),
                              tooltip: 'Underline',
                              isActive: _hasUnderline,
                              activeColor: primaryAccent,
                              onTap: () => setState(() => _hasUnderline = !_hasUnderline),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: SquareToggleButton(
                              label: 'S',
                              labelStyle: const TextStyle(decoration: TextDecoration.lineThrough, fontWeight: FontWeight.w600),
                              tooltip: 'Strikethrough',
                              isActive: _isStrikethrough,
                              activeColor: primaryAccent,
                              onTap: () => setState(() => _isStrikethrough = !_isStrikethrough),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 0.8,
                      height: 18,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
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
                              onTap: () => setState(() => _textAlign = 'left'),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: SquareToggleButton(
                              icon: Icons.format_align_center_rounded,
                              tooltip: 'Align Center',
                              isActive: _textAlign == 'center',
                              activeColor: primaryAccent,
                              onTap: () => setState(() => _textAlign = 'center'),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: SquareToggleButton(
                              icon: Icons.format_align_right_rounded,
                              tooltip: 'Align Right',
                              isActive: _textAlign == 'right',
                              activeColor: primaryAccent,
                              onTap: () => setState(() => _textAlign = 'right'),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: SquareToggleButton(
                              icon: Icons.format_align_justify_rounded,
                              tooltip: 'Justify',
                              isActive: _textAlign == 'justify',
                              activeColor: primaryAccent,
                              onTap: () => setState(() => _textAlign = 'justify'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Row 3: Visual Case Segmented Switcher (flex: 2) + Direction Buttons (flex: 1)
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SegmentedGlassSwitcher<String>(
                        height: 30.0,
                        selectedValue: _letterCase,
                        activeColor: primaryAccent,
                        onSelected: (val) => setState(() => _letterCase = val),
                        segments: const [
                          SegmentData(
                            value: 'normal',
                            label: 'Aa',
                            tooltip: 'Normal: Aa',
                            style: TextStyle(fontSize: 11.5),
                          ),
                          SegmentData(
                            value: 'uppercase',
                            label: 'AA',
                            tooltip: 'UPPERCASE: AA',
                            style: TextStyle(fontSize: 11.5),
                          ),
                          SegmentData(
                            value: 'lowercase',
                            label: 'aa',
                            tooltip: 'lowercase: aa',
                            style: TextStyle(fontSize: 11.5),
                          ),
                          SegmentData(
                            value: 'capitalize',
                            label: 'Ab',
                            tooltip: 'Capitalize: Ab',
                            style: TextStyle(fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: Row(
                        children: [
                          Expanded(
                            child: SquareToggleButton(
                              label: 'LTR',
                              labelStyle: const TextStyle(fontSize: 11.0, fontWeight: FontWeight.w600),
                              tooltip: 'Left to Right',
                              isActive: _textDirection == TextDirection.ltr,
                              activeColor: primaryAccent,
                              onTap: () => setState(() => _textDirection = TextDirection.ltr),
                            ),
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: SquareToggleButton(
                              label: 'RTL',
                              labelStyle: const TextStyle(fontSize: 11.0, fontWeight: FontWeight.w600),
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

                const SizedBox(height: 8),

                // Row 4: Three Flat Full-Width Color Swatch Pill Buttons [ text | mark | node bg ]
                Row(
                  children: [
                    Expanded(
                      child: GlassColorPillButton<Color>(
                        label: 'text',
                        selectedValue: _textColor,
                        activeColor: primaryAccent,
                        onSelected: (val) => setState(() => _textColor = val),
                        options: [
                          const ColorPillOption(value: Colors.white, color: Colors.white, label: 'White'),
                          const ColorPillOption(value: Color(0xFFD0D4E0), color: Color(0xFFD0D4E0), label: 'Silver'),
                          ColorPillOption(value: primaryAccent, color: primaryAccent, label: 'Accent'),
                          const ColorPillOption(value: Color(0xFF00F0FF), color: Color(0xFF00F0FF), label: 'Cyan'),
                          const ColorPillOption(value: Color(0xFFFFB800), color: Color(0xFFFFB800), label: 'Amber'),
                          const ColorPillOption(value: Color(0xFFFF5C5C), color: Color(0xFFFF5C5C), label: 'Coral'),
                          const ColorPillOption(value: Color(0xFF10B981), color: Color(0xFF10B981), label: 'Emerald'),
                          const ColorPillOption(value: Color(0xFFA855F7), color: Color(0xFFA855F7), label: 'Purple'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GlassColorPillButton<String>(
                        label: 'mark',
                        selectedValue: _highlightColor,
                        activeColor: primaryAccent,
                        onSelected: (val) => setState(() => _highlightColor = val),
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
                    const SizedBox(width: 8),
                    Expanded(
                      child: GlassColorPillButton<Color?>(
                        label: 'node bg',
                        selectedValue: _nodeBgColor,
                        activeColor: primaryAccent,
                        onSelected: (val) => setState(() => _nodeBgColor = val),
                        options: [
                          const ColorPillOption(value: null, label: 'Auto (Glass)', isNone: true),
                          ColorPillOption(value: primaryAccent, color: primaryAccent, label: 'Accent'),
                          const ColorPillOption(value: Color(0xFF1E293B), color: Color(0xFF1E293B), label: 'Slate'),
                          const ColorPillOption(value: Color(0xFF0F172A), color: Color(0xFF0F172A), label: 'Midnight'),
                          const ColorPillOption(value: Color(0xFF1E1B4B), color: Color(0xFF1E1B4B), label: 'Indigo'),
                          const ColorPillOption(value: Color(0xFF064E3B), color: Color(0xFF064E3B), label: 'Emerald'),
                          const ColorPillOption(value: Color(0xFF701A75), color: Color(0xFF701A75), label: 'Fuchsia'),
                          const ColorPillOption(value: Color(0xFF7C2D12), color: Color(0xFF7C2D12), label: 'Rust'),
                        ],
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
                            setState(() {
                              _nodeShape = kAvailableNodeShapes[idx].id;
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
                        height: 30.0,
                        activeColor: primaryAccent,
                        selectedValue: _fillStyle,
                        onSelected: (val) => setState(() => _fillStyle = val),
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
                        label: 'tint',
                        selectedValue: _fillTint,
                        activeColor: primaryAccent,
                        onSelected: (val) => setState(() => _fillTint = val),
                        options: [
                          const ColorPillOption(value: null, label: 'Auto (Glass)', isNone: true),
                          ColorPillOption(value: primaryAccent, color: primaryAccent, label: 'Accent'),
                          const ColorPillOption(value: Color(0xFF1E293B), color: Color(0xFF1E293B), label: 'Slate'),
                          const ColorPillOption(value: Color(0xFF0F172A), color: Color(0xFF0F172A), label: 'Midnight'),
                          const ColorPillOption(value: Color(0xFF1E1B4B), color: Color(0xFF1E1B4B), label: 'Indigo'),
                          const ColorPillOption(value: Color(0xFF064E3B), color: Color(0xFF064E3B), label: 'Emerald'),
                          const ColorPillOption(value: Color(0xFF701A75), color: Color(0xFF701A75), label: 'Fuchsia'),
                          const ColorPillOption(value: Color(0xFF7C2D12), color: Color(0xFF7C2D12), label: 'Rust'),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

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
                        onChanged: (val) => setState(() => _opacity = val),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: CompactSliderBox(
                        label: 'Radius',
                        value: _cornerRadius,
                        min: 0,
                        max: 24,
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
            },
            child: Column(
              children: [
                // Row 1: Stroke Pattern Switcher (flex: 2) + Border Color Pill (flex: 1)
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SegmentedGlassSwitcher<String>(
                        height: 30.0,
                        activeColor: primaryAccent,
                        selectedValue: _borderStyle,
                        onSelected: (val) => setState(() => _borderStyle = val),
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
                        selectedValue: _borderColor,
                        activeColor: primaryAccent,
                        onSelected: (val) => setState(() => _borderColor = val),
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

                const SizedBox(height: 6),

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
                        onChanged: (val) => setState(() => _borderWidth = val),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: CompactSliderBox(
                        label: 'Opacity',
                        value: _borderOpacity,
                        min: 0,
                        max: 100,
                        unit: '%',
                        activeColor: primaryAccent,
                        onChanged: (val) => setState(() => _borderOpacity = val),
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
            },
            child: Column(
              children: [
                // Row 1: Shadow Mode Switcher (flex: 2) + Glow Color Pill (flex: 1)
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SegmentedGlassSwitcher<String>(
                        height: 30.0,
                        activeColor: primaryAccent,
                        selectedValue: _shadowMode,
                        onSelected: (val) => setState(() => _shadowMode = val),
                        segments: const [
                          SegmentData(value: 'none', label: 'None'),
                          SegmentData(value: 'soft', label: 'Soft'),
                          SegmentData(value: 'crisp', label: 'Hard'),
                          SegmentData(value: 'glow', label: 'Glow'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: GlassColorPillButton<Color?>(
                        label: 'glow',
                        selectedValue: _shadowColor,
                        activeColor: primaryAccent,
                        onSelected: (val) => setState(() => _shadowColor = val),
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

                const SizedBox(height: 6),

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
                        onChanged: (val) => setState(() => _shadowBlur = val),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: CompactSliderBox(
                        label: 'Distance',
                        value: _shadowDistance,
                        min: 0,
                        max: 16,
                        unit: 'px',
                        activeColor: primaryAccent,
                        onChanged: (val) => setState(() => _shadowDistance = val),
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
