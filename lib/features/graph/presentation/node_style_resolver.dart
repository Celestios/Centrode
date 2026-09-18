import 'package:flutter/material.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'strategies/node_layout_strategy.dart';

class NodeStyleResolver {
  const NodeStyleResolver._();

  static ({Size size, int lineCount}) calculateNodeSize(
    UiNode node, {
    bool isEditing = false,
  }) {
    return const DefaultNodeLayoutStrategy().calculateSize(
      node,
      isEditing: isEditing,
    );
  }

  static NodeStyle resolveNodeStyle(UiNode node) {
    final ns = node.style;
    if (ns != null) return ns;
    throw StateError(
      'No style found for node ${node.id}. Style resolver must be configured.',
    );
  }
}
