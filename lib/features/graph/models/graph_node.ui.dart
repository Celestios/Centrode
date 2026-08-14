// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// UiNodeGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'graph_node.dart';

enum UiNodes {
  comment,
  container,
  drawing,
  frame,
  info,
  inter,
  media,
  shape,
  task,
}

class CommentUiNode extends UiNode {
  @override
  String text;

  CommentUiNode({
    required super.position,
    super.id,
    super.parentContainerId,
    super.layer,
    super.createdAt,
    super.updatedAt,
    super.size,
    super.content,
    super.style,
    super.resolvedStyle,
    super.layout,
    super.resolvedLayout,
    super.lineCount,
    super.initialExpandable,
    super.isExpanded,
    super.locked,
    super.significance,
    required this.text,
  });

  @override
  String get tableName => 'CommentNode';

  @override
  Nodes toRust() {
    return Nodes.commentNode(
      CommentNode(
        id: TypedRecordId(
          table: TableKind.commentNode,
          key: UuidValue.fromString(id.toUuidString()),
        ),
        parentContainerId: parentContainerId != null
            ? TypedRecordId(
                table: TableKind.containerNode,
                key: UuidValue.fromString(parentContainerId!.toUuidString()),
              )
            : null,
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
      id: RawUuid.fromString(node.id.key.uuid),
      parentContainerId: node.parentContainerId != null
          ? RawUuid.fromString(node.parentContainerId!.key.uuid)
          : null,
      createdAt: node.createdAt,
      updatedAt: node.updatedAt,
      layer: node.layer,
      position: Offset(node.position.x.toDouble(), node.position.y.toDouble()),
      size: Size(node.size.width.toDouble(), node.size.height.toDouble()),
      text: node.text,
    );
  }

  CommentUiNode copyWith({
    RawUuid? id,
    RawUuid? parentContainerId,
    int? createdAt,
    int? updatedAt,
    String? layer,
    Offset? position,
    Size? size,
    Content? content,
    NodeStyle? style,
    NodeStyle? resolvedStyle,
    NodeLayout? layout,
    NodeLayout? resolvedLayout,
    int? lineCount,
    bool? expandable,
    bool? isExpanded,
    bool? locked,
    int? significance,
    String? text,
  }) {
    return CommentUiNode(
      id: id ?? this.id,
      parentContainerId: parentContainerId ?? this.parentContainerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      layer: layer ?? this.layer,
      position: position ?? this.position,
      size: size ?? this.size,
      content: content ?? this.content,
      style: style ?? this.style,
      resolvedStyle: resolvedStyle ?? this.resolvedStyle,
      layout: layout ?? this.layout,
      resolvedLayout: resolvedLayout ?? this.resolvedLayout,
      lineCount: lineCount ?? this.lineCount,
      initialExpandable: expandable ?? this.expandable,
      isExpanded: isExpanded ?? this.isExpanded,
      locked: locked ?? this.locked,
      significance: significance ?? this.significance,
      text: text ?? this.text,
    );
  }
}

class ContainerUiNode extends UiNode {
  String title;
  bool isClosed;
  int childCount;
  List<Tag> tags;
  List<Comment> comments;

  ContainerUiNode({
    required super.position,
    super.id,
    super.parentContainerId,
    super.layer,
    super.createdAt,
    super.updatedAt,
    super.size,
    super.content,
    super.style,
    super.resolvedStyle,
    super.layout,
    super.resolvedLayout,
    super.lineCount,
    super.initialExpandable,
    super.isExpanded,
    super.locked,
    super.significance,
    required this.title,
    required this.isClosed,
    required this.childCount,
    this.tags = const [],
    this.comments = const [],
  });

  @override
  String get tableName => 'ContainerNode';

  @override
  Nodes toRust() {
    return Nodes.containerNode(
      ContainerNode(
        id: TypedRecordId(
          table: TableKind.containerNode,
          key: UuidValue.fromString(id.toUuidString()),
        ),
        parentContainerId: parentContainerId != null
            ? TypedRecordId(
                table: TableKind.containerNode,
                key: UuidValue.fromString(parentContainerId!.toUuidString()),
              )
            : null,
        position: frb.Coordinates(
          x: position.dx.round(),
          y: position.dy.round(),
        ),
        layer: layer,
        createdAt: createdAt,
        updatedAt: updatedAt,
        style: style,
        resolvedStyle: resolvedStyle,
        layout: layout,
        resolvedLayout: resolvedLayout,
        size: frb.Size(width: size.width.round(), height: size.height.round()),
        locked: locked,
        significance: significance,
        title: title,
        isClosed: isClosed,
        childCount: childCount,
        tags: tags.map((tag) => TagEdge.hydrated(tag)).toList(),
        comments: comments,
      ),
    );
  }

