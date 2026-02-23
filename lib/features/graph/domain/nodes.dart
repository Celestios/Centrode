import 'dart:convert';
import 'dart:ui'; // For Offset and Color

import 'package:mycelium/src/rust/bridge/api.dart';
import 'package:mycelium/src/rust/domain/nodes.dart';
import 'package:mycelium/src/rust/domain/base_models.dart';

import 'utils.dart';
import 'styling.dart';
import 'content_builder.dart';

// -----------------------------------------------------------------------------
// ID Normalization Helper
// -----------------------------------------------------------------------------

/// Strips the SurrealDB 'table:' prefix to ensure stable Map keys.
/// SurrealDB returns IDs as 'table:id' (e.g., 'inode:123'), but createNode
/// returns just the ID ('123'). This normalizes all IDs for O(1) lookups.
String _stripTablePrefix(String? raw) {
  if (raw == null) return "unknown";
  final parts = raw.split(':');
  return parts.length > 1 ? parts.sublist(1).join(':') : raw;
}

// -----------------------------------------------------------------------------
// UiNode Type Enum
// -----------------------------------------------------------------------------

enum UiNodeType { info, task, inter }

// -----------------------------------------------------------------------------
// UiNode Abstract Base Class
// -----------------------------------------------------------------------------

/// The Base Entity for everything on the Canvas.
/// This acts as the "ViewModel" for your nodes.
abstract class UiNode {
  // Core Identity
  String id; // Mutable because we swap Temp ID -> Real ID
  final UiNodeType type;

  // Visual Properties (Cached for performance)
  Offset position;
  Size size;
  Color color;

  // Common Data
  String text;
  bool isSelected;

  // Aesthetics for node-specific overrides
  StyleProfile? aesthetics;

  UiNode({
    required this.id,
    required this.type,
    required this.position,
    this.text = "",
    this.size = const Size(100, 60), // Default size
    this.color = const Color(0xFFFFFFFF),
    this.isSelected = false,
    this.aesthetics,
  });

  /// Factory to convert the Raw Rust Enum into a Dart UiNode
  static UiNode fromFFI(NodeOutput ffiNode) {
    if (ffiNode is NodeOutput_Info) {
      return InfoUiNode.fromRust(ffiNode.field0);
    } else if (ffiNode is NodeOutput_Task) {
      return TaskUiNode.fromRust(ffiNode.field0);
    } else if (ffiNode is NodeOutput_Inter) {
      return InterUiNode.fromRust(ffiNode.field0);
    } else {
      throw UnsupportedError('Unknown NodeOutput type');
    }
  }

  /// Converts the UI state back to a Rust input object for saving/creation
  NodeInput toInput();

  /// Creates a copy of this node with the given fields replaced.
  UiNode copyWith({Offset? position});
}

// -----------------------------------------------------------------------------
// Concrete Implementations
// -----------------------------------------------------------------------------

class InfoUiNode extends UiNode {
  final List<String> tags;
  final bool locked;

  InfoUiNode({
    required super.id,
    required super.position,
    required super.text,
    super.color = const Color(0xFFBBDEFB), // Blue-ish default
    this.tags = const [],
    this.locked = false,
    super.aesthetics,
  }) : super(type: UiNodeType.info);

  factory InfoUiNode.fromRust(INode source) {
    // 1. O(1) Spatial Extraction directly from FFI Struct
    // 2. Eradicated JSON parsing overhead
    return InfoUiNode(
      id: _stripTablePrefix(source.id),
      position: Offset(
        source.position.x.toDouble(),
        source.position.y.toDouble(),
      ),
      text: source.content.text, // Mapped to new Content structure
      tags: source.tags,
      locked: source.locked,
      aesthetics: source.aesthetics != null
          ? StyleProfile.fromJson(jsonDecode(source.aesthetics!))
          : null,
    );
  }

