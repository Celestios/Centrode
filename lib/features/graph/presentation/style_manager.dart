import 'package:mycelium/shared/logging.dart';
import 'package:mycelium/shared/domain/raw_uuid.dart';
import 'package:mycelium/features/graph/models/models.dart';
import 'package:mycelium/presentation/theme/graph_theme.dart';
import 'package:mycelium/features/graph/presentation/strategies/node_style_strategy.dart';
import 'package:mycelium/features/graph/presentation/strategies/relation_style_strategy.dart';
import 'package:mycelium/features/graph/presentation/strategies/significance_strategy.dart';
import 'package:mycelium/features/graph/presentation/style_flyweight.dart';
import 'package:mycelium/features/graph/store/modules/graph_store.dart';
import 'package:mycelium/features/graph/models/commands/graph_command_context.dart'
    show GraphStyleUpdater;

class StyleManager implements GraphStyleUpdater {
  final Logger _log = Logger('StyleManager');

  final GraphStore _store;
  final NodeStyleStrategy _styleStrategy;
  final RelationStyleStrategy _relationStrategy;
  final SignificanceStrategy _modifier;
  final StyleFlyweight _flyweight = StyleFlyweight();

  GraphTheme? _theme;
  DisplayMode _displayMode = DisplayMode.leveling;

  StyleManager(
    this._store, {
    NodeStyleStrategy? styleStrategy,
    RelationStyleStrategy? relationStrategy,
    SignificanceStrategy? modifier,
  })  : _styleStrategy = styleStrategy ?? const DefaultNodeStyleStrategy(),
        _relationStrategy = relationStrategy ?? const DefaultRelationStyleStrategy(),
        _modifier = modifier ?? const SignificanceStrategy();

  void updateAllStyles(Iterable<UiNode> nodes, Iterable<UiRelation> relations) {
    _log.info('Rebuilding all styles (theme: ${_theme?.name})');
    _flyweight.clear();
    for (final node in nodes) {
      _resolveAndCacheNode(node);
    }
    for (final rel in relations) {
      _resolveAndCacheRelation(rel);
    }
  }

  @override
  void updateStyleForNode(RawUuid id) {
    final node = _store.nodeLookup[id];
    if (node != null) _resolveAndCacheNode(node);
  }

  @override
  void updateStyleForRelation(RawUuid id) {
    final rel = _store.relationLookup[id];
    if (rel != null) _resolveAndCacheRelation(rel);
  }

  void setTheme(GraphTheme? theme) {
    _theme = theme;
    _flyweight.clear();
  }

  void setDisplayMode(DisplayMode mode) {
    if (_displayMode == mode) return;
    _displayMode = mode;
    _flyweight.clear();
    for (final node in _store.nodeLookup.values) {
      _resolveAndCacheNode(node);
    }
  }

  void _resolveAndCacheNode(UiNode node) {
    if (_theme == null) return;
    final NodeStyle base = _flyweight.resolve(node, _theme!, _styleStrategy);
    final resolvedBase = _applyModifier(base, node.significance);
    node.resolvedStyle = NodeStyleStrategy.scaleStyle(resolvedBase);
  }

  void _resolveAndCacheRelation(UiRelation relation) {
    if (_theme == null) return;
    final base = _relationStrategy.resolve(relation, _theme!);
    relation.resolvedStyle = base;
  }

  NodeStyle _applyModifier(NodeStyle base, int significance) {
    if (_displayMode == DisplayMode.importance && significance > 0) {
      return _modifier.apply(base, significance);
    }
    return base;
  }
}
