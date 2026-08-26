import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/shared/elements/centrode_icon_button.dart';
import 'package:centrode/shared/utils/date_utils.dart';
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

  Widget _buildCenteredPlaceholder(ThemeData theme, String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildAddTagTriggerButton(ThemeData theme, Color primaryAccent) {
    return CentrodeIconButton(
      icon: Icons.add_rounded,
      onPressed: _startAddingTag,
      iconSize: 20,
      enableHover: false,
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
                  height: 32,
                  child: TextField(
                    controller: _tagController,
                    focusNode: _tagFocusNode,
                    style: TextStyle(
                      fontSize: 12.0,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                    decoration: InputDecoration(
                      hintText: 'New tag name...',
                      hintStyle: TextStyle(
                        fontSize: 11.5,
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
              CentrodeIconButton(
                icon: Icons.close_rounded,
                onPressed: _cancelAddingTag,
                iconSize: 16,
                buttonSize: 26,
                enableHover: false,
              ),
              const SizedBox(width: 4),
              CentrodeIconButton(
                icon: Icons.check_rounded,
                onPressed: () => _addTag(node),
                iconSize: 16,
                buttonSize: 26,
                enableHover: false,
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
                          margin: const EdgeInsets.only(right: 6),
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Color(colorValue),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.white24,
                              width: isSelected ? 2.0 : 0.8,
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
                                  size: 10,
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
              CentrodeIconButton(
                icon: Icons.shuffle_rounded,
                onPressed: _randomizePalette,
                iconSize: 18,
                enableHover: false,
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
        // Section 1: TAGS (Always Open)
        GlassSectionShell(
          title: 'Tags',
          icon: Icons.label_rounded,
          accentColor: primaryAccent,
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
                          horizontal: 9,
                          vertical: 5,
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
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: tagColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tag.fields.name,
                              style: TextStyle(
                                fontSize: 11.5,
                                color: theme.textTheme.bodyMedium?.color
                                    ?.withValues(alpha: 0.95),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 5),
                            CentrodeIconButton(
                              icon: Icons.close_rounded,
                              onPressed: () => widget.renderState.removeTagFromNode(
                                node.id,
                                tag.key.key.uuid,
                              ),
                              iconSize: 15,
                              buttonSize: 22,
                              enableHover: false,
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

        // Section 2: COMMENTS (Always Open)
        GlassSectionShell(
          title: 'Comments',
          icon: Icons.comment_rounded,
          accentColor: primaryAccent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 32,
                      child: TextField(
                        controller: _commentController,
                        focusNode: _commentFocusNode,
                        style: TextStyle(
                          fontSize: 12.0,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Write a comment...',
                          hintStyle: TextStyle(
                            fontSize: 11.5,
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
                  CentrodeIconButton(
                    icon: Icons.send_rounded,
                    onPressed: () => _addComment(node),
                    iconSize: 18,
                    enableHover: false,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (node.comments.isNotEmpty)
                Column(
                  children: node.comments.map((comment) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.all(9),
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
                                formatTimestampShort(comment.createdAt.toInt()),
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withValues(alpha: 0.45),
                                ),
                              ),
                              CentrodeIconButton(
                                icon: Icons.delete_outline_rounded,
                                onPressed: () => widget.renderState
                                    .removeCommentFromNode(node.id, comment),
                                iconSize: 16,
                                enableHover: false,
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            comment.text,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withValues(alpha: 0.9),
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Center(
                    child: Text(
                      'No comments added',
                      style: TextStyle(
                        fontSize: 11.5,
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
