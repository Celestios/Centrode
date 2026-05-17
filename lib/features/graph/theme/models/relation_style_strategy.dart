import 'package:mycelium/src/rust/domain/styles.dart'; // RelationStyle
import 'package:mycelium/presentation/theme/graph_theme.dart';
import 'package:mycelium/features/graph/models/graph_relation.dart';
import 'package:flutter/material.dart';

abstract class RelationStyleStrategy {
  const RelationStyleStrategy();
  RelationStyle resolve(UiRelation relation, GraphTheme theme);
}

class DefaultRelationStyleStrategy extends RelationStyleStrategy {
  const DefaultRelationStyleStrategy();

  @override
  RelationStyle resolve(UiRelation relation, GraphTheme theme) {
    if (relation.style != null) return relation.style!;
    return RelationStyle(
      bgColor: Colors.transparent.toARGB32(),
      strokeColor: theme.dividerColor.toARGB32(),
      strokeWidth: 2,
      fontFamily: theme.fontFamily,
      fontSize: 10,
      shape: 'line',
      width: 0,
      height: 0,
      arrowType: 'filled_triangle',
      arrowSize: 10,
    );
  }
}
