import 'package:flutter/material.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import 'package:centrode/shared/elements/centrode_icon_button.dart';
import 'package:centrode/shared/elements/glass_divider.dart';

class VerticalTextFormatToolbar extends StatelessWidget {
  final VoidCallback onToggleBold;
  final VoidCallback onToggleItalic;
  final VoidCallback onToggleUnderline;
  final VoidCallback onToggleHeader1;
  final VoidCallback onToggleHeader2;
  final VoidCallback onToggleHeader3;
  final VoidCallback onToggleBlockquote;
  final VoidCallback onToggleCodeBlock;
  final VoidCallback onToggleBulletList;
  final VoidCallback onToggleOrderedList;
  final VoidCallback onClearBlockFormat;
  final VoidCallback onAddHyperlink;
  final ValueChanged<String>? onSelectFontFamily;
  final VoidCallback onCycleTextColor;
  final VoidCallback onToggleHighlight;
  final VoidCallback onCycleHighlightColor;
  final VoidCallback onCycleTextAlign;
  final TextAlign currentTextAlign;
  final VoidCallback onIncreaseFontSize;
  final VoidCallback onDecreaseFontSize;
  final Widget? dragHandle;

  const VerticalTextFormatToolbar({
    super.key,
    required this.onToggleBold,
    required this.onToggleItalic,
    required this.onToggleUnderline,
    required this.onToggleHeader1,
    required this.onToggleHeader2,
    required this.onToggleHeader3,
    required this.onToggleBlockquote,
    required this.onToggleCodeBlock,
    required this.onToggleBulletList,
    required this.onToggleOrderedList,
    required this.onClearBlockFormat,
    required this.onAddHyperlink,
    required this.onSelectFontFamily,
    required this.onCycleTextColor,
    required this.onToggleHighlight,
    required this.onCycleHighlightColor,
    required this.onCycleTextAlign,
    this.currentTextAlign = TextAlign.center,
    required this.onIncreaseFontSize,
    required this.onDecreaseFontSize,
    this.dragHandle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final textColor = theme.textTheme.bodyMedium?.color ?? onSurface;

    return GlassPanel(
      blur: 12,
      borderRadius: 10,
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      color: theme.cardColor.withValues(alpha: 0.9),
      shadow: BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (dragHandle != null) dragHandle!,
                if (dragHandle != null) GlassDivider(orientation: Axis.horizontal, width: 20, height: 1, margin: const EdgeInsets.symmetric(vertical: 2)),

                CentrodeIconButton(
                  icon: Icons.format_bold_rounded,
                  tooltip: 'Bold',
                  onPressed: onToggleBold,
                  iconSize: 18,
                  buttonSize: 28,
                  iconColor: textColor.withValues(alpha: 0.75),
                  hoverColor: primaryColor,
                ),
                CentrodeIconButton(
                  icon: Icons.format_italic_rounded,
                  tooltip: 'Italic',
                  onPressed: onToggleItalic,
                  iconSize: 18,
                  buttonSize: 28,
                  iconColor: textColor.withValues(alpha: 0.75),
                  hoverColor: primaryColor,
                ),
                CentrodeIconButton(
                  icon: Icons.format_underlined_rounded,
                  tooltip: 'Underline',
                  onPressed: onToggleUnderline,
                  iconSize: 18,
                  buttonSize: 28,
                  iconColor: textColor.withValues(alpha: 0.75),
                  hoverColor: primaryColor,
                ),

                GlassDivider(orientation: Axis.horizontal, width: 20, height: 1, margin: const EdgeInsets.symmetric(vertical: 2)),

                CentrodeIconButton(
                  icon: Icons.looks_one_rounded,
                  tooltip: 'H1',
                  onPressed: onToggleHeader1,
                  iconSize: 18,
                  buttonSize: 28,
                  iconColor: textColor.withValues(alpha: 0.75),
                  hoverColor: primaryColor,
                ),
                CentrodeIconButton(
                  icon: Icons.looks_two_rounded,
                  tooltip: 'H2',
                  onPressed: onToggleHeader2,
                  iconSize: 18,
                  buttonSize: 28,
                  iconColor: textColor.withValues(alpha: 0.75),
                  hoverColor: primaryColor,
                ),
                CentrodeIconButton(
                  icon: Icons.looks_3_rounded,
                  tooltip: 'H3',
                  onPressed: onToggleHeader3,
                  iconSize: 18,
                  buttonSize: 28,
                  iconColor: textColor.withValues(alpha: 0.75),
                  hoverColor: primaryColor,
                ),

                GlassDivider(orientation: Axis.horizontal, width: 20, height: 1, margin: const EdgeInsets.symmetric(vertical: 2)),

                CentrodeIconButton(
                  icon: Icons.format_list_bulleted_rounded,
                  tooltip: 'Bullet List',
                  onPressed: onToggleBulletList,
                  iconSize: 18,
                  buttonSize: 28,
                  iconColor: textColor.withValues(alpha: 0.75),
                  hoverColor: primaryColor,
                ),
                CentrodeIconButton(
                  icon: Icons.format_list_numbered_rounded,
                  tooltip: 'Numbered List',
                  onPressed: onToggleOrderedList,
                  iconSize: 18,
                  buttonSize: 28,
                  iconColor: textColor.withValues(alpha: 0.75),
                  hoverColor: primaryColor,
                ),
                CentrodeIconButton(
                  icon: Icons.format_quote_rounded,
                  tooltip: 'Blockquote',
                  onPressed: onToggleBlockquote,
                  iconSize: 18,
                  buttonSize: 28,
                  iconColor: textColor.withValues(alpha: 0.75),
                  hoverColor: primaryColor,
                ),
              ],
            ),
            GlassDivider(orientation: Axis.vertical, height: double.infinity, margin: const EdgeInsets.symmetric(horizontal: 2)),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CentrodeIconButton(
                  icon: Icons.text_fields_rounded,
                  tooltip: 'Normal Text',
                  onPressed: onClearBlockFormat,
                  iconSize: 18,
                  buttonSize: 28,
                  iconColor: textColor.withValues(alpha: 0.75),
                  hoverColor: primaryColor,
                ),
                CentrodeIconButton(
                  icon: Icons.insert_link_rounded,
                  tooltip: 'Insert Link',
                  onPressed: onAddHyperlink,
                  iconSize: 18,
                  buttonSize: 28,
                  iconColor: textColor.withValues(alpha: 0.75),
                  hoverColor: primaryColor,
                ),

                GlassDivider(orientation: Axis.horizontal, width: 20, height: 1, margin: const EdgeInsets.symmetric(vertical: 2)),

                CentrodeIconButton(
                  icon: Icons.code_rounded,
                  tooltip: 'Code Block',
                  onPressed: onToggleCodeBlock,
                  iconSize: 18,
                  buttonSize: 28,
                  iconColor: textColor.withValues(alpha: 0.75),
                  hoverColor: primaryColor,
                ),

                GlassDivider(orientation: Axis.horizontal, width: 20, height: 1, margin: const EdgeInsets.symmetric(vertical: 2)),

                CentrodeIconButton(
                  icon: Icons.font_download_rounded,
                  tooltip: 'Font Family',
                  onPressed: () => _showFontPicker(context, textColor),
                  iconSize: 18,
                  buttonSize: 28,
                  iconColor: textColor.withValues(alpha: 0.75),
                  hoverColor: primaryColor,
                ),
                CentrodeIconButton(
                  icon: Icons.palette_outlined,
                  tooltip: 'Text Color',
                  onPressed: onCycleTextColor,
                  iconSize: 18,
                  buttonSize: 28,
                  iconColor: textColor.withValues(alpha: 0.75),
                  hoverColor: primaryColor,
                ),
                CentrodeIconButton(
                  icon: Icons.highlight_rounded,
                  tooltip: 'Highlight',
                  onPressed: onToggleHighlight,
                  iconSize: 18,
                  buttonSize: 28,
                  iconColor: textColor.withValues(alpha: 0.75),
                  hoverColor: primaryColor,
                ),
                CentrodeIconButton(
                  icon: Icons.color_lens_outlined,
                  tooltip: 'Highlight Color',
                  onPressed: onCycleHighlightColor,
                  iconSize: 18,
                  buttonSize: 28,
                  iconColor: textColor.withValues(alpha: 0.75),
                  hoverColor: primaryColor,
                ),

                GlassDivider(orientation: Axis.horizontal, width: 20, height: 1, margin: const EdgeInsets.symmetric(vertical: 2)),

                CentrodeIconButton(
                  icon: Icons.add_circle_outline_rounded,
                  tooltip: 'Font Size +',
                  onPressed: onIncreaseFontSize,
                  iconSize: 18,
                  buttonSize: 28,
                  iconColor: textColor.withValues(alpha: 0.75),
                  hoverColor: primaryColor,
                ),
                CentrodeIconButton(
                  icon: Icons.remove_circle_outline_rounded,
                  tooltip: 'Font Size -',
                  onPressed: onDecreaseFontSize,
                  iconSize: 18,
                  buttonSize: 28,
                  iconColor: textColor.withValues(alpha: 0.75),
                  hoverColor: primaryColor,
                ),

                GlassDivider(orientation: Axis.horizontal, width: 20, height: 1, margin: const EdgeInsets.symmetric(vertical: 2)),

                CentrodeIconButton(
                  icon: _getAlignIcon(currentTextAlign),
                  tooltip: 'Text Align',
                  onPressed: onCycleTextAlign,
                  iconSize: 18,
                  buttonSize: 28,
                  iconColor: textColor.withValues(alpha: 0.75),
                  hoverColor: primaryColor,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _getAlignIcon(TextAlign align) {
    switch (align) {
      case TextAlign.left:
        return Icons.format_align_left_rounded;
      case TextAlign.right:
        return Icons.format_align_right_rounded;
      default:
        return Icons.format_align_center_rounded;
    }
  }

  void _showFontPicker(BuildContext context, Color textColor) {
    final fonts = ['System', 'Inter', 'Roboto', 'Consolas'];
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () => entry.remove(),
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: position.dx + renderBox.size.width + 4,
            top: position.dy,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 120,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: fonts.map((font) {
                    final displayName = font == 'System' ? 'Default' : font;
                    return InkWell(
                      onTap: () {
                        onSelectFontFamily?.call(font);
                        entry.remove();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          displayName,
                          style: TextStyle(
                            fontFamily: font == 'System' ? null : font,
                            fontSize: 13,
                            color: textColor,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(entry);
  }

}
