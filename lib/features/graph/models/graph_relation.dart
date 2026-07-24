import 'package:mycelium/src/rust/domain/styles.dart' hide EndpointShape;
import 'package:uuid/uuid.dart';
import 'package:mycelium/src/rust/domain/types.dart';
import 'package:mycelium/src/rust/domain/id.dart';
import 'package:mycelium/src/rust/domain/relations.dart';

// ---------------------------------------------------------------------------
// Abstract base class
// ---------------------------------------------------------------------------
sealed class UiRelation {
  final String id;
  String fromNodeId;
  String fromNodeTable;
  String toNodeId;
  String toNodeTable;
  String verb;
  String layer;
  bool directionless;
  RelationStyle? style;
  RelationStyle? resolvedStyle;
  RelationLayout? layout;
  RelationLayout? resolvedLayout;
  final int createdAt;
  int updatedAt;

  UiRelation({
    String? id,
    required this.fromNodeId,
    required this.fromNodeTable,
    required this.toNodeId,
    required this.toNodeTable,
    String? verb,
    bool? directionless,
    this.style,
    this.resolvedStyle,
    this.layout,
    this.resolvedLayout,
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
    super.id,
    required super.fromNodeId,
    required super.fromNodeTable,
    required super.toNodeId,
    required super.toNodeTable,
    super.verb,
    super.directionless,
    super.style,
    super.resolvedStyle,
    super.layout,
    super.resolvedLayout,
    super.layer,
    super.createdAt,
    super.updatedAt,
  });

  /// Creates a shallow copy with optional field overrides.
  InfoUiRelation copyWith({
    String? id,
    String? fromNodeId,
    String? fromNodeTable,
    String? toNodeId,
    String? toNodeTable,
    String? verb,
    String? layer,
    bool? directionless,
    RelationStyle? style,
    RelationStyle? resolvedStyle,
    RelationLayout? layout,
    RelationLayout? resolvedLayout,
    int? createdAt,
    int? updatedAt,
  }) {
    return InfoUiRelation(
      id: id ?? this.id,
      fromNodeId: fromNodeId ?? this.fromNodeId,
      fromNodeTable: fromNodeTable ?? this.fromNodeTable,
      toNodeId: toNodeId ?? this.toNodeId,
      toNodeTable: toNodeTable ?? this.toNodeTable,
      verb: verb ?? this.verb,
      layer: layer ?? this.layer,
      directionless: directionless ?? this.directionless,
      style: style ?? this.style,
      resolvedStyle: resolvedStyle ?? this.resolvedStyle,
      layout: layout ?? this.layout,
      resolvedLayout: resolvedLayout ?? this.resolvedLayout,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  IRelation toRust() {
    return IRelation(
      key: TypedRecordId(
        table: TableKind.iRelation,
        key: UuidValue.fromString(id),
      ),
      in_: TypedRecordId(
        table: TableKind.values.firstWhere(
          (t) => t.name.toLowerCase() == fromNodeTable.toLowerCase(),
          orElse: () => TableKind.iNode,
        ),
        key: UuidValue.fromString(fromNodeId),
      ),
      out: TypedRecordId(
        table: TableKind.values.firstWhere(
          (t) => t.name.toLowerCase() == toNodeTable.toLowerCase(),
          orElse: () => TableKind.iNode,
        ),
        key: UuidValue.fromString(toNodeId),
      ),
      fields: IRelationFields(
        verb: verb,
        style: style,
        resolvedStyle: resolvedStyle,
        layout: layout,
        resolvedLayout: resolvedLayout,
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
      id: relation.key.key.uuid,
      fromNodeId: relation.in_.key.uuid,
      fromNodeTable: relation.in_.table.name,
      toNodeId: relation.out.key.uuid,
      toNodeTable: relation.out.table.name,
      verb: relation.fields.verb,
      directionless: relation.fields.directionless,
      style: relation.fields.style,
      resolvedStyle: relation.fields.resolvedStyle,
      layout: relation.fields.layout,
      resolvedLayout: relation.fields.resolvedLayout,
      createdAt: relation.fields.createdAt,
      updatedAt: relation.fields.updatedAt,
    );
  }
}
