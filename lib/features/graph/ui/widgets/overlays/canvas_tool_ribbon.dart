import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import '../../../presentation/workspace_tabs_controller.dart';
import 'package:centrode/presentation/widgets/hover_scale_button.dart';

typedef SegmentItem<T> = ({
  IconData icon,
  String label,
  T mode,
  String? tooltip,
  String? accentBadge,
});

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

    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final textColor = theme.textTheme.bodyMedium?.color ?? onSurface;

    final tools = <SegmentItem<String>>[
      (icon: Icons.near_me_outlined, label: 'Select', mode: 'select', tooltip: 'Select Tool', accentBadge: null),
      (icon: Icons.pan_tool_outlined, label: 'Pan', mode: 'pan', tooltip: 'Pan Canvas', accentBadge: null),
      (icon: Icons.draw_rounded, label: 'Draw', mode: 'draw', tooltip: 'Freehand Drawing', accentBadge: null),
      (icon: Icons.auto_fix_high_outlined, label: 'Optimize', mode: 'optimize', tooltip: 'Optimize Graph', accentBadge: null),
    ];

    final views = <SegmentItem<String>>[
      (icon: Icons.bubble_chart_outlined, label: 'Canvas', mode: 'canvas', tooltip: 'Standard Knowledge Graph Canvas', accentBadge: null),
      (icon: Icons.hub_outlined, label: 'Graph', mode: 'force_graph', tooltip: 'Live Force-Directed Dot & Line Graph View', accentBadge: 'LIVE'),
      (icon: Icons.task_alt_rounded, label: 'Tasks', mode: 'task_view', tooltip: 'Task Overview', accentBadge: null),
      (icon: Icons.style_rounded, label: 'Flashcards', mode: 'flashcard_view', tooltip: 'Spaced Repetition Flashcards', accentBadge: null),
    ];

    return GlassPanel(
      blur: 16,
      borderRadius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      shadow: BoxShadow(
        color: Colors.black.withValues(alpha: 0.22),
        blurRadius: 16,
        spreadRadius: -2,
        offset: const Offset(0, 6),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Compact Toggle Button on the left
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                _isCompact
                    ? Icons.chevron_right_rounded
                    : Icons.chevron_left_rounded,
                color: textColor.withValues(alpha: 0.7),
                size: 20,
              ),
              tooltip: _isCompact ? 'Expand ribbon' : 'Compact ribbon',
              onPressed: () {
                setState(() {
                  _isCompact = !_isCompact;
                });
              },
            ),
            const SizedBox(width: 2),
            const _GlassDivider(),
            const SizedBox(width: 2),

            // Track 1: TOOLS (Select, Pan, Connect, Optimize)
            ValueListenableBuilder<String>(
              valueListenable: session.toolModeNotifier,
              builder: (context, currentMode, _) {
                return _RibbonCapsule(
                  label: _isCompact ? null : 'TOOLS',
                  child: GlassSlidingSegmentedControl<String>(
                    items: tools,
                    currentMode: currentMode,
                    isCompact: _isCompact,
                    onSelected: (newMode) => session.setToolMode(newMode),
                  ),
                );
              },
            ),

            const SizedBox(width: 2),
            const _GlassDivider(),
            const SizedBox(width: 2),

            // Track 2: VIEWS (Canvas, Graph, Tasks, Flashcards)
            ValueListenableBuilder<String>(
              valueListenable: session.currentViewNotifier,
              builder: (context, currentView, _) {
                return _RibbonCapsule(
                  label: _isCompact ? null : 'VIEWS',
                  child: GlassSlidingSegmentedControl<String>(
                    items: views,
                    currentMode: currentView,
                    isCompact: _isCompact,
                    onSelected: (newView) => session.currentViewNotifier.value = newView,
                  ),
                );
              },
            ),

            const SizedBox(width: 2),
            const _GlassDivider(),
            const SizedBox(width: 2),

            // Track 3: Relation Label Display Mode (Cycle through Auto -> Always -> Never)
            ValueListenableBuilder<String>(
              valueListenable: session.relationLabelModeNotifier,
              builder: (context, mode, _) {
                final labelIcons = {
                  'auto': Icons.auto_mode_rounded,
                  'always': Icons.visibility_rounded,
                  'never': Icons.visibility_off_rounded,
                };
                final labelTitles = {
                  'auto': 'Auto',
                  'always': 'Always',
                  'never': 'Never',
                };
                return _RibbonCapsule(
                  label: _isCompact ? null : 'LABELS',
                  child: HoverScaleButton(
                    onTap: () {
                      const modes = ['auto', 'always', 'never'];
                      final nextIndex = (modes.indexOf(mode) + 1) % modes.length;
                      session.relationLabelModeNotifier.value = modes[nextIndex];
                    },
                    tooltip: 'Relation Label Display: ${labelTitles[mode]} (Click to cycle)',
                    borderRadius: BorderRadius.circular(10),
                    builder: (context, isHovered, isPressed) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: EdgeInsets.symmetric(
                          horizontal: _isCompact ? 8 : 10,
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
                              labelIcons[mode] ?? Icons.label_outlined,
                              size: 16,
                              color: mode != 'auto'
                                  ? textColor
                                  : (isHovered ? primaryColor : textColor.withValues(alpha: 0.8)),
                            ),
                            if (!_isCompact) ...[
                              const SizedBox(width: 5),
                              Text(
                                labelTitles[mode] ?? mode,
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
        ),
      ),
    );
  }
}

class GlassSlidingSegmentedControl<T> extends StatefulWidget {
  final List<SegmentItem<T>> items;
  final T currentMode;
  final ValueChanged<T> onSelected;
  final bool isCompact;

  const GlassSlidingSegmentedControl({
    super.key,
    required this.items,
    required this.currentMode,
    required this.onSelected,
    required this.isCompact,
  });

  @override
  State<GlassSlidingSegmentedControl<T>> createState() => _GlassSlidingSegmentedControlState<T>();
}

class _GlassSlidingSegmentedControlState<T> extends State<GlassSlidingSegmentedControl<T>> {
  bool _isPressed = false;

  void _handlePointerPosition(Offset localPosition, double totalWidth) {
    if (totalWidth <= 0 || widget.items.isEmpty) return;
    final itemWidth = totalWidth / widget.items.length;
    final targetIndex = (localPosition.dx / itemWidth).floor().clamp(0, widget.items.length - 1);
    final targetMode = widget.items[targetIndex].mode;
    if (targetMode != widget.currentMode) {
      widget.onSelected(targetMode);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final onSurface = theme.colorScheme.onSurface;
    final textColor = theme.textTheme.bodyMedium?.color ?? onSurface;

    final activeIndex = widget.items.indexWhere((item) => item.mode == widget.currentMode);
    final safeIndex = activeIndex >= 0 ? activeIndex : 0;
    final itemWidth = widget.isCompact ? 34.0 : 88.0;

    return Listener(
      onPointerDown: (event) {
        setState(() => _isPressed = true);
        final RenderBox box = context.findRenderObject() as RenderBox;
        final local = box.globalToLocal(event.position);
        _handlePointerPosition(local, box.size.width);
      },
      onPointerMove: (event) {
        final RenderBox box = context.findRenderObject() as RenderBox;
        final local = box.globalToLocal(event.position);
        _handlePointerPosition(local, box.size.width);
      },
      onPointerUp: (_) {
        setState(() => _isPressed = false);
      },
      onPointerCancel: (_) {
        setState(() => _isPressed = false);
      },
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.08),
            width: 0.8,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Sliding Glass Thumb Indicator
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              left: safeIndex * itemWidth,
              top: 0,
              bottom: 0,
              width: itemWidth,
              child: AnimatedScale(
                scale: _isPressed ? 1.14 : 1.0,
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutBack,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withValues(alpha: _isPressed ? 0.50 : 0.35),
                        primaryColor.withValues(alpha: _isPressed ? 0.28 : 0.16),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: _isPressed ? 0.85 : 0.55),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: _isPressed ? 0.45 : 0.25),
                        blurRadius: _isPressed ? 16 : 10,
                        spreadRadius: _isPressed ? 1 : -1,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Row of Segments
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < widget.items.length; i++) ...[
                  SizedBox(
                    width: itemWidth,
                    height: 28,
                    child: Tooltip(
                      message: widget.items[i].tooltip ?? widget.items[i].label,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.items[i].icon,
                            size: 16,
                            color: i == safeIndex
                                ? textColor
                                : textColor.withValues(alpha: 0.75),
                          ),
                          if (!widget.isCompact) ...[
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                widget.items[i].label,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: i == safeIndex ? FontWeight.bold : FontWeight.w500,
                                  color: i == safeIndex
                                      ? textColor
                                      : textColor.withValues(alpha: 0.75),
                                ),
                              ),
                            ),
                          ],
                          if (!widget.isCompact && widget.items[i].accentBadge != null) ...[
                            const SizedBox(width: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: primaryColor,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                widget.items[i].accentBadge!,
                                style: const TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RibbonCapsule extends StatelessWidget {
  final Widget child;
  final String? label;

  const _RibbonCapsule({
    required this.child,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (label != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 3, right: 3),
              child: RotatedBox(
                quarterTurns: 3,
                child: Text(
                  label!,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    color: theme.colorScheme.primary.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
            Container(
              width: 1,
              height: 18,
              margin: const EdgeInsets.only(right: 4),
              color: theme.dividerColor.withValues(alpha: 0.15),
            ),
          ],
          child,
        ],
      ),
    );
  }
}

class _GlassDivider extends StatelessWidget {
  const _GlassDivider();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      width: 1.2,
      height: 26,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.dividerColor.withValues(alpha: 0.0),
            theme.dividerColor.withValues(alpha: 0.35),
            theme.dividerColor.withValues(alpha: 0.0),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}
