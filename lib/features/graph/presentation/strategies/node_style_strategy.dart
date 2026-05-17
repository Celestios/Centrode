import 'package:mycelium/src/rust/domain/styles.dart'; // NodeStyle
import 'package:mycelium/presentation/theme/graph_theme.dart';
import 'package:mycelium/features/graph/models/graph_node.dart';

/// Responsible for computing the *base* [NodeStyle] for a node,
/// using per‑node overrides and theme defaults.
abstract class NodeStyleStrategy {
  const NodeStyleStrategy();

  /// Returns a fully populated [NodeStyle] for rendering.
  /// [node.style] may be null → use theme defaults.
  NodeStyle resolve(UiNode node, GraphTheme theme);
}

class InfoNodeStyleStrategy extends NodeStyleStrategy {
  const InfoNodeStyleStrategy();

  @override
  NodeStyle resolve(UiNode node, GraphTheme theme) {
    if (node.style != null) return node.style!;

    return NodeStyle(
      bgColor: theme.primaryColor.toARGB32(),
      strokeColor: theme.dividerColor.toARGB32(),
      strokeWidth: 1,
      fontFamily: theme.fontFamily,
      fontSize: theme.bodyFontSize,
      shape: 'rectangle',
      width: 150,
      height: 40,
    );
  }
}

class TaskNodeStyleStrategy extends NodeStyleStrategy {
  const TaskNodeStyleStrategy();

  @override
  NodeStyle resolve(UiNode node, GraphTheme theme) {
    if (node.style != null) return node.style!;
    return NodeStyle(
      bgColor: 0xFFC8E6C9,
      strokeColor: 0xFF000000,
      strokeWidth: 1,
      fontFamily: theme.fontFamily,
      fontSize: theme.bodyFontSize,
      shape: 'rectangle',
      width: 150,
      height: 40,
    );
  }
}
