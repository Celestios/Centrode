import 'package:centrode/features/graph/models/graph_node.dart';
import 'package:centrode/src/rust/domain/styles.dart';
import 'package:centrode/presentation/theme/graph_theme.dart';
import 'strategies/node_style_strategy.dart';

/// Flyweight cache for interned [NodeStyle] instances.
///
/// Wraps [NodeStyleStrategy] calls with a hash-based interning cache.
/// Identical combinations of (node type, style overrides, theme) produce
/// the exact same cached [NodeStyle] instance, eliminating duplicate
/// allocations across thousands of nodes.
class StyleFlyweight {
  final Map<int, NodeStyle> _cache = {};

  NodeStyle resolve(UiNode node, GraphTheme theme, NodeStyleStrategy strategy) {
    final signature = Object.hash(
      strategy.runtimeType,
      node.runtimeType,
      node.style?.bgColor,
      node.style?.fontSize,
      node.style?.borderRadius,
      node.style?.padding,
      node.style?.shape,
      theme.primaryColor.toARGB32(),
      theme.bodyFontSize,
      theme.fontFamily,
      theme.borderRadius,
    );

    return _cache.putIfAbsent(
      signature,
      () => strategy.computeStyle(node, theme),
    );
  }

  void clear() => _cache.clear();

  int get size => _cache.length;
}
