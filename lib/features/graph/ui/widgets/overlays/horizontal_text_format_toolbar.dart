import 'package:flutter/material.dart';
import 'package:mycelium/shared/widgets/glass_panel/glass_panel.dart';
import 'package:mycelium/presentation/widgets/hover_scale_button.dart';
import '../../../presentation/graph_metrics.dart';

class HorizontalTextFormatToolbar extends StatelessWidget {
  final VoidCallback onToggleBold;
  final VoidCallback onToggleItalic;
  final VoidCallback onToggleUnderline;
  final VoidCallback onToggleHeader1;
  final VoidCallback onToggleHeader2;
  final VoidCallback onToggleHeader3;
  final VoidCallback onAddHyperlink;

  const HorizontalTextFormatToolbar({
    super.key,
    required this.onToggleBold,
    required this.onToggleItalic,
    required this.onToggleUnderline,
    required this.onToggleHeader1,
    required this.onToggleHeader2,
    required this.onToggleHeader3,
    required this.onAddHyperlink,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final textColor = theme.textTheme.bodyMedium?.color ?? onSurface;

    return GlassPanel(
      blur: 14,
      borderRadius: 12,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      color: theme.cardColor.withValues(alpha: 0.9),
      shadow: BoxShadow(
        color: Colors.black.withValues(alpha: 0.2),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Formatting Section: Bold, Italic, Underline
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

          // Divider
          _buildDivider(theme),

          // Heading Section: H1, H2, H3
          _buildFormatButton(
            icon: Icons.looks_one_rounded,
            tooltip: 'Heading 1',
            onPressed: onToggleHeader1,
            textColor: textColor,
            hoverColor: primaryColor,
          ),
          _buildFormatButton(
            icon: Icons.looks_two_rounded,
            tooltip: 'Heading 2',
            onPressed: onToggleHeader2,
            textColor: textColor,
            hoverColor: primaryColor,
          ),
          _buildFormatButton(
            icon: Icons.looks_3_rounded,
            tooltip: 'Heading 3',
            onPressed: onToggleHeader3,
            textColor: textColor,
            hoverColor: primaryColor,
          ),

          // Divider
          _buildDivider(theme),

          // Link Section
          _buildFormatButton(
            icon: Icons.insert_link_rounded,
            tooltip: 'Insert Link',
            onPressed: onAddHyperlink,
            textColor: textColor,
            hoverColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: theme.dividerColor.withValues(alpha: 0.3),
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
      borderRadius: BorderRadius.circular(6),
      builder: (context, isHovered, isPressed) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 32,
          height: 32,
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
              size: 20,
            ),
          ),
        );
      },
    );
  }
}
