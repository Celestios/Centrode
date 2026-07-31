import 'dart:ui';
import 'package:uuid/uuid.dart';
import 'package:centrode/src/rust/domain/id.dart';
import 'package:centrode/src/rust/domain/types.dart';
import 'package:centrode/src/rust/domain/styles.dart' hide EndpointShape;
import 'package:centrode/src/rust/domain/patches.dart';
import 'package:centrode/src/rust/domain/base_models.dart' as frb;
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'graph_command_context.dart';
import '../../store/graph_data_query.dart';

TypedRecordId parseTypedRecordId(String table, RawUuid key) {
  final kind = TableKind.values.firstWhere(
    (t) => t.name.toLowerCase() == table.toLowerCase(),
    orElse: () => TableKind.iNode,
  );
  return TypedRecordId(
    table: kind,
    key: UuidValue.fromString(key.toUuidString()),
  );
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
      NodePatch.size(
        frb.Size(width: newSize.width.round(), height: newSize.height.round()),
      ),
    );
    reversePatches.add(
      NodePatch.size(
        frb.Size(width: oldSize.width.round(), height: oldSize.height.round()),
      ),
    );
  }

  return (forwardPatches, reversePatches);
}

(List<RelationPatch> forward, List<RelationPatch> reverse)
buildRelationLayoutPatches(
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

void restoreDeletedEntity({
  required GraphCommandContext controller,
  required RawUuid targetId,
  required String tableName,
  required Map<RawUuid, dynamic> lookupMap,
  required dynamic entity,
  required GraphUpdateType updateType,
  dynamic payload,
}) {
  lookupMap[targetId] = entity;
  controller.publishUpdate(
    GraphEntityUpdate(
      id: targetId,
      tableName: tableName,
      type: updateType,
      payload: payload,
    ),
  );
  controller.triggerUpdate();
}
