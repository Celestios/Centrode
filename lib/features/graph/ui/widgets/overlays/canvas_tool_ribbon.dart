import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import 'package:centrode/shared/elements/elements.dart';
import 'package:centrode/shared/widgets/context_menu_overlay.dart';
import '../../../presentation/workspace_tabs_controller.dart';

const _labelModes = ['auto', 'always', 'never'];
const _labelIcons = {
  'auto': Icons.auto_mode_rounded,
  'always': Icons.visibility_rounded,
  'never': Icons.visibility_off_rounded,
};
const _labelTitles = {
  'auto': 'Auto',
  'always': 'Always',
  'never': 'Never',
};
const _labelDisplayTitles = {
  'auto': 'Auto Display',
  'always': 'Always Show',
  'never': 'Never Show',
};


class CanvasToolRibbon extends StatefulWidget {
  const CanvasToolRibbon({super.key});

  @override
  State<CanvasToolRibbon> createState() => _CanvasToolRibbonState();
}

class _CanvasToolRibbonState extends State<CanvasToolRibbon> {
  bool _isCompact = true;

  @override
  Widget build(BuildContext context) {
    final tabsController = context.watch<WorkspaceTabsController>();
    final session = tabsController.activeSession;
    final isAndroid = !kIsWeb && Platform.isAndroid;
    final effectiveCompact = isAndroid || _isCompact;

    final theme = Theme.of(context);
    final palette = CentrodeDerivedPalette.of(context);
    final primaryColor = theme.colorScheme.primary;

    final tools = <SegmentItem<String>>[
      (icon: Icons.near_me_outlined, label: 'Select', mode: 'select', tooltip: 'Select Tool (Single or Marquee)', accentBadge: null),
      if (isAndroid)
        (icon: Icons.pan_tool_outlined, label: 'Pan', mode: 'pan', tooltip: 'Pan Canvas (No accidental selections)', accentBadge: null),
      (icon: Icons.crop_square_rounded, label: 'Frame', mode: 'frame', tooltip: 'Frame Tool (Draw Grouping Box)', accentBadge: null),
      (icon: Icons.draw_rounded, label: 'Draw', mode: 'draw', tooltip: 'Freehand Drawing', accentBadge: null),
      (icon: Icons.auto_fix_high_outlined, label: 'Optimize', mode: 'optimize', tooltip: 'Optimize Graph', accentBadge: null),
    ];

    final views = <SegmentItem<String>>[
      (icon: Icons.bubble_chart_outlined, label: 'Canvas', mode: 'canvas', tooltip: 'Standard Knowledge Graph Canvas', accentBadge: null),
      (icon: Icons.hub_outlined, label: 'Graph', mode: 'force_graph', tooltip: 'Live Force-Directed Dot & Line Graph View', accentBadge: 'LIVE'),
      (icon: Icons.task_alt_rounded, label: 'Tasks', mode: 'task_view', tooltip: 'Task Overview', accentBadge: null),
      (icon: Icons.style_rounded, label: 'Flashcards', mode: 'flashcard_view', tooltip: 'Spaced Repetition Flashcards', accentBadge: null),
    ];

    final ribbonPreset = GlassPresets.ribbon(context);

    return GlassPanel(
      borderRadius: ribbonPreset.borderRadius!,
      blur: ribbonPreset.blur!,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shadow: ribbonPreset.shadow,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Compact Toggle Button on the left (Desktop only)
            if (!isAndroid) ...[
              CentrodeIconButton(
                icon: effectiveCompact
                    ? Icons.chevron_right_rounded
                    : Icons.chevron_left_rounded,
                onPressed: () {
                  setState(() {
                    _isCompact = !_isCompact;
                  });
                },
                tooltip: effectiveCompact ? 'Expand ribbon' : 'Compact ribbon',
                iconSize: UiIconSize.standard,
                compact: true,
              ),
              const SizedBox(width: UiSpacing.tight),
              GlassDivider(useGradient: true),
              const SizedBox(width: UiSpacing.tight),
            ],

            // Track 1: TOOLS (Select, Pan, Connect, Optimize)
            ValueListenableBuilder<String>(
              valueListenable: session.toolModeNotifier,
              builder: (context, currentMode, _) {
                  return RibbonCapsule(
                    label: effectiveCompact ? null : 'TOOLS',
                    child: CentrodeSegmentedControl<String>(
                      items: tools,
                      currentMode: currentMode,
                      isCompact: effectiveCompact,
                      onSelected: (newMode) => session.setToolMode(newMode),
                    ),
                  );
              },
            ),

            if (!isAndroid) ...[
              const SizedBox(width: UiSpacing.tight),
              GlassDivider(useGradient: true),
              const SizedBox(width: UiSpacing.tight),

              // Track 2: VIEWS (Canvas, Graph, Tasks, Flashcards)
              ValueListenableBuilder<String>(
                valueListenable: session.currentViewNotifier,
                builder: (context, currentView, _) {
                  return RibbonCapsule(
                    label: effectiveCompact ? null : 'VIEWS',
                    child: CentrodeSegmentedControl<String>(
                      items: views,
                      currentMode: currentView,
                      isCompact: effectiveCompact,
                      onSelected: (newView) => session.currentViewNotifier.value = newView,
                    ),
                  );
                },
              ),

              const SizedBox(width: UiSpacing.tight),
              GlassDivider(useGradient: true),
              const SizedBox(width: UiSpacing.tight),

              // Track 3: Relation Label Display Mode
              ValueListenableBuilder<String>(
                valueListenable: session.relationLabelModeNotifier,
                builder: (context, mode, _) {
                  return RibbonCapsule(
                    label: effectiveCompact ? null : 'LABELS',
                    child: HoverScaleButton(
                      onTap: () {
                        final nextIndex = (_labelModes.indexOf(mode) + 1) % _labelModes.length;
                        session.relationLabelModeNotifier.value = _labelModes[nextIndex];
                      },
                      tooltip: 'Relation Label Display: ${_labelTitles[mode]} (Click to cycle)',
                      borderRadius: BorderRadius.circular(UiRadius.panel),
                      builder: (context, isHovered, isPressed) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: UiControlSize.dense + 4,
                          padding: EdgeInsets.symmetric(
                            horizontal: effectiveCompact ? 8 : 10,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: mode != 'auto'
                                ? primaryColor.withValues(alpha: 0.25)
                                : (isHovered
                                    ? palette.hoverOverlay
                                    : palette.surface.controlBackground),
                            borderRadius: BorderRadius.circular(UiRadius.panel),
                            border: Border.all(
                              color: mode != 'auto'
                                  ? primaryColor.withValues(alpha: 0.55)
                                  : (isHovered
                                      ? primaryColor.withValues(alpha: 0.3)
                                      : palette.surface.controlBorder),
                              width: UiStrokeWidth.subtle,
                            ),
                            boxShadow: mode != 'auto'
                                ? [
                                    BoxShadow(
                                      color: primaryColor.withValues(alpha: 0.2),
                                      blurRadius: 8,
                                      spreadRadius: -1,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _labelIcons[mode] ?? Icons.label_outlined,
                                size: UiIconSize.dense,
                                color: mode != 'auto'
                                    ? palette.textOn(primaryColor.withValues(alpha: 0.25))
                                    : (isHovered ? primaryColor : palette.surface.controlForeground.withValues(alpha: 0.8)),
                              ),
                              if (!effectiveCompact) ...[
                                const SizedBox(width: 5),
                                Text(
                                  _labelTitles[mode] ?? mode,
                                  style: TextStyle(
                                    fontSize: UiFont.compact,
                                    fontWeight: mode != 'auto' ? FontWeight.bold : FontWeight.w500,
                                    color: mode != 'auto'
                                        ? palette.textOn(primaryColor.withValues(alpha: 0.25))
                                        : (isHovered ? primaryColor : palette.surface.controlForeground),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ExtraRibbonMenuWidget extends StatelessWidget {
  final TabSession? session;

  const ExtraRibbonMenuWidget({super.key, this.session});

  @override
  Widget build(BuildContext context) {
    final tabsController = Provider.of<WorkspaceTabsController>(context);
    final activeSession = session ?? tabsController.activeSession;

    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final views = <SegmentItem<String>>[
      (icon: Icons.bubble_chart_outlined, label: 'Canvas', mode: 'canvas', tooltip: 'Standard Knowledge Graph Canvas', accentBadge: null),
      (icon: Icons.hub_outlined, label: 'Graph', mode: 'force_graph', tooltip: 'Live Force-Directed Dot & Line Graph View', accentBadge: 'LIVE'),
      (icon: Icons.task_alt_rounded, label: 'Tasks', mode: 'task_view', tooltip: 'Task Overview', accentBadge: null),
      (icon: Icons.style_rounded, label: 'Flashcards', mode: 'flashcard_view', tooltip: 'Spaced Repetition Flashcards', accentBadge: null),
    ];

    final iconButtonPreset = GlassPresets.iconButton(context);

    return GlassPanel(
      borderRadius: iconButtonPreset.borderRadius!,
      width: iconButtonPreset.width,
      height: iconButtonPreset.height,
      padding: EdgeInsets.zero,
      child: Builder(
        builder: (btnContext) => MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              final renderBox = btnContext.findRenderObject() as RenderBox;
              final targetRect =
                  renderBox.localToGlobal(Offset.zero) & renderBox.size;

              CentrodeContextMenu.showAt(
                context: btnContext,
                targetRect: targetRect,
                items: [
                  const CentrodeMenuItem.header('VIEWS'),
                  for (final view in views)
                    CentrodeMenuItem.action(
                      label: view.label,
                      leadingIcon: view.icon,
                      onTap: () {
                        activeSession.currentViewNotifier.value = view.mode;
                      },
                    ),
                  const CentrodeMenuItem.divider(),
                  const CentrodeMenuItem.header('RELATION LABELS'),
                  for (final mode in _labelModes)
                    CentrodeMenuItem.action(
                      label: _labelDisplayTitles[mode]!,
                      leadingIcon: _labelIcons[mode]!,
                      onTap: () {
                        activeSession.relationLabelModeNotifier.value = mode;
                      },
                    ),
                ],
              );
            },
            child: Center(
              child: Icon(
                Icons.grid_view_rounded,
                color: primaryColor,
                size: UiIconSize.standard,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
