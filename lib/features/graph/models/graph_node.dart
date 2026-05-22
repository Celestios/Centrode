import 'package:flutter/painting.dart';
import 'package:mycelium/features/graph/models/content_builder.dart';
import 'package:mycelium/src/rust/domain/nodes.dart';
import 'package:mycelium/src/rust/domain/styles.dart';
import 'package:uuid/uuid.dart';
import 'package:mycelium/src/rust/domain/base_models.dart' as frb;
import 'package:mycelium/src/rust/domain/contents.dart';
import 'package:mycelium/features/graph/presentation/graph_metrics.dart';
import 'package:mycelium/src/rust/domain/tags.dart';

enum UiNodes { info, task }

// -----------------------------------------------------------------------------
// UiNode Abstract Base Class
// -----------------------------------------------------------------------------

sealed class UiNode {
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
  Size size;
  Content content;

  String get text => content.text;

  bool expandable = false;
  int lineCount;
  String get tableName;

  Nodes toRust();

  static UiNode fromRust(Object rustNode) {
    if (rustNode is INode) return InfoUiNode.fromRust(rustNode);
    if (rustNode is TaskNode) return TaskUiNode.fromRust(rustNode);
    throw ArgumentError('Unsupported Rust node type: ${rustNode.runtimeType}');
  }

  // ──────────────────── normal constructor ────────────────────────────────
  UiNode({
    String? id,
    int? createdAt,
    int? updatedAt,
    bool? locked,
    this.style,
    this.resolvedStyle,
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
       size = size ?? AppConfig.node.defaultSize,
       content = content ?? ContentFactory.fromText("topic"),
       lineCount = lineCount ?? 1 {
    if (initialExpandable != null) {
      expandable = initialExpandable;
    }
  }

  static UiNode? copy(UiNode? node) {
    if (node == null) return null;
    if (node is InfoUiNode) return node.copyWith();
    if (node is TaskUiNode) return node.copyWith();
    throw ArgumentError('Unsupported node type: ${node.runtimeType}');
  }

  // ──────────────────── layout engine ─────────────────────────────────────
}

// -----------------------------------------------------------------------------
// Concrete Implementations
// -----------------------------------------------------------------------------

class InfoUiNode extends UiNode {
  List<Tag> tags;
  List<String> aliases;
  List<frb.Comment> comments;
  String? attachment;

  InfoUiNode({
    required super.position,
    super.content,
    super.id,
    super.createdAt,
    super.updatedAt,
    super.locked,
    super.style,
    super.resolvedStyle,
    super.layer,
    super.size,
    super.isExpanded,
    super.lineCount,
    super.significance,
    this.tags = const [],
    this.aliases = const [],
    this.comments = const [],
    this.attachment,
  });

  @override
  String get tableName => 'INode';

  @override
  Nodes toRust() {
    return Nodes.iNode(
      INode(
        key: id,
        fields: INodeFields(
          content: content,
          style: style,
          resolvedStyle: resolvedStyle,
          layer: layer,
          position: frb.Coordinates(
            x: position.dx.round(),
            y: position.dy.round(),
          ),
          size: frb.Size(
            width: size.width.round(),
            height: size.height.round(),
          ),
          lineCount: lineCount,
          expandable: expandable,
          isExpanded: isExpanded,
          locked: locked,
          tags: tags.map((tag) => TagEdge.hydrated(tag)).toList(),
          aliases: aliases,
          comments: comments,
          attachment: attachment,
          significance: significance,
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      ),
    );
  }

  factory InfoUiNode.fromRust(INode node) {
    final fields = node.fields;
    return InfoUiNode(
      id: node.key,
      createdAt: fields.createdAt,
      updatedAt: fields.updatedAt,
      locked: fields.locked,
      style: fields.style,
      resolvedStyle: fields.resolvedStyle,
      layer: fields.layer,
      position: Offset(
        fields.position.x.toDouble(),
        fields.position.y.toDouble(),
      ),
      size: Size(fields.size.width.toDouble(), fields.size.height.toDouble()),
      isExpanded: fields.isExpanded,
      significance: fields.significance,
      content: fields.content,
      lineCount: fields.lineCount,
      tags: fields.tags.map((edge) {
        return edge.when(
          hydrated: (tag) => tag,
          pointer: (record) => Tag(name: record.key, color: 0xFF78909C),
        );
      }).toList(),
      aliases: fields.aliases,
      comments: fields.comments,
      attachment: fields.attachment,
    );
  }

  InfoUiNode copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    bool? locked,
    NodeStyle? style,
    NodeStyle? resolvedStyle,
    String? layer,
    Size? size,
    bool? isExpanded,
    int? lineCount,
    int? significance,
    Offset? position,
    Content? content,
    List<Tag>? tags,
    List<String>? aliases,
    List<frb.Comment>? comments,
    String? attachment,
  }) {
    return InfoUiNode(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      locked: locked ?? this.locked,
      style: style ?? this.style,
      resolvedStyle: resolvedStyle ?? this.resolvedStyle,
      layer: layer ?? this.layer,
      size: size ?? this.size,
      isExpanded: isExpanded ?? this.isExpanded,
      lineCount: lineCount ?? this.lineCount,
      significance: significance ?? this.significance,
      position: position ?? this.position,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      aliases: aliases ?? this.aliases,
      comments: comments ?? this.comments,
      attachment: attachment ?? this.attachment,
    );
  }
}

class TaskUiNode extends UiNode {
  int? dueDate;
  String state;

