import 'package:mycelium/src/rust/domain/styles.dart'; // RelationStyle
import 'package:mycelium/presentation/theme/graph_theme.dart';
import 'package:mycelium/features/graph/models/graph_relation.dart';
import 'package:flutter/material.dart';
import 'package:mycelium/features/graph/presentation/graph_metrics.dart';

abstract class RelationStyleStrategy {
  const RelationStyleStrategy();

  /// Resolves the correct style strategy based on type.
  static RelationStyleStrategy fromType(String? type) {
    return const DefaultRelationStyleStrategy();
  }

  RelationStyle resolve(UiRelation relation, GraphTheme theme);




  /// Centralized static helper to resolve a relation's populated style.
  static RelationStyle resolveStyle(UiRelation relation, {GraphTheme? theme}) {
    if (relation.resolvedStyle != null) return relation.resolvedStyle!;
    if (theme != null) {
      return const DefaultRelationStyleStrategy().resolve(relation, theme);
    }
    return fallbackStyle();
  }

  /// Centralized aesthetic fallback config used across the store and painter.
  static RelationStyle fallbackStyle() {
    return RelationStyle(
      bgColor: Colors.transparent.toARGB32(),
      strokeColor: Colors.black.toARGB32(),
      strokeWidth: AppConfig.relation.strokeWidth.round(),
      fontFamily: AppConfig.visuals.defaultFont,
      fontSize: AppConfig.relation.labelFontSize,
      shape: 'line',
      width: 0,
      height: 0,
      arrowType: 'filled_triangle',
      arrowSize: 10,
      // --- Advanced Style Properties ---
      textColor: Colors.black.toARGB32(),
      shadowColor: const Color(0x1F000000).toARGB32(),
      shadowBlur: 2.0,
      shadowOffsetX: 1.0,
      shadowOffsetY: 1.0,
      strategyType: 'default',
      strokePattern: 'solid',
    );
  }
}

class DefaultRelationStyleStrategy extends RelationStyleStrategy {
  const DefaultRelationStyleStrategy();

  @override
  RelationStyle resolve(UiRelation relation, GraphTheme theme) {
    if (relation.style != null) return relation.style!;
    return RelationStyleStrategy.fallbackStyle().copyWith(
      strokeColor: theme.primaryColor.withValues(alpha: 0.5).toARGB32(),
      fontFamily: theme.fontFamily,
      textColor: theme.bodyTextColor.toARGB32(),
    );
  }
}
