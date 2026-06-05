import 'package:flutter/painting.dart';
import 'package:mycelium/features/graph/models/content_builder.dart';
import 'package:mycelium/src/rust/domain/nodes.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import 'package:uuid/uuid.dart';
import 'package:mycelium/src/rust/domain/base_models.dart' as frb;
import 'package:mycelium/src/rust/domain/base_models.dart' hide Size;
import 'package:mycelium/src/rust/domain/contents.dart';
import 'package:mycelium/src/rust/domain/tags.dart';

part 'graph_node.ui.dart';

enum UiNodes { info, task }

// -----------------------------------------------------------------------------
// UiNode Abstract Base Class
// -----------------------------------------------------------------------------

sealed class UiNode {
  static const Size defaultNodeSize = Size(100.0, 60.0);

  final String id;
  final int createdAt;
  String layer;
  int updatedAt;
  bool locked;
  bool isExpanded;
  int significance;
  NodeStyle? resolvedStyle;
  Offset position;

  // ──────────────────── public dependency properties ────────
  NodeStyle? style;
  NodeLayout? layout;
  NodeLayout? resolvedLayout;
  Size size;
  Content content;

  String get text => content.text;

  bool expandable = false;
  int lineCount;
  String get tableName;

  Nodes toRust();

  static UiNode fromRust(Object rustNode) => _$uiNodeFromRust(rustNode);

  // ──────────────────── normal constructor ────────────────────────────────
  UiNode({
    String? id,
    int? createdAt,
    int? updatedAt,
    bool? locked,
    this.style,
    this.resolvedStyle,
    this.layout,
    this.resolvedLayout,
    String? layer,
    Size? size,
    bool? isExpanded,
    bool? initialExpandable,
    int? lineCount,
    Content? content,
    this.significance = 0,
    required this.position,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
       updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch,
       locked = locked ?? false,
       layer = layer ?? "default",
       isExpanded = isExpanded ?? false,
       size = size ?? defaultNodeSize,
       content = content ?? ContentFactory.fromText("topic"),
       lineCount = lineCount ?? 1 {
    if (initialExpandable != null) {
      expandable = initialExpandable;
    }
  }

  static UiNode? copy(UiNode? node) => _$uiNodeCopy(node);

  // ──────────────────── layout engine ─────────────────────────────────────
}
