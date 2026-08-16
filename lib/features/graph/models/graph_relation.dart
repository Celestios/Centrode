import 'package:centrode/src/rust/domain/styles.dart' hide EndpointShape;
import 'package:uuid/uuid.dart';
import 'package:centrode/src/rust/domain/types.dart';
import 'package:centrode/src/rust/domain/id.dart';
import 'package:centrode/src/rust/domain/relations.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

// ---------------------------------------------------------------------------
// Abstract base class
// ---------------------------------------------------------------------------
abstract class UiRelation {
  RawUuid id;
  String verb;
  String layer;
  RawUuid fromNodeId;
  String fromNodeTable;
  RawUuid toNodeId;
  String toNodeTable;
  RelationDirection direction;
  final int createdAt;
  int updatedAt;

  RelationStyle? style;
  RelationStyle? resolvedStyle;
  RelationLayout? layout;
  RelationLayout? resolvedLayout;

  UiRelation({
    RawUuid? id,
    String? verb,
    String? layer,
    required this.fromNodeId,
    required this.fromNodeTable,
    required this.toNodeId,
    required this.toNodeTable,
    RelationDirection? direction,
    int? createdAt,
    int? updatedAt,
    this.style,
    this.resolvedStyle,
    this.layout,
    this.resolvedLayout,
  }) : id = id ?? RawUuid.v4(),
       verb = verb ?? 'relates to',
       layer = layer ?? 'default',
       direction = direction ?? RelationDirection.forward,
       createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
       updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  /// Normalizes endpoint ordering (from <= to) and swaps sides/shapes accordingly.
  UiRelation normalize() {
    final startShape = style?.startShape ?? resolvedStyle?.startShape;
    final endShape = style?.endShape ?? resolvedStyle?.endShape;

    final targetDirection = (startShape == endShape && startShape != null)
        ? RelationDirection.undirected
        : RelationDirection.forward;

    if (direction != RelationDirection.backward &&
        direction != RelationDirection.undirected) {
      direction = targetDirection;
    }
    return this;
  }

  /// Converts to the Rust FFI representation.
  IRelation toRust();

  /// Deserialises from the Rust FFI type.
  factory UiRelation.fromRust(IRelation relation) {
    return InfoUiRelation.fromRust(relation);
  }

  /// Creates a deep copy of this relation.
  UiRelation clone();

  static UiRelation? copy(UiRelation? rel) {
    if (rel == null) return null;
    return rel.clone()..normalize();
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
    super.direction,
    super.style,
    super.resolvedStyle,
    super.layout,
    super.resolvedLayout,
    super.layer,
    super.createdAt,
    super.updatedAt,
  });

  /// Creates a shallow copy with optional field overrides.
  @override
  InfoUiRelation clone() => copyWith();

  InfoUiRelation copyWith({
    RawUuid? id,
    RawUuid? fromNodeId,
    String? fromNodeTable,
    RawUuid? toNodeId,
    String? toNodeTable,
    String? verb,
    String? layer,
    RelationDirection? direction,
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
      direction: direction ?? this.direction,
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
        key: UuidValue.fromString(id.toUuidString()),
      ),
      in_: TypedRecordId(
        table: TableKind.values.firstWhere(
          (t) => t.name.toLowerCase() == fromNodeTable.toLowerCase(),
        ),
        key: UuidValue.fromString(fromNodeId.toUuidString()),
      ),
      out: TypedRecordId(
        table: TableKind.values.firstWhere(
          (t) => t.name.toLowerCase() == toNodeTable.toLowerCase(),
        ),
        key: UuidValue.fromString(toNodeId.toUuidString()),
      ),
      fields: IRelationFields(
        verb: verb,
        style: style,
        resolvedStyle: resolvedStyle,
        layout: layout,
        resolvedLayout: resolvedLayout,
        direction: direction,
        layer: layer,
        createdAt: createdAt,
        updatedAt: updatedAt,
      ),
    );
  }

  /// Deserialises from an FFI [IRelation].
  factory InfoUiRelation.fromRust(IRelation relation) {
    return InfoUiRelation(
      id: RawUuid.fromString(relation.key.key.uuid),
      fromNodeId: RawUuid.fromString(relation.in_.key.uuid),
      fromNodeTable: relation.in_.table.name,
      toNodeId: RawUuid.fromString(relation.out.key.uuid),
      toNodeTable: relation.out.table.name,
      verb: relation.fields.verb,
      direction: relation.fields.direction,
      style: relation.fields.style,
      resolvedStyle: relation.fields.resolvedStyle,
      layout: relation.fields.layout,
      resolvedLayout: relation.fields.resolvedLayout,
      createdAt: relation.fields.createdAt,
      updatedAt: relation.fields.updatedAt,
    );
  }
}
