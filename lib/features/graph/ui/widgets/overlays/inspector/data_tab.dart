import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import '../../../../presentation/node_render_state.dart';
import '../../../../models/models.dart';
import '../../../../engine/config.dart';

class DataTab extends StatefulWidget {
  final RawUuid nodeId;
  final NodeRenderState renderState;

  const DataTab({super.key, required this.nodeId, required this.renderState});

  @override
  State<DataTab> createState() => _DataTabState();
}

class _DataTabState extends State<DataTab> {
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _tagFocusNode = FocusNode();
  final FocusNode _commentFocusNode = FocusNode();

  bool _isAddingTag = false;
  int? _selectedTagColor;
  List<int> _currentPalette = [...AppConfig.node.defaultTagColors];
  RawUuid? _lastNodeId;

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

  void _addTag(InfoUiNode node) {
    final text = _tagController.text.trim();
    if (text.isEmpty) return;

    if (node.tags.any(
      (t) => t.fields.name.toLowerCase() == text.toLowerCase(),
    )) {
      _tagController.clear();
      return;
    }

    final color = _selectedTagColor ?? _currentPalette.first;
    widget.renderState.addTagToNode(node.id, text, color);

    _tagController.clear();
    setState(() {
      _isAddingTag = false;
    });
  }

  void _addComment(InfoUiNode node) {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    widget.renderState.addCommentToNode(node.id, text);

    _commentController.clear();
    _commentFocusNode.requestFocus();
  }

  String _formatTimestamp(int timestampMs) {
    final dt = DateTime.fromMillisecondsSinceEpoch(timestampMs).toLocal();
    String pad(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${pad(dt.month)}-${pad(dt.day)} ${pad(dt.hour)}:${pad(dt.minute)}';
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

  Widget _buildTagEditor(ThemeData theme, InfoUiNode node) {
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
                    onSubmitted: (val) => _addTag(node),
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
                onPressed: () => _addTag(node),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final node = widget.renderState.getNode(widget.nodeId);

    if (_lastNodeId != widget.nodeId) {
      _lastNodeId = widget.nodeId;
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
                        onTap: () => widget.renderState.removeTagFromNode(
                          node.id,
                          tag.key.key.uuid,
                        ),
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
          _buildTagEditor(theme, node),
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
                  onSubmitted: (val) => _addComment(node),
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton(
              icon: const Icon(Icons.send_rounded, size: 14),
              onPressed: () => _addComment(node),
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
                              onTap: () => widget.renderState
                                  .removeCommentFromNode(node.id, comment),
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
}
