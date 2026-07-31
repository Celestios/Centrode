import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/features/graph/presentation/workspace_tabs_controller.dart';
import 'package:centrode/features/graph/store/graph_data_query_controller.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/presentation/palette_action_registry.dart';

enum SearchResultType { command, node, tag, relation, relationHeader }

class SearchResult {
  final String title;
  final String subtitle;
  final IconData icon;
  final SearchResultType type;
  final void Function(BuildContext context) onSelected;
  final UiRelation? relation;
  final String? relationVerb;

  const SearchResult({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.type,
    required this.onSelected,
    this.relation,
    this.relationVerb,
  });
}

abstract class SearchSource {
  bool canHandle(String query);
  Future<List<SearchResult>> search(String query, SearchContext context);
}

class SearchContext {
  final WorkspaceTabsController tabsController;
  final BuildContext buildContext;

  SearchContext({required this.tabsController, required this.buildContext});

  GraphDataQueryController? get queryController =>
      tabsController.activeSession.queryController;
}

class CommandPaletteSearchSource extends SearchSource {
  @override
  bool canHandle(String query) => query.startsWith('>');

  @override
  Future<List<SearchResult>> search(String query, SearchContext context) async {
    final term = query.substring(1).trim().toLowerCase();
    final actions = PaletteActionRegistry.instance.getActions(
      context.buildContext,
    );
    return actions
        .where((act) => act.title.toLowerCase().contains(term))
        .map(
          (act) => SearchResult(
            title: act.title,
            subtitle: act.subtitle,
            icon: act.icon,
            type: SearchResultType.command,
            onSelected: act.onSelected,
          ),
        )
        .toList();
  }
}

class TagSearchSource extends SearchSource {
  @override
  bool canHandle(String query) => query.startsWith('#');

  @override
  Future<List<SearchResult>> search(String query, SearchContext context) async {
    final queryController = context.queryController;
    if (queryController == null) return [];
    final term = query.substring(1).trim().toLowerCase();
    final results = <SearchResult>[];

    for (final node in queryController.nodeLookup.values) {
      if (node is InfoUiNode) {
        final matchesTag = node.tags.any(
          (t) => t.fields.name.toLowerCase().contains(term),
        );
        if (matchesTag) {
          results.add(
            SearchResult(
              title: node.text.isEmpty ? 'Untitled Node' : node.text,
              subtitle:
                  'Node • Tagged • ${node.tags.map((t) => '#${t.fields.name}').join(', ')}',
              icon: Icons.tag_rounded,
              type: SearchResultType.tag,
              onSelected: (ctx) => _focusOnUiNode(ctx, node.id),
            ),
          );
        }
      }
    }
    return results;
  }

  void _focusOnUiNode(BuildContext context, RawUuid nodeId) {
    final tabsController = context.read<WorkspaceTabsController>();
    final session = tabsController.activeSession;
    final uiNode = session.queryController?.nodeLookup[nodeId];
    final viewportController = session.viewportController;

    if (uiNode != null && viewportController != null) {
      final bounds = BoundingBox(
        minX: uiNode.position.dx - 150,
        minY: uiNode.position.dy - 150,
        maxX: uiNode.position.dx + uiNode.size.width + 150,
        maxY: uiNode.position.dy + uiNode.size.height + 150,
      );
      viewportController.focusOnBounds(bounds);
    }
  }
}

class DatabaseSearchSource extends SearchSource {
  @override
  bool canHandle(String query) => query.startsWith('?');