  factory ContainerUiNode.fromRust(ContainerNode node) {
    return ContainerUiNode(
      id: RawUuid.fromString(node.id.key.uuid),
      parentContainerId: node.parentContainerId != null
          ? RawUuid.fromString(node.parentContainerId!.key.uuid)
          : null,
      createdAt: node.createdAt,
      updatedAt: node.updatedAt,
      layer: node.layer,
      position: Offset(node.position.x.toDouble(), node.position.y.toDouble()),
      style: node.style,
      resolvedStyle: node.resolvedStyle,
      layout: node.layout,
      resolvedLayout: node.resolvedLayout,
      size: Size(node.size.width.toDouble(), node.size.height.toDouble()),
      locked: node.locked,
      significance: node.significance,
      title: node.title,
      isClosed: node.isClosed,
      childCount: node.childCount,
      tags: node.tags.map((edge) {
        return edge.when(
          hydrated: (tag) => tag,
          pointer: (record) => Tag(
            key: record,
            fields: TagFields(
              name: record.key.uuid,
              color: 0xFF78909C,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            ),
          ),
        );
      }).toList(),
      comments: node.comments,
    );
  }

  ContainerUiNode copyWith({
    RawUuid? id,
    RawUuid? parentContainerId,
    int? createdAt,
    int? updatedAt,
    String? layer,
    Offset? position,
    Size? size,
    Content? content,
    NodeStyle? style,
    NodeStyle? resolvedStyle,
    NodeLayout? layout,
    NodeLayout? resolvedLayout,
    int? lineCount,
    bool? expandable,
    bool? isExpanded,
    bool? locked,
    int? significance,
    String? title,
    bool? isClosed,
    int? childCount,
    List<Tag>? tags,
    List<Comment>? comments,
  }) {
    return ContainerUiNode(
      id: id ?? this.id,
      parentContainerId: parentContainerId ?? this.parentContainerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      layer: layer ?? this.layer,
      position: position ?? this.position,
      size: size ?? this.size,
      content: content ?? this.content,
      style: style ?? this.style,
      resolvedStyle: resolvedStyle ?? this.resolvedStyle,
      layout: layout ?? this.layout,
      resolvedLayout: resolvedLayout ?? this.resolvedLayout,
      lineCount: lineCount ?? this.lineCount,
      initialExpandable: expandable ?? this.expandable,
      isExpanded: isExpanded ?? this.isExpanded,
      locked: locked ?? this.locked,
      significance: significance ?? this.significance,
      title: title ?? this.title,
      isClosed: isClosed ?? this.isClosed,
      childCount: childCount ?? this.childCount,
      tags: tags ?? this.tags,
      comments: comments ?? this.comments,
    );
  }
}

class DrawingUiNode extends UiNode {
  List<String> paths;
  BrushType brushType;
  double brushThickness;
  String brushColor;

