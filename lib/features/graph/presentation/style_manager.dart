import 'package:mycelium/shared/logging.dart';
import 'package:mycelium/features/graph/models/models.dart';
import 'package:mycelium/presentation/theme/graph_theme.dart';
import 'package:mycelium/features/graph/presentation/strategies/node_style_strategy.dart';
import 'package:mycelium/features/graph/presentation/strategies/relation_style_strategy.dart';
import 'package:mycelium/features/graph/presentation/strategies/significance_strategy.dart';
import 'package:mycelium/features/graph/store/modules/graph_store.dart';
import 'package:mycelium/features/graph/models/commands/graph_command_context.dart'
    show GraphStyleUpdater;

class StyleManager implements GraphStyleUpdater {
  final Logger _log = Logger('StyleManager');

  final GraphStore _store;
  final NodeStyleStrategy _infoStrategy = const InfoNodeStyleStrategy();
  final NodeStyleStrategy _taskStrategy = const TaskNodeStyleStrategy();
  final NodeStyleStrategy _drawingStrategy = const DrawingNodeStyleStrategy();
  final RelationStyleStrategy _relationStrategy =
      const DefaultRelationStyleStrategy();
  final SignificanceStrategy _modifier = const SignificanceStrategy();

  GraphTheme? _theme;
  DisplayMode _displayMode = DisplayMode.leveling;

  StyleManager(this._store);

  // --- Public triggers ---

  /// Called when the theme changes or after initial load.
  void updateAllStyles(Iterable<UiNode> nodes, Iterable<UiRelation> relations) {
    _log.info('Rebuilding all styles (theme: ${_theme?.name})');
    for (final node in nodes) {
      _resolveAndCacheNode(node);
    }
    for (final rel in relations) {
      _resolveAndCacheRelation(rel);
    }
  }

  @override
  void updateStyleForNode(String id) {
    final node = _store.nodeLookup[id];
    if (node != null) _resolveAndCacheNode(node);
  }

  @override
  void updateStyleForRelation(String id) {
    final rel = _store.relationLookup[id];
    if (rel != null) _resolveAndCacheRelation(rel);
  }

  void setTheme(GraphTheme? theme) {
    _theme = theme;
  }

  void setDisplayMode(DisplayMode mode) {
    if (_displayMode == mode) return;
    _displayMode = mode;
    // Reapply the modifier to all already‑styled nodes
    for (final node in _store.nodeLookup.values) {
      _applyModifierAndCache(node);
    }
  }

  // --- Internal resolution ---

  void _resolveAndCacheNode(UiNode node) {
    if (_theme == null) return;
    final NodeStyle base;
    if (node is InfoUiNode) {
      base = _infoStrategy.resolve(node, _theme!);
    } else if (node is TaskUiNode) {
      base = _taskStrategy.resolve(node, _theme!);
    } else if (node is DrawingUiNode) {
      base = _drawingStrategy.resolve(node, _theme!);
    } else {
      _log.warning('StyleManager: Unknown node type encountered: ${node.runtimeType} (ID: ${node.id}, Table: ${node.tableName})');
      return;
    }
    final resolvedBase = _applyModifier(base, node.significance);
    node.resolvedStyle = NodeStyleStrategy.scaleStyle(resolvedBase);
  }

  void _resolveAndCacheRelation(UiRelation relation) {
    if (_theme == null) return;
    final base = _relationStrategy.resolve(relation, _theme!);
    relation.resolvedStyle = base;
  }

  void _applyModifierAndCache(UiNode node) {
    if (node.resolvedStyle == null) {
      _resolveAndCacheNode(node);
      return;
    }
    // Re‑resolve base? Or reapply modifier on cached base?
    // For simplicity, we re‑resolve using the strategy (it will use node.style override again).
    _resolveAndCacheNode(node);
  }

  NodeStyle _applyModifier(NodeStyle base, int significance) {
    if (_displayMode == DisplayMode.importance && significance > 0) {
      return _modifier.apply(base, significance);
    }
    return base;
  }
}
