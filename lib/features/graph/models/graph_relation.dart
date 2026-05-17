// lib/features/graph/domain/relations.dart

import 'package:mycelium/src/rust/domain/styles.dart';
import 'package:uuid/uuid.dart';
import 'package:mycelium/src/rust/domain/relations.dart';

// ---------------------------------------------------------------------------
// Abstract base class
// ---------------------------------------------------------------------------
sealed class UiRelation {
  final String id;
  String fromNodeId;
  String toNodeId;
  String verb;
  String layer;
  bool directionless;
  RelationStyle? style;
  RelationStyle? resolvedStyle;
  final int createdAt;
  int updatedAt;

  UiRelation({
    String? id,
    required this.fromNodeId,
    required this.toNodeId,
    String? verb,
    bool? directionless,
    this.style,
    this.resolvedStyle,
    String? layer,
    int? createdAt,
    int? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       verb = verb ?? "default",
       directionless = directionless ?? false,
       layer = layer ?? "default",
       createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
       updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  /// Converts to the Rust FFI representation.
  IRelation toRust();

  /// Deserialises from the Rust FFI type.
  factory UiRelation.fromRust(IRelation relation) {
    return InfoUiRelation.fromRust(relation);
  }

  /// Creates a shallow copy of any [UiRelation] subtype.
  static UiRelation? copy(UiRelation? rel) {
    if (rel == null) return null;
    if (rel is InfoUiRelation) return rel.copyWith();
    throw ArgumentError('Unsupported relation type: ${rel.runtimeType}');
  }
}

// ---------------------------------------------------------------------------
// Concrete implementation
// ---------------------------------------------------------------------------
class InfoUiRelation extends UiRelation {
  InfoUiRelation({
    String? id,
    required super.fromNodeId,
    required super.toNodeId,
    super.verb,
    super.directionless,
    super.style,
    super.resolvedStyle,
    super.layer,
    super.createdAt,
    super.updatedAt,
  });

  /// Creates a shallow copy with optional field overrides.
  InfoUiRelation copyWith({
    String? id,
    String? fromNodeId,
    String? toNodeId,
    String? verb,
    String? layer,
    bool? directionless,
    RelationStyle? style,
    RelationStyle? resolvedStyle,
    int? createdAt,
    int? updatedAt,
  }) {
    return InfoUiRelation(
      id: id ?? this.id,
      fromNodeId: fromNodeId ?? this.fromNodeId,
      toNodeId: toNodeId ?? this.toNodeId,
      verb: verb ?? this.verb,
      layer: layer ?? this.layer,
      directionless: directionless ?? this.directionless,
      style: style ?? this.style,
      resolvedStyle: resolvedStyle ?? this.resolvedStyle,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  IRelation toRust() {
    return IRelation(
      key: id,
      fields: IRelationFields(
        in_: fromNodeId,
        out: toNodeId,
        verb: verb,
        style: style,
        resolvedStyle: resolvedStyle,
        directionless: directionless,
        layer: layer,
        createdAt: createdAt,
        updatedAt: updatedAt,
      ),
    );
  }

  /// Deserialises from an FFI [IRelation].
  factory InfoUiRelation.fromRust(IRelation relation) {
    return InfoUiRelation(
      id: relation.key,
      fromNodeId: relation.fields.in_,
      toNodeId: relation.fields.out,
      verb: relation.fields.verb,
      directionless: relation.fields.directionless,
      style: relation.fields.style,
      resolvedStyle: relation.fields.resolvedStyle,
      createdAt: relation.fields.createdAt,
      updatedAt: relation.fields.updatedAt,
    );
  }
}
