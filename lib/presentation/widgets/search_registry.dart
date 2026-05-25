import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/graph/presentation/workspace_tabs_controller.dart';
import '../../features/graph/models/graph_node.dart';
import '../../src/rust/domain/nodes.dart';
import '../../src/rust/domain/base_models.dart' show BoundingBox;
import 'command_registry.dart';

enum SearchResultType { command, node, tag }

class SearchResult {
  final String title;
  final String subtitle;
  final IconData icon;
  final SearchResultType type;
  final void Function(BuildContext context) onSelected;

  const SearchResult({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.type,
    required this.onSelected,
  });
}

class SearchRegistry {
  SearchRegistry._();
  static final SearchRegistry instance = SearchRegistry._();

  int _activeQueryId = 0;

  /// Performs search based on the query and handles sequence numbers to ignore stale results.
  /// Returns null if this query was superseded by a newer query.
  Future<List<SearchResult>?> search(String rawQuery, BuildContext context) async {
    final queryId = ++_activeQueryId;
    final results = await _performSearch(rawQuery, context);

    if (queryId != _activeQueryId) {
      return null; // Stale query
    }
    return results;
  }

  Future<List<SearchResult>> _performSearch(String rawQuery, BuildContext context) async {
    final query = rawQuery.trim();
    if (query.isEmpty) {
      return [];
    }

    final tabsController = context.read<WorkspaceTabsController>();
    final session = tabsController.activeSession;
    final dataController = session.dataController;

    // 1. Command Palette Prefix ('>')
    if (query.startsWith('>')) {
      final term = query.substring(1).trim().toLowerCase();
      final commands = CommandRegistry.instance.getCommands(context);
      return commands
          .where((cmd) => cmd.title.toLowerCase().contains(term))
          .map((cmd) => SearchResult(
                title: cmd.title,
                subtitle: cmd.subtitle,
                icon: cmd.icon,
                type: SearchResultType.command,
                onSelected: cmd.onSelected,
              ))
          .toList();
    }

    // 2. Tag Filter Prefix ('#')
    if (query.startsWith('#')) {
      if (dataController == null) return [];
      final term = query.substring(1).trim().toLowerCase();
      final results = <SearchResult>[];

      for (final node in dataController.nodesIterable) {
        if (node is InfoUiNode) {
          final matchesTag = node.tags.any((t) => t.name.toLowerCase().contains(term));
          if (matchesTag) {
            results.add(SearchResult(
              title: node.text.isEmpty ? 'Untitled Node' : node.text,
              subtitle: 'Node • Tagged • ${node.tags.map((t) => '#${t.name}').join(', ')}',
              icon: Icons.tag_rounded,
              type: SearchResultType.tag,
              onSelected: (ctx) => _focusOnUiNode(ctx, node.id),
            ));
          }
        }
      }
      return results;
    }

    // 3. Database Query Prefix ('?')
    if (query.startsWith('?')) {
      final term = query.substring(1).trim();
      final handle = session.handle;
      if (handle == null) return [];

      try {
        final rustNodes = await handle.querySearch(query: term);
        final results = <SearchResult>[];

        for (final rustNode in rustNodes) {
          String key = '';
          String title = 'Untitled Node';
          String subtitle = 'Database';
          IconData icon = Icons.help_outline_rounded;

          if (rustNode is Nodes_INode) {
            final node = rustNode.field0;
            key = node.key;
            title = node.fields.content.text.isEmpty ? 'Untitled Node' : node.fields.content.text;
            subtitle = 'Database • Info';
            icon = Icons.description_outlined;
          } else if (rustNode is Nodes_TaskNode) {
            final node = rustNode.field0;
            key = node.key;
            title = node.fields.content.text.isEmpty ? 'Untitled Node' : node.fields.content.text;
            subtitle = 'Database • Task • State: ${node.fields.state}';
            icon = Icons.task_alt_outlined;
          } else if (rustNode is Nodes_InterNode) {
            final node = rustNode.field0;
            key = node.key;
            title = node.fields.verb.isEmpty ? 'Untitled Relation' : node.fields.verb;
            subtitle = 'Database • Inter';
            icon = Icons.alt_route_rounded;
          }

          if (key.isNotEmpty) {
            results.add(SearchResult(
              title: title,
              subtitle: subtitle,
              icon: icon,
              type: SearchResultType.node,
              onSelected: (ctx) => _focusOnUiNode(ctx, key),
            ));
          }
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
          )
        ];
      }
    }

    // 4. Default Canvas Node Text Search (no prefix)
    if (dataController == null) return [];
    final term = query.toLowerCase();
    final results = <SearchResult>[];

    for (final node in dataController.nodesIterable) {
      if (node.text.toLowerCase().contains(term)) {
        results.add(SearchResult(
          title: node.text.isEmpty ? 'Untitled Node' : node.text,
          subtitle: 'Node • ${node.tableName == 'INode' ? 'Info' : 'Task'}',
          icon: node.tableName == 'INode' ? Icons.description_outlined : Icons.task_alt_outlined,
          type: SearchResultType.node,
          onSelected: (ctx) => _focusOnUiNode(ctx, node.id),
        ));
      }
    }

    return results;
  }

  void _focusOnUiNode(BuildContext context, String nodeId) {
    final tabsController = context.read<WorkspaceTabsController>();
    final session = tabsController.activeSession;
    final uiNode = session.dataController?.nodeLookup[nodeId];
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
