import 'package:flutter/widgets.dart';
import 'package:centrode/src/rust/domain/types.dart';
import '../models/models.dart';
import '../store/command_queue_processor.dart';

enum TemplateSortOption { alphabeticalAsc, alphabeticalDesc, newest, oldest }

/// Tier 2 presentation coordinator for managing template cache, search filtering,
/// sorting, and mutation dispatching.
class TemplateManagerCoordinator extends ChangeNotifier {
  final CommandQueueProcessor _commandProcessor;

  List<Template> _templates = const [];
  String _searchQuery = '';
  TemplateSortOption _sortOption = TemplateSortOption.newest;
  bool _isLoading = false;

  TemplateManagerCoordinator({
    required CommandQueueProcessor commandProcessor,
  }) : _commandProcessor = commandProcessor;

  List<Template> get allTemplates => _templates;
  String get searchQuery => _searchQuery;
  TemplateSortOption get sortOption => _sortOption;
  bool get isLoading => _isLoading;

  List<Template> get filteredTemplates {
    var list = _templates;
    if (_searchQuery.isNotEmpty) {
      final queryLower = _searchQuery.toLowerCase();
      list = list.where((t) => t.name.toLowerCase().contains(queryLower)).toList();
    }
    list = List<Template>.from(list);
    list.sort((a, b) {
      switch (_sortOption) {
        case TemplateSortOption.alphabeticalAsc:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case TemplateSortOption.alphabeticalDesc:
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        case TemplateSortOption.newest:
          return b.createdAt.toInt().compareTo(a.createdAt.toInt());
        case TemplateSortOption.oldest:
          return a.createdAt.toInt().compareTo(b.createdAt.toInt());
      }
    });
    return list;
  }

  void setSearchQuery(String query) {
    _searchQuery = query.trim();
    notifyListeners();
  }

  void setSortOption(TemplateSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    final raw = await _commandProcessor.templateMutations.getAllTemplates();
    _templates = raw.whereType<Template>().toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> instantiateTemplate(String templateId, Offset position) async {
    await _commandProcessor.templateMutations.instantiateTemplate(templateId, position);
  }

  Future<void> deleteTemplate(String templateId) async {
    await _commandProcessor.templateMutations.deleteTemplate(templateId);
    await refresh();
  }
}
