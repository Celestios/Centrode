import 'package:flutter/foundation.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import '../models/commands/patch_helpers.dart';
import '../models/models.dart';
import '../store/command_queue_processor.dart';
import '../store/graph_data_query.dart';

enum TagSortOption { alphabeticalAsc, alphabeticalDesc, usageDesc, usageAsc }

/// Tier 2 presentation coordinator for managing tag cache, search filtering,
/// sorting, and mutation dispatching.
class TagManagerCoordinator extends ChangeNotifier {
  final CommandQueueProcessor _commandProcessor;
  final GraphDataQuery _query;

  List<Tag> _tags = const [];
  String _searchQuery = '';
  TagSortOption _sortOption = TagSortOption.alphabeticalAsc;
  bool _isLoading = false;

  TagManagerCoordinator({
    required CommandQueueProcessor commandProcessor,
    required GraphDataQuery query,
  })  : _commandProcessor = commandProcessor,
        _query = query;

  List<Tag> get allTags => _tags;
  String get searchQuery => _searchQuery;
  TagSortOption get sortOption => _sortOption;
  bool get isLoading => _isLoading;

  List<Tag> get filteredTags {
    var list = _tags;
    if (_searchQuery.isNotEmpty) {
      final queryLower = _searchQuery.toLowerCase();
      list = list.where((t) => t.fields.name.toLowerCase().contains(queryLower)).toList();
    }
    list = List<Tag>.from(list);
    list.sort((a, b) {
      switch (_sortOption) {
        case TagSortOption.alphabeticalAsc:
          return a.fields.name.toLowerCase().compareTo(b.fields.name.toLowerCase());
        case TagSortOption.alphabeticalDesc:
          return b.fields.name.toLowerCase().compareTo(a.fields.name.toLowerCase());
        case TagSortOption.usageDesc:
          return getTagUsageCount(b.key.key.uuid).compareTo(getTagUsageCount(a.key.key.uuid));
        case TagSortOption.usageAsc:
          return getTagUsageCount(a.key.key.uuid).compareTo(getTagUsageCount(b.key.key.uuid));
      }
    });
    return list;
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  void setSortOption(TagSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  int getTagUsageCount(String tagKey) {
    int count = 0;
    for (final node in _query.nodeLookup.values) {
      if (node is InfoUiNode) {
        if (node.tags.any((t) => t.key.key.uuid == tagKey)) {
          count++;
        }
      }
    }
    return count;
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    final rawTags = await _commandProcessor.propertyMutations.getAllTags();
    _tags = rawTags.whereType<Tag>().toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> createTag(String name, int color) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final newTag = Tag(
      key: parseTypedRecordId('Tag', RawUuid.v4()),
      fields: TagFields(
        name: name,
        color: color,
        createdAt: timestamp,
        updatedAt: timestamp,
      ),
    );
    await _commandProcessor.createTag(newTag);
    await refresh();
  }

  Future<void> updateTag(Tag updatedTag) async {
    await _commandProcessor.updateTag(updatedTag);
    await refresh();
  }

  Future<void> deleteTag(String tagKey) async {
    await _commandProcessor.deleteTag(tagKey);
    await refresh();
  }
}
