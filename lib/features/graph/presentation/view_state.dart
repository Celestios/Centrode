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
      positionNotifier.value +
      Offset(sizeNotifier.value.width / 2, sizeNotifier.value.height);

  Offset get topLeftPort => positionNotifier.value + Offset.zero;

  Offset get topRightPort =>
      positionNotifier.value + Offset(sizeNotifier.value.width, 0);

  Offset get bottomLeftPort =>
      positionNotifier.value + Offset(0, sizeNotifier.value.height);

  Offset get bottomRightPort =>
      positionNotifier.value +
      Offset(sizeNotifier.value.width, sizeNotifier.value.height);

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

  /// Finds the name and position of the port on this node closest to a given point.
  ({String name, Offset position}) getClosestPort(Offset point) {
    double bestDist = double.infinity;
    String bestName = 'Right';
    Offset bestPos = rightPort;
    for (final name in portNames) {
      final portPos = getPortPosition(name);
      final dist = (point - portPos).distance;
      if (dist < bestDist) {
        bestDist = dist;
        bestName = name;
        bestPos = portPos;
      }
    }
    return (name: bestName, position: bestPos);
  }

  /// Finds the closest pair of ports between two nodes (from and to).
  /// Returns a record containing the start port name/position and the end port name/position.
  static ({String startName, Offset startPos, String endName, Offset endPos})
  getClosestPortsBetween(NodeViewState fromVs, NodeViewState toVs) {
    double bestDist = double.infinity;
    String bestStartName = 'Right';
    Offset bestStartPos = fromVs.rightPort;
    String bestEndName = 'Left';
    Offset bestEndPos = toVs.leftPort;

    for (final fromName in portNames) {
      final fromPortPos = fromVs.getPortPosition(fromName);
      for (final toName in portNames) {
        final toPortPos = toVs.getPortPosition(toName);
        final dist = (fromPortPos - toPortPos).distance;
        if (dist < bestDist) {
          bestDist = dist;
          bestStartName = fromName;
          bestStartPos = fromPortPos;
          bestEndName = toName;
          bestEndPos = toPortPos;
        }
      }
    }

    return (
      startName: bestStartName,
      startPos: bestStartPos,
      endName: bestEndName,
      endPos: bestEndPos,
    );
  }

  Rect get rightResizeHitbox => Rect.fromLTRB(
    rect.right - AppConfig.interaction.resizeEdgeWidth,
    rect.top + 24.0,
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

  void dispose() {
    positionNotifier.dispose();
    sizeNotifier.dispose();
    isExpandedNotifier.dispose();
    dragWidthNotifier.dispose();
    lineCountNotifier.dispose();
  }
}
