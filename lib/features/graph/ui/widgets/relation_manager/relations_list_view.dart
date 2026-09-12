import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:centrode/shared/theme/design_tokens.dart';
import '../../../store/graph_data_query.dart';
import '../../../store/graph_data_query_controller.dart';
import 'package:centrode/presentation/widgets/search/searchable_sort_list_header.dart';

enum RelationSortOption {
  usageDesc,
  usageAsc,
  alphabeticalAsc,
  alphabeticalDesc,
}

class RelationTypeEntry {
  final String verb;
  final int count;

  const RelationTypeEntry({
    required this.verb,
    required this.count,
  });
}

class RelationsListView extends StatefulWidget {
  const RelationsListView({super.key});

  @override
  State<RelationsListView> createState() => _RelationsListViewState();
}

class _RelationsListViewState extends State<RelationsListView> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  RelationSortOption _sortOption = RelationSortOption.usageDesc;
  String? _hoveredVerb;
  StreamSubscription<GraphEntityUpdate>? _subscription;

  static const List<SortOption<RelationSortOption>> _sortOptions = [
    SortOption(
      value: RelationSortOption.usageDesc,
      label: 'Usage (High - Low)',
      icon: Icons.trending_down_rounded,
    ),
    SortOption(
      value: RelationSortOption.usageAsc,
      label: 'Usage (Low - High)',
      icon: Icons.trending_up_rounded,
    ),
    SortOption(
      value: RelationSortOption.alphabeticalAsc,
      label: 'Alphabetical (A - Z)',
      icon: Icons.sort_by_alpha_rounded,
    ),
    SortOption(
      value: RelationSortOption.alphabeticalDesc,
      label: 'Alphabetical (Z - A)',
      icon: Icons.sort_by_alpha_rounded,
    ),
  ];

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    _subscription?.cancel();
    final queryController = context.read<GraphDataQueryController>();
    _subscription = queryController.onEntityUpdate.listen((_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  List<RelationTypeEntry> _aggregateAndSortRelations(GraphDataQueryController queryController) {
    final Map<String, int> counts = {};

    for (final relation in queryController.relations) {
      final verb = relation.verb.trim();
      final displayVerb = verb.isEmpty ? 'relates to' : verb;
      counts[displayVerb] = (counts[displayVerb] ?? 0) + 1;
    }

    List<RelationTypeEntry> entries = counts.entries
        .map((e) => RelationTypeEntry(verb: e.key, count: e.value))
        .toList();

    if (_searchQuery.isNotEmpty) {
      final queryLower = _searchQuery.toLowerCase();
      entries = entries.where((e) => e.verb.toLowerCase().contains(queryLower)).toList();
    }

    switch (_sortOption) {
      case RelationSortOption.usageDesc:
        entries.sort((a, b) {
          final cmp = b.count.compareTo(a.count);
          return cmp != 0 ? cmp : a.verb.toLowerCase().compareTo(b.verb.toLowerCase());
        });
      case RelationSortOption.usageAsc:
        entries.sort((a, b) {
          final cmp = a.count.compareTo(b.count);
          return cmp != 0 ? cmp : a.verb.toLowerCase().compareTo(b.verb.toLowerCase());
        });
      case RelationSortOption.alphabeticalAsc:
        entries.sort((a, b) => a.verb.toLowerCase().compareTo(b.verb.toLowerCase()));
      case RelationSortOption.alphabeticalDesc:
        entries.sort((a, b) => b.verb.toLowerCase().compareTo(a.verb.toLowerCase()));
    }

    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final queryController = context.read<GraphDataQueryController>();
    final entries = _aggregateAndSortRelations(queryController);
    final totalUniqueTypes = queryController.relations
        .map((r) => r.verb.trim().isEmpty ? 'relates to' : r.verb.trim())
        .toSet()
        .length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SearchableSortedListHeader<RelationSortOption>(
          searchController: _searchController,
          hintText: 'Search labels...',
          currentSort: _sortOption,
          sortOptions: _sortOptions,
          onSortChanged: (newSort) {
            setState(() {
              _sortOption = newSort;
            });
          },
          tooltip: 'Sort labels',
          itemCount: entries.length,
          itemLabel: entries.length == 1 ? 'label' : 'labels',
        ),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
            child: Center(
              child: Text(
                totalUniqueTypes == 0
                    ? 'No labels in graph'
                    : 'No matching labels',
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
              itemCount: entries.length,
              padding: UiInsets.verticalTight,
              itemBuilder: (context, index) {
                final item = entries[index];
                final isHovered = _hoveredVerb == item.verb;

                return MouseRegion(
                  onEnter: (_) {
                    setState(() {
                      _hoveredVerb = item.verb;
                    });
                  },
                  onExit: (_) {
                    setState(() {
                      _hoveredVerb = null;
                    });
                  },
                  child: Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    color: isHovered
                        ? theme.colorScheme.onSurface.withValues(alpha: 0.05)
                        : Colors.transparent,
                    child: Row(
                      children: [
                        Icon(
                          Icons.polyline_outlined,
                          size: UiIconSize.dense,
                          color: theme.colorScheme.primary.withValues(alpha: 0.75),
                        ),
                        const SizedBox(width: UiSpacing.standard),
                        Expanded(
                          child: Text(
                            item.verb,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: UiFont.standard,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7.0,
                            vertical: 2.0,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Text(
                            '${item.count}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: UiFont.micro,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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
  }
}
