import 'package:flutter/material.dart';
import 'package:mycelium/shared/widgets/glass_panel/glass_panel.dart';
import 'package:mycelium/presentation/widgets/hover_scale_button.dart';

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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dragHandle != null) dragHandle!,
              if (dragHandle != null) _buildDivider(theme),

              _buildButton(Icons.format_bold_rounded, 'Bold', onToggleBold, textColor, primaryColor),
              _buildButton(Icons.format_italic_rounded, 'Italic', onToggleItalic, textColor, primaryColor),
              _buildButton(Icons.format_underlined_rounded, 'Underline', onToggleUnderline, textColor, primaryColor),

              _buildDivider(theme),

              _buildButton(Icons.looks_one_rounded, 'H1', onToggleHeader1, textColor, primaryColor),
              _buildButton(Icons.looks_two_rounded, 'H2', onToggleHeader2, textColor, primaryColor),
              _buildButton(Icons.looks_3_rounded, 'H3', onToggleHeader3, textColor, primaryColor),

              _buildDivider(theme),

              _buildButton(Icons.format_list_bulleted_rounded, 'Bullet List', onToggleBulletList, textColor, primaryColor),
              _buildButton(Icons.format_list_numbered_rounded, 'Numbered List', onToggleOrderedList, textColor, primaryColor),
              _buildButton(Icons.format_quote_rounded, 'Blockquote', onToggleBlockquote, textColor, primaryColor),
              _buildButton(Icons.code_rounded, 'Code Block', onToggleCodeBlock, textColor, primaryColor),
              _buildButton(Icons.text_fields_rounded, 'Normal Text', onClearBlockFormat, textColor, primaryColor),

              _buildDivider(theme),

              _buildButton(Icons.insert_link_rounded, 'Insert Link', onAddHyperlink, textColor, primaryColor),
            ],
          ),
          _buildDivider(theme),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildButton(Icons.font_download_rounded, 'Font Family', () => _showFontPicker(context, textColor), textColor, primaryColor),
              _buildButton(Icons.palette_outlined, 'Text Color', onCycleTextColor, textColor, primaryColor),
              _buildButton(Icons.highlight_rounded, 'Highlight', onToggleHighlight, textColor, primaryColor),
              _buildButton(Icons.color_lens_outlined, 'Highlight Color', onCycleHighlightColor, textColor, primaryColor),

              _buildDivider(theme),

              _buildButton(Icons.add_circle_outline_rounded, 'Font Size +', onIncreaseFontSize, textColor, primaryColor),
              _buildButton(Icons.remove_circle_outline_rounded, 'Font Size -', onDecreaseFontSize, textColor, primaryColor),

              _buildDivider(theme),

              _buildButton(Icons.format_align_left_rounded, 'Align Left', onCycleTextAlign, textColor, primaryColor),
              _buildButton(Icons.format_align_center_rounded, 'Align Center', onCycleTextAlign, textColor, primaryColor),
              _buildButton(Icons.format_align_right_rounded, 'Align Right', onCycleTextAlign, textColor, primaryColor),
            ],
          ),
        ],
      ),
    );
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
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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

  Widget _buildDivider(ThemeData theme) {
    return Container(
      width: 1,
      height: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: theme.dividerColor.withValues(alpha: 0.3),
    );
  }

  Widget _buildButton(IconData icon, String tooltip, VoidCallback onPressed, Color textColor, Color hoverColor) {
    return HoverScaleButton(
      onTap: onPressed,
      hoverScale: 1.08,
      pressScale: 0.94,
      tooltip: tooltip,
      borderRadius: BorderRadius.circular(6),
      builder: (context, isHovered, isPressed) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: isHovered
                  ? LinearGradient(
                      colors: [
                        hoverColor.withValues(alpha: 0.18),
                        hoverColor.withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              border: isHovered
                  ? Border.all(
                      color: hoverColor.withValues(alpha: 0.3),
                      width: 1.0,
                    )
                  : Border.all(color: Colors.transparent),
              boxShadow: isHovered
                  ? [
                      BoxShadow(
                        color: hoverColor.withValues(alpha: 0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : [],
            ),
            child: Center(
              child: Icon(
                icon,
                color: isHovered ? hoverColor : textColor.withValues(alpha: 0.75),
                size: 16,
              ),
            ),
          ),
        );
      },
    );
  }
}