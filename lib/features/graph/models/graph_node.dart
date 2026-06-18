import 'dart:ui';
import 'package:mycelium/features/graph/models/content_builder.dart';
import 'package:mycelium/src/rust/domain/nodes.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import 'package:uuid/uuid.dart';
import 'package:mycelium/src/rust/domain/base_models.dart' as frb;
import 'package:mycelium/src/rust/domain/base_models.dart' hide Size;
import 'package:mycelium/src/rust/domain/contents.dart';
import 'package:mycelium/src/rust/domain/tags.dart';

part 'graph_node.ui.dart';

// -----------------------------------------------------------------------------
// UiNode Abstract Base Class
// -----------------------------------------------------------------------------

sealed class UiNode {
  static const Size defaultNodeSize = Size(100.0, 80.0);

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
  Color get defaultPreviewColor {
    final self = this;
    if (self is InfoUiNode) return const Color(0xFF90CAF9);
    if (self is TaskUiNode) return const Color(0xFFA5D6A7);
    if (self is CommentUiNode) return const Color(0xFFB0BEC5);
    if (self is DrawingUiNode) return const Color(0xFFCE93D8);
    if (self is ShapeUiNode) return const Color(0xFFFFCC80);
    if (self is FrameUiNode) return const Color(0xFFBCAAA4);
    if (self is MediaUiNode) return const Color(0xFF80CBC4);
    if (self is InterUiNode) return const Color(0xFFFFF59D);
    return const Color(0xFF90CAF9);
  }

  Size get previewSize {
    final self = this;
    if (self is InterUiNode || self is DrawingUiNode) {
      return const Size(60.0, 36.0);
    }
    return size;
  }
}
