import 'package:logging/logging.dart';
import 'package:mycelium/features/graph/models/models.dart';
import 'package:mycelium/presentation/theme/graph_theme.dart';
import 'package:mycelium/features/graph/theme/models/node_style_strategy.dart';
import 'package:mycelium/features/graph/theme/models/relation_style_strategy.dart';
import 'package:mycelium/features/graph/theme/models/significance_modifier.dart';
import 'package:mycelium/features/graph/store/mixins/graph_store_mixin.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import 'package:mycelium/src/rust/domain/base_models.dart' show DisplayMode;

class StyleManager {
  final Logger _log = Logger('StyleManager');

  final GraphStoreMixin _store;
  final NodeStyleStrategy _infoStrategy = const InfoNodeStyleStrategy();
  final NodeStyleStrategy _taskStrategy = const TaskNodeStyleStrategy();
  final RelationStyleStrategy _relationStrategy =
      const DefaultRelationStyleStrategy();
  final SignificanceModifier _modifier = const SignificanceModifier();

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

  void updateStyleForNode(String id) {
    final node = _store.nodeLookup[id];
    if (node != null) _resolveAndCacheNode(node);
  }

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
    } else {
      _log.warning('Unknown node type: ${node.runtimeType}');
      return;
    }
    node.resolvedStyle = _applyModifier(base, node.significance);
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
