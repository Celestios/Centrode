// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// UiNodeGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'graph_node.dart';

enum UiNodes { comment, drawing, frame, info, inter, media, shape, task }

class CommentUiNode extends UiNode {
  String text;

  CommentUiNode({
    required super.position,
    super.id,
    super.layer,
    super.createdAt,
    super.updatedAt,
    super.size,
    required this.text,
  });

  @override
  String get tableName => 'CommentNode';

  @override
  Nodes toRust() {
    return Nodes.commentNode(
      CommentNode(
        id: frb.RecordStrings(table: tableName, key: id),
        position: frb.Coordinates(
          x: position.dx.round(),
          y: position.dy.round(),
        ),
        layer: layer,
        createdAt: createdAt,
        updatedAt: updatedAt,
        size: frb.Size(width: size.width.round(), height: size.height.round()),
        text: text,
      ),
    );
  }

  factory CommentUiNode.fromRust(CommentNode node) {
    return CommentUiNode(
      id: node.id.key,
      createdAt: node.createdAt,
      updatedAt: node.updatedAt,
      layer: node.layer,
      position: Offset(node.position.x.toDouble(), node.position.y.toDouble()),
      size: Size(node.size.width.toDouble(), node.size.height.toDouble()),
      text: node.text,
    );
  }

  CommentUiNode copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    String? layer,
    Offset? position,
    Size? size,
    String? text,
  }) {
    return CommentUiNode(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      layer: layer ?? this.layer,
      position: position ?? this.position,
      size: size ?? this.size,
      text: text ?? this.text,
    );
  }
}

class DrawingUiNode extends UiNode {
  List<String> paths;
  String brushType;
  double brushThickness;
  String brushColor;

  DrawingUiNode({
    required super.position,
    super.id,
    super.layer,
    super.createdAt,
    super.updatedAt,
    super.size,
    super.locked,
    this.paths = const [],
    required this.brushType,
    required this.brushThickness,
    required this.brushColor,
  });

  @override
  String get tableName => 'DrawingNode';

  @override
  Nodes toRust() {
    return Nodes.drawingNode(
      DrawingNode(
        id: frb.RecordStrings(table: tableName, key: id),
        position: frb.Coordinates(
          x: position.dx.round(),
          y: position.dy.round(),
        ),
        layer: layer,
        createdAt: createdAt,
        updatedAt: updatedAt,
        size: frb.Size(width: size.width.round(), height: size.height.round()),
        locked: locked,
        paths: paths,
        brushType: brushType,
        brushThickness: brushThickness,
        brushColor: brushColor,
      ),
    );
  }

  factory DrawingUiNode.fromRust(DrawingNode node) {
    return DrawingUiNode(
      id: node.id.key,
      createdAt: node.createdAt,
      updatedAt: node.updatedAt,
      layer: node.layer,
      position: Offset(node.position.x.toDouble(), node.position.y.toDouble()),
      size: Size(node.size.width.toDouble(), node.size.height.toDouble()),
      locked: node.locked,
      paths: node.paths,
      brushType: node.brushType,
      brushThickness: node.brushThickness,
      brushColor: node.brushColor,
    );
  }

  DrawingUiNode copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    String? layer,
    Offset? position,
    Size? size,
    bool? locked,
    List<String>? paths,
    String? brushType,
    double? brushThickness,
    String? brushColor,
  }) {
    return DrawingUiNode(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      layer: layer ?? this.layer,
      position: position ?? this.position,
      size: size ?? this.size,
      locked: locked ?? this.locked,
      paths: paths ?? this.paths,
      brushType: brushType ?? this.brushType,
      brushThickness: brushThickness ?? this.brushThickness,
      brushColor: brushColor ?? this.brushColor,
    );
  }
}

class FrameUiNode extends UiNode {
  String title;

  FrameUiNode({
    required super.position,
    super.id,
    super.layer,
    super.createdAt,
    super.updatedAt,
    super.style,
    super.size,
    required this.title,
  });

  @override
  String get tableName => 'FrameNode';

  @override
  Nodes toRust() {
    return Nodes.frameNode(
      FrameNode(
        id: frb.RecordStrings(table: tableName, key: id),
        position: frb.Coordinates(
          x: position.dx.round(),
          y: position.dy.round(),
        ),
        layer: layer,
        createdAt: createdAt,
        updatedAt: updatedAt,
        style: style,
        size: frb.Size(width: size.width.round(), height: size.height.round()),
        title: title,
      ),
    );
  }

  factory FrameUiNode.fromRust(FrameNode node) {
    return FrameUiNode(
      id: node.id.key,
      createdAt: node.createdAt,
      updatedAt: node.updatedAt,
      layer: node.layer,
      position: Offset(node.position.x.toDouble(), node.position.y.toDouble()),
      style: node.style,
      size: Size(node.size.width.toDouble(), node.size.height.toDouble()),
      title: node.title,
    );
  }

