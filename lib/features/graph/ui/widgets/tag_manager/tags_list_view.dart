import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:mycelium/shared/domain/raw_uuid.dart';
import '../../../models/graph_node.dart';
import '../../../store/graph_data_query_controller.dart';
import '../../../store/command_queue_processor.dart';
import '../../../../../src/rust/domain/types.dart';
import '../../../../../src/rust/domain/tags.dart';
import 'package:mycelium/presentation/widgets/search/searchable_sort_list_header.dart';
import 'delete_tag_dialog.dart';
import '../../../models/commands/patch_helpers.dart';
import 'tag_color_picker_panel.dart';

const List<int> _presetColors = [
  0xFF818CF8, // Indigo
  0xFF34D399, // Mint/Green
  0xFFFBBF24, // Amber
  0xFFC084FC, // Lavender
  0xFFF472B6, // Rose
  0xFFFB923C, // Orange
  0xFF94A3B8, // Slate
  0xFFEC407A, // Pink
  0xFF7E57C2, // Deep Purple
  0xFF42A5F5, // Blue
  0xFF26A69A, // Teal
];

enum TagSortOption { alphabeticalAsc, alphabeticalDesc, usageDesc, usageAsc }

class TagsListView extends StatefulWidget {
  const TagsListView({super.key});

  @override
  State<TagsListView> createState() => _TagsListViewState();
}

