import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/node_render_state.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import 'package:centrode/shared/elements/elements.dart';
import '../inspector/relation_appearance_section.dart';
import 'inspector/data_tab.dart';

class RightPropertyPanel extends StatefulWidget {
  const RightPropertyPanel({super.key});

  @override
  State<RightPropertyPanel> createState() => _RightPropertyPanelState();
}

class _RightPropertyPanelState extends State<RightPropertyPanel> {
  double _panelWidth = 320.0;
  bool _isExpanded = false;

  static const double _handleWidth = 42.0;
  static const double _handleHeight = 160.0;
  static const double _gapWidth = 4.0;
  static const double _defaultPanelWidth = 320.0;
  static const double _minPanelWidth = 240.0;
  static const double _maxPanelWidth = 550.0;

  bool _isHovered = false;
  bool _isDragging = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded && _panelWidth < _minPanelWidth) {
        _panelWidth = _defaultPanelWidth;
      }
    });
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _isDragging = true;
      _panelWidth = (_panelWidth - details.primaryDelta!)
          .clamp(_minPanelWidth, _maxPanelWidth);
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
      final velocity = details.primaryVelocity ?? 0.0;
      if (velocity > 300) {
        _isExpanded = false;
      } else if (velocity < -300) {
        _isExpanded = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final renderState = context.watch<NodeRenderState>();
    final selectedEntities = renderState.selectedEntities;
    final nodeCount = selectedEntities
        .where((id) => renderState.nodeLookup.containsKey(id))
        .length;
    final relationCount = selectedEntities
        .where((id) => renderState.relationLookup.containsKey(id))
        .length;

    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final double contentWidth = _handleWidth + _gapWidth + _panelWidth;
    final double totalWidth = _isExpanded ? contentWidth : _handleWidth;

    return AnimatedContainer(
      duration: Duration(milliseconds: _isDragging ? 0 : 250),
      curve: Curves.easeInOut,
      width: totalWidth,
      child: OverflowBox(
        alignment: Alignment.bottomLeft,
        minWidth: contentWidth,
        maxWidth: contentWidth,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: _handleWidth,
              height: _handleHeight,
              child: _buildHandle(
                primaryColor,
                selectedEntities.isNotEmpty,
                nodeCount,
                relationCount,
              ),
            ),
            const SizedBox(width: _gapWidth),
            SizedBox(
              width: _panelWidth,
              child: _buildContentPanel(
                context,
                renderState,
                selectedEntities,
                nodeCount,
                relationCount,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle(
    Color primaryColor,
    bool isSelected,
    int nodeCount,
    int relationCount,
  ) {
    final relationColor = Colors.amber.shade600;
    final showBadges = isSelected && !_isExpanded;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _toggleExpanded,
        onHorizontalDragUpdate: _handleHorizontalDragUpdate,
        onHorizontalDragEnd: _handleHorizontalDragEnd,
        behavior: HitTestBehavior.opaque,
        child: GlassPanel(
          width: _handleWidth,
          height: _handleHeight,
          borderRadius: 12,
          blur: 12.0,
          shadow: BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 4.0),
            decoration: BoxDecoration(
              color: _isHovered
                  ? primaryColor.withValues(alpha: 0.18)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (!showBadges)
                  Icon(
                    Icons.tune_rounded,
                    size: 16,
                    color: primaryColor,
                  )
                else
                  Center(
                    child: SizedBox(
                      width: 34,
                      height: 18,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          if (relationCount > 0)
                            Positioned(
                              left: nodeCount > 0 ? 1 : 8,
                              top: 0,
                              child: _BadgeCircle(
                                count: relationCount,
                                color: relationColor,
                                size: 18,
                              ),
                            ),
                          if (nodeCount > 0)
                            Positioned(
                              left: relationCount > 0 ? 15 : 8,
                              top: 0,
                              child: _BadgeCircle(
                                count: nodeCount,
                                color: primaryColor,
                                size: 18,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: Center(
                    child: RotatedBox(
                      quarterTurns: 3,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'INSPECTOR',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: primaryColor.withValues(alpha: 0.9),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Icon(
                  _isExpanded
                      ? Icons.chevron_right_rounded
                      : Icons.chevron_left_rounded,
                  size: 16,
                  color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContentPanel(
    BuildContext context,
    NodeRenderState renderState,
    Set<dynamic> selectedEntities,
    int nodeCount,
    int relationCount,
  ) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final amberColor = Colors.amber.shade600;

    final isNothingSelected = nodeCount == 0 && relationCount == 0;
    final isOnlyNodes = nodeCount > 0 && relationCount == 0;
    final isOnlyRelations = relationCount > 0 && nodeCount == 0;

    final Color panelEdgeColor = isNothingSelected
        ? Colors.white.withValues(alpha: 0.25)
        : isOnlyNodes
            ? primaryColor.withValues(alpha: 0.65)
            : isOnlyRelations
                ? amberColor.withValues(alpha: 0.65)
                : primaryColor.withValues(alpha: 0.65);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: panelEdgeColor,
          width: isNothingSelected ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isNothingSelected
                ? Colors.white.withValues(alpha: 0.08)
                : panelEdgeColor.withValues(alpha: 0.15),
            blurRadius: isNothingSelected ? 12 : 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: GlassPanel(
        borderRadius: 16,
        blur: 12.0,
        shadow: BoxShadow(
          color: Colors.black.withValues(alpha: 0.25),
          blurRadius: 12,
          offset: const Offset(0, 3),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Tab Switcher Bar (Appearance vs Data)
              _buildTopTabBar(context, renderState),
              const SizedBox(height: 10),

              // Main Dynamic Body with Full-Width Sliding Tab Transition
              Expanded(
                child: ClipRect(
                  child: ValueListenableBuilder<InspectorTab>(
                    valueListenable: renderState.activeInspectorTabNotifier,
                    builder: (context, activeTab, _) {
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 280),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                          return Stack(
                            alignment: Alignment.topCenter,
                            children: <Widget>[
                              ...previousChildren,
                              if (currentChild != null) currentChild,
                            ],
                          );
                        },
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          final isData = child.key == const ValueKey('data_tab');
                          final inOffset = Tween<Offset>(
                            begin: Offset(isData ? 1.0 : -1.0, 0.0),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeInOutCubic,
                          ));
                          final fadeAnim = Tween<double>(begin: 0.15, end: 1.0).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeInOut,
                            ),
                          );
                          return SlideTransition(
                            position: inOffset,
                            child: FadeTransition(opacity: fadeAnim, child: child),
                          );
                        },
                      child: activeTab == InspectorTab.data
                          ? KeyedSubtree(
                              key: const ValueKey('data_tab'),
                              child: nodeCount > 0
                                  ? SingleChildScrollView(
                                      physics: const BouncingScrollPhysics(),
                                      child: DataTab(
                                        nodeId: selectedEntities.firstWhere(
                                          (id) => renderState.nodeLookup.containsKey(id),
                                        ),
                                        renderState: renderState,
                                      ),
                                    )
                                  : Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                                        child: Text(
                                          'Select a node to inspect and edit its Tags & Comments.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.color
                                                ?.withValues(alpha: 0.5),
                                          ),
                                        ),
                                      ),
                                    ),
                            )
                          : KeyedSubtree(
                              key: const ValueKey('appearance_tab'),
                              child: ListView(
                                padding: EdgeInsets.zero,
                                physics: const BouncingScrollPhysics(),
                                children: [
                                  if (isNothingSelected || nodeCount > 0)
                                    NodesSectionShell(isGlobal: isNothingSelected),
                                  if (isNothingSelected || relationCount > 0)
                                    RelationsSectionShell(isGlobal: isNothingSelected),
                                ],
                              ),
                            ),
                    );
                  },
                ),
              ),
            ),

              const SizedBox(height: 8),

              // Scope Status Badge Moved to Bottom
              _ContextStatusBadge(
                nodeCount: nodeCount,
                relationCount: relationCount,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopTabBar(
    BuildContext context,
    NodeRenderState renderState,
  ) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return ValueListenableBuilder<InspectorTab>(
      valueListenable: renderState.activeInspectorTabNotifier,
      builder: (context, activeTab, _) {
        final isAppearance = activeTab == InspectorTab.appearance;

        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.1),
              width: 0.8,
            ),
          ),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOutCubic,
            tween: Tween<double>(
              begin: isAppearance ? 1.0 : 0.0,
              end: isAppearance ? 1.0 : 0.0,
            ),
            builder: (context, progress, _) {
              final appearanceFlex = (1000 * (1.0 + progress * 0.75)).round();
              final dataFlex = (1000 * (1.0 + (1.0 - progress) * 0.75)).round();

              return Row(
                children: [
                  Expanded(
                    flex: appearanceFlex,
                    child: _GlassTabButton(
                      icon: Icons.palette_rounded,
                      label: 'Appearance',
                      isActive: isAppearance,
                      activeColor: primaryColor,
                      onTap: () {
                        renderState.activeInspectorTabNotifier.value =
                            InspectorTab.appearance;
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: dataFlex,
                    child: _GlassTabButton(
                      icon: Icons.storage_rounded,
                      label: 'Data',
                      isActive: !isAppearance,
                      activeColor: primaryColor,
                      onTap: () {
                        renderState.activeInspectorTabNotifier.value =
                            InspectorTab.data;
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

/// Standout Prominent Top Context Status Badge Bounding Box.
class _ContextStatusBadge extends StatelessWidget {
  final int nodeCount;
  final int relationCount;

  const _ContextStatusBadge({
    required this.nodeCount,
    required this.relationCount,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final amberColor = Colors.amber.shade600;
    final neutralColor = Colors.white.withValues(alpha: 0.85);

    final isNothingSelected = nodeCount == 0 && relationCount == 0;
    final isOnlyNodes = nodeCount > 0 && relationCount == 0;
    final isOnlyRelations = relationCount > 0 && nodeCount == 0;
    final isMixed = nodeCount > 0 && relationCount > 0;

    Color primaryAccent;
    if (isNothingSelected) {
      primaryAccent = neutralColor;
    } else if (isOnlyNodes) {
      primaryAccent = primaryColor;
    } else if (isOnlyRelations) {
      primaryAccent = amberColor;
    } else {
      primaryAccent = primaryColor;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isNothingSelected
              ? Colors.white.withValues(alpha: 0.22)
              : primaryAccent.withValues(alpha: 0.6),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isNothingSelected
                ? Colors.white.withValues(alpha: 0.06)
                : primaryAccent.withValues(alpha: 0.25),
            blurRadius: 8,
            spreadRadius: -1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isNothingSelected) ...[
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 0.8),
              ),
              child: Icon(Icons.public_rounded, size: 11, color: neutralColor),
            ),
            const SizedBox(width: 6),
            Text(
              'GLOBAL DEFAULTS',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.9,
                color: neutralColor,
              ),
            ),
          ] else if (isOnlyNodes) ...[
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: primaryColor.withValues(alpha: 0.6), width: 0.8),
              ),
              child: Icon(Icons.account_tree_rounded, size: 11, color: primaryColor),
            ),
            const SizedBox(width: 6),
            Text(
              '$nodeCount NODE${nodeCount > 1 ? 'S' : ''} SELECTED',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: primaryColor,
              ),
            ),
          ] else if (isOnlyRelations) ...[
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: amberColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: amberColor.withValues(alpha: 0.6), width: 0.8),
              ),
              child: Icon(Icons.link_rounded, size: 11, color: amberColor),
            ),
            const SizedBox(width: 6),
            Text(
              '$relationCount RELATION${relationCount > 1 ? 'S' : ''} SELECTED',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: amberColor,
              ),
            ),
          ] else if (isMixed) ...[
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.account_tree_rounded, size: 10, color: primaryColor),
            ),
            const SizedBox(width: 4),
            Text(
              '$nodeCount NODE${nodeCount > 1 ? 'S' : ''}',
              style: TextStyle(
                fontSize: 9.0,
                fontWeight: FontWeight.w800,
                color: primaryColor,
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 1.0,
              height: 10,
              color: Colors.white24,
            ),
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: amberColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.link_rounded, size: 10, color: amberColor),
            ),
            const SizedBox(width: 4),
            Text(
              '$relationCount RELATION${relationCount > 1 ? 'S' : ''}',
              style: TextStyle(
                fontSize: 9.0,
                fontWeight: FontWeight.w800,
                color: amberColor,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BadgeCircle extends StatelessWidget {
  final int count;
  final Color color;
  final double size;

  const _BadgeCircle({
    required this.count,
    required this.color,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).scaffoldBackgroundColor,
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          '$count',
          style: TextStyle(
            fontSize: size * 0.45,
            fontWeight: FontWeight.w900,
            color: Colors.black87,
          ),
        ),
      ),
    );
  }
}

class _GlassTabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const _GlassTabButton({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyMedium?.color ?? theme.colorScheme.onSurface;

    return CentrodeButton(
      onTap: onTap,
      enableHover: false,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 30,
        decoration: BoxDecoration(
          color: isActive
              ? activeColor.withValues(alpha: 0.25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 0.5)
                : Colors.transparent,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: isActive ? 14 : 12.5,
              color: isActive
                  ? activeColor
                  : textColor.withValues(alpha: 0.6),
            ),
            const SizedBox(width: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 180),
              style: TextStyle(
                fontSize: isActive ? 11.5 : 10.0,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? activeColor
                    : textColor.withValues(alpha: 0.7),
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
