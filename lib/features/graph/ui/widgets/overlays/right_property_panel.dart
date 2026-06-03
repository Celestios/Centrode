import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../presentation/node_render_state.dart';
import 'collapsible_sidebar.dart';
import '../../../store/graph_data_controller.dart';
import '../../../models/models.dart';
import '../../../presentation/graph_metrics.dart';
import 'package:mycelium/features/graph/presentation/strategies/node_style_strategy.dart';
import 'package:mycelium/shared/utils/color_utils.dart';

class RightPropertyPanel extends StatefulWidget {
  const RightPropertyPanel({super.key});

  @override
  State<RightPropertyPanel> createState() => _RightPropertyPanelState();
}

class _RightPropertyPanelState extends State<RightPropertyPanel> {
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _tagFocusNode = FocusNode();
  final FocusNode _commentFocusNode = FocusNode();

  bool _isAddingTag = false;
  int? _selectedTagColor;
  List<int> _currentPalette = [...AppConfig.node.defaultTagColors];
  String? _lastNodeId;

  @override
  void dispose() {
    _tagController.dispose();
    _commentController.dispose();
    _tagFocusNode.dispose();
    _commentFocusNode.dispose();
    super.dispose();
  }

  void _randomizePalette() {
    final rand = math.Random();
    final newColors = List.generate(5, (_) {
      final hue = rand.nextDouble() * 360.0;
      return HSVColor.fromAHSV(1.0, hue, 0.70, 0.80).toColor().toARGB32();
    });
    setState(() {
      _currentPalette = newColors;
      _selectedTagColor = newColors.first;
    });
  }

  void _startAddingTag() {
    setState(() {
      _isAddingTag = true;
      _selectedTagColor = _currentPalette.first;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tagFocusNode.requestFocus();
    });
  }

  void _cancelAddingTag() {
    _tagController.clear();
    setState(() {
      _isAddingTag = false;
    });
  }

  NodeStyle _getEffectiveStyle(UiNode node) {
    return node.style ?? NodeStyleStrategy.resolveStyle(node);
  }

  void _updateSelectedNodesStyle(
    List<String> nodeIds,
    GraphDataController dataController,
    NodeStyle Function(NodeStyle style) updateFn,
  ) {
    for (final id in nodeIds) {
      final node = dataController.nodeLookup[id];
      if (node != null) {
        final style = _getEffectiveStyle(node);
        dataController.updateNodeStyle(id, updateFn(style));
      }
    }
  }

