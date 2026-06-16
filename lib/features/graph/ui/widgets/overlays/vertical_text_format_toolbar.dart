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
      borderRadius: 8,
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      color: theme.cardColor.withValues(alpha: 0.9),
      shadow: BoxShadow(
        color: Colors.black.withValues(alpha: 0.15),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
      child: SizedBox(
        width: 28,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dragHandle != null) dragHandle!,
            if (dragHandle != null) _buildDivider(theme),

            _buildFormatButton(
              icon: Icons.format_bold_rounded,
              tooltip: 'Bold',
              onPressed: onToggleBold,
              textColor: textColor,
              hoverColor: primaryColor,
            ),
            _buildFormatButton(
              icon: Icons.format_italic_rounded,
              tooltip: 'Italic',
              onPressed: onToggleItalic,
              textColor: textColor,
              hoverColor: primaryColor,
            ),
            _buildFormatButton(
              icon: Icons.format_underlined_rounded,
              tooltip: 'Underline',
              onPressed: onToggleUnderline,
              textColor: textColor,
              hoverColor: primaryColor,
            ),

            _buildDivider(theme),

            _buildButtonRow(
              buttons: [
                _miniButton(Icons.looks_one_rounded, 'H1', onToggleHeader1, textColor, primaryColor),
                _miniButton(Icons.looks_two_rounded, 'H2', onToggleHeader2, textColor, primaryColor),
                _miniButton(Icons.looks_3_rounded, 'H3', onToggleHeader3, textColor, primaryColor),
              ],
            ),

            _buildDivider(theme),

            _buildFormatButton(
              icon: Icons.format_list_bulleted_rounded,
              tooltip: 'Bullet List',
              onPressed: onToggleBulletList,
              textColor: textColor,
              hoverColor: primaryColor,
            ),
            _buildFormatButton(
              icon: Icons.format_list_numbered_rounded,
              tooltip: 'Numbered List',
              onPressed: onToggleOrderedList,
              textColor: textColor,
              hoverColor: primaryColor,
            ),
            _buildFormatButton(
              icon: Icons.format_quote_rounded,
              tooltip: 'Blockquote',
              onPressed: onToggleBlockquote,
              textColor: textColor,
              hoverColor: primaryColor,
            ),
            _buildFormatButton(
              icon: Icons.code_rounded,
              tooltip: 'Code Block',
              onPressed: onToggleCodeBlock,
              textColor: textColor,
              hoverColor: primaryColor,
            ),
            _buildFormatButton(
              icon: Icons.text_fields_rounded,
              tooltip: 'Normal Text',
              onPressed: onClearBlockFormat,
              textColor: textColor,
              hoverColor: primaryColor,
            ),

            _buildDivider(theme),

            _buildButtonRow(
              buttons: [
                _buildFontPickerButton(context, textColor, primaryColor),
                _miniButton(Icons.palette_outlined, 'Color', onCycleTextColor, textColor, primaryColor),
              ],
            ),
            _buildButtonRow(
              buttons: [
                _miniButton(Icons.highlight_rounded, 'Highlight', onToggleHighlight, textColor, primaryColor),
                _miniButton(Icons.color_lens_outlined, 'Hi-Color', onCycleHighlightColor, textColor, primaryColor),
              ],
            ),

            _buildDivider(theme),

            _buildButtonRow(
              buttons: [
                _miniButton(Icons.format_align_left_rounded, 'Align Left', onCycleTextAlign, textColor, primaryColor),
                _miniButton(Icons.format_align_center_rounded, 'Align Center', onCycleTextAlign, textColor, primaryColor),
                _miniButton(Icons.format_align_right_rounded, 'Align Right', onCycleTextAlign, textColor, primaryColor),
              ],
            ),

            _buildDivider(theme),

            _buildFormatButton(
              icon: Icons.insert_link_rounded,
              tooltip: 'Insert Link',
              onPressed: onAddHyperlink,
              textColor: textColor,
              hoverColor: primaryColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Container(
      width: 18,
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 2),
      color: theme.dividerColor.withValues(alpha: 0.3),
    );
  }

  Widget _buildButtonRow({required List<Widget> buttons}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: buttons,
      ),
    );
  }

  Widget _miniButton(
    IconData icon,
    String tooltip,
    VoidCallback onPressed,
    Color textColor,
    Color hoverColor,
  ) {
    return HoverScaleButton(
      onTap: onPressed,
      hoverScale: 1.08,
      pressScale: 0.94,
      tooltip: tooltip,
      borderRadius: BorderRadius.circular(4),
      builder: (context, isHovered, isPressed) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 18,
          height: 18,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
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
          ),
          child: Center(
            child: Icon(
              icon,
              color: isHovered ? hoverColor : textColor.withValues(alpha: 0.75),
              size: 12,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFontPickerButton(BuildContext context, Color textColor, Color hoverColor) {
    final fonts = ['System', 'Inter', 'Roboto', 'Consolas'];
    return HoverScaleButton(
      onTap: () {
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
      },
      hoverScale: 1.08,
      pressScale: 0.94,
      tooltip: 'Font Family',
      borderRadius: BorderRadius.circular(4),
      builder: (context, isHovered, isPressed) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 18,
          height: 18,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
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
          ),
          child: Center(
            child: Icon(
              Icons.font_download_rounded,
              color: isHovered ? hoverColor : textColor.withValues(alpha: 0.75),
              size: 12,
            ),
          ),
        );
      },
    );
  }

  Widget _buildFormatButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required Color textColor,
    required Color hoverColor,
  }) {
    return HoverScaleButton(
      onTap: onPressed,
      hoverScale: 1.08,
      pressScale: 0.94,
      tooltip: tooltip,
      borderRadius: BorderRadius.circular(5),
      builder: (context, isHovered, isPressed) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
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
                size: 15,
              ),
            ),
          ),
        );
      },
    );
  }
}