  FrameUiNode copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    String? layer,
    Offset? position,
    NodeStyle? style,
    Size? size,
    String? title,
  }) {
    return FrameUiNode(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      layer: layer ?? this.layer,
      position: position ?? this.position,
      style: style ?? this.style,
      size: size ?? this.size,
      title: title ?? this.title,
    );
  }
}

class InfoUiNode extends UiNode {
  List<Tag> tags;
  List<String> aliases;
  List<Comment> comments;
  String? attachment;

  InfoUiNode({
    required super.position,
    super.id,
    super.layer,
    super.createdAt,
    super.updatedAt,
    super.content,
    super.style,
    super.resolvedStyle,
    super.layout,
    super.resolvedLayout,
    super.size,
    super.lineCount,
    super.initialExpandable,
    super.isExpanded,
    super.locked,
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
        id: frb.RecordStrings(table: tableName, key: id),
        position: frb.Coordinates(
          x: position.dx.round(),
          y: position.dy.round(),
        ),
        layer: layer,
        createdAt: createdAt,
        updatedAt: updatedAt,
        content: content,
        style: style,
        resolvedStyle: resolvedStyle,
        layout: layout,
        resolvedLayout: resolvedLayout,
        size: frb.Size(width: size.width.round(), height: size.height.round()),
        lineCount: lineCount,
        expandable: expandable,
        isExpanded: isExpanded,
        locked: locked,
        significance: significance,
        tags: tags.map((tag) => TagEdge.hydrated(tag)).toList(),
        aliases: aliases,
        comments: comments,
        attachment: attachment,
      ),
    );
  }

  factory InfoUiNode.fromRust(INode node) {
    return InfoUiNode(
      id: node.id.key,
      createdAt: node.createdAt,
      updatedAt: node.updatedAt,
      layer: node.layer,
      position: Offset(node.position.x.toDouble(), node.position.y.toDouble()),
      content: node.content,
      style: node.style,
      resolvedStyle: node.resolvedStyle,
      layout: node.layout,
      resolvedLayout: node.resolvedLayout,
      size: Size(node.size.width.toDouble(), node.size.height.toDouble()),
      lineCount: node.lineCount,
      initialExpandable: node.expandable,
      isExpanded: node.isExpanded,
      locked: node.locked,
      significance: node.significance,
      tags: node.tags.map((edge) {
        return edge.when(
          hydrated: (tag) => tag,
          pointer: (record) => Tag(
            key: record.key,
            fields: TagFields(
              name: record.key,
              color: 0xFF78909C,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            ),
          ),
        );
      }).toList(),
      aliases: node.aliases,
      comments: node.comments,
      attachment: node.attachment,
    );
  }

  InfoUiNode copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    String? layer,
    Offset? position,
    Content? content,
    NodeStyle? style,
    NodeStyle? resolvedStyle,
    NodeLayout? layout,
    NodeLayout? resolvedLayout,
    Size? size,
    int? lineCount,
    bool? expandable,
    bool? isExpanded,
    bool? locked,
    int? significance,
    List<Tag>? tags,
    List<String>? aliases,
    List<Comment>? comments,
    String? attachment,
  }) {
    return InfoUiNode(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      layer: layer ?? this.layer,
      position: position ?? this.position,
      content: content ?? this.content,
      style: style ?? this.style,
      resolvedStyle: resolvedStyle ?? this.resolvedStyle,
      layout: layout ?? this.layout,
      resolvedLayout: resolvedLayout ?? this.resolvedLayout,
      size: size ?? this.size,
      lineCount: lineCount ?? this.lineCount,
      initialExpandable: expandable ?? this.expandable,
      isExpanded: isExpanded ?? this.isExpanded,
      locked: locked ?? this.locked,
      significance: significance ?? this.significance,
      tags: tags ?? this.tags,
      aliases: aliases ?? this.aliases,
      comments: comments ?? this.comments,
      attachment: attachment ?? this.attachment,
    );
  }
}

class InterUiNode extends UiNode {
  String? styleName;
  String verb;
  String? behavioralFeatures;

  InterUiNode({
    required super.position,
    super.id,
    super.layer,
    super.createdAt,
    super.updatedAt,
    this.styleName,
    required this.verb,
    this.behavioralFeatures,
  });

  @override
  String get tableName => 'InterNode';

  @override
  Nodes toRust() {
    return Nodes.interNode(
      InterNode(
        id: frb.RecordStrings(table: tableName, key: id),
        position: frb.Coordinates(
          x: position.dx.round(),
          y: position.dy.round(),
        ),
        layer: layer,
        createdAt: createdAt,
        updatedAt: updatedAt,
        style: styleName,
        verb: verb,
        behavioralFeatures: behavioralFeatures,
      ),
    );
  }