  Widget _buildSectionHeader(
    ThemeData theme,
    String title, {
    IconData? icon, // Optional icon parameter
  }) {
    // If icon is provided, create a Row with icon and text
    if (icon != null) {
      return Row(
        children: [
          Icon(
            icon,
            size: 10,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 4), // Spacing between icon and text
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

    // Otherwise, just return the text
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

  @override
  Widget build(BuildContext context) {
    final renderState = context.watch<NodeRenderState>();
    final dataController = context.watch<GraphDataController>();
    final selectedEntities = renderState.selectedEntities;
    final isSelected = selectedEntities.isNotEmpty;

    return CollapsibleSidebar(
      title: 'INSPECTOR',
      icon: Icons.tune_rounded,
      isRight: true,
      isVisible: isSelected,
      showHeader: false,
      expandedWidth: 260.0,
      child: isSelected
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTabBar(context, renderState),
                ValueListenableBuilder<InspectorTab>(
                  valueListenable: renderState.activeInspectorTabNotifier,
                  builder: (context, activeTab, _) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: activeTab == InspectorTab.appearance
                          ? _buildAppearanceTab(
                              context,
                              selectedEntities,
                              dataController,
                            )
                          : _buildDataTab(
                              context,
                              selectedEntities,
                              dataController,
                            ),
                    );
                  },
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildTabBar(BuildContext context, NodeRenderState renderState) {
    final theme = Theme.of(context);
    return ValueListenableBuilder<InspectorTab>(
      valueListenable: renderState.activeInspectorTabNotifier,
      builder: (context, activeTab, _) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.15),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 36,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
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
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${renderState.selectedEntities.length}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
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
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? activeBgColor : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
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

  Widget _buildAppearanceTab(
    BuildContext context,
    Set<String> selectedEntities,
    GraphDataController dataController,
  ) {
    final theme = Theme.of(context);
    final nodeIds = selectedEntities
        .where((id) => dataController.nodeLookup.containsKey(id))
        .toList();
    final relationIds = selectedEntities
        .where((id) => dataController.relationLookup.containsKey(id))
        .toList();

    if (nodeIds.isEmpty && relationIds.isEmpty) {
      return _buildCenteredPlaceholder(
        theme,
        'Select an item to customize appearance',
      );
    }

    if (relationIds.isNotEmpty && nodeIds.isEmpty) {
      final firstRelation = dataController.relationLookup[relationIds.first]!;
      final currentStrategy = firstRelation.layout?.strategyType ?? 'default';

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(theme, 'LINE STYLE'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    for (final id in relationIds) {
                      dataController.updateRelationLayout(
                        id,
                        strategyType: 'default',
                      );
                    }
                    setState(() {});
                  },
                  icon: Icon(
                    Icons.horizontal_rule_rounded,
                    size: 16,
                    color:
                        currentStrategy == 'default' ||
                            (currentStrategy != 'bezier' &&
                                currentStrategy != 'orthogonal')
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  label: Text(
                    'Straight',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          currentStrategy == 'default' ||
                              (currentStrategy != 'bezier' &&
                                  currentStrategy != 'orthogonal')
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color:
                          currentStrategy == 'default' ||
                              (currentStrategy != 'bezier' &&
                                  currentStrategy != 'orthogonal')
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor:
                        currentStrategy == 'default' ||
                            (currentStrategy != 'bezier' &&
                                currentStrategy != 'orthogonal')
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    for (final id in relationIds) {
                      dataController.updateRelationLayout(
                        id,
                        strategyType: 'bezier',
                      );
                    }
                    setState(() {});
                  },
                  icon: Icon(
                    Icons.gesture_rounded,
                    size: 16,
                    color: currentStrategy == 'bezier'
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  label: Text(
                    'Bezier',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: currentStrategy == 'bezier'
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: currentStrategy == 'bezier'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: currentStrategy == 'bezier'
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    for (final id in relationIds) {
                      dataController.updateRelationLayout(
                        id,
                        strategyType: 'orthogonal',
                      );
                    }
                    setState(() {});
                  },
                  icon: Icon(
                    Icons.alt_route_rounded,
                    size: 16,
                    color: currentStrategy == 'orthogonal'
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  label: Text(
                    'Orthogonal',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: currentStrategy == 'orthogonal'
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: currentStrategy == 'orthogonal'
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    backgroundColor: currentStrategy == 'orthogonal'
                        ? theme.colorScheme.primary.withValues(alpha: 0.1)
                        : Colors.transparent,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    final firstNode = dataController.nodeLookup[nodeIds.first]!;
    final currentStyle = _getEffectiveStyle(firstNode);

    // List of modern, curated colors
    final colors = [
      0xFF818CF8, // Premium Indigo
      0xFF34D399, // Premium Mint
      0xFFFBBF24, // Premium Amber
      0xFFC084FC, // Premium Lavender
      0xFFF472B6, // Premium Rose
      0xFFFB923C, // Premium Orange
      0xFF94A3B8, // Premium Slate
      0xFFE2E8F0, // Premium Slate White
    ];

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
                  dataController,
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
                  dataController,
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: colors.map((col) {
            final isSelected = currentStyle.bgColor == col;
            return GestureDetector(
              onTap: () => _updateSelectedNodesStyle(
                nodeIds,
                dataController,
                (style) => style.copyWith(
                  bgColor: col,
                  textColor: ColorUtils.getContrastTextColorInt(col),
                  strokeColor: ColorUtils.getContrastStrokeColorInt(col),
                ),
              ),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Color(col),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.white24,
                    width: isSelected ? 2.5 : 1,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),
        _buildStyleSlider(
          title: 'FONT SIZE',
          value: currentStyle.fontSize,
          min: 8,
          max: 24,
          onChanged: (val) => _updateSelectedNodesStyle(
            nodeIds,
            dataController,
            (style) => style.copyWith(fontSize: val),
          ),
        ),
        const SizedBox(height: 12),
        _buildStyleSlider(
          title: 'BORDER RADIUS',
          value: currentStyle.borderRadius,
          min: 0,
          max: 24,
          onChanged: (val) => _updateSelectedNodesStyle(
            nodeIds,
            dataController,
            (style) => style.copyWith(borderRadius: val),
          ),
        ),
        const SizedBox(height: 12),
        _buildStyleSlider(
          title: 'BORDER WIDTH',
          value: currentStyle.strokeWidth.toDouble(),
          min: 0,
          max: 6,
          onChanged: (val) => _updateSelectedNodesStyle(
            nodeIds,
            dataController,
            (style) => style.copyWith(strokeWidth: val.round()),
          ),
        ),
      ],
    );
  }

  Widget _buildStyleSlider({
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

  Widget _buildDataTab(
    BuildContext context,
    Set<String> selectedEntities,
    GraphDataController dataController,
  ) {
    final theme = Theme.of(context);

    if (selectedEntities.length != 1) {
      return _buildCenteredPlaceholder(
        theme,
        'Select a single node to view metadata',
      );
    }

    final nodeId = selectedEntities.first;
    final node = dataController.nodeLookup[nodeId];

    if (_lastNodeId != nodeId) {
      _lastNodeId = nodeId;
      _isAddingTag = false;
      _tagController.clear();
      _currentPalette = [...AppConfig.node.defaultTagColors];
    }

    if (node is! InfoUiNode) {
      return _buildCenteredPlaceholder(
        theme,
        'Metadata is only available for information nodes',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TAGS SECTION
        _buildSectionHeader(theme, 'TAGS', icon: Icons.local_offer),
        const SizedBox(height: 8),
        if (node.tags.isNotEmpty || !_isAddingTag)
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...node.tags.map((tag) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Color(tag.fields.color).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(tag.fields.color).withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tag.fields.name,
                        style: TextStyle(
                          fontSize: 10,
                          color: Color(tag.fields.color),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => dataController.removeTagFromNode(node.id, tag.key),
                        child: Icon(
                          Icons.close,
                          size: 10,
                          color: Color(tag.fields.color),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              if (!_isAddingTag) _buildAddTagTriggerButton(theme),
            ],
          )
        else if (!_isAddingTag)
          _buildAddTagTriggerButton(theme),
        if (_isAddingTag) ...[
          const SizedBox(height: 8),
          _buildTagEditor(theme, node, dataController),
        ],
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Divider(height: 1),
        ),

        // COMMENTS SECTION
        _buildSectionHeader(theme, 'COMMENTS'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 32,
                child: TextField(
                  controller: _commentController,
                  focusNode: _commentFocusNode,
                  style: const TextStyle(fontSize: 11),
                  decoration: InputDecoration(
                    hintText: 'Write a comment...',
                    hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    filled: true,
                    fillColor: Colors.black.withValues(alpha: 0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (val) => _addComment(node, dataController),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.send_rounded, size: 14),
              onPressed: () => _addComment(node, dataController),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primary.withValues(
                  alpha: 0.15,
                ),
                foregroundColor: theme.colorScheme.primary,
                padding: const EdgeInsets.all(8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Scrollable List of Comments
        if (node.comments.isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxHeight: 250),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: node.comments.map((comment) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatTimestamp(comment.createdAt.toInt()),
                              style: TextStyle(
                                fontSize: 9,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => dataController.removeCommentFromNode(node.id, comment),
                              child: Icon(
                                Icons.delete_outline_rounded,
                                size: 12,
                                color: theme.colorScheme.error.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          comment.text,
                          style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.85,
                            ),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: Text(
                'No comments yet',
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _addTag(InfoUiNode node, GraphDataController dataController) {
    final text = _tagController.text.trim();
    if (text.isEmpty) return;

    // Check if tag already exists on this node
    if (node.tags.any((t) => t.fields.name.toLowerCase() == text.toLowerCase())) {
      _tagController.clear();
      return;
    }

    final color = _selectedTagColor ?? _currentPalette.first;
    dataController.addTagToNode(node.id, text, color);

    _tagController.clear();
    setState(() {
      _isAddingTag = false;
    });
  }

  void _addComment(InfoUiNode node, GraphDataController dataController) {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    dataController.addCommentToNode(node.id, text);

    _commentController.clear();
    _commentFocusNode.requestFocus();
  }

  String _formatTimestamp(int timestampMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs).toLocal();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${pad(dt.month)}-${pad(dt.day)} ${pad(dt.hour)}:${pad(dt.minute)}';
  }

  Widget _buildAddTagTriggerButton(ThemeData theme) {
    return InkWell(
      onTap: _startAddingTag,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 14, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildTagEditor(
    ThemeData theme,
    InfoUiNode node,
    GraphDataController dataController,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 32,
                  child: TextField(
                    controller: _tagController,
                    focusNode: _tagFocusNode,
                    style: const TextStyle(fontSize: 11),
                    decoration: InputDecoration(
                      hintText: 'Tag name...',
                      hintStyle: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.4,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.15),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (val) => _addTag(node, dataController),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 14),
                onPressed: _cancelAddingTag,
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: theme.colorScheme.onSurface.withValues(
                    alpha: 0.6,
                  ),
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(32, 32),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const Icon(Icons.check_rounded, size: 14),
                onPressed: () => _addTag(node, dataController),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.15,
                  ),
                  foregroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.all(8),
                  minimumSize: const Size(32, 32),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _currentPalette.map((colorValue) {
                      final isSelected = _selectedTagColor == colorValue;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedTagColor = colorValue;
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 6),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Color(colorValue),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.white24,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: 10,
                                  color:
                                      ThemeData.estimateBrightnessForColor(
                                            Color(colorValue),
                                          ) ==
                                          Brightness.dark
                                      ? Colors.white
                                      : Colors.black,
                                )
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: 'Randomize Colors',
                child: InkWell(
                  onTap: _randomizePalette,
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.shuffle_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