  @override
  NodeInput toInput() {
    return NodeInput.info(
      INode(
        id: id.startsWith("temp_") ? null : id,
        content: ContentFactory.fromText(text), // New Content object
        tags: tags,
        locked: locked,
        aesthetics: aesthetics != null
            ? jsonEncode(aesthetics!.toJson())
            : null,
        position: Coordinates(
          x: position.dx.toInt(),
          y: position.dy.toInt(),
          z: 0,
        ), // Formal Spatial Struct
        aliases: [],
        comments:
            [], // Note: FFI now expects List<Comment>, an empty list is technically sound here
        attachment: null,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  InfoUiNode copyWith({Offset? position}) {
    return InfoUiNode(
      id: id,
      position: position ?? this.position,
      text: text,
      color: color,
      tags: tags,
      locked: locked,
      aesthetics: aesthetics ?? this.aesthetics,
    );
  }
}

class TaskUiNode extends UiNode {
  String state; // TODO: Make this an Enum (Todo, Done)
  DateTime? dueDate;

  TaskUiNode({
    required super.id,
    required super.position,
    required super.text,
    super.color = const Color(0xFFC8E6C9), // Green-ish default
    required this.state,
    this.dueDate,
    super.aesthetics,
  }) : super(type: UiNodeType.task);

  factory TaskUiNode.fromRust(TaskNode source) {
    return TaskUiNode(
      id: _stripTablePrefix(source.id),
      position: Offset(
        source.position.x.toDouble(),
        source.position.y.toDouble(),
      ),
      text: source.content.text, // Mapped to new Content structure
      state: source.state,
      dueDate: source.dueDate != null
          ? DateTime.fromMillisecondsSinceEpoch(source.dueDate!)
          : null,
      aesthetics: source.aesthetics != null
          ? StyleProfile.fromJson(jsonDecode(source.aesthetics!))
          : null,
    );
  }

  @override
  NodeInput toInput() {
    return NodeInput.task(
      TaskNode(
        id: id.startsWith("temp_") ? null : id,
        content: ContentFactory.fromText(text),
        state: state,
        dueDate: dueDate?.millisecondsSinceEpoch,
        aesthetics: aesthetics != null
            ? jsonEncode(aesthetics!.toJson())
            : null,
        position: Coordinates(
          x: position.dx.toInt(),
          y: position.dy.toInt(),
          z: 0,
        ),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  TaskUiNode copyWith({Offset? position}) {
    return TaskUiNode(
      id: id,
      position: position ?? this.position,
      text: text,
      color: color,
      state: state,
      dueDate: dueDate,
      aesthetics: aesthetics ?? this.aesthetics,
    );
  }
}

class InterUiNode extends UiNode {
  String verb;

  InterUiNode({
    required super.id,
    required super.position,
    super.text = "", // Inters use 'verb' primarily
    super.color = const Color(0xFFFFF9C4), // Yellow-ish
    required this.verb,
    super.aesthetics,
  }) : super(type: UiNodeType.inter);

  factory InterUiNode.fromRust(InterNode source) {
    return InterUiNode(
      id: _stripTablePrefix(source.id),
      position: Offset(
        source.position.x.toDouble(),
        source.position.y.toDouble(),
      ),
      verb: source.verb,
      text: source.verb,
      aesthetics: source.aesthetics != null
          ? StyleProfile.fromJson(jsonDecode(source.aesthetics!))
          : null,
    );
  }

  @override
  NodeInput toInput() {
    return NodeInput.inter(
      InterNode(
        id: id.startsWith("temp_") ? null : id,
        verb: verb,
        behavioralFeatures: null,
        aesthetics: aesthetics != null
            ? jsonEncode(aesthetics!.toJson())
            : null,
        position: Coordinates(
          x: position.dx.toInt(),
          y: position.dy.toInt(),
          z: 0,
        ),
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  InterUiNode copyWith({Offset? position}) {
    return InterUiNode(
      id: id,
      position: position ?? this.position,
      text: text,
      color: color,
      verb: verb,
      aesthetics: aesthetics ?? this.aesthetics,
    );
  }
}

// -----------------------------------------------------------------------------
// UiNode Schema Extension
// -----------------------------------------------------------------------------

/// Provides canonical table name mapping for Rust Repository compatibility.
/// The Rust layer uses different table names than the UI layer:
/// - InfoUiNode → "inode" (not "info_node")
/// - TaskUiNode → "task_node"
/// - InterUiNode → "inter_node"
extension UiNodeSchema on UiNode {
  /// Returns the exact table name required by the Rust Repository.
  /// No fallbacks allowed - throws for unknown node types.
  String get rustTable {
    if (this is InfoUiNode) return "inode";
    if (this is TaskUiNode) return "task_node";
    if (this is InterUiNode) return "inter_node";
    throw UnsupportedError("Unknown node type: ${this.runtimeType}");
  }
}
