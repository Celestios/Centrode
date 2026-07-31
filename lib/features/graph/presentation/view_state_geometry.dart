import 'dart:ui';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/presentation/strategies/node_style_strategy.dart';
import 'package:centrode/features/graph/engine/config.dart';

/// Isolated helper calculator for node resize and expand toggle hitboxes.
abstract class NodeHitboxCalculator {
  static Rect rightResizeHitbox(
    Offset position,
    Size size,
    double? dragWidth, {
    bool hasMetadata = false,
  }) {
    final w = dragWidth ?? size.width;
    final r = position.dx + w;
    final bottom = position.dy + size.height;
    final top = position.dy + (hasMetadata ? 24.0 : 0.0);
    return Rect.fromLTRB(
      r - AppConfig.interaction.resizeEdgeWidth,
      top,
      r,
      bottom,
    );
  }

  static Rect leftResizeHitbox(Offset position, Size size) {
    final l = position.dx;
    final bottom = position.dy + size.height;
    return Rect.fromLTRB(
      l,
      position.dy,
      l + AppConfig.interaction.resizeEdgeWidth,
      bottom,
    );
  }

  static Rect expandToggleHitbox(
    Offset position,
    Size size,
    UiNode node,
    bool isExpanded,
  ) {
    final style =
        node.resolvedStyle ?? node.style ?? NodeStyleStrategy.fallbackStyle();
    final fontScale = style.fontSize / 14.0;
    final toggleSpace = NodeStyleStrategy.expandToggleSpace(
      isExpanded,
      fontScale,
    );
    final taskBadgeHeight = node is TaskUiNode
        ? NodeStyleStrategy.taskBadgeHeight(fontScale)
        : 0.0;

    final bottomOffset = style.padding + taskBadgeHeight;
    final rectBottom = position.dy + size.height;
    return Rect.fromLTRB(
      position.dx,
      rectBottom - bottomOffset - toggleSpace,
      position.dx + size.width,
      rectBottom - bottomOffset,
    );
  }
}
