import 'dart:ui';
import 'package:uuid/uuid.dart';
import 'package:mycelium/src/rust/domain/id.dart';
import 'package:mycelium/src/rust/domain/types.dart';
import 'package:mycelium/src/rust/domain/styles.dart' hide EndpointShape;
import 'package:mycelium/src/rust/domain/patches.dart';
import 'package:mycelium/src/rust/domain/base_models.dart' as frb;
import 'package:mycelium/shared/domain/raw_uuid.dart';

TypedRecordId parseTypedRecordId(String table, dynamic key) {
  final kind = TableKind.values.firstWhere(
    (t) => t.name.toLowerCase() == table.toLowerCase(),
    orElse: () => TableKind.iNode,
  );
  final uuidStr = key is RawUuid ? key.toUuidString() : key as String;
  return TypedRecordId(table: kind, key: UuidValue.fromString(uuidStr));
}

(List<NodePatch> forward, List<NodePatch> reverse) buildNodeStylePatches(
  NodeStyle? oldStyle,
  NodeStyle? newStyle,
  Size? oldSize,
  Size? newSize,
) {
  final List<NodePatch> forwardPatches = [];
  final List<NodePatch> reversePatches = [];

  if (newStyle != null || oldStyle != null) {
    forwardPatches.add(NodePatch.style(newStyle));
    reversePatches.add(NodePatch.style(oldStyle));
  }

  if (newSize != null && oldSize != null) {
    forwardPatches.add(
      NodePatch.size(frb.Size(width: newSize.width.round(), height: newSize.height.round())),
    );
    reversePatches.add(
      NodePatch.size(frb.Size(width: oldSize.width.round(), height: oldSize.height.round())),
    );
  }

  return (forwardPatches, reversePatches);
}

(List<RelationPatch> forward, List<RelationPatch> reverse) buildRelationLayoutPatches(
  RelationLayout? oldLayout,
  RelationLayout? newLayout,
  RelationStyle? oldStyle,
  RelationStyle? newStyle,
) {
  final List<RelationPatch> forwardPatches = [];
  final List<RelationPatch> reversePatches = [];

  if (newLayout != null || oldLayout != null) {
    forwardPatches.add(RelationPatch.layout(newLayout));
    reversePatches.add(RelationPatch.layout(oldLayout));
  }

  if (newStyle != null || oldStyle != null) {
    forwardPatches.add(RelationPatch.style(newStyle));
    reversePatches.add(RelationPatch.style(oldStyle));
  }

  return (forwardPatches, reversePatches);
}