  factory InterUiNode.fromRust(InterNode node) {
    return InterUiNode(
      id: node.id.key,
      createdAt: node.createdAt,
      updatedAt: node.updatedAt,
      layer: node.layer,
      position: Offset(node.position.x.toDouble(), node.position.y.toDouble()),
      styleName: node.style,
      verb: node.verb,
      behavioralFeatures: node.behavioralFeatures,
    );
  }

  InterUiNode copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    String? layer,
    Offset? position,
    String? styleName,
    String? verb,
    String? behavioralFeatures,
  }) {
    return InterUiNode(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      layer: layer ?? this.layer,
      position: position ?? this.position,
      styleName: styleName ?? this.styleName,
      verb: verb ?? this.verb,
      behavioralFeatures: behavioralFeatures ?? this.behavioralFeatures,
    );
  }
}

class MediaUiNode extends UiNode {
  String sourceUrl;
  String mediaType;

  MediaUiNode({
    required super.position,
    super.id,
    super.layer,
    super.createdAt,
    super.updatedAt,
    super.size,
    required this.sourceUrl,
    required this.mediaType,
  });

  @override
  String get tableName => 'MediaNode';

  @override
  Nodes toRust() {
    return Nodes.mediaNode(
      MediaNode(
        id: frb.RecordStrings(table: tableName, key: id),
        position: frb.Coordinates(
          x: position.dx.round(),
          y: position.dy.round(),
        ),
        layer: layer,
        createdAt: createdAt,
        updatedAt: updatedAt,
        size: frb.Size(width: size.width.round(), height: size.height.round()),
        sourceUrl: sourceUrl,
        mediaType: mediaType,
      ),
    );
  }

  factory MediaUiNode.fromRust(MediaNode node) {
    return MediaUiNode(
      id: node.id.key,
      createdAt: node.createdAt,
      updatedAt: node.updatedAt,
      layer: node.layer,
      position: Offset(node.position.x.toDouble(), node.position.y.toDouble()),
      size: Size(node.size.width.toDouble(), node.size.height.toDouble()),
      sourceUrl: node.sourceUrl,
      mediaType: node.mediaType,
    );
  }

  MediaUiNode copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    String? layer,
    Offset? position,
    Size? size,
    String? sourceUrl,
    String? mediaType,
  }) {
    return MediaUiNode(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      layer: layer ?? this.layer,
      position: position ?? this.position,
      size: size ?? this.size,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      mediaType: mediaType ?? this.mediaType,
    );
  }
}

class ShapeUiNode extends UiNode {
  String shapeType;

  ShapeUiNode({
    required super.position,
    super.id,
    super.layer,
    super.createdAt,
    super.updatedAt,
    super.style,
    super.size,
    required this.shapeType,
  });

  @override
  String get tableName => 'ShapeNode';

  @override
  Nodes toRust() {
    return Nodes.shapeNode(
      ShapeNode(
        id: frb.RecordStrings(table: tableName, key: id),
        position: frb.Coordinates(
          x: position.dx.round(),
          y: position.dy.round(),
        ),
        layer: layer,
        createdAt: createdAt,
        updatedAt: updatedAt,
        style: style,
        size: frb.Size(width: size.width.round(), height: size.height.round()),
        shapeType: shapeType,
      ),
    );
  }

  factory ShapeUiNode.fromRust(ShapeNode node) {
    return ShapeUiNode(
      id: node.id.key,
      createdAt: node.createdAt,
      updatedAt: node.updatedAt,
      layer: node.layer,
      position: Offset(node.position.x.toDouble(), node.position.y.toDouble()),
      style: node.style,
      size: Size(node.size.width.toDouble(), node.size.height.toDouble()),
      shapeType: node.shapeType,
    );
  }

  ShapeUiNode copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    String? layer,
    Offset? position,
    NodeStyle? style,
    Size? size,
    String? shapeType,
  }) {
    return ShapeUiNode(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      layer: layer ?? this.layer,
      position: position ?? this.position,
      style: style ?? this.style,
      size: size ?? this.size,
      shapeType: shapeType ?? this.shapeType,
    );
  }
}

class TaskUiNode extends UiNode {
  int? dueDate;
  String state;

  TaskUiNode({
    required super.position,
    super.id,
    super.layer,
    super.createdAt,
    super.updatedAt,
    super.content,
    super.size,
    super.initialExpandable,
    super.isExpanded,
    super.style,
    super.resolvedStyle,
    super.layout,
    super.resolvedLayout,
    super.significance,
    this.dueDate,
    this.state = 'Not Done',
  });

