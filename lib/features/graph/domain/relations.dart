import 'dart:convert';
import 'dart:ui';

import 'package:mycelium/src/rust/domain/relations.dart';

import '../../../core/config/app_config.dart';
import 'utils.dart';
import 'styling.dart';

/// Represents a relationship between two nodes in the graph.
/// This acts as the "ViewModel" for relations, wrapping the FFI data
/// with UI-specific state like selection.
class UiRelation {
  String id;
  final String fromNodeId;
  final String toNodeId;
  final String label; // "verb"
  final Color color;
  bool isSelected; // [NEW] Track selection state

  UiRelation({
    required this.id,
    required this.fromNodeId,
    required this.toNodeId,
    this.label = "",
    this.color = const Color(0xFFAAAAAA),
    this.isSelected = false, // [NEW] Default to unselected
    this.aesthetics,
  });

  StyleProfile? aesthetics;

  factory UiRelation.fromFFI(IRelation source) {
    // Map the Rust 'in' and 'out' fields to fromNodeId and toNodeId
    // Strip table prefixes for stable Map key lookups
    return UiRelation(
      id: stripTablePrefix(source.id),
      fromNodeId: stripTablePrefix(source.inId), // Binds the Rust 'in' field
      toNodeId: stripTablePrefix(source.outId), // Binds the Rust 'out' field
      label: source.verb,
      aesthetics: source.aesthetics != null
          ? StyleProfile.fromJson(jsonDecode(source.aesthetics!))
          : null,
    );
  }

  RelationInput toInput() {
    return RelationInput(
      from: fromNodeId,
      to: toNodeId,
      props: IRelation(
        id: id.startsWith(AppConfig.core.tempIdPrefix) ? null : null,
        inId: null,
        outId: null,
        verb: label,
        aesthetics: aesthetics != null
            ? jsonEncode(aesthetics!.toJson())
            : null,
        directionless: false,
        layer: 0,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  /// Creates a copy of this relation with optionally updated fields.
  /// Used for optimistic label updates during inline editing.
  UiRelation copyWith({
    String? id,
    String? label,
    Color? color,
    bool? isSelected,
  }) {
    return UiRelation(
      id: id ?? this.id,
      fromNodeId: fromNodeId,
      toNodeId: toNodeId,
      label: label ?? this.label,
      color: color ?? this.color,
      isSelected: isSelected ?? this.isSelected, // [NEW]
      aesthetics: aesthetics ?? aesthetics,
    );
  }
}
