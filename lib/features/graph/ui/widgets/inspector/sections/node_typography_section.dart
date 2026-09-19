import 'package:centrode/shared/elements/elements.dart';
import 'package:flutter/material.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/engine/config.dart';
import 'package:centrode/features/graph/ui/canvas/text/text_format_models.dart';
import '../components/sub_block_shell.dart';
import '../components/glass_dropdown.dart';
import '../components/square_icon_group.dart';
import '../components/glass_color_pill_button.dart';
import '../components/font_size_unravel_picker.dart';

class NodeTypographySection extends StatelessWidget {
  final NodeRenderState renderState;
  final String fontFamily;
  final double fontSize;
  final Color textColor;
  final String highlightColor;
  final Color? nodeBgColor;
  final bool isBold;
  final bool isItalic;
  final bool isStrikethrough;
  final String letterCase;
  final double letterSpacing;
  final double lineHeight;
  final bool hasUnderline;
  final String underlineStyle;
  final Color underlineColor;
  final String textAlign;
  final TextDirection textDirection;
  final Color accentColor;
  final ValueChanged<String> onFontFamilyChanged;
  final ValueChanged<double> onFontSizeChanged;
  final ValueChanged<Color> onTextColorChanged;
  final ValueChanged<String> onHighlightColorChanged;
  final ValueChanged<Color?> onNodeBgColorChanged;
  final VoidCallback onBoldToggled;
  final VoidCallback onItalicToggled;
  final VoidCallback onStrikethroughToggled;
  final VoidCallback onUnderlineToggled;
  final ValueChanged<String> onLetterCaseChanged;
  final ValueChanged<String> onTextAlignChanged;
  final ValueChanged<TextDirection> onTextDirectionChanged;
  final VoidCallback onReset;

  const NodeTypographySection({
    super.key,
    required this.renderState,
    required this.fontFamily,
    required this.fontSize,
    required this.textColor,
    required this.highlightColor,
    this.nodeBgColor,
    required this.isBold,
    required this.isItalic,
    required this.isStrikethrough,
    required this.letterCase,
    required this.letterSpacing,
    required this.lineHeight,
    required this.hasUnderline,
    required this.underlineStyle,
    required this.underlineColor,
    required this.textAlign,
    required this.textDirection,
    required this.accentColor,
    required this.onFontFamilyChanged,
    required this.onFontSizeChanged,
    required this.onTextColorChanged,
    required this.onHighlightColorChanged,
    required this.onNodeBgColorChanged,
    required this.onBoldToggled,
    required this.onItalicToggled,
    required this.onStrikethroughToggled,
    required this.onUnderlineToggled,
    required this.onLetterCaseChanged,
    required this.onTextAlignChanged,
    required this.onTextDirectionChanged,
    required this.onReset,
  });

  static const Map<String, int?> _highlightColorMap = {
    'none': null,
    'yellow': 0xFFFFE600,
    'cyan': 0xFF00E5FF,
    'green': 0xFF00FF66,
    'pink': 0xFFFF007A,
    'orange': 0xFFFF8800,
  };

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

