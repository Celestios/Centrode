import 'package:flutter/material.dart';
import '../../../../presentation/node_render_state.dart';
import '../../../../models/models.dart';
import 'package:mycelium/features/graph/engine/config.dart';
import 'package:mycelium/features/graph/presentation/strategies/node_style_strategy.dart';
import 'package:mycelium/shared/utils/color_utils.dart';
import 'package:mycelium/shared/widgets/color_palette/color_palette.dart';

class AppearanceTab extends StatelessWidget {
  final Set<String> selectedEntities;
  final NodeRenderState renderState;

  const AppearanceTab({
    super.key,
    required this.selectedEntities,
    required this.renderState,
  });

  NodeStyle _getEffectiveStyle(UiNode node) {
    return node.style ?? NodeStyleStrategy.resolveStyle(node);
  }

  void _updateSelectedNodesStyle(
    List<String> nodeIds,
    NodeRenderState renderState,
    NodeStyle Function(NodeStyle style) updateFn,
  ) {
    renderState.updateNodesStyle(nodeIds, updateFn);
  }

  Widget _buildSectionHeader(ThemeData theme, String title, {IconData? icon}) {
    if (icon != null) {
      return Row(
        children: [
          Icon(
            icon,
            size: 10,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      );
    }
    return Text(
      title,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildCenteredPlaceholder(ThemeData theme, String text) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildStyleSlider(
    BuildContext context, {
    required String title,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(theme, title),
            Text(
              value.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 2,
            activeTrackColor: theme.colorScheme.primary,
            inactiveTrackColor: theme.dividerColor.withValues(alpha: 0.15),
            thumbColor: theme.colorScheme.primary,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nodeIds = selectedEntities
        .where((id) => renderState.getNode(id) != null)
        .toList();
    final relationIds = selectedEntities
        .where((id) => renderState.getRelation(id) != null)
        .toList();

    if (nodeIds.isEmpty && relationIds.isEmpty) {
      return _buildCenteredPlaceholder(
        theme,
        'Select an item to customize appearance',
      );
    }

    if (relationIds.isNotEmpty && nodeIds.isEmpty) {
      final firstRelation = renderState.getRelation(relationIds.first)!;
      final currentStrategy = firstRelation.layout?.strategyType ?? 'default';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(theme, 'LINE STYLE'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _StrategyButton(
                  icon: Icons.horizontal_rule_rounded,
                  label: 'Straight',
                  strategyType: 'default',
                  currentStrategy: currentStrategy,
                  theme: theme,
                  onTap: () => renderState.updateRelationsLayout(
                    relationIds,
                    strategyType: 'default',
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _StrategyButton(
                  icon: Icons.gesture_rounded,
                  label: 'Bezier',
                  strategyType: 'bezier',
                  currentStrategy: currentStrategy,
                  theme: theme,
                  onTap: () => renderState.updateRelationsLayout(
                    relationIds,
                    strategyType: 'bezier',
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _StrategyButton(
                  icon: Icons.alt_route_rounded,
                  label: 'Orthogonal',
                  strategyType: 'orthogonal',
                  currentStrategy: currentStrategy,
                  theme: theme,
                  onTap: () => renderState.updateRelationsLayout(
                    relationIds,
                    strategyType: 'orthogonal',
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    final firstNode = renderState.getNode(nodeIds.first)!;
    final currentStyle = _getEffectiveStyle(firstNode);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(theme, 'SHAPE'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _updateSelectedNodesStyle(
                  nodeIds,
                  renderState,
                  (style) => style.copyWith(shape: 'rectangle'),
                ),
                icon: const Icon(Icons.crop_square, size: 16),
                label: const Text('Rectangle', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: currentStyle.shape != 'circle'
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                  side: BorderSide(
                    color: currentStyle.shape != 'circle'
                        ? theme.colorScheme.primary
                        : theme.dividerColor.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _updateSelectedNodesStyle(
                  nodeIds,
                  renderState,
                  (style) => style.copyWith(shape: 'circle'),
                ),
                icon: const Icon(Icons.circle_outlined, size: 16),
                label: const Text('Circle', style: TextStyle(fontSize: 11)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: currentStyle.shape == 'circle'
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                  side: BorderSide(
                    color: currentStyle.shape == 'circle'
                        ? theme.colorScheme.primary
                        : theme.dividerColor.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildSectionHeader(theme, 'BACKGROUND COLOR'),
        const SizedBox(height: 8),
        UniversalColorPalette(
          initialColor: Color(currentStyle.bgColor),
          mode: ColorPaletteMode.advanced,
          showAlpha: true,
          onColorSelected: (col) => _updateSelectedNodesStyle(
            nodeIds,
            renderState,
            (style) => style.copyWith(
              bgColor: col.toARGB32(),
              textColor: ColorUtils.getContrastTextColorInt(col.toARGB32()),
              strokeColor: ColorUtils.getContrastStrokeColorInt(col.toARGB32()),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildStyleSlider(
          context,
          title: 'FONT SIZE',
          value: currentStyle.fontSize,
          min: AppConfig.node.minFontSize,
          max: AppConfig.node.maxFontSize,
          onChanged: (val) => _updateSelectedNodesStyle(
            nodeIds,
            renderState,
            (style) => style.copyWith(fontSize: val),
          ),
        ),
        const SizedBox(height: 12),
        _buildStyleSlider(
          context,
          title: 'BORDER RADIUS',
          value: currentStyle.borderRadius,
          min: 0,
          max: 24,
          onChanged: (val) => _updateSelectedNodesStyle(
            nodeIds,
            renderState,
            (style) => style.copyWith(borderRadius: val),
          ),
        ),
        const SizedBox(height: 12),
        _buildStyleSlider(
          context,
          title: 'BORDER WIDTH',
          value: currentStyle.strokeWidth.toDouble(),
          min: 0,
          max: 6,
          onChanged: (val) => _updateSelectedNodesStyle(
            nodeIds,
            renderState,
            (style) => style.copyWith(strokeWidth: val.round()),
          ),
        ),
      ],
    );
  }
}

class _StrategyButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String strategyType;
  final String currentStrategy;
  final ThemeData theme;
  final VoidCallback onTap;

  const _StrategyButton({
    required this.icon,
    required this.label,
    required this.strategyType,
    required this.currentStrategy,
    required this.theme,
    required this.onTap,
  });

  bool get _isSelected =>
      currentStrategy == strategyType ||
      (currentStrategy != 'bezier' &&
          currentStrategy != 'orthogonal' &&
          strategyType == 'default');

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(
        icon,
        size: 16,
        color: _isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface.withValues(alpha: 0.6),
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: _isSelected ? FontWeight.bold : FontWeight.normal,
          color: _isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
        ),
      ),
      style: TextButton.styleFrom(
        backgroundColor: _isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
