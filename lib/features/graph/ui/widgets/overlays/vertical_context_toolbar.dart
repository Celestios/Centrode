import 'package:flutter/material.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import 'package:centrode/features/graph/engine/config.dart';
import 'package:centrode/src/rust/domain/styles.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/shared/elements/elements.dart';

class VerticalContextToolbar extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback? onCopy;
  final bool isMulti;
  final bool isRelationOnly;
  final bool canSaveTemplate;
  final RawUuid? singleNodeId;
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
  final ValueChanged<String>? onRelationBodyStrategyChanged;
  final ValueChanged<EndpointShape>? onStartShapeChanged;
  final ValueChanged<EndpointShape>? onEndShapeChanged;

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
    this.onRelationBodyStrategyChanged,
    this.onStartShapeChanged,
    this.onEndShapeChanged,
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
              child: Builder(
                builder: (context) {
                  final preset = GlassPresets.toolbar(context);
                  return GlassPanel(
                    borderRadius: preset.borderRadius ?? 10,
                    color: preset.color,
                    blur: preset.blur ?? 12,
                    shadow: preset.shadow,
                    child: const SizedBox.shrink(),
                  );
                },
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
                    CentrodeIconButton(
                      icon: Icons.link_rounded,
                      onPressed: onDrawConnection ?? () {},
                      tooltip: 'Draw Connection',
                      iconSize: UiIconSize.standard,
                      buttonSize: 32,
                      enableHover: false,
                      iconColor: primaryColor,
                    ),
                  ],

                  if (onCopy != null)
                    CentrodeIconButton(
                      icon: Icons.copy_rounded,
                      onPressed: onCopy!,
                      tooltip: 'Copy',
                      iconSize: UiIconSize.standard,
                      buttonSize: 32,
                      enableHover: false,
                      iconColor: primaryColor,
                    ),

                  CentrodeIconButton(
                    icon: Icons.delete_outline_rounded,
                    onPressed: onDelete,
                    tooltip: 'Delete',
                    iconSize: UiIconSize.standard,
                    buttonSize: 32,
                    enableHover: false,
                    iconColor: Colors.red.shade400,
                  ),

                  // Divider between Quick Actions and Group Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 1,
                      horizontal: 4,
                    ),
                    child: GlassDivider(
                      orientation: Axis.horizontal,
                      width: 24,
                      height: 1,
                      useGradient: false,
                      alpha: 0.3,
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
                          icon: Icons.waves_rounded,
                          tooltip: 'Snake Route',
                          onPressed: () =>
                              onRelationLayoutChanged?.call('snake'),
                        ),
                        SubmenuButtonData(
                          icon: Icons.ssid_chart_rounded,
                          tooltip: 'Smooth Route',
                          onPressed: () =>
                              onRelationLayoutChanged?.call('bspline'),
                        ),
                        SubmenuButtonData(
                          icon: Icons.polyline_rounded,
                          tooltip: 'Diagonal Route',
                          onPressed: () =>
                              onRelationLayoutChanged?.call('octilinear'),
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
                          icon: Icons.line_style_rounded,
                          tooltip: 'No Body Style',
                          onPressed: () =>
                              onRelationBodyStrategyChanged?.call('none'),
                        ),
                        SubmenuButtonData(
                          icon: Icons.trending_down_rounded,
                          tooltip: 'Taper',
                          onPressed: () =>
                              onRelationBodyStrategyChanged?.call('taper'),
                        ),
                        SubmenuButtonData(
                          icon: Icons.waves_rounded,
                          tooltip: 'Wave',
                          onPressed: () => onRelationBodyStrategyChanged?.call(
                            'widthModulate',
                          ),
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
                    VerticalToolbarGroupButton(
                      positionOnRight: positionOnRight,
                      triggerIcon: Icons.play_arrow_rounded,
                      triggerTooltip: 'Start Shape',
                      submenuButtons: [
                        SubmenuButtonData(
                          icon: Icons.block_rounded,
                          tooltip: 'No Start Shape',
                          onPressed: () =>
                              onStartShapeChanged?.call(EndpointShape.none),
                        ),
                        SubmenuButtonData(
                          icon: Icons.arrow_right_rounded,
                          tooltip: 'Arrow',
                          onPressed: () =>
                              onStartShapeChanged?.call(EndpointShape.arrow),
                        ),
                        SubmenuButtonData(
                          icon: Icons.arrow_right_alt_rounded,
                          tooltip: 'Open Arrow',
                          onPressed: () => onStartShapeChanged?.call(
                            EndpointShape.openArrow,
                          ),
                        ),
                        SubmenuButtonData(
                          icon: Icons.circle,
                          tooltip: 'Circle',
                          onPressed: () =>
                              onStartShapeChanged?.call(EndpointShape.circle),
                        ),
                        SubmenuButtonData(
                          icon: Icons.diamond_rounded,
                          tooltip: 'Diamond',
                          onPressed: () =>
                              onStartShapeChanged?.call(EndpointShape.diamond),
                        ),
                        SubmenuButtonData(
                          icon: Icons.square_rounded,
                          tooltip: 'Square',
                          onPressed: () =>
                              onStartShapeChanged?.call(EndpointShape.square),
                        ),
                      ],
                    ),
                    VerticalToolbarGroupButton(
                      positionOnRight: positionOnRight,
                      triggerIcon: Icons.stop_rounded,
                      triggerTooltip: 'End Shape',
                      submenuButtons: [
                        SubmenuButtonData(
                          icon: Icons.block_rounded,
                          tooltip: 'No End Shape',
                          onPressed: () =>
                              onEndShapeChanged?.call(EndpointShape.none),
                        ),
                        SubmenuButtonData(
                          icon: Icons.arrow_right_rounded,
                          tooltip: 'Arrow',
                          onPressed: () =>
                              onEndShapeChanged?.call(EndpointShape.arrow),
                        ),
                        SubmenuButtonData(
                          icon: Icons.arrow_right_alt_rounded,
                          tooltip: 'Open Arrow',
                          onPressed: () =>
                              onEndShapeChanged?.call(EndpointShape.openArrow),
                        ),
                        SubmenuButtonData(
                          icon: Icons.circle,
                          tooltip: 'Circle',
                          onPressed: () =>
                              onEndShapeChanged?.call(EndpointShape.circle),
                        ),
                        SubmenuButtonData(
                          icon: Icons.diamond_rounded,
                          tooltip: 'Diamond',
                          onPressed: () =>
                              onEndShapeChanged?.call(EndpointShape.diamond),
                        ),
                        SubmenuButtonData(
                          icon: Icons.square_rounded,
                          tooltip: 'Square',
                          onPressed: () =>
                              onEndShapeChanged?.call(EndpointShape.square),
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
                  CentrodeIconButton(
                    icon: widget.triggerIcon,
                    onPressed: () {},
                    tooltip: widget.triggerTooltip,
                    iconSize: widget.iconSize,
                    buttonSize: 32,
                    enableHover: true,
                    hoverColor: primaryColor,
                  ),

                  // Submenu - Expanded to the right
                  if (_isHovered)
                    _buildSubmenuPanel(isRight: true, textColor: textColor, primaryColor: primaryColor),
                ]
              : [
                  // Submenu - Expanded to the left
                  if (_isHovered)
                    _buildSubmenuPanel(isRight: false, textColor: textColor, primaryColor: primaryColor),

                  // Trigger Button (Last when on left)
                  CentrodeIconButton(
                    icon: widget.triggerIcon,
                    onPressed: () {},
                    tooltip: widget.triggerTooltip,
                    iconSize: widget.iconSize,
                    buttonSize: 32,
                    enableHover: true,
                    hoverColor: primaryColor,
                  ),
                ],
        ),
      ),
    );
  }



  Widget _buildSubmenuPanel({
    required bool isRight,
    required Color textColor,
    required Color primaryColor,
  }) {
    return Padding(
      padding: EdgeInsets.only(left: isRight ? 8 : 0, right: isRight ? 0 : 8),
      child: Builder(
        builder: (context) {
          final preset = GlassPresets.submenu(context, isRight: isRight);
          return GlassPanel(
            borderRadius: preset.borderRadius ?? 8,
            color: preset.color,
            blur: preset.blur ?? 10,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            shadow: preset.shadow,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: widget.submenuButtons
                  .map((btn) => _buildSubmenuButton(btn, textColor, primaryColor))
                  .toList(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSubmenuButton(
    SubmenuButtonData btn,
    Color defaultColor,
    Color hoverColor,
  ) {
    return CentrodeIconButton(
      icon: btn.icon,
      tooltip: btn.tooltip,
      onPressed: btn.onPressed,
      iconSize: UiIconSize.standard,
      buttonSize: 28,
      iconColor: btn.color ?? defaultColor.withValues(alpha: 0.75),
      hoverColor: btn.color != null
          ? btn.color!.withValues(alpha: 0.8)
          : hoverColor,
    );
  }
}

