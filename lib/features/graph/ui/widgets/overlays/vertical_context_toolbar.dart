import 'package:flutter/material.dart';
import 'package:mycelium/shared/widgets/glass_panel/glass_panel.dart';
import 'package:mycelium/features/graph/engine/config.dart';
import 'package:mycelium/presentation/widgets/hover_scale_button.dart';

class VerticalContextToolbar extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback? onCopy;
  final bool isMulti;
  final bool isRelationOnly;
  final bool canSaveTemplate;
  final String? singleNodeId;
  final Widget? dragHandle; // Passed from parent to enable gesture dragging
  final VoidCallback? onDrawConnection;

  // Callbacks for text formatting and shape style changes:
  final VoidCallback? onDecreaseFontSize;
  final VoidCallback? onIncreaseFontSize;
  final VoidCallback? onToggleFontFamily;
  final VoidCallback? onCycleTextColor;
  final VoidCallback? onSaveTemplate;
  final ValueChanged<String>? onShapeChanged;
  final ValueChanged<String>? onRelationLayoutChanged;
  final ValueChanged<String>? onRelationStrokePatternChanged;

  final VoidCallback? onToggleBold;
  final VoidCallback? onToggleItalic;
  final VoidCallback? onToggleUnderline;
  final VoidCallback? onToggleHeader1;
  final VoidCallback? onToggleHeader2;
  final VoidCallback? onToggleHeader3;
  final VoidCallback? onAddHyperlink;

  final bool positionOnRight;

  const VerticalContextToolbar({
    super.key,
    required this.onDelete,
    this.onCopy,
    required this.isMulti,
    this.isRelationOnly = false,
    this.canSaveTemplate = false,
    this.singleNodeId,
    this.dragHandle,
    this.onDecreaseFontSize,
    this.onIncreaseFontSize,
    this.onToggleFontFamily,
    this.onCycleTextColor,
    this.onSaveTemplate,
    this.onShapeChanged,
    this.onDrawConnection,
    this.onRelationLayoutChanged,
    this.onRelationStrokePatternChanged,
    this.onToggleBold,
    this.onToggleItalic,
    this.onToggleUnderline,
    this.onToggleHeader1,
    this.onToggleHeader2,
    this.onToggleHeader3,
    this.onAddHyperlink,
    this.positionOnRight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return GlassGroup(
      settings: GlassSettings(
        refractStrength: AppConfig.liquidGlass.refractStrength,
        bridgeReachFactor: 2.5,
        bridgeThicknessFactor: AppConfig.liquidGlass.bridgeThicknessFactor,
        useLocalCoordinates: AppConfig.liquidGlass.useLocalCoordinates,
      ),
      child: SizedBox(
        width: 520,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: positionOnRight ? Alignment.topLeft : Alignment.topRight,
          children: [
            // Background vertical glass bar (fixed width 40, matches column height)
            Positioned(
              top: 0,
              bottom: 0,
              left: positionOnRight ? 0 : null,
              right: positionOnRight ? null : 0,
              width: 40,
              child: GlassPanel(
                borderRadius: 10,
                blur: 12,
                color: theme.cardColor.withValues(alpha: 0.9),
                shadow: BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
                child: const SizedBox.shrink(),
              ),
            ),
            // Interactive Column (non-positioned, determines the height, aligned to side)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: positionOnRight
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.end,
                children: [
                  // 1. Quick Actions Section
                  if (dragHandle != null) dragHandle!,

                  if (!isRelationOnly && isMulti) ...[
                    _buildQuickButton(
                      icon: Icons.link_rounded,
                      tooltip: 'Draw Connection',
                      onPressed: onDrawConnection ?? () {},
                      color: primaryColor,
                    ),
                  ],

                  if (onCopy != null)
                    _buildQuickButton(
                      icon: Icons.copy_rounded,
                      tooltip: 'Copy',
                      onPressed: onCopy!,
                      color: primaryColor,
                    ),

                  _buildQuickButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Delete',
                    onPressed: onDelete,
                    color: Colors.red.shade400,
                  ),

                  // Divider between Quick Actions and Group Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 1,
                      horizontal: 4,
                    ),
                    child: Container(
                      width: 24,
                      height: 1,
                      color: theme.dividerColor.withValues(alpha: 0.3),
                    ),
                  ),

                  // 2. Group Buttons Section
                  if (isRelationOnly) ...[
                    // Relation-specific style groups
                    VerticalToolbarGroupButton(
                      positionOnRight: positionOnRight,
                      triggerIcon: Icons.timeline_rounded,
                      triggerTooltip: 'Relation Style',
                      submenuButtons: [
                        SubmenuButtonData(
                          icon: Icons.linear_scale_rounded,
                          tooltip: 'Straight Route',
                          onPressed: () =>
                              onRelationLayoutChanged?.call('default'),
                        ),
                        SubmenuButtonData(
                          icon: Icons.gesture_rounded,
                          tooltip: 'Bezier Route',
                          onPressed: () =>
                              onRelationLayoutChanged?.call('bezier'),
                        ),
                        SubmenuButtonData(
                          icon: Icons.route_rounded,
                          tooltip: 'Manhattan Route',
                          onPressed: () =>
                              onRelationLayoutChanged?.call('orthogonal'),
                        ),
                        SubmenuButtonData(
                          icon: Icons.border_style_rounded,
                          tooltip: 'Solid Line',
                          onPressed: () =>
                              onRelationStrokePatternChanged?.call('solid'),
                        ),
                        SubmenuButtonData(
                          icon: Icons.border_clear_rounded,
                          tooltip: 'Dashed Line',
                          onPressed: () =>
                              onRelationStrokePatternChanged?.call('dashed'),
                        ),
                        SubmenuButtonData(
                          icon: Icons.blur_on_rounded,
                          tooltip: 'Dotted Line',
                          onPressed: () =>
                              onRelationStrokePatternChanged?.call('dotted'),
                        ),
                        SubmenuButtonData(
                          icon: Icons.arrow_forward_rounded,
                          tooltip: 'One-Way Direction',
                          onPressed: () {},
                        ),
                        SubmenuButtonData(
                          icon: Icons.swap_horiz_rounded,
                          tooltip: 'Bi-Directional',
                          onPressed: () {},
                        ),
                        SubmenuButtonData(
                          icon: Icons.colorize_rounded,
                          tooltip: 'Relation Color',
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ] else if (isMulti) ...[
                    // Multi-selection specific groups
                    VerticalToolbarGroupButton(
                      positionOnRight: positionOnRight,
                      triggerIcon: Icons.align_horizontal_left_rounded,
                      triggerTooltip: 'Align & Distribute',
                      submenuButtons: [
                        SubmenuButtonData(
                          icon: Icons.align_horizontal_left_rounded,
                          tooltip: 'Align Left',
                          onPressed: () {},
                        ),
                        SubmenuButtonData(
                          icon: Icons.align_horizontal_center_rounded,
                          tooltip: 'Align Center (Horiz)',
                          onPressed: () {},
                        ),
                        SubmenuButtonData(
                          icon: Icons.align_horizontal_right_rounded,
                          tooltip: 'Align Right',
                          onPressed: () {},
                        ),
                        SubmenuButtonData(
                          icon: Icons.align_vertical_top_rounded,
                          tooltip: 'Align Top',
                          onPressed: () {},
                        ),
                        SubmenuButtonData(
                          icon: Icons.align_vertical_center_rounded,
                          tooltip: 'Align Middle (Vert)',
                          onPressed: () {},
                        ),
                        SubmenuButtonData(
                          icon: Icons.align_vertical_bottom_rounded,
                          tooltip: 'Align Bottom',
                          onPressed: () {},
                        ),
                        SubmenuButtonData(
                          icon: Icons.horizontal_distribute_rounded,
                          tooltip: 'Distribute Horizontally',
                          onPressed: () {},
                        ),
                        SubmenuButtonData(
                          icon: Icons.vertical_distribute_rounded,
                          tooltip: 'Distribute Vertically',
                          onPressed: () {},
                        ),
                      ],
                    ),
                    VerticalToolbarGroupButton(
                      positionOnRight: positionOnRight,
                      triggerIcon: Icons.text_format_rounded,
                      triggerTooltip: 'Batch Format Text',
                      iconSize: 26,
                      submenuButtons: [
                        SubmenuButtonData(
                          icon: Icons.format_bold_rounded,
                          tooltip: 'Bold',
                          onPressed: () {},
                        ),
                        SubmenuButtonData(
                          icon: Icons.format_italic_rounded,
                          tooltip: 'Italic',
                          onPressed: () {},
                        ),
                        SubmenuButtonData(
                          icon: Icons.palette_outlined,
                          tooltip: 'Text Color',
                          onPressed: () {},
                        ),
                      ],
                    ),
                    VerticalToolbarGroupButton(
                      positionOnRight: positionOnRight,
                      triggerIcon: Icons.settings_outlined,
                      triggerTooltip: 'Group Actions',
                      submenuButtons: [
                        SubmenuButtonData(
                          icon: Icons.group_work_outlined,
                          tooltip: 'Group Items',
                          onPressed: () {},
                        ),
                        SubmenuButtonData(
                          icon: Icons.bookmark_add_outlined,
                          tooltip: 'Save Group as Template',
                          onPressed: onSaveTemplate ?? () {},
                        ),
                      ],
                    ),
                  ] else ...[
                    // Single Node style & format groups
                    VerticalToolbarGroupButton(
                      positionOnRight: positionOnRight,
                      triggerIcon: Icons.category_rounded,
                      triggerTooltip: 'Shape & Style',
                      submenuButtons: [
                        SubmenuButtonData(
                          icon: Icons.crop_square_rounded,
                          tooltip: 'Rectangle Shape',
                          onPressed: () => onShapeChanged?.call('rectangle'),
                        ),
                        SubmenuButtonData(
                          icon: Icons.rounded_corner_rounded,
                          tooltip: 'Rounded Rectangle Shape',
                          onPressed: () {},
                        ),
                        SubmenuButtonData(
                          icon: Icons.stadium_outlined,
                          tooltip: 'Pill Shape',
                          onPressed: () {},
                        ),
                        SubmenuButtonData(
                          icon: Icons.circle_outlined,
                          tooltip: 'Circle Shape',
                          onPressed: () => onShapeChanged?.call('circle'),
                        ),
                        SubmenuButtonData(
                          icon: Icons.format_color_fill_rounded,
                          tooltip: 'Background Fill Color',
                          onPressed: () {},
                        ),
                        SubmenuButtonData(
                          icon: Icons.line_weight_rounded,
                          tooltip: 'Border Style',
                          onPressed: () {},
                        ),
                      ],
                    ),
                    VerticalToolbarGroupButton(
                      positionOnRight: positionOnRight,
                      triggerIcon: Icons.settings_outlined,
                      triggerTooltip: 'Node Settings',
                      submenuButtons: [
                        SubmenuButtonData(
                          icon: Icons.bookmark_add_outlined,
                          tooltip: 'Save as Template',
                          onPressed: onSaveTemplate ?? () {},
                        ),
                        SubmenuButtonData(
                          icon: Icons.lock_outline_rounded,
                          tooltip: 'Lock/Unlock Position',
                          onPressed: () {},
                        ),
                        SubmenuButtonData(
                          icon: Icons.unfold_less_rounded,
                          tooltip: 'Collapse/Expand Subtree',
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: onPressed,
            child: Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              child: Icon(icon, color: color, size: 20),
            ),
          ),
        ),
      ),
    );
  }
}

class SubmenuButtonData {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;

  SubmenuButtonData({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
  });
}

class VerticalToolbarGroupButton extends StatefulWidget {
  final IconData triggerIcon;
  final String triggerTooltip;
  final List<SubmenuButtonData> submenuButtons;
  final double iconSize;
  final bool positionOnRight;

  const VerticalToolbarGroupButton({
    super.key,
    required this.triggerIcon,
    required this.triggerTooltip,
    required this.submenuButtons,
    this.iconSize = 20,
    this.positionOnRight = false,
  });

  @override
  State<VerticalToolbarGroupButton> createState() =>
      _VerticalToolbarGroupButtonState();
}

class _VerticalToolbarGroupButtonState
    extends State<VerticalToolbarGroupButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final textColor =
        theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Listener(
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: widget.positionOnRight
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: widget.positionOnRight
              ? [
                  // Trigger Button (First when on right)
                  _buildTriggerButton(textColor, primaryColor),

                  // Submenu - Expanded to the right
                  if (_isHovered)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: GlassPanel(
                        borderRadius: 8,
                        blur: 10,
                        color: theme.cardColor.withValues(alpha: 0.92),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        shadow: BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(2, 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: widget.submenuButtons
                              .map(
                                (btn) => _buildSubmenuButton(
                                    btn, textColor, primaryColor),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                ]
              : [
                  // Submenu - Expanded to the left
                  if (_isHovered)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GlassPanel(
                        borderRadius: 8,
                        blur: 10,
                        color: theme.cardColor.withValues(alpha: 0.92),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        shadow: BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 8,
                          offset: const Offset(-2, 2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: widget.submenuButtons
                              .map(
                                (btn) => _buildSubmenuButton(
                                    btn, textColor, primaryColor),
                              )
                              .toList(),
                        ),
                      ),
                    ),

                  // Trigger Button (Last when on left)
                  _buildTriggerButton(textColor, primaryColor),
                ],
        ),
      ),
    );
  }

  Widget _buildTriggerButton(Color textColor, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Tooltip(
        message: widget.triggerTooltip,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _isHovered
                ? primaryColor.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Icon(
              widget.triggerIcon,
              color: _isHovered
                  ? primaryColor
                  : textColor.withValues(alpha: 0.75),
              size: widget.iconSize,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmenuButton(
    SubmenuButtonData btn,
    Color defaultColor,
    Color hoverColor,
  ) {
    return HoverIconButton(
      icon: btn.icon,
      tooltip: btn.tooltip,
      onPressed: btn.onPressed,
      defaultColor: btn.color ?? defaultColor.withValues(alpha: 0.75),
      hoverColor: btn.color != null
          ? btn.color!.withValues(alpha: 0.8)
          : hoverColor,
    );
  }
}

class HoverIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color defaultColor;
  final Color hoverColor;

  const HoverIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    required this.defaultColor,
    required this.hoverColor,
  });

  @override
  Widget build(BuildContext context) {
    return HoverScaleButton(
      onTap: onPressed,
      hoverScale: 1.08,
      pressScale: 0.94,
      tooltip: tooltip,
      borderRadius: BorderRadius.circular(6),
      builder: (context, isHovered, isPressed) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
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
                color: isHovered ? hoverColor : defaultColor,
                size: 18,
              ),
            ),
          ),
        );
      },
    );
  }
}