  DrawingUiNode({
    required super.position,
    super.id,
    super.parentContainerId,
    super.layer,
    super.createdAt,
    super.updatedAt,
    super.size,
    super.content,
    super.style,
    super.resolvedStyle,
    super.layout,
    super.resolvedLayout,
    super.lineCount,
    super.initialExpandable,
    super.isExpanded,
    super.locked,
    super.significance,
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
        id: TypedRecordId(
          table: TableKind.drawingNode,
          key: UuidValue.fromString(id.toUuidString()),
        ),
        parentContainerId: parentContainerId != null
            ? TypedRecordId(
                table: TableKind.containerNode,
                key: UuidValue.fromString(parentContainerId!.toUuidString()),
              )
            : null,
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
      id: RawUuid.fromString(node.id.key.uuid),
      parentContainerId: node.parentContainerId != null
          ? RawUuid.fromString(node.parentContainerId!.key.uuid)
          : null,
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
    RawUuid? id,
    RawUuid? parentContainerId,
    int? createdAt,
    int? updatedAt,
    String? layer,
    Offset? position,
    Size? size,
    Content? content,
    NodeStyle? style,
    NodeStyle? resolvedStyle,
    NodeLayout? layout,
    NodeLayout? resolvedLayout,
    int? lineCount,
    bool? expandable,
    bool? isExpanded,
    bool? locked,
    int? significance,
    List<String>? paths,
    BrushType? brushType,
    double? brushThickness,
    String? brushColor,
  }) {
    return DrawingUiNode(
      id: id ?? this.id,
      parentContainerId: parentContainerId ?? this.parentContainerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      layer: layer ?? this.layer,
      position: position ?? this.position,
      size: size ?? this.size,
      content: content ?? this.content,
      style: style ?? this.style,
      resolvedStyle: resolvedStyle ?? this.resolvedStyle,
      layout: layout ?? this.layout,
      resolvedLayout: resolvedLayout ?? this.resolvedLayout,
      lineCount: lineCount ?? this.lineCount,
      initialExpandable: expandable ?? this.expandable,
      isExpanded: isExpanded ?? this.isExpanded,
      locked: locked ?? this.locked,
      significance: significance ?? this.significance,
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
    super.parentContainerId,
    super.layer,
    super.createdAt,
    super.updatedAt,
    super.size,
    super.content,
    super.style,
    super.resolvedStyle,
    super.layout,
    super.resolvedLayout,
    super.lineCount,
    super.initialExpandable,
    super.isExpanded,
    super.locked,
    super.significance,
    required this.title,
  });

  @override
  String get tableName => 'FrameNode';

