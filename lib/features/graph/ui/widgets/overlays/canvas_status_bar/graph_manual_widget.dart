import 'package:centrode/shared/theme/design_tokens.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';

// -----------------------------------------------------------------------------
// BOTTOM LEFT: Graph Manual Legend Dialog Trigger
// -----------------------------------------------------------------------------
class GraphManualWidget extends StatelessWidget {
  final bool isSquareIconOnly;

  const GraphManualWidget({
    super.key,
    this.isSquareIconOnly = false,
  });

  void _showManualDialog(
    BuildContext context,
    ThemeData theme,
    Color primaryColor,
    Color textColor,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: AlertDialog(
            backgroundColor: theme.cardColor.withValues(alpha: 0.95),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(UiRadius.panel),
              side: BorderSide(color: primaryColor.withValues(alpha: 0.25)),
            ),
            title: Row(
              children: [
                Icon(Icons.menu_book_rounded, color: primaryColor),
                const SizedBox(width: UiSpacing.standard),
                const Text('Keyboard Shortcuts & Guide'),
              ],
            ),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Node Types', primaryColor),
                  _buildLegendRow(
                    primaryColor,
                    'Info Node',
                    'Core informational units, general content.',
                    textColor,
                  ),
                  _buildLegendRow(
                    Colors.greenAccent,
                    'Task Node',
                    'Actionable checklist nodes or tracking items.',
                    textColor,
                  ),
                  _buildLegendRow(
                    Colors.yellowAccent,
                    'Inter Node',
                    'Intermediate linkage or transition entities.',
                    textColor,
                  ),
                  const SizedBox(height: UiSpacing.container),
                  _buildSectionHeader('Connection Lines', primaryColor),
                  _buildLegendRow(
                    textColor.withValues(alpha: 0.7),
                    'Solid Line',
                    'Direct association, standard labeled relation.',
                    textColor,
                  ),
                  _buildLegendRow(
                    textColor.withValues(alpha: 0.5),
                    'Dashed Line',
                    'Soft association or conditional dependency.',
                    textColor,
                  ),
                  const SizedBox(height: UiSpacing.container),
                  _buildSectionHeader(
                    'Canvas Interaction Controls',
                    primaryColor,
                  ),
                  Text(
                    '• Pan View: Hold Middle Click or Space + Drag.\n'
                    '• Zoom: Use Mouse Scroll Wheel.\n'
                    '• Double Tap Canvas: Create a new Node.\n'
                    '• Drag Selection: Hold shift and drag selection marquee.',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.7),
                      fontSize: UiFont.standard,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Close', style: TextStyle(color: primaryColor)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: UiFont.micro,
          fontWeight: FontWeight.bold,
          color: primaryColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildLegendRow(
    Color color,
    String name,
    String desc,
    Color textColor,
  ) {
    return Padding(
      padding: UiInsets.verticalTight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(3),
              border: Border.all(color: color, width: UiStrokeWidth.thick),
            ),
          ),
          const SizedBox(width: UiSpacing.standard),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: UiFont.standard),
                children: [
                  TextSpan(
                    text: '$name: ',
                    style: TextStyle(fontWeight: FontWeight.bold, color: color),
                  ),
                  TextSpan(
                    text: desc,
                    style: TextStyle(color: textColor.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final textColor = theme.textTheme.bodyMedium?.color ?? onSurface;

    if (isSquareIconOnly) {
      return GlassPanel(
        borderRadius: 14,
        width: 40,
        height: UiControlSize.tile,
        padding: EdgeInsets.zero,
        onTap: () => _showManualDialog(context, theme, primaryColor, textColor),
        child: Tooltip(
          message: 'Manual & Guide',
          child: Center(
            child: Icon(Icons.menu_book_rounded, color: primaryColor, size: UiIconSize.standard),
          ),
        ),
      );
    }

    return GlassPanel(
      borderRadius: 10,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      onTap: () => _showManualDialog(context, theme, primaryColor, textColor),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_rounded, color: primaryColor, size: UiIconSize.dense),
          const SizedBox(width: UiSpacing.tight),
          Text(
            'Manual & Guide',
            style: TextStyle(
              fontSize: UiFont.compact,
              fontWeight: FontWeight.w600,
              color: textColor.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
