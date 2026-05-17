import 'package:flutter/material.dart';
import 'package:mycelium/features/graph/presentation/graph_metrics.dart';
import 'package:mycelium/features/graph/models/graph_relation.dart';
import 'package:mycelium/src/rust/domain/styles.dart';

/// Responsible for computing the physical size or bounds for a relation,
/// such as the label's hit area.
abstract class RelationLayoutStrategy {
  const RelationLayoutStrategy();

  /// Calculates the size of the relation elements (e.g., label bounding box).
  Size calculate(UiRelation relation, RelationStyle style);
}

class DefaultRelationLayoutStrategy extends RelationLayoutStrategy {
  const DefaultRelationLayoutStrategy();

  @override
  Size calculate(UiRelation relation, RelationStyle style) {
    // For now, we use the fixed hit area defined in AppConfig for relation labels.
    // This adheres to the rule of avoiding magic numbers.
    return AppConfig.interaction.relationLabelHitArea;
  }
}