  @override
  Nodes toRust() {
    return Nodes.frameNode(
      FrameNode(
        id: TypedRecordId(
          table: TableKind.frameNode,
          key: UuidValue.fromString(id.toUuidString()),
        ),
        parentContainerId: parentContainerId != null
            ? TypedRecordId(
                table: TableKind.containerNode,
                key: UuidValue.fromString(parentContainerId!.toUuidString()),
              )
            : null,
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
      id: RawUuid.fromString(node.id.key.uuid),
      parentContainerId: node.parentContainerId != null
          ? RawUuid.fromString(node.parentContainerId!.key.uuid)
          : null,
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
    RawUuid? id,
    RawUuid? parentContainerId,
    int? createdAt,
    int? updatedAt,
    String? layer,
    Offset? position,
    Size? size,
    Content? content,
    NodeStyle? style,
    NodeStyle? resolvedStyle,
    NodeLayout? layout,
    NodeLayout? resolvedLayout,
    int? lineCount,
    bool? expandable,
    bool? isExpanded,
    bool? locked,
    int? significance,
    String? title,
  }) {
    return FrameUiNode(
      id: id ?? this.id,
      parentContainerId: parentContainerId ?? this.parentContainerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      layer: layer ?? this.layer,
      position: position ?? this.position,
      size: size ?? this.size,
      content: content ?? this.content,
      style: style ?? this.style,
      resolvedStyle: resolvedStyle ?? this.resolvedStyle,
      layout: layout ?? this.layout,
      resolvedLayout: resolvedLayout ?? this.resolvedLayout,
      lineCount: lineCount ?? this.lineCount,
      initialExpandable: expandable ?? this.expandable,
      isExpanded: isExpanded ?? this.isExpanded,
      locked: locked ?? this.locked,
      significance: significance ?? this.significance,
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
    super.parentContainerId,
    super.layer,
    super.createdAt,
    super.updatedAt,
    super.size,
    super.content,
    super.style,
    super.resolvedStyle,
    super.layout,
    super.resolvedLayout,
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
        id: TypedRecordId(
          table: TableKind.iNode,
          key: UuidValue.fromString(id.toUuidString()),
        ),
        parentContainerId: parentContainerId != null
            ? TypedRecordId(
                table: TableKind.containerNode,
                key: UuidValue.fromString(parentContainerId!.toUuidString()),
              )
            : null,
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
      id: RawUuid.fromString(node.id.key.uuid),
      parentContainerId: node.parentContainerId != null
          ? RawUuid.fromString(node.parentContainerId!.key.uuid)
          : null,
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
            key: record,
            fields: TagFields(
              name: record.key.uuid,
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
    RawUuid? id,
    RawUuid? parentContainerId,
    int? createdAt,
    int? updatedAt,
    String? layer,
    Offset? position,
    Size? size,
    Content? content,
    NodeStyle? style,
    NodeStyle? resolvedStyle,
    NodeLayout? layout,
    NodeLayout? resolvedLayout,
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
      parentContainerId: parentContainerId ?? this.parentContainerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      layer: layer ?? this.layer,
      position: position ?? this.position,
      size: size ?? this.size,
      content: content ?? this.content,
      style: style ?? this.style,
      resolvedStyle: resolvedStyle ?? this.resolvedStyle,
      layout: layout ?? this.layout,
      resolvedLayout: resolvedLayout ?? this.resolvedLayout,
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
    super.parentContainerId,
    super.layer,
    super.createdAt,
    super.updatedAt,
    super.size,
    super.content,
    super.style,
    super.resolvedStyle,
    super.layout,
    super.resolvedLayout,
    super.lineCount,
    super.initialExpandable,
    super.isExpanded,
    super.locked,
    super.significance,
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
        id: TypedRecordId(
          table: TableKind.interNode,
          key: UuidValue.fromString(id.toUuidString()),
        ),
        parentContainerId: parentContainerId != null
            ? TypedRecordId(
                table: TableKind.containerNode,
                key: UuidValue.fromString(parentContainerId!.toUuidString()),
              )
            : null,
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
      id: RawUuid.fromString(node.id.key.uuid),
      parentContainerId: node.parentContainerId != null
          ? RawUuid.fromString(node.parentContainerId!.key.uuid)
          : null,
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
    RawUuid? id,
    RawUuid? parentContainerId,
    int? createdAt,
    int? updatedAt,
    String? layer,
    Offset? position,
    Size? size,
    Content? content,
    NodeStyle? style,
    NodeStyle? resolvedStyle,
    NodeLayout? layout,
    NodeLayout? resolvedLayout,
    int? lineCount,
    bool? expandable,
    bool? isExpanded,
    bool? locked,
    int? significance,
    String? styleName,
    String? verb,
    String? behavioralFeatures,
  }) {
    return InterUiNode(
      id: id ?? this.id,
      parentContainerId: parentContainerId ?? this.parentContainerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      layer: layer ?? this.layer,
      position: position ?? this.position,
      size: size ?? this.size,
      content: content ?? this.content,
      style: style ?? this.style,
      resolvedStyle: resolvedStyle ?? this.resolvedStyle,
      layout: layout ?? this.layout,
      resolvedLayout: resolvedLayout ?? this.resolvedLayout,
      lineCount: lineCount ?? this.lineCount,
      initialExpandable: expandable ?? this.expandable,
      isExpanded: isExpanded ?? this.isExpanded,
      locked: locked ?? this.locked,
      significance: significance ?? this.significance,
      styleName: styleName ?? this.styleName,
      verb: verb ?? this.verb,
      behavioralFeatures: behavioralFeatures ?? this.behavioralFeatures,
    );
  }
}

class MediaUiNode extends UiNode {
  String sourceUrl;
  MediaType mediaType;

  MediaUiNode({
    required super.position,
    super.id,
    super.parentContainerId,
    super.layer,
    super.createdAt,
    super.updatedAt,
    super.size,
    super.content,
    super.style,
    super.resolvedStyle,
    super.layout,
    super.resolvedLayout,
    super.lineCount,
    super.initialExpandable,
    super.isExpanded,
    super.locked,
    super.significance,
    required this.sourceUrl,
    required this.mediaType,
  });

  @override
  String get tableName => 'MediaNode';

  @override
  Nodes toRust() {
    return Nodes.mediaNode(
      MediaNode(
        id: TypedRecordId(
          table: TableKind.mediaNode,
          key: UuidValue.fromString(id.toUuidString()),
        ),
        parentContainerId: parentContainerId != null
            ? TypedRecordId(
                table: TableKind.containerNode,
                key: UuidValue.fromString(parentContainerId!.toUuidString()),
              )
            : null,
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
      id: RawUuid.fromString(node.id.key.uuid),
      parentContainerId: node.parentContainerId != null
          ? RawUuid.fromString(node.parentContainerId!.key.uuid)
          : null,
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
    RawUuid? id,
    RawUuid? parentContainerId,
    int? createdAt,
    int? updatedAt,
    String? layer,
    Offset? position,
    Size? size,
    Content? content,
    NodeStyle? style,
    NodeStyle? resolvedStyle,
    NodeLayout? layout,
    NodeLayout? resolvedLayout,
    int? lineCount,
    bool? expandable,
    bool? isExpanded,
    bool? locked,
    int? significance,
    String? sourceUrl,
    MediaType? mediaType,
  }) {
    return MediaUiNode(
      id: id ?? this.id,
      parentContainerId: parentContainerId ?? this.parentContainerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      layer: layer ?? this.layer,
      position: position ?? this.position,
      size: size ?? this.size,
      content: content ?? this.content,
      style: style ?? this.style,
      resolvedStyle: resolvedStyle ?? this.resolvedStyle,
      layout: layout ?? this.layout,
      resolvedLayout: resolvedLayout ?? this.resolvedLayout,
      lineCount: lineCount ?? this.lineCount,
      initialExpandable: expandable ?? this.expandable,
      isExpanded: isExpanded ?? this.isExpanded,
      locked: locked ?? this.locked,
      significance: significance ?? this.significance,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      mediaType: mediaType ?? this.mediaType,
    );
  }
}

class ShapeUiNode extends UiNode {
  ShapeType shapeType;

  ShapeUiNode({
    required super.position,
    super.id,
    super.parentContainerId,
    super.layer,
    super.createdAt,
    super.updatedAt,
    super.size,
    super.content,
    super.style,
    super.resolvedStyle,
    super.layout,
    super.resolvedLayout,
    super.lineCount,
    super.initialExpandable,
    super.isExpanded,
    super.locked,
    super.significance,
    required this.shapeType,
  });

  @override
  String get tableName => 'ShapeNode';

  @override
  Nodes toRust() {
    return Nodes.shapeNode(
      ShapeNode(
        id: TypedRecordId(
          table: TableKind.shapeNode,
          key: UuidValue.fromString(id.toUuidString()),
        ),
        parentContainerId: parentContainerId != null
            ? TypedRecordId(
                table: TableKind.containerNode,
                key: UuidValue.fromString(parentContainerId!.toUuidString()),
              )
            : null,
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
      id: RawUuid.fromString(node.id.key.uuid),
      parentContainerId: node.parentContainerId != null
          ? RawUuid.fromString(node.parentContainerId!.key.uuid)
          : null,
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
    RawUuid? id,
    RawUuid? parentContainerId,
    int? createdAt,
    int? updatedAt,
    String? layer,
    Offset? position,
    Size? size,
    Content? content,
    NodeStyle? style,
    NodeStyle? resolvedStyle,
    NodeLayout? layout,
    NodeLayout? resolvedLayout,
    int? lineCount,
    bool? expandable,
    bool? isExpanded,
    bool? locked,
    int? significance,
    ShapeType? shapeType,
  }) {
    return ShapeUiNode(
      id: id ?? this.id,
      parentContainerId: parentContainerId ?? this.parentContainerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      layer: layer ?? this.layer,
      position: position ?? this.position,
      size: size ?? this.size,
      content: content ?? this.content,
      style: style ?? this.style,
      resolvedStyle: resolvedStyle ?? this.resolvedStyle,
      layout: layout ?? this.layout,
      resolvedLayout: resolvedLayout ?? this.resolvedLayout,
      lineCount: lineCount ?? this.lineCount,
      initialExpandable: expandable ?? this.expandable,
      isExpanded: isExpanded ?? this.isExpanded,
      locked: locked ?? this.locked,
      significance: significance ?? this.significance,
      shapeType: shapeType ?? this.shapeType,
    );
  }
}

class TaskUiNode extends UiNode {
  int? dueDate;
  TaskState state;

  TaskUiNode({
    required super.position,
    super.id,
    super.parentContainerId,
    super.layer,
    super.createdAt,
    super.updatedAt,
    super.size,
    super.content,
    super.style,
    super.resolvedStyle,
    super.layout,
    super.resolvedLayout,
    super.lineCount,
    super.initialExpandable,
    super.isExpanded,
    super.locked,
    super.significance,
    this.dueDate,
    this.state = TaskState.todo,
  });

  @override
  String get tableName => 'TaskNode';

  @override
  Nodes toRust() {
    return Nodes.taskNode(
      TaskNode(
        id: TypedRecordId(
          table: TableKind.taskNode,
          key: UuidValue.fromString(id.toUuidString()),
        ),
        parentContainerId: parentContainerId != null
            ? TypedRecordId(
                table: TableKind.containerNode,
                key: UuidValue.fromString(parentContainerId!.toUuidString()),
              )
            : null,
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
      id: RawUuid.fromString(node.id.key.uuid),
      parentContainerId: node.parentContainerId != null
          ? RawUuid.fromString(node.parentContainerId!.key.uuid)
          : null,
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
    RawUuid? id,
    RawUuid? parentContainerId,
    int? createdAt,
    int? updatedAt,
    String? layer,
    Offset? position,
    Size? size,
    Content? content,
    NodeStyle? style,
    NodeStyle? resolvedStyle,
    NodeLayout? layout,
    NodeLayout? resolvedLayout,
    int? lineCount,
    bool? expandable,
    bool? isExpanded,
    bool? locked,
    int? significance,
    int? dueDate,
    TaskState? state,
  }) {
    return TaskUiNode(
      id: id ?? this.id,
      parentContainerId: parentContainerId ?? this.parentContainerId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      layer: layer ?? this.layer,
      position: position ?? this.position,
      size: size ?? this.size,
      content: content ?? this.content,
      style: style ?? this.style,
      resolvedStyle: resolvedStyle ?? this.resolvedStyle,
      layout: layout ?? this.layout,
      resolvedLayout: resolvedLayout ?? this.resolvedLayout,
      lineCount: lineCount ?? this.lineCount,
      initialExpandable: expandable ?? this.expandable,
      isExpanded: isExpanded ?? this.isExpanded,
      locked: locked ?? this.locked,
      significance: significance ?? this.significance,
      dueDate: dueDate ?? this.dueDate,
      state: state ?? this.state,
    );
  }
}

UiNode _$uiNodeFromRust(Object rustNode) {
  if (rustNode is CommentNode) {
    return CommentUiNode.fromRust(rustNode);
  }
  if (rustNode is ContainerNode) {
    return ContainerUiNode.fromRust(rustNode);
  }
  if (rustNode is DrawingNode) {
    return DrawingUiNode.fromRust(rustNode);
  }
  if (rustNode is FrameNode) {
    return FrameUiNode.fromRust(rustNode);
  }
  if (rustNode is INode) {
    return InfoUiNode.fromRust(rustNode);
  }
  if (rustNode is InterNode) {
    return InterUiNode.fromRust(rustNode);
  }
  if (rustNode is MediaNode) {
    return MediaUiNode.fromRust(rustNode);
  }
  if (rustNode is ShapeNode) {
    return ShapeUiNode.fromRust(rustNode);
  }
  if (rustNode is TaskNode) {
    return TaskUiNode.fromRust(rustNode);
  }
  if (rustNode is Nodes_CommentNode) {
    return CommentUiNode.fromRust(rustNode.field0);
  }
  if (rustNode is Nodes_ContainerNode) {
    return ContainerUiNode.fromRust(rustNode.field0);
  }
  if (rustNode is Nodes_DrawingNode) {
    return DrawingUiNode.fromRust(rustNode.field0);
  }
  if (rustNode is Nodes_FrameNode) {
    return FrameUiNode.fromRust(rustNode.field0);
  }
  if (rustNode is Nodes_INode) {
    return InfoUiNode.fromRust(rustNode.field0);
  }
  if (rustNode is Nodes_InterNode) {
    return InterUiNode.fromRust(rustNode.field0);
  }
  if (rustNode is Nodes_MediaNode) {
    return MediaUiNode.fromRust(rustNode.field0);
  }
  if (rustNode is Nodes_ShapeNode) {
    return ShapeUiNode.fromRust(rustNode.field0);
  }
  if (rustNode is Nodes_TaskNode) {
    return TaskUiNode.fromRust(rustNode.field0);
  }
  throw ArgumentError('Unsupported Rust node type: ${rustNode.runtimeType}');
}

UiNode? _$uiNodeCopy(UiNode? node) {
  if (node == null) {
    return null;
  }
  if (node is CommentUiNode) {
    return node.copyWith();
  }
  if (node is ContainerUiNode) {
    return node.copyWith();
  }
  if (node is DrawingUiNode) {
    return node.copyWith();
  }
  if (node is FrameUiNode) {
    return node.copyWith();
  }
  if (node is InfoUiNode) {
    return node.copyWith();
  }
  if (node is InterUiNode) {
    return node.copyWith();
  }
  if (node is MediaUiNode) {
    return node.copyWith();
  }
  if (node is ShapeUiNode) {
    return node.copyWith();
  }
  if (node is TaskUiNode) {
    return node.copyWith();
  }
  throw ArgumentError('Unsupported node type: ${node.runtimeType}');
}
