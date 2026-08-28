import 'package:flutter/material.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import 'package:centrode/shared/elements/centrode_icon_button.dart';
import 'package:centrode/shared/elements/glass_divider.dart';

class VerticalTextFormatToolbar extends StatefulWidget {
  final VoidCallback onToggleHeader1;
  final VoidCallback onToggleHeader2;
  final VoidCallback onToggleHeader3;
  final VoidCallback onToggleBlockquote;
  final VoidCallback onToggleCodeBlock;
  final VoidCallback onToggleBulletList;
  final VoidCallback onToggleOrderedList;
  final VoidCallback onClearBlockFormat;
  final VoidCallback onAddHyperlink;
  final Widget? dragHandle;

  const VerticalTextFormatToolbar({
    super.key,
    required this.onToggleHeader1,
    required this.onToggleHeader2,
    required this.onToggleHeader3,
    required this.onToggleBlockquote,
    required this.onToggleCodeBlock,
    required this.onToggleBulletList,
    required this.onToggleOrderedList,
    required this.onClearBlockFormat,
    required this.onAddHyperlink,
    this.dragHandle,
  });

  @override
  State<VerticalTextFormatToolbar> createState() => _VerticalTextFormatToolbarState();
}

class _VerticalTextFormatToolbarState extends State<VerticalTextFormatToolbar> {
  int _headingIndex = 0; // 0: None/Normal, 1: H1, 2: H2, 3: H3
  int _listIndex = 0;    // 0: None, 1: Bullet, 2: Numbered

  void _cycleHeading() {
    setState(() {
      _headingIndex = (_headingIndex + 1) % 4;
    });
    switch (_headingIndex) {
      case 1:
        widget.onToggleHeader1();
        break;
      case 2:
        widget.onToggleHeader2();
        break;
      case 3:
        widget.onToggleHeader3();
        break;
      case 0:
      default:
        widget.onClearBlockFormat();
        break;
    }
  }

  void _cycleList() {
    setState(() {
      _listIndex = (_listIndex + 1) % 3;
    });
    switch (_listIndex) {
      case 1:
        widget.onToggleBulletList();
        break;
      case 2:
        widget.onToggleOrderedList();
        break;
      case 0:
      default:
        widget.onClearBlockFormat();
        break;
    }
  }

  IconData get _headingIcon {
    switch (_headingIndex) {
      case 1:
        return Icons.looks_one_rounded;
      case 2:
        return Icons.looks_two_rounded;
      case 3:
        return Icons.looks_3_rounded;
      case 0:
      default:
        return Icons.title_rounded;
    }
  }

  String get _headingTooltip {
    switch (_headingIndex) {
      case 1:
        return 'Heading: H1';
      case 2:
        return 'Heading: H2';
      case 3:
        return 'Heading: H3';
      case 0:
      default:
        return 'Heading';
    }
  }

  IconData get _listIcon {
    switch (_listIndex) {
      case 1:
        return Icons.format_list_bulleted_rounded;
      case 2:
        return Icons.format_list_numbered_rounded;
      case 0:
      default:
        return Icons.format_list_bulleted_rounded;
    }
  }

  String get _listTooltip {
    switch (_listIndex) {
      case 1:
        return 'List: Bullet';
      case 2:
        return 'List: Numbered';
      case 0:
      default:
        return 'List (Bullet / Numbered)';
    }
  }

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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.dragHandle != null) widget.dragHandle!,
          if (widget.dragHandle != null)
            GlassDivider(
              orientation: Axis.horizontal,
              width: 20,
              height: 1,
              margin: const EdgeInsets.symmetric(vertical: 2),
            ),

          CentrodeIconButton(
            icon: _headingIcon,
            tooltip: _headingTooltip,
            onPressed: _cycleHeading,
            iconSize: 18,
            buttonSize: 28,
            iconColor: _headingIndex > 0 ? primaryColor : textColor.withValues(alpha: 0.75),
            hoverColor: primaryColor,
          ),

          CentrodeIconButton(
            icon: _listIcon,
            tooltip: _listTooltip,
            onPressed: _cycleList,
            iconSize: 18,
            buttonSize: 28,
            iconColor: _listIndex > 0 ? primaryColor : textColor.withValues(alpha: 0.75),
            hoverColor: primaryColor,
          ),

          CentrodeIconButton(
            icon: Icons.format_quote_rounded,
            tooltip: 'Blockquote',
            onPressed: widget.onToggleBlockquote,
            iconSize: 18,
            buttonSize: 28,
            iconColor: textColor.withValues(alpha: 0.75),
            hoverColor: primaryColor,
          ),

          CentrodeIconButton(
            icon: Icons.code_rounded,
            tooltip: 'Code Block',
            onPressed: widget.onToggleCodeBlock,
            iconSize: 18,
            buttonSize: 28,
            iconColor: textColor.withValues(alpha: 0.75),
            hoverColor: primaryColor,
          ),

          GlassDivider(
            orientation: Axis.horizontal,
            width: 20,
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 2),
          ),

          CentrodeIconButton(
            icon: Icons.insert_link_rounded,
            tooltip: 'Insert Link',
            onPressed: widget.onAddHyperlink,
            iconSize: 18,
            buttonSize: 28,
            iconColor: textColor.withValues(alpha: 0.75),
            hoverColor: primaryColor,
          ),
        ],
      ),
    );
  }
}
