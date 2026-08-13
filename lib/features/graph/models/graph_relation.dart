import 'package:flutter/foundation.dart';
import 'package:centrode/src/rust/domain/styles.dart' hide EndpointShape;
import 'package:uuid/uuid.dart';
import 'package:centrode/src/rust/domain/types.dart';
import 'package:centrode/src/rust/domain/id.dart';
import 'package:centrode/src/rust/domain/relations.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

// ---------------------------------------------------------------------------
// Abstract base class
// ---------------------------------------------------------------------------
sealed class UiRelation {
  final RawUuid id;
  RawUuid fromNodeId;
  String fromNodeTable;
  RawUuid toNodeId;
  String toNodeTable;
  String verb;
  String layer;
  RelationDirection direction;
  RelationStyle? style;
  RelationStyle? resolvedStyle;
  RelationLayout? layout;
  RelationLayout? resolvedLayout;
  final int createdAt;
  int updatedAt;

  UiRelation({
    RawUuid? id,
    required this.fromNodeId,
    required this.fromNodeTable,
    required this.toNodeId,
    required this.toNodeTable,
    String? verb,
    RelationDirection? direction,
    this.style,
    this.resolvedStyle,
    this.layout,
    this.resolvedLayout,
    String? layer,
    int? createdAt,
    int? updatedAt,
  }) : id = id ?? RawUuid.v4(),
       verb = verb ?? "default",
       direction = direction ?? RelationDirection.forward,
       layer = layer ?? "default",
       createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
       updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch {
    normalize();
  }

  /// Normalizes endpoint ordering (from <= to) and swaps sides/shapes accordingly.
  UiRelation normalize() {
    final startShape = style?.startShape ?? resolvedStyle?.startShape;
    final endShape = style?.endShape ?? resolvedStyle?.endShape;

    final targetDirection = (startShape == endShape && startShape != null)
        ? RelationDirection.undirected
        : RelationDirection.forward;

    final fromKey = '${fromNodeTable.toLowerCase()}:${fromNodeId.toUuidString()}';
    final toKey = '${toNodeTable.toLowerCase()}:${toNodeId.toUuidString()}';

    final fromSide = layout?.fromSide ?? resolvedLayout?.fromSide;
    final toSide = layout?.toSide ?? resolvedLayout?.toSide;

    if (fromKey.compareTo(toKey) <= 0) {
      if (direction != targetDirection &&
          direction != RelationDirection.backward &&
          direction != RelationDirection.undirected) {
        direction = targetDirection;
      }
      return this;
    }

    final oldFromId = fromNodeId;
    final oldFromTable = fromNodeTable;
    fromNodeId = toNodeId;
    fromNodeTable = toNodeTable;
    toNodeId = oldFromId;
    toNodeTable = oldFromTable;

    if (direction == RelationDirection.forward) {
      direction = RelationDirection.backward;
    } else if (direction == RelationDirection.backward) {
      direction = RelationDirection.forward;
    } else if (direction == RelationDirection.undirected) {
      direction = RelationDirection.undirected;
    } else {
      direction = targetDirection;
    }

    if (layout != null) {
      layout = layout!.copyWith(
        fromSide: layout!.toSide,
        toSide: layout!.fromSide,
        controlPoint1: layout!.controlPoint2,
        controlPoint2: layout!.controlPoint1,
      );
    }
    if (resolvedLayout != null) {
      resolvedLayout = resolvedLayout!.copyWith(
        fromSide: resolvedLayout!.toSide,
        toSide: resolvedLayout!.fromSide,
        controlPoint1: resolvedLayout!.controlPoint2,
        controlPoint2: resolvedLayout!.controlPoint1,
      );
    }

    if (style != null) {
      style = style!.copyWith(
        startShape: style!.endShape,
        endShape: style!.startShape,
      );
    }
    if (resolvedStyle != null) {
      resolvedStyle = resolvedStyle!.copyWith(
        startShape: resolvedStyle!.endShape,
        endShape: resolvedStyle!.startShape,
      );
    }

    return this;
  }

  /// Converts to the Rust FFI representation.
  IRelation toRust();

  /// Deserialises from the Rust FFI type.
  factory UiRelation.fromRust(IRelation relation) {
    return InfoUiRelation.fromRust(relation);
  }

  static UiRelation? copy(UiRelation? rel) {
    if (rel == null) return null;
    if (rel is InfoUiRelation) return rel.copyWith()..normalize();
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
          orElse: () => TableKind.iNode,
        ),
        key: UuidValue.fromString(fromNodeId.toUuidString()),
      ),
      out: TypedRecordId(
        table: TableKind.values.firstWhere(
          (t) => t.name.toLowerCase() == toNodeTable.toLowerCase(),
          orElse: () => TableKind.iNode,
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