  @override
  Widget build(BuildContext context) {
    final effectiveRenderState = renderState;
    final theme = Theme.of(context);

    return SubBlockShell(
      title: 'Text',
      accentColor: accentColor,
      onReset: onReset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: GlassDropdown<String>(
                  selectedValue: fontFamily,
                  activeColor: accentColor,
                  height: UiControlSize.standard,
                  onSelected: (val) {
                    onFontFamilyChanged(val);
                    final nodeIds =
                        _getSelectedNodes(effectiveRenderState).map((n) => n.id).toList();
                    if (nodeIds.isNotEmpty) {
                      effectiveRenderState.updateNodesStyle(
                        nodeIds,
                        (style) => style.copyWith(fontFamily: val),
                      );
                      if (effectiveRenderState.activeEditId != null) {
                        effectiveRenderState.setFontFamilyCallback?.call(val);
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
                fontSize: fontSize,
                activeColor: accentColor,
                onChanged: (val) {
                  final clamped =
                      val.clamp(AppConfig.node.minFontSize, AppConfig.node.maxFontSize);
                  onFontSizeChanged(clamped);
                  final nodeIds =
                      _getSelectedNodes(effectiveRenderState).map((n) => n.id).toList();
                  if (nodeIds.isNotEmpty) {
                    effectiveRenderState.updateNodesStyle(
                      nodeIds,
                      (style) => style.copyWith(fontSize: clamped),
                    );
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: UiSpacing.standard),

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
                        isActive: isBold,
                        activeColor: accentColor,
                        onTap: () {
                          final next = !isBold;
                          onBoldToggled();
                          if (effectiveRenderState.activeEditId != null) {
                            effectiveRenderState.applyFormatCallback?.call(TextFormatType.bold);
                          }
                          for (final node in _getSelectedNodes(effectiveRenderState)) {
                            final newContent =
                                node.content.toggleMark(MarkType.bold, forceState: next);
                            effectiveRenderState.commitEntityText(node.id, newContent);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: UiSpacing.tight),
                    Expanded(
                      child: SquareToggleButton(
                        label: 'I',
                        labelStyle: const TextStyle(
                            fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
                        tooltip: 'Italic',
                        isActive: isItalic,
                        activeColor: accentColor,
                        onTap: () {
                          final next = !isItalic;
                          onItalicToggled();
                          if (effectiveRenderState.activeEditId != null) {
                            effectiveRenderState.applyFormatCallback
                                ?.call(TextFormatType.italic);
                          }
                          for (final node in _getSelectedNodes(effectiveRenderState)) {
                            final newContent =
                                node.content.toggleMark(MarkType.italic, forceState: next);
                            effectiveRenderState.commitEntityText(node.id, newContent);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: UiSpacing.tight),
                    Expanded(
                      child: SquareToggleButton(
                        label: 'U',
                        labelStyle: const TextStyle(
                            decoration: TextDecoration.underline,
                            fontWeight: FontWeight.w600),
                        tooltip: 'Underline',
                        isActive: hasUnderline,
                        activeColor: accentColor,
                        onTap: () {
                          final next = !hasUnderline;
                          onUnderlineToggled();
                          if (effectiveRenderState.activeEditId != null) {
                            effectiveRenderState.applyFormatCallback
                                ?.call(TextFormatType.underline);
                          }
                          for (final node in _getSelectedNodes(effectiveRenderState)) {
                            final newContent =
                                node.content.toggleMark(MarkType.underline, forceState: next);
                            effectiveRenderState.commitEntityText(node.id, newContent);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: UiSpacing.tight),
                    Expanded(
                      child: SquareToggleButton(
                        label: 'S',
                        labelStyle: const TextStyle(
                            decoration: TextDecoration.lineThrough,
                            fontWeight: FontWeight.w600),
                        tooltip: 'Strikethrough',
                        isActive: isStrikethrough,
                        activeColor: accentColor,
                        onTap: () {
                          final next = !isStrikethrough;
                          onStrikethroughToggled();
                          for (final node in _getSelectedNodes(effectiveRenderState)) {
                            final newContent = node.content
                                .toggleMark(MarkType.strikethrough, forceState: next);
                            effectiveRenderState.commitEntityText(node.id, newContent);
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
                        isActive: textAlign == 'left',
                        activeColor: accentColor,
                        onTap: () {
                          onTextAlignChanged('left');
                          for (final node in _getSelectedNodes(effectiveRenderState)) {
                            final newContent = node.content.setTextAlign('left');
                            effectiveRenderState.commitEntityText(node.id, newContent);
                          }
                          if (effectiveRenderState.activeEditId != null) {
                            effectiveRenderState.currentTextAlignNotifier.value =
                                TextAlign.left;
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: UiSpacing.tight),
                    Expanded(
                      child: SquareToggleButton(
                        icon: Icons.format_align_center_rounded,
                        tooltip: 'Align Center',
                        isActive: textAlign == 'center',
                        activeColor: accentColor,
                        onTap: () {
                          onTextAlignChanged('center');
                          for (final node in _getSelectedNodes(effectiveRenderState)) {
                            final newContent = node.content.setTextAlign('center');
                            effectiveRenderState.commitEntityText(node.id, newContent);
                          }
                          if (effectiveRenderState.activeEditId != null) {
                            effectiveRenderState.currentTextAlignNotifier.value =
                                TextAlign.center;
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: UiSpacing.tight),
                    Expanded(
                      child: SquareToggleButton(
                        icon: Icons.format_align_right_rounded,
                        tooltip: 'Align Right',
                        isActive: textAlign == 'right',
                        activeColor: accentColor,
                        onTap: () {
                          onTextAlignChanged('right');
                          for (final node in _getSelectedNodes(effectiveRenderState)) {
                            final newContent = node.content.setTextAlign('right');
                            effectiveRenderState.commitEntityText(node.id, newContent);
                          }
                          if (effectiveRenderState.activeEditId != null) {
                            effectiveRenderState.currentTextAlignNotifier.value =
                                TextAlign.right;
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: UiSpacing.tight),
                    Expanded(
                      child: SquareToggleButton(
                        icon: Icons.format_align_justify_rounded,
                        tooltip: 'Justify',
                        isActive: textAlign == 'justify',
                        activeColor: accentColor,
                        onTap: () {
                          onTextAlignChanged('justify');
                          for (final node in _getSelectedNodes(effectiveRenderState)) {
                            final newContent = node.content.setTextAlign('justify');
                            effectiveRenderState.commitEntityText(node.id, newContent);
                          }
                          if (effectiveRenderState.activeEditId != null) {
                            effectiveRenderState.currentTextAlignNotifier.value =
                                TextAlign.justify;
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

          Row(
            children: [
              Expanded(
                flex: 2,
                child: CentrodeSegmentedControl<String>(
                  items: const [
                    (icon: Icons.text_fields, label: 'Aa', mode: 'normal', tooltip: 'Normal: Aa', accentBadge: null),
                    (icon: Icons.text_fields, label: 'AA', mode: 'uppercase', tooltip: 'UPPERCASE: AA', accentBadge: null),
                    (icon: Icons.text_fields, label: 'aa', mode: 'lowercase', tooltip: 'lowercase: aa', accentBadge: null),
                    (icon: Icons.text_fields, label: 'Ab', mode: 'capitalize', tooltip: 'Capitalize: Ab', accentBadge: null),
                  ],
                  currentMode: letterCase,
                  isCompact: false,
                  onSelected: (val) {
                    onLetterCaseChanged(val);
                    for (final node in _getSelectedNodes(effectiveRenderState)) {
                      final newContent = node.content.transformLetterCase(val);
                      effectiveRenderState.commitEntityText(node.id, newContent);
                    }
                  },
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
                        labelStyle: const TextStyle(
                            fontSize: UiFont.compact, fontWeight: FontWeight.w600),
                        tooltip: 'Left to Right',
                        isActive: textDirection == TextDirection.ltr,
                        activeColor: accentColor,
                        onTap: () => onTextDirectionChanged(TextDirection.ltr),
                      ),
                    ),
                    const SizedBox(width: UiSpacing.tight),
                    Expanded(
                      child: SquareToggleButton(
                        label: 'RTL',
                        labelStyle: const TextStyle(
                            fontSize: UiFont.compact, fontWeight: FontWeight.w600),
                        tooltip: 'Right to Left',
                        isActive: textDirection == TextDirection.rtl,
                        activeColor: accentColor,
                        onTap: () => onTextDirectionChanged(TextDirection.rtl),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: UiSpacing.standard),

          Row(
            children: [
              Expanded(
                child: GlassColorPillButton<Color>(
                  label: 'text',
                  selectedValue: textColor,
                  activeColor: accentColor,
                  onSelected: (val) {
                    onTextColorChanged(val);
                    final nodeIds =
                        _getSelectedNodes(effectiveRenderState).map((n) => n.id).toList();
                    if (nodeIds.isNotEmpty) {
                      effectiveRenderState.updateNodesStyle(
                        nodeIds,
                        (style) => style.copyWith(textColor: val.toARGB32()),
                      );
                    }
                  },
                  options: [
                    const ColorPillOption(
                        value: Colors.white, color: Colors.white, label: 'White'),
                    ColorPillOption(value: accentColor, color: accentColor, label: 'Accent'),
                    ...CentrodeDerivedPalette.of(context).swatches.take(6).map((c) =>
                        ColorPillOption(
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
                  selectedValue: highlightColor,
                  activeColor: accentColor,
                  onSelected: (val) {
                    onHighlightColorChanged(val);
                    final int? colorInt = _highlightColorMap[val];
                    for (final node in _getSelectedNodes(effectiveRenderState)) {
                      final newContent = node.content.setHighlightColor(colorInt);
                      effectiveRenderState.commitEntityText(node.id, newContent);
                    }
                    if (effectiveRenderState.activeEditId != null) {
                      final hexStr = colorInt != null
                          ? '#${colorInt.toRadixString(16).padLeft(8, '0').substring(2)}'
                          : null;
                      effectiveRenderState.toggleHighlightCallback?.call(colorUrl: hexStr);
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
                  selectedValue: nodeBgColor,
                  activeColor: accentColor,
                  onSelected: (val) {
                    onNodeBgColorChanged(val);
                    final nodeIds =
                        _getSelectedNodes(effectiveRenderState).map((n) => n.id).toList();
                    if (nodeIds.isNotEmpty) {
                      final bgInt = (val ?? theme.cardColor).toARGB32();
                      effectiveRenderState.updateNodesStyle(
                        nodeIds,
                        (style) => style.copyWith(bgColor: bgInt),
                      );
                    }
                  },
                  options: _buildGlassColorOptions(context, accentColor),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