  @override
  String get tableName => 'TaskNode';

  @override
  Nodes toRust() {
    return Nodes.taskNode(
      TaskNode(
        id: frb.RecordStrings(table: tableName, key: id),
        position: frb.Coordinates(
          x: position.dx.round(),
          y: position.dy.round(),
        ),
        layer: layer,
        createdAt: createdAt,
        updatedAt: updatedAt,
        content: content,
        size: frb.Size(width: size.width.round(), height: size.height.round()),
        expandable: expandable,
        isExpanded: isExpanded,
        style: style,
        resolvedStyle: resolvedStyle,
        layout: layout,
        resolvedLayout: resolvedLayout,
        significance: significance,
        dueDate: dueDate,
        state: state,
      ),
    );
  }

  factory TaskUiNode.fromRust(TaskNode node) {
    return TaskUiNode(
      id: node.id.key,
      createdAt: node.createdAt,
      updatedAt: node.updatedAt,
      layer: node.layer,
      position: Offset(node.position.x.toDouble(), node.position.y.toDouble()),
      content: node.content,
      size: Size(node.size.width.toDouble(), node.size.height.toDouble()),
      initialExpandable: node.expandable,
      isExpanded: node.isExpanded,
      style: node.style,
      resolvedStyle: node.resolvedStyle,
      layout: node.layout,
      resolvedLayout: node.resolvedLayout,
      significance: node.significance,
      dueDate: node.dueDate,
      state: node.state,
    );
  }

  TaskUiNode copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    String? layer,
    Offset? position,
    Content? content,
    Size? size,
    bool? expandable,
    bool? isExpanded,
    NodeStyle? style,
    NodeStyle? resolvedStyle,
    NodeLayout? layout,
    NodeLayout? resolvedLayout,
    int? significance,
    int? dueDate,
    String? state,
  }) {
    return TaskUiNode(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      layer: layer ?? this.layer,
      position: position ?? this.position,
      content: content ?? this.content,
      size: size ?? this.size,
      initialExpandable: expandable ?? this.expandable,
      isExpanded: isExpanded ?? this.isExpanded,
      style: style ?? this.style,
      resolvedStyle: resolvedStyle ?? this.resolvedStyle,
      layout: layout ?? this.layout,
      resolvedLayout: resolvedLayout ?? this.resolvedLayout,
      significance: significance ?? this.significance,
      dueDate: dueDate ?? this.dueDate,
      state: state ?? this.state,
    );
  }
}

UiNode _$uiNodeFromRust(Object rustNode) {
  if (rustNode is CommentNode) return CommentUiNode.fromRust(rustNode);
  if (rustNode is DrawingNode) return DrawingUiNode.fromRust(rustNode);
  if (rustNode is FrameNode) return FrameUiNode.fromRust(rustNode);
  if (rustNode is INode) return InfoUiNode.fromRust(rustNode);
  if (rustNode is InterNode) return InterUiNode.fromRust(rustNode);
  if (rustNode is MediaNode) return MediaUiNode.fromRust(rustNode);
  if (rustNode is ShapeNode) return ShapeUiNode.fromRust(rustNode);
  if (rustNode is TaskNode) return TaskUiNode.fromRust(rustNode);
  if (rustNode is Nodes_CommentNode)
    return CommentUiNode.fromRust(rustNode.field0);
  if (rustNode is Nodes_DrawingNode)
    return DrawingUiNode.fromRust(rustNode.field0);
  if (rustNode is Nodes_FrameNode) return FrameUiNode.fromRust(rustNode.field0);
  if (rustNode is Nodes_INode) return InfoUiNode.fromRust(rustNode.field0);
  if (rustNode is Nodes_InterNode) return InterUiNode.fromRust(rustNode.field0);
  if (rustNode is Nodes_MediaNode) return MediaUiNode.fromRust(rustNode.field0);
  if (rustNode is Nodes_ShapeNode) return ShapeUiNode.fromRust(rustNode.field0);
  if (rustNode is Nodes_TaskNode) return TaskUiNode.fromRust(rustNode.field0);
  throw ArgumentError('Unsupported Rust node type: ${rustNode.runtimeType}');
}

UiNode? _$uiNodeCopy(UiNode? node) {
  if (node == null) return null;
  if (node is CommentUiNode) return node.copyWith();
  if (node is DrawingUiNode) return node.copyWith();
  if (node is FrameUiNode) return node.copyWith();
  if (node is InfoUiNode) return node.copyWith();
  if (node is InterUiNode) return node.copyWith();
  if (node is MediaUiNode) return node.copyWith();
  if (node is ShapeUiNode) return node.copyWith();
  if (node is TaskUiNode) return node.copyWith();
  throw ArgumentError('Unsupported node type: ${node.runtimeType}');
}
