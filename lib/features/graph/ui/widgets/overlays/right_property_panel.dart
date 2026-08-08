import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/node_render_state.dart';
import 'package:centrode/shared/utils/color_utils.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';

class RightPropertyPanel extends StatefulWidget {
  const RightPropertyPanel({super.key});

  @override
  State<RightPropertyPanel> createState() => _RightPropertyPanelState();
}

class _RightPropertyPanelState extends State<RightPropertyPanel> {
  double _panelWidth = 280.0;
  bool _isExpanded = false;

  static const double _handleWidth = 42.0;
  static const double _handleHeight = 160.0;
  static const double _gapWidth = 4.0;
  static const double _defaultPanelWidth = 280.0;
  static const double _minPanelWidth = 200.0;
  static const double _maxPanelWidth = 500.0;

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
    final isSelected = selectedEntities.isNotEmpty;

    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    final double contentWidth = _handleWidth + _gapWidth + _panelWidth;
    final double totalWidth = _isExpanded ? contentWidth : _handleWidth;

    return AnimatedContainer(
      duration: Duration(milliseconds: _isDragging ? 0 : 250),
      curve: Curves.easeInOut,
      width: totalWidth,
      child: ClipRect(
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
                  isSelected,
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
                  isSelected,
                  nodeCount,
                  relationCount,
                ),
              ),
            ],
          ),
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
            offset: const Offset(-2, 2),
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
                if (!isSelected)
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
    bool isSelected,
    int nodeCount,
    int relationCount,
  ) {
    final theme = Theme.of(context);
    final parts = <String>[];
    if (nodeCount > 0) parts.add('$nodeCount node${nodeCount == 1 ? '' : 's'}');
    if (relationCount > 0) {
      parts.add('$relationCount relation${relationCount == 1 ? '' : 's'}');
    }
    final selectionText = parts.join(', ');

    return GlassPanel(
      borderRadius: 16,
      blur: 12.0,
      shadow: BoxShadow(
        color: Colors.black.withValues(alpha: 0.25),
        blurRadius: 12,
        offset: const Offset(-3, 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTabBar(context, renderState),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              width: double.infinity,
              child: Text(
                isSelected ? selectionText : 'Canvas Workspace',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, NodeRenderState renderState) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<InspectorTab>(
      valueListenable: renderState.activeInspectorTabNotifier,
      builder: (context, activeTab, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.15),
              ),
            ),
          ),
          child: Container(
            height: 36,
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: theme.cardColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: theme.dividerColor.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    context,
                    label: 'Appearance',
                    isActive: activeTab == InspectorTab.appearance,
                    onTap: () {
                      renderState.activeInspectorTabNotifier.value =
                          InspectorTab.appearance;
                    },
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    context,
                    label: 'Data',
                    isActive: activeTab == InspectorTab.data,
                    onTap: () {
                      renderState.activeInspectorTabNotifier.value =
                          InspectorTab.data;
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTabButton(
    BuildContext context, {
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isPanelDark = ColorUtils.isDark(theme.cardColor);
    final activeBgColor = theme.colorScheme.primary;
    final activeTextColor = ColorUtils.getContrastTextColor(activeBgColor);
    final inactiveTextColor = isPanelDark
        ? Colors.white.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.6);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? activeBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeBgColor.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            color: isActive ? activeTextColor : inactiveTextColor,
          ),
        ),
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
            color: ColorUtils.getContrastTextColor(color),
          ),
        ),
      ),
    );
  }
}