  @override
  Future<List<SearchResult>> search(String query, SearchContext context) async {
    final queryController = context.queryController;
    if (queryController == null) return [];
    final term = query.substring(1).trim();

    try {
      final dbResults = await queryController.searchDatabase(term);
      final results = <SearchResult>[];

      for (final res in dbResults) {
        IconData icon = Icons.help_outline_rounded;
        String subtitle = 'Database';
        switch (res.type) {
          case DatabaseSearchResultType.infoNode:
            icon = Icons.description_outlined;
            subtitle = 'Database • Info';
            break;
          case DatabaseSearchResultType.taskNode:
            icon = Icons.task_alt_outlined;
            subtitle =
                'Database • Task${res.state != null ? ' • State: ${res.state}' : ''}';
            break;
          case DatabaseSearchResultType.relation:
            icon = Icons.alt_route_rounded;
            subtitle = 'Database • Inter';
            break;
        }

        final title = res.text.isEmpty
            ? (res.type == DatabaseSearchResultType.relation
                  ? 'Untitled Relation'
                  : 'Untitled Node')
            : res.text;

        results.add(
          SearchResult(
            title: title,
            subtitle: subtitle,
            icon: icon,
            type: SearchResultType.node,
            onSelected: (ctx) =>
                _focusOnUiNode(ctx, RawUuid.fromString(res.key)),
          ),
        );
      }
      return results;
    } catch (e) {
      debugPrint('SearchRegistry: FFI querySearch error: $e');
      return [
        SearchResult(
          title: 'Error executing query',
          subtitle: e.toString(),
          icon: Icons.error_outline_rounded,
          type: SearchResultType.command,
          onSelected: (_) {},
        ),
      ];
    }
  }

  void _focusOnUiNode(BuildContext context, RawUuid nodeId) {
    final tabsController = context.read<WorkspaceTabsController>();
    final session = tabsController.activeSession;
    final uiNode = session.queryController?.nodeLookup[nodeId];
    final viewportController = session.viewportController;

    if (uiNode != null && viewportController != null) {
      final bounds = BoundingBox(
        minX: uiNode.position.dx - 150,
        minY: uiNode.position.dy - 150,
        maxX: uiNode.position.dx + uiNode.size.width + 150,
        maxY: uiNode.position.dy + uiNode.size.height + 150,
      );
      viewportController.focusOnBounds(bounds);
    }
  }
}

class CanvasSearchSource extends SearchSource {
  @override
  bool canHandle(String query) => true;

  @override
  Future<List<SearchResult>> search(String query, SearchContext context) async {
    final queryController = context.queryController;
    if (queryController == null) return [];
    final term = query.toLowerCase();
    final results = <SearchResult>[];

    for (final node in queryController.nodeLookup.values) {
      if (node.text.toLowerCase().contains(term)) {
        results.add(
          SearchResult(
            title: node.text.isEmpty ? 'Untitled Node' : node.text,
            subtitle: 'Node • ${node.tableName == 'INode' ? 'Info' : 'Task'}',
            icon: node.tableName == 'INode'
                ? Icons.description_outlined
                : Icons.task_alt_outlined,
            type: SearchResultType.node,
            onSelected: (ctx) => _focusOnUiNode(ctx, node.id),
          ),
        );
      }
    }

    final matchingRelations = <UiRelation>[];
    for (final relation in queryController.relations) {
      final fromNode = queryController.nodeLookup[relation.fromNodeId];
      final toNode = queryController.nodeLookup[relation.toNodeId];

      final matchesVerb = relation.verb.toLowerCase().contains(term);
      final matchesFrom =
          fromNode != null && fromNode.text.toLowerCase().contains(term);
      final matchesTo =
          toNode != null && toNode.text.toLowerCase().contains(term);

      if (matchesVerb || matchesFrom || matchesTo) {
        matchingRelations.add(relation);
      }
    }

    if (matchingRelations.isNotEmpty) {
      final groupedRelations = <String, List<UiRelation>>{};
      for (final rel in matchingRelations) {
        final verbKey = rel.verb.trim().toLowerCase();
        groupedRelations.putIfAbsent(verbKey, () => []).add(rel);
      }

      for (final entry in groupedRelations.entries) {
        final canonicalVerb = entry.value.first.verb;

        results.add(
          SearchResult(
            title: '',
            subtitle: '',
            icon: Icons.alt_route_rounded,
            type: SearchResultType.relationHeader,
            relationVerb: canonicalVerb,
            onSelected: (_) {},
          ),
        );

        for (final rel in entry.value) {
          final fromNode = queryController.nodeLookup[rel.fromNodeId];
          final toNode = queryController.nodeLookup[rel.toNodeId];
          final fromText = fromNode?.text ?? 'Untitled Node';
          final toText = toNode?.text ?? 'Untitled Node';

          results.add(
            SearchResult(
              title: '$fromText ➔ $toText',
              subtitle: 'Relation • ${rel.verb}',
              icon: Icons.trending_flat_rounded,
              type: SearchResultType.relation,
              relation: rel,
              relationVerb: rel.verb,
              onSelected: (ctx) => _focusOnUiRelation(ctx, rel),
            ),
          );
        }
      }
    }

    return results;
  }

