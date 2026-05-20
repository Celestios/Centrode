import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:logging/logging.dart';
import 'package:mycelium/features/graph/models/graph_node.dart';
import 'package:mycelium/features/graph/presentation/strategies/node_layout_strategy.dart';
import 'package:mycelium/features/graph/presentation/graph_metrics.dart';


class NodeViewState {
  final String nodeId;
  final ValueNotifier<Offset> positionNotifier;
  final ValueNotifier<Size> sizeNotifier;
  final ValueNotifier<bool> isExpandedNotifier;
  final ValueNotifier<double?> dragWidthNotifier = ValueNotifier(null);
  final ValueNotifier<int> lineCountNotifier = ValueNotifier(0);

  int get lineCount => lineCountNotifier.value;

  final Logger _log = Logger('NodeViewState');

  NodeViewState(UiNode node)
    : nodeId = node.id,
      positionNotifier = ValueNotifier<Offset>(node.position),
      sizeNotifier = ValueNotifier<Size>(node.size),
      isExpandedNotifier = ValueNotifier<bool>(node.isExpanded) {
    lineCountNotifier.value = node.lineCount;
  }

  /// Re‑hydrates the ViewState with the latest data from the domain node.
  void rehydrate(UiNode node) {
    assert(node.id == nodeId, 'ViewState rehydrated with a different node ID');
    positionNotifier.value = node.position;
    sizeNotifier.value = node.size;
    isExpandedNotifier.value = node.isExpanded;
    dragWidthNotifier.value = null;
    lineCountNotifier.value = node.lineCount;

    _log.fine('VIEWSTATE: Rehydrated state for $nodeId');
  }

  /// After a user triggers expand/collapse, update **both** the node and the notifier.
  void toggleExpanded(UiNode node) {
    node.isExpanded = !node.isExpanded;
    isExpandedNotifier.value = node.isExpanded;
    _recomputeSizeWithStrategy(node);
    sizeNotifier.value = node.size;
  }

  void _recomputeSizeWithStrategy(UiNode node, {bool isEditing = false}) {
    node.size = NodeLayoutStrategy.calculateSize(node, isEditing: isEditing);
  }

  // --- DRY Geometry Getters ---
  Rect get rect => positionNotifier.value & sizeNotifier.value;

  Offset get rightPort =>
      positionNotifier.value +
      Offset(sizeNotifier.value.width, sizeNotifier.value.height / 2);

  Offset get leftPort =>
      positionNotifier.value + Offset(0, sizeNotifier.value.height / 2);

  Offset get topPort =>
      positionNotifier.value + Offset(sizeNotifier.value.width / 2, 0);

  Offset get bottomPort =>
      positionNotifier.value + Offset(sizeNotifier.value.width / 2, sizeNotifier.value.height);

  Offset get topLeftPort =>
      positionNotifier.value + Offset.zero;

  Offset get topRightPort =>
      positionNotifier.value + Offset(sizeNotifier.value.width, 0);

  Offset get bottomLeftPort =>
      positionNotifier.value + Offset(0, sizeNotifier.value.height);

  Offset get bottomRightPort =>
      positionNotifier.value + Offset(sizeNotifier.value.width, sizeNotifier.value.height);

  static const List<String> portNames = [
    'Left',
    'Right',
    'Top',
    'Bottom',
    'TopLeft',
    'TopRight',
    'BottomLeft',
    'BottomRight',
  ];

  Offset getPortPosition(String side) {
    switch (side) {
      case 'Top':
        return topPort;
      case 'Bottom':
        return bottomPort;
      case 'Left':
        return leftPort;
      case 'Right':
        return rightPort;
      case 'TopLeft':
        return topLeftPort;
      case 'TopRight':
        return topRightPort;
      case 'BottomLeft':
        return bottomLeftPort;
      case 'BottomRight':
        return bottomRightPort;
      default:
        return rightPort; // Fallback
    }
  }

  Map<String, Offset> getAllPorts() => {
        'Left': leftPort,
        'Right': rightPort,
        'Top': topPort,
        'Bottom': bottomPort,
        'TopLeft': topLeftPort,
        'TopRight': topRightPort,
        'BottomLeft': bottomLeftPort,
        'BottomRight': bottomRightPort,
      };

  Rect get rightResizeHitbox => Rect.fromLTRB(
        rect.right - AppConfig.interaction.resizeEdgeWidth,
        rect.top,
        rect.right,
        rect.bottom,
      );

  Rect get leftResizeHitbox => Rect.fromLTRB(
        rect.left,
        rect.top,
        rect.left + AppConfig.interaction.resizeEdgeWidth,
        rect.bottom,
      );

  Rect get expandToggleHitbox =>
      Rect.fromLTRB(rect.left, rect.bottom - 24, rect.right, rect.bottom);

  void updatePosition(Offset delta) {
    positionNotifier.value += delta;
  }

  void updatePositionWithScale(Offset screenDelta, double currentScale) {
    if (currentScale <= 0) return;
    positionNotifier.value += screenDelta / currentScale;
  }

  void syncToNode(UiNode node) {
    node.position = positionNotifier.value;
  }

  /// Called when content or aesthetics change.
  void onContentOrStyleChanged(UiNode node, {bool isEditing = false}) {
    isExpandedNotifier.value = node.isExpanded;
    _recomputeSizeWithStrategy(node, isEditing: isEditing);
    sizeNotifier.value = node.size;
    lineCountNotifier.value = node.lineCount;
  }

  /// Called during resize drag to set the temporary width.
  void updateDragWidth(double width) {
    dragWidthNotifier.value = width;
  }

  /// Commits the drag width to the node and clears the transient width.
  void commitDragWidth(UiNode node) {
    final w = dragWidthNotifier.value;
    if (w != null) {
      node.size = Size(w, node.size.height);
      _recomputeSizeWithStrategy(node);
      sizeNotifier.value = node.size;
      dragWidthNotifier.value = null;
    }
  }

  void dispose() {
    positionNotifier.dispose();
    sizeNotifier.dispose();
    isExpandedNotifier.dispose();
    dragWidthNotifier.dispose();
    lineCountNotifier.dispose();
  }
}