  TaskUiNode({
    required super.position,
    super.content,
    super.id,
    super.createdAt,
    super.updatedAt,
    super.locked,
    super.style,
    super.resolvedStyle,
    super.layer,
    super.size,
    super.isExpanded,
    super.lineCount,
    super.significance,
    this.dueDate,
    this.state = "Not Done",
  });

  @override
  String get tableName => 'TaskNode';

  @override
  Nodes toRust() {
    return Nodes.taskNode(
      TaskNode(
        key: id,
        fields: TaskNodeFields(
          content: content,
          dueDate: dueDate,
          state: state,
          position: frb.Coordinates(
            x: position.dx.round(),
            y: position.dy.round(),
          ),
          size: frb.Size(
            width: size.width.round(),
            height: size.height.round(),
          ),
          expandable: expandable,
          isExpanded: isExpanded,
          layer: layer,
          style: style,
          resolvedStyle: resolvedStyle,
          significance: significance,
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      ),
    );
  }

  factory TaskUiNode.fromRust(TaskNode node) {
    final fields = node.fields;
    return TaskUiNode(
      id: node.key,
      createdAt: fields.createdAt,
      updatedAt: fields.updatedAt,
      style: fields.style,
      resolvedStyle: fields.resolvedStyle,
      layer: fields.layer,
      position: Offset(
        fields.position.x.toDouble(),
        fields.position.y.toDouble(),
      ),
      size: Size(fields.size.width.toDouble(), fields.size.height.toDouble()),
      isExpanded: fields.isExpanded,
      significance: fields.significance,
      content: fields.content,
      dueDate: fields.dueDate,
      state: fields.state,
    );
  }

  TaskUiNode copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    bool? locked,
    NodeStyle? style,
    NodeStyle? resolvedStyle,
    String? layer,
    Size? size,
    bool? isExpanded,
    int? lineCount,
    int? significance,
    Offset? position,
    Content? content,
    int? dueDate,
    String? state,
  }) {
    return TaskUiNode(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      locked: locked ?? this.locked,
      style: style ?? this.style,
      resolvedStyle: resolvedStyle ?? this.resolvedStyle,
      layer: layer ?? this.layer,
      size: size ?? this.size,
      isExpanded: isExpanded ?? this.isExpanded,
      lineCount: lineCount ?? this.lineCount,
      significance: significance ?? this.significance,
      position: position ?? this.position,
      content: content ?? this.content,
      dueDate: dueDate ?? this.dueDate,
      state: state ?? this.state,
    );
  }
}