  void _focusOnUiNode(BuildContext context, RawUuid nodeId) {
    final tabsController = context.read<WorkspaceTabsController>();
    final session = tabsController.activeSession;
    final uiNode = session.queryController?.nodeLookup[nodeId];
    final viewportController = session.viewportController;

    if (uiNode != null && viewportController != null) {
      final bounds = BoundingBox(
        minX: uiNode.position.dx - 150,
        minY: uiNode.position.dy - 150,
        maxX: uiNode.position.dx + uiNode.size.width + 150,
        maxY: uiNode.position.dy + uiNode.size.height + 150,
      );
      viewportController.focusOnBounds(bounds);
    }
  }

  void _focusOnUiRelation(BuildContext context, UiRelation relation) {
    final tabsController = context.read<WorkspaceTabsController>();
    final session = tabsController.activeSession;
    final queryController = session.queryController;
    if (queryController == null) return;

    final fromNode = queryController.nodeLookup[relation.fromNodeId];
    final toNode = queryController.nodeLookup[relation.toNodeId];
    final viewportController = session.viewportController;

    if (viewportController != null) {
      if (fromNode != null && toNode != null) {
        final double minX = fromNode.position.dx < toNode.position.dx
            ? fromNode.position.dx
            : toNode.position.dx;
        final double minY = fromNode.position.dy < toNode.position.dy
            ? fromNode.position.dy
            : toNode.position.dy;
        final double maxX =
            (fromNode.position.dx + fromNode.size.width) >
                (toNode.position.dx + toNode.size.width)
            ? (fromNode.position.dx + fromNode.size.width)
            : (toNode.position.dx + toNode.size.width);
        final double maxY =
            (fromNode.position.dy + fromNode.size.height) >
                (toNode.position.dy + toNode.size.height)
            ? (fromNode.position.dy + fromNode.size.height)
            : (toNode.position.dy + toNode.size.height);

        final bounds = BoundingBox(
          minX: minX - 150,
          minY: minY - 150,
          maxX: maxX + 150,
          maxY: maxY + 150,
        );
        viewportController.focusOnBounds(bounds);
      } else if (fromNode != null) {
        final bounds = BoundingBox(
          minX: fromNode.position.dx - 150,
          minY: fromNode.position.dy - 150,
          maxX: fromNode.position.dx + fromNode.size.width + 150,
          maxY: fromNode.position.dy + fromNode.size.height + 150,
        );
        viewportController.focusOnBounds(bounds);
      } else if (toNode != null) {
        final bounds = BoundingBox(
          minX: toNode.position.dx - 150,
          minY: toNode.position.dy - 150,
          maxX: toNode.position.dx + toNode.size.width + 150,
          maxY: toNode.position.dy + toNode.size.height + 150,
        );
        viewportController.focusOnBounds(bounds);
      }
    }
  }
}

class SearchRegistry {
  SearchRegistry._();
  static final SearchRegistry instance = SearchRegistry._();

  int _activeQueryId = 0;

  final List<SearchSource> _sources = [
    CommandPaletteSearchSource(),
    TagSearchSource(),
    DatabaseSearchSource(),
    CanvasSearchSource(),
  ];

  Future<List<SearchResult>?> search(
    String rawQuery,
    BuildContext context,
  ) async {
    final queryId = ++_activeQueryId;
    final results = await _performSearch(rawQuery, context);

    if (queryId != _activeQueryId) {
      return null;
    }
    return results;
  }

  Future<List<SearchResult>> _performSearch(
    String rawQuery,
    BuildContext context,
  ) async {
    final query = rawQuery.trim();
    if (query.isEmpty) return [];

    final tabsController = context.read<WorkspaceTabsController>();
    final searchContext = SearchContext(
      tabsController: tabsController,
      buildContext: context,
    );

    for (final source in _sources) {
      if (source.canHandle(query)) {
        return await source.search(query, searchContext);
      }
    }
    return [];
  }
}