class _TagsListViewState extends State<TagsListView> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _createController = TextEditingController();
  final TextEditingController _renameController = TextEditingController();

  final FocusNode _createFocusNode = FocusNode();
  final FocusNode _renameFocusNode = FocusNode();

  String _searchQuery = '';
  TagSortOption _sortOption = TagSortOption.usageDesc;

  String? _hoveredTagKey;
  String? _editingTagKey;
  String? _validationError;

  // State for creating a new tag color
  int _newTagColor = 0xFF5C6BC0; // Default Indigo

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _createController.dispose();
    _renameController.dispose();
    _createFocusNode.dispose();
    _renameFocusNode.dispose();
    super.dispose();
  }

  int _getTagUsageCount(String tagKey, GraphDataQueryController controller) {
    int count = 0;
    for (final node in controller.nodeLookup.values) {
      if (node is InfoUiNode) {
        if (node.tags.any((t) => t.key.key.uuid == tagKey)) {
          count++;
        }
      }
    }
    return count;
  }

  void _showColorPicker(
    BuildContext context,
    Offset anchorPos,
    Tag tag,
    CommandQueueProcessor controller,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (dialogContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(dialogContext).pop(),
                child: const SizedBox(),
              ),
            ),
            Positioned(
              left: anchorPos.dx + 28,
              top: (anchorPos.dy - 60).clamp(
                20.0,
                MediaQuery.of(context).size.height - 200.0,
              ),
              child: Material(
                color: Colors.transparent,
                child: TagColorPickerPanel(
                  initialColor: tag.fields.color,
                  onColorSelected: (newColor) async {
                    final updatedTag = Tag(
                      key: tag.key,
                      fields: TagFields(
                        name: tag.fields.name,
                        color: newColor,
                        createdAt: tag.fields.createdAt,
                        updatedAt: DateTime.now().millisecondsSinceEpoch,
                      ),
                    );
                    await controller.propertyMutations.updateTag(updatedTag);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showNewColorPicker(BuildContext context, Offset anchorPos) {
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (dialogContext) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(dialogContext).pop(),
                child: const SizedBox(),
              ),
            ),
            Positioned(
              left: anchorPos.dx + 28,
              top: (anchorPos.dy - 60).clamp(
                20.0,
                MediaQuery.of(context).size.height - 200.0,
              ),
              child: Material(
                color: Colors.transparent,
                child: TagColorPickerPanel(
                  initialColor: _newTagColor,
                  onColorSelected: (newColor) {
                    setState(() {
                      _newTagColor = newColor;
                    });
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _submitCreateTag(
    CommandQueueProcessor controller,
    List<Tag> allTags,
  ) async {
    final name = _createController.text.trim();
    if (name.isEmpty) return;

    // Check duplicate
    if (allTags.any((t) => t.fields.name.toLowerCase() == name.toLowerCase())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tag "$name" already exists!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newTag = Tag(
      key: parseTypedRecordId('Tag', RawUuid.v4()),
      fields: TagFields(
        name: name,
        color: _newTagColor,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );

    try {
      await controller.propertyMutations.createTag(newTag);
      _createController.clear();
      // Generate a new random color for next tag
      setState(() {
        _newTagColor = (List<int>.from(_presetColors)..shuffle()).first;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _submitRename(
    Tag tag,
    CommandQueueProcessor controller,
    List<Tag> allTags,
  ) async {
    final newName = _renameController.text.trim();
    if (newName.isEmpty) {
      setState(() => _validationError = 'Name cannot be empty');
      return;
    }
    if (newName.toLowerCase() == tag.fields.name.toLowerCase()) {
      setState(() {
        _editingTagKey = null;
        _validationError = null;
      });
      return;
    }
    // Check duplicates
    if (allTags.any(
      (t) =>
          t.key != tag.key &&
          t.fields.name.toLowerCase() == newName.toLowerCase(),
    )) {
      setState(() => _validationError = 'Tag name must be unique');
      return;
    }

    try {
      final updatedTag = Tag(
        key: tag.key,
        fields: TagFields(
          name: newName,
          color: tag.fields.color,
          createdAt: tag.fields.createdAt,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      await controller.propertyMutations.updateTag(updatedTag);
      setState(() {
        _editingTagKey = null;
        _validationError = null;
      });
    } catch (e) {
      setState(() => _validationError = e.toString());
    }
  }

  void _startEditing(Tag tag) {
    setState(() {
        _editingTagKey = tag.key.key.uuid;
      _renameController.text = tag.fields.name;
      _validationError = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _renameFocusNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.read<CommandQueueProcessor>();
    final queryController = context.read<GraphDataQueryController>();
    final theme = Theme.of(context);

    return FutureBuilder<List<Tag>>(
      future: controller.propertyMutations.getAllTags(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const SizedBox(
            height: 100,
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final allTags = (snapshot.data ?? []).whereType<Tag>().toList();

        // Apply search query filter
        var filteredTags = allTags;
        if (_searchQuery.isNotEmpty) {
          filteredTags = allTags
              .where(
                (t) => t.fields.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
              )
              .toList();
        }

        // Pre-compute tag usage counts in O(num_nodes) single pass
        final Map<String, int> usageCounts = {};
        for (final node in queryController.nodeLookup.values) {
          if (node is InfoUiNode) {
            for (final tag in node.tags) {
                usageCounts[tag.key.key.uuid] = (usageCounts[tag.key.key.uuid] ?? 0) + 1;
            }
          }
        }

        // Apply sorting option
        filteredTags.sort((a, b) {
          switch (_sortOption) {
            case TagSortOption.alphabeticalAsc:
              return a.fields.name.toLowerCase().compareTo(
                b.fields.name.toLowerCase(),
              );
            case TagSortOption.alphabeticalDesc:
              return b.fields.name.toLowerCase().compareTo(
                a.fields.name.toLowerCase(),
              );
            case TagSortOption.usageDesc:
              return (usageCounts[b.key.key.uuid] ?? 0).compareTo(usageCounts[a.key.key.uuid] ?? 0);
            case TagSortOption.usageAsc:
              return (usageCounts[a.key.key.uuid] ?? 0).compareTo(usageCounts[b.key.key.uuid] ?? 0);
          }
        });

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SearchableSortedListHeader<TagSortOption>(
              searchController: _searchController,
              hintText: 'Search tags...',
              currentSort: _sortOption,
              sortOptions: const [
                SortOption(
                  value: TagSortOption.usageDesc,
                  label: 'Most Used',
                  icon: Icons.trending_down_rounded,
                ),
                SortOption(
                  value: TagSortOption.usageAsc,
                  label: 'Least Used',
                  icon: Icons.trending_up_rounded,
                ),
                SortOption(
                  value: TagSortOption.alphabeticalAsc,
                  label: 'Name A-Z',
                  icon: Icons.sort_by_alpha_rounded,
                ),
                SortOption(
                  value: TagSortOption.alphabeticalDesc,
                  label: 'Name Z-A',
                  icon: Icons.sort_by_alpha_rounded,
                ),
              ],
              onSortChanged: (option) {
                setState(() {
                  _sortOption = option;
                });
              },
              tooltip: 'Sort tags',
              leading: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 28,
                      child: TextField(
                        controller: _createController,
                        focusNode: _createFocusNode,
                        style: const TextStyle(fontSize: 11),
                        decoration: InputDecoration(
                          hintText: 'Create tag...',
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.4,
                            ),
                            fontSize: 11,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) =>
                            _submitCreateTag(controller, allTags),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTapDown: (details) {
                      _showNewColorPicker(context, details.globalPosition);
                    },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Color(_newTagColor),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white30),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),

            // Scrollable List Body
            if (filteredTags.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: Text(
                    _searchQuery.isEmpty ? 'No tags yet' : 'No matching tags',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: 11,
                    ),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredTags.length,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemBuilder: (context, index) {
                    final tag = filteredTags[index];
                      final usageCount = _getTagUsageCount(tag.key.key.uuid, queryController);
                      final isEditing = _editingTagKey == tag.key.key.uuid;

                    return MouseRegion(
                      onEnter: (_) {
                        setState(() {
                          _hoveredTagKey = tag.key.key.uuid;
                        });
                      },
                      onExit: (_) {
                        setState(() {
                          _hoveredTagKey = null;
                        });
                      },
                      child: Container(
                        height: 38,
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        color: isEditing
                            ? theme.colorScheme.primary.withValues(alpha: 0.05)
                            : _hoveredTagKey == tag.key.key.uuid
                            ? theme.colorScheme.onSurface.withValues(
                                alpha: 0.04,
                              )
                            : Colors.transparent,
                        child: Row(
                          children: [
                            // Tag Color Circle (click to pick color)
                            GestureDetector(
                              onTapDown: (details) {
                                _showColorPicker(
                                  context,
                                  details.globalPosition,
                                  tag,
                                  controller,
                                );
                              },
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: Color(tag.fields.color),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white24),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Tag name / Edit Field
                            Expanded(
                              child: isEditing
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          height: 22,
                                          child: TextField(
                                            controller: _renameController,
                                            focusNode: _renameFocusNode,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            decoration: const InputDecoration(
                                              contentPadding: EdgeInsets.zero,
                                              isDense: true,
                                              border: InputBorder.none,
                                            ),
                                            onSubmitted: (_) => _submitRename(
                                              tag,
                                              controller,
                                              allTags,
                                            ),
                                          ),
                                        ),
                                        if (_validationError != null)
                                          Text(
                                            _validationError!,
                                            style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: 8,
                                            ),
                                          ),
                                      ],
                                    )
                                  : GestureDetector(
                                      onDoubleTap: () => _startEditing(tag),
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.text,
                                        child: Text(
                                          tag.fields.name,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                            ),

                            // Right side: options on hover, otherwise usage badge
                            if (isEditing)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.close_rounded,
                                      size: 14,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _editingTagKey = null;
                                        _validationError = null;
                                      });
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 24,
                                      minHeight: 24,
                                      maxWidth: 24,
                                      maxHeight: 24,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.check_rounded,
                                      size: 14,
                                      color: Colors.greenAccent,
                                    ),
                                    onPressed: () =>
                                        _submitRename(tag, controller, allTags),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 24,
                                      minHeight: 24,
                                      maxWidth: 24,
                                      maxHeight: 24,
                                    ),
                                  ),
                                ],
                              )
                            else if (_hoveredTagKey == tag.key.key.uuid)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_rounded,
                                      size: 14,
                                    ),
                                    onPressed: () => _startEditing(tag),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 24,
                                      minHeight: 24,
                                      maxWidth: 24,
                                      maxHeight: 24,
                                    ),
                                    tooltip: 'Rename tag',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 14,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () async {
                                      final confirm = await showDeleteTagDialog(
                                        context,
                                        tag.fields.name,
                                      );
                                      if (confirm == true) {
                                          await controller.propertyMutations.deleteTag(tag.key.key.uuid);
                                      }
                                    },
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 24,
                                      minHeight: 24,
                                      maxWidth: 24,
                                      maxHeight: 24,
                                    ),
                                    tooltip: 'Delete tag globally',
                                  ),
                                ],
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$usageCount',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
