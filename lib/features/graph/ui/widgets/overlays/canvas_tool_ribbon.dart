import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import 'package:centrode/shared/elements/elements.dart';
import '../../../presentation/workspace_tabs_controller.dart';
import 'package:centrode/presentation/widgets/hover_scale_button.dart';

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
    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final textColor = theme.textTheme.bodyMedium?.color ?? onSurface;

    final tools = <SegmentItem<String>>[
      (icon: Icons.near_me_outlined, label: 'Select', mode: 'select', tooltip: 'Select Tool (Single or Marquee)', accentBadge: null),
      if (isAndroid)
        (icon: Icons.pan_tool_outlined, label: 'Pan', mode: 'pan', tooltip: 'Pan Canvas (No accidental selections)', accentBadge: null),
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
                iconSize: 20,
                compact: true,
              ),
              const SizedBox(width: 2),
              GlassDivider(useGradient: true),
              const SizedBox(width: 2),
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
              const SizedBox(width: 2),
              GlassDivider(useGradient: true),
              const SizedBox(width: 2),

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

              const SizedBox(width: 2),
              GlassDivider(useGradient: true),
              const SizedBox(width: 2),

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
                      borderRadius: BorderRadius.circular(10),
                      builder: (context, isHovered, isPressed) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: EdgeInsets.symmetric(
                            horizontal: effectiveCompact ? 8 : 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: mode != 'auto'
                                ? primaryColor.withValues(alpha: 0.25)
                                : (isHovered
                                    ? primaryColor.withValues(alpha: 0.12)
                                    : Colors.transparent),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: mode != 'auto'
                                  ? primaryColor.withValues(alpha: 0.55)
                                  : (isHovered
                                      ? primaryColor.withValues(alpha: 0.3)
                                      : Colors.transparent),
                              width: 1.0,
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
                                size: 16,
                                color: mode != 'auto'
                                    ? textColor
                                    : (isHovered ? primaryColor : textColor.withValues(alpha: 0.8)),
                              ),
                              if (!effectiveCompact) ...[
                                const SizedBox(width: 5),
                                Text(
                                  _labelTitles[mode] ?? mode,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: mode != 'auto' ? FontWeight.bold : FontWeight.w500,
                                    color: mode != 'auto'
                                        ? textColor
                                        : (isHovered ? primaryColor : textColor),
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
    final onSurface = theme.colorScheme.onSurface;
    final textColor = theme.textTheme.bodyMedium?.color ?? onSurface;

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
      child: PopupMenuButton<String>(
        padding: EdgeInsets.zero,
        icon: Icon(
          Icons.grid_view_rounded,
          color: primaryColor,
          size: 20,
        ),
        tooltip: 'Extra Ribbon Options',
        offset: const Offset(0, -180),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: theme.cardColor,
        onSelected: (value) {
          if (value.startsWith('view_')) {
            activeSession.currentViewNotifier.value = value.substring(5);
          } else if (value.startsWith('label_')) {
            activeSession.relationLabelModeNotifier.value = value.substring(6);
          }
        },
        itemBuilder: (context) {
          final currentView = activeSession.currentViewNotifier.value;
          final currentLabelMode = activeSession.relationLabelModeNotifier.value;

          return [
            const PopupMenuItem<String>(
              enabled: false,
              child: Text(
                'VIEWS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            for (final view in views)
              PopupMenuItem<String>(
                value: 'view_${view.mode}',
                child: Row(
                  children: [
                    Icon(
                      view.icon,
                      size: 16,
                      color: view.mode == currentView ? primaryColor : textColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      view.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: view.mode == currentView ? FontWeight.bold : FontWeight.normal,
                        color: view.mode == currentView ? primaryColor : textColor,
                      ),
                    ),
                  ],
                ),
              ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              enabled: false,
              child: Text(
                'RELATION LABELS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ),
            for (final mode in _labelModes)
              PopupMenuItem<String>(
                value: 'label_$mode',
                child: Row(
                  children: [
                    Icon(_labelIcons[mode]!, size: 16, color: currentLabelMode == mode ? primaryColor : textColor),
                    const SizedBox(width: 8),
                    Text(_labelDisplayTitles[mode]!, style: TextStyle(fontSize: 12, color: currentLabelMode == mode ? primaryColor : textColor)),
                  ],
                ),
              ),
          ];
        },
      ),
    );
  }
}
