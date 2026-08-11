import 'dart:ui';
import 'package:centrode/features/graph/models/content_builder.dart';
import 'package:centrode/src/rust/domain/types.dart';
import 'package:centrode/src/rust/domain/nodes.dart';
import 'package:centrode/src/rust/domain/tags.dart';
import 'package:centrode/src/rust/domain/id.dart';
import 'package:centrode/src/rust/domain/styles.dart';
import 'package:uuid/uuid.dart';
import 'package:centrode/src/rust/domain/base_models.dart' as frb;
import 'package:centrode/src/rust/domain/base_models.dart' hide Size;
import 'package:centrode/src/rust/domain/contents.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

part 'graph_node.ui.dart';

// -----------------------------------------------------------------------------
// UiNode Abstract Base Class
// -----------------------------------------------------------------------------

sealed class UiNode {
  static const Size defaultNodeSize = Size(100.0, 80.0);

  final RawUuid id;
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
    RawUuid? id,
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
  }) : id = id ?? RawUuid.v4(),
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

  UiNode? cloneWithId(RawUuid newId) => switch (this) {
    InfoUiNode() => (this as InfoUiNode).copyWith(id: newId),
    TaskUiNode() => (this as TaskUiNode).copyWith(id: newId),
    CommentUiNode() => (this as CommentUiNode).copyWith(id: newId),
    DrawingUiNode() => (this as DrawingUiNode).copyWith(id: newId),
    FrameUiNode() => (this as FrameUiNode).copyWith(id: newId),
    InterUiNode() => (this as InterUiNode).copyWith(id: newId),
    MediaUiNode() => (this as MediaUiNode).copyWith(id: newId),
    ShapeUiNode() => (this as ShapeUiNode).copyWith(id: newId),
  };

  // ──────────────────── layout engine ─────────────────────────────────────
  Color get defaultPreviewColor => switch (this) {
    InfoUiNode() => const Color(0xFF90CAF9),
    TaskUiNode() => const Color(0xFFA5D6A7),
    CommentUiNode() => const Color(0xFFB0BEC5),
    DrawingUiNode() => const Color(0xFFCE93D8),
    ShapeUiNode() => const Color(0xFFFFCC80),
    FrameUiNode() => const Color(0xFFBCAAA4),
    MediaUiNode() => const Color(0xFF80CBC4),
    InterUiNode() => const Color(0xFFFFF59D),
  };

  Size get previewSize {
    final self = this;
    if (self is InterUiNode || self is DrawingUiNode) {
      return const Size(60.0, 36.0);
    }
    return size;
  }
}

extension DrawingUiNodeExtension on DrawingUiNode {
  List<List<Offset>> get parsedPaths {
    return paths.map((pathStr) {
      return pathStr
          .split(';')
          .map((p) {
            final coords = p.split(',');
            if (coords.length < 2) return null;
            final x = double.tryParse(coords[0]);
            final y = double.tryParse(coords[1]);
            if (x == null || y == null) return null;
            return Offset(x, y);
          })
          .whereType<Offset>()
          .toList();
    }).toList();
  }
}
