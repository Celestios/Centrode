import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:centrode/shared/elements/elements.dart';
import 'package:centrode/presentation/widgets/search/searchable_sort_list_header.dart';
import '../../../../../src/rust/domain/types.dart';
import '../../../../../src/rust/domain/tags.dart';
import '../../../presentation/tag_manager_coordinator.dart';
import '../../../store/command_queue_processor.dart';
import '../../../store/graph_data_query.dart';
import 'delete_tag_dialog.dart';
import 'tag_color_picker_panel.dart';

List<int> get _presetColors =>
    CentrodeDerivedPalette.current.swatches.map((c) => c.toARGB32()).toList();

class TagsListView extends StatefulWidget {
  final TagManagerCoordinator? coordinator;

  const TagsListView({super.key, this.coordinator});

  @override
  State<TagsListView> createState() => _TagsListViewState();
}

class _TagsListViewState extends State<TagsListView> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _createController = TextEditingController();
  final TextEditingController _renameController = TextEditingController();

  final FocusNode _createFocusNode = FocusNode();
  final FocusNode _renameFocusNode = FocusNode();
  final GlobalKey _newColorDotKey = GlobalKey();

  TagManagerCoordinator? _internalCoordinator;
  TagManagerCoordinator get _coordinator =>
      widget.coordinator ?? _internalCoordinator!;

  String? _hoveredTagKey;
  String? _editingTagKey;
  String? _validationError;

  // State for creating a new tag color
  int _newTagColor = 0xFF5C6BC0; // Default Indigo

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _coordinator.setSearchQuery(_searchController.text);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.coordinator == null && _internalCoordinator == null) {
      _internalCoordinator = TagManagerCoordinator(
        commandProcessor: context.read<CommandQueueProcessor>(),
        query: context.read<GraphDataQuery>(),
      );
      _internalCoordinator!.setSortOption(TagSortOption.usageDesc);
      _internalCoordinator!.refresh();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _createController.dispose();
    _renameController.dispose();
    _createFocusNode.dispose();
    _renameFocusNode.dispose();
    _internalCoordinator?.dispose();
    super.dispose();
  }

  void _showColorPicker(
    BuildContext context,
    Offset anchorPos,
    Tag tag,
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
                    await _coordinator.updateTag(updatedTag);
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

  void _submitCreateTag() async {
    final name = _createController.text.trim();
    if (name.isEmpty) return;

    if (_coordinator.allTags.any(
      (t) => t.fields.name.toLowerCase() == name.toLowerCase(),
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tag "$name" already exists!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    await _coordinator.createTag(name, _newTagColor);
    _createController.clear();
    setState(() {
      _newTagColor = (List<int>.from(_presetColors)..shuffle()).first;
    });
  }

  void _submitRename(Tag tag) async {
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
    if (_coordinator.allTags.any(
      (t) =>
          t.key != tag.key &&
          t.fields.name.toLowerCase() == newName.toLowerCase(),
    )) {
      setState(() => _validationError = 'Tag name must be unique');
      return;
    }

    final updatedTag = Tag(
      key: tag.key,
      fields: TagFields(
        name: newName,
        color: tag.fields.color,
        createdAt: tag.fields.createdAt,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    await _coordinator.updateTag(updatedTag);
    setState(() {
      _editingTagKey = null;
      _validationError = null;
    });
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
    final theme = Theme.of(context);

    return ListenableBuilder(
      listenable: _coordinator,
      builder: (context, _) {
        final filteredTags = _coordinator.filteredTags;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SearchableSortedListHeader<TagSortOption>(
              searchController: _searchController,
              hintText: 'Search tags...',
              currentSort: _coordinator.sortOption,
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
              onSortChanged: (option) => _coordinator.setSortOption(option),
              tooltip: 'Sort tags',
              leading: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: UiControlSize.dense,
                      child: TextField(
                        controller: _createController,
                        focusNode: _createFocusNode,
                        style: const TextStyle(fontSize: UiFont.compact),
                        decoration: InputDecoration(
                          hintText: 'Create tag...',
                          hintStyle: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.4,
                            ),
                            fontSize: UiFont.compact,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          filled: true,
                          fillColor: Colors.black.withValues(alpha: 0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              UiRadius.control,
                            ),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _submitCreateTag(),
                      ),
                    ),
                  ),
                  const SizedBox(width: UiSpacing.tight),
                  CentrodeButton(
                    onTap: () {
                      final RenderBox? renderBox =
                          _newColorDotKey.currentContext?.findRenderObject()
                              as RenderBox?;
                      if (renderBox != null) {
                        _showNewColorPicker(
                          context,
                          renderBox.localToGlobal(
                            Offset(
                              renderBox.size.width / 2,
                              renderBox.size.height / 2,
                            ),
                          ),
                        );
                      }
                    },
                    enableHover: false,
                    borderRadius: BorderRadius.circular(9),
                    child: Container(
                      key: _newColorDotKey,
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: Color(_newTagColor),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white30),
                      ),
                    ),
                  ),
                  const SizedBox(width: UiSpacing.tight),
                ],
              ),
            ),

            // Scrollable List Body
            if (filteredTags.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32.0),
                child: Center(
                  child: Text(
                    _coordinator.searchQuery.isEmpty
                        ? 'No tags yet'
                        : 'No matching tags',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      fontSize: UiFont.compact,
                    ),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredTags.length,
                  padding: UiInsets.verticalTight,
                  itemBuilder: (context, index) {
                    final tag = filteredTags[index];
                    final usageCount = _coordinator.getTagUsageCount(
                      tag.key.key.uuid,
                    );
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
                            const SizedBox(width: UiSpacing.standard),

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
                                              fontSize: UiFont.standard,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            decoration: const InputDecoration(
                                              contentPadding: EdgeInsets.zero,
                                              isDense: true,
                                              border: InputBorder.none,
                                            ),
                                            onSubmitted: (_) =>
                                                _submitRename(tag),
                                          ),
                                        ),
                                        if (_validationError != null)
                                          Text(
                                            _validationError!,
                                            style: const TextStyle(
                                              color: Colors.redAccent,
                                              fontSize: UiFont.micro,
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
                                            fontSize: UiFont.standard,
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
                                  CentrodeIconButton(
                                    icon: Icons.close_rounded,
                                    onPressed: () {
                                      setState(() {
                                        _editingTagKey = null;
                                        _validationError = null;
                                      });
                                    },
                                    iconSize: UiIconSize.dense,
                                    buttonSize: 24,
                                    enableHover: false,
                                  ),
                                  CentrodeIconButton(
                                    icon: Icons.check_rounded,
                                    onPressed: () => _submitRename(tag),
                                    iconSize: UiIconSize.dense,
                                    buttonSize: 24,
                                    enableHover: false,
                                    iconColor: Colors.greenAccent,
                                  ),
                                ],
                              )
                            else if (_hoveredTagKey == tag.key.key.uuid)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CentrodeIconButton(
                                    icon: Icons.edit_rounded,
                                    onPressed: () => _startEditing(tag),
                                    iconSize: UiIconSize.dense,
                                    buttonSize: 24,
                                    enableHover: false,
                                    tooltip: 'Rename tag',
                                  ),
                                  CentrodeIconButton(
                                    icon: Icons.delete_outline_rounded,
                                    onPressed: () async {
                                      final confirm = await showDeleteTagDialog(
                                        context,
                                        tag.fields.name,
                                      );
                                      if (confirm == true) {
                                        await _coordinator.deleteTag(
                                          tag.key.key.uuid,
                                        );
                                      }
                                    },
                                    iconSize: UiIconSize.dense,
                                    buttonSize: 24,
                                    enableHover: false,
                                    iconColor: Colors.redAccent,
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
                                  borderRadius: BorderRadius.circular(
                                    UiRadius.card,
                                  ),
                                ),
                                child: Text(
                                  '$usageCount',
                                  style: TextStyle(
                                    fontSize: UiFont.micro,
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
