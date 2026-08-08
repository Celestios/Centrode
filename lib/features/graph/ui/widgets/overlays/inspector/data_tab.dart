import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import '../../../../presentation/node_render_state.dart';
import '../../../../models/models.dart';
import '../../../../engine/config.dart';
import '../../inspector/relation_appearance_section.dart';

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

  Widget _buildCenteredPlaceholder(ThemeData theme, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildAddTagTriggerButton(ThemeData theme, Color primaryAccent) {
    return GestureDetector(
      onTap: _startAddingTag,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: primaryAccent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: primaryAccent.withValues(alpha: 0.35),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 12, color: primaryAccent),
            const SizedBox(width: 4),
            Text(
              'Add Tag',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: primaryAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagEditor(ThemeData theme, InfoUiNode node, Color primaryAccent) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: primaryAccent.withValues(alpha: 0.2), width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 28,
                  child: TextField(
                    controller: _tagController,
                    focusNode: _tagFocusNode,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                    decoration: InputDecoration(
                      hintText: 'New tag name...',
                      hintStyle: TextStyle(
                        fontSize: 10,
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.4),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.25),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (val) => _addTag(node),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: _cancelAddingTag,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    size: 12,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.6),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => _addTag(node),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryAccent.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: primaryAccent.withValues(alpha: 0.5),
                      width: 0.8,
                    ),
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: primaryAccent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
                          margin: const EdgeInsets.only(right: 5),
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Color(colorValue),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.white24,
                              width: isSelected ? 1.8 : 0.8,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: Color(colorValue).withValues(alpha: 0.4),
                                      blurRadius: 4,
                                    ),
                                  ]
                                : [],
                          ),
                          child: isSelected
                              ? Icon(
                                  Icons.check,
                                  size: 9,
                                  color: ThemeData.estimateBrightnessForColor(
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
              GestureDetector(
                onTap: _randomizePalette,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 0.6,
                    ),
                  ),
                  child: Icon(
                    Icons.shuffle_rounded,
                    size: 12,
                    color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
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
    final primaryAccent = theme.colorScheme.primary;
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
        'Metadata is available for information nodes.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sub-block 1: TAGS
        SubBlockShell(
          title: 'Tags',
          accentColor: primaryAccent,
          initiallyExpanded: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (node.tags.isNotEmpty || !_isAddingTag)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ...node.tags.map((tag) {
                      final tagColor = Color(tag.fields.color);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: tagColor.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: tagColor.withValues(alpha: 0.45),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: tagColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              tag.fields.name,
                              style: TextStyle(
                                fontSize: 9.5,
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () => widget.renderState.removeTagFromNode(
                                node.id,
                                tag.key.key.uuid,
                              ),
                              child: Icon(
                                Icons.close_rounded,
                                size: 11,
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (!_isAddingTag) _buildAddTagTriggerButton(theme, primaryAccent),
                  ],
                )
              else if (!_isAddingTag)
                _buildAddTagTriggerButton(theme, primaryAccent),

              if (_isAddingTag) ...[
                const SizedBox(height: 6),
                _buildTagEditor(theme, node, primaryAccent),
              ],
            ],
          ),
        ),

        // Sub-block 2: COMMENTS
        SubBlockShell(
          title: 'Comments',
          accentColor: primaryAccent,
          initiallyExpanded: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 28,
                      child: TextField(
                        controller: _commentController,
                        focusNode: _commentFocusNode,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Write a comment...',
                          hintStyle: TextStyle(
                            fontSize: 10,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withValues(alpha: 0.4),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.2),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (val) => _addComment(node),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _addComment(node),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryAccent.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: primaryAccent.withValues(alpha: 0.5),
                          width: 0.8,
                        ),
                      ),
                      child: Icon(
                        Icons.send_rounded,
                        size: 12,
                        color: primaryAccent,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (node.comments.isNotEmpty)
                Column(
                  children: node.comments.map((comment) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.06),
                          width: 0.6,
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
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.4),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => widget.renderState
                                    .removeCommentFromNode(node.id, comment),
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 11,
                                  color: theme.colorScheme.error.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            comment.text,
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.85),
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Center(
                    child: Text(
                      'No comments added',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.textTheme.bodyMedium?.color
                            ?.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
