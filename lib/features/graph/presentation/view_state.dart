import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:logging/logging.dart';
import 'package:mycelium/features/graph/models/graph_node.dart';
import 'package:mycelium/features/graph/presentation/strategies/node_layout_strategy.dart';
import 'package:mycelium/features/graph/engine/config.dart';
import 'package:mycelium/features/graph/engine/states/volatile_node_state.dart';

class NodeViewState implements VolatileNodeState {
  final String nodeId;
  final ValueNotifier<Offset> positionNotifier;
  final ValueNotifier<Size> sizeNotifier;
  final ValueNotifier<bool> isExpandedNotifier;
  final ValueNotifier<double?> dragWidthNotifier = ValueNotifier(null);
  final ValueNotifier<int> lineCountNotifier = ValueNotifier(0);
  final ValueNotifier<int> styleNotifier = ValueNotifier(0);

  int get lineCount => lineCountNotifier.value;

  final Logger _log = Logger('NodeViewState');

  static ({Size size, int lineCount}) Function(UiNode, {bool isEditing}) _sizeComputer =
      NodeLayoutStrategy.calculateSize;

  static void setSizeComputer(({Size size, int lineCount}) Function(UiNode, {bool isEditing}) computer) {
    _sizeComputer = computer;
  }

  // Cached geometry — invalidated when position/size/dragWidth change
  Rect? _cachedRect;
  Rect? _cachedRightResizeHitbox;
  Rect? _cachedLeftResizeHitbox;
  Rect? _cachedExpandToggleHitbox;

  NodeViewState(UiNode node)
    : nodeId = node.id,
      positionNotifier = ValueNotifier<Offset>(node.position),
      sizeNotifier = ValueNotifier<Size>(node.size),
      isExpandedNotifier = ValueNotifier<bool>(node.isExpanded) {
    lineCountNotifier.value = node.lineCount;
    positionNotifier.addListener(_invalidateGeometry);
    sizeNotifier.addListener(_invalidateGeometry);
    dragWidthNotifier.addListener(_invalidateGeometry);
  }

  void _invalidateGeometry() {
    _cachedRect = null;
    _cachedRightResizeHitbox = null;
    _cachedLeftResizeHitbox = null;
    _cachedExpandToggleHitbox = null;
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
    final result = _sizeComputer(node, isEditing: isEditing);
    node.size = result.size;
    node.lineCount = result.lineCount;
  }

  // --- DRY Geometry Getters ---
  Rect get rect => _cachedRect ??= positionNotifier.value & sizeNotifier.value;

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

  Rect get rightResizeHitbox {
    if (_cachedRightResizeHitbox != null) return _cachedRightResizeHitbox!;
    final w = dragWidthNotifier.value ?? sizeNotifier.value.width;
    final r = positionNotifier.value.dx + w;
    _cachedRightResizeHitbox = Rect.fromLTRB(
      r - AppConfig.interaction.resizeEdgeWidth,
      rect.top + 24.0,
      r,
      rect.bottom,
    );
    return _cachedRightResizeHitbox!;
  }

  Rect get leftResizeHitbox {
    if (_cachedLeftResizeHitbox != null) return _cachedLeftResizeHitbox!;
    final l = positionNotifier.value.dx;
    _cachedLeftResizeHitbox = Rect.fromLTRB(
      l,
      rect.top,
      l + AppConfig.interaction.resizeEdgeWidth,
      rect.bottom,
    );
    return _cachedLeftResizeHitbox!;
  }

  Rect get expandToggleHitbox {
    if (_cachedExpandToggleHitbox != null) return _cachedExpandToggleHitbox!;
    _cachedExpandToggleHitbox = Rect.fromLTRB(
      rect.left, rect.bottom - 24, rect.right, rect.bottom,
    );
    return _cachedExpandToggleHitbox!;
  }

  void updatePosition(Offset delta) {
    positionNotifier.value += delta;
  }

  void updatePositionWithScale(Offset screenDelta, double currentScale) {
    if (currentScale <= 0) return;
    positionNotifier.value += screenDelta / currentScale;
  }

  /// Called when size-affecting properties change (content, size, expansion).
  void onSizeChanged(UiNode node, {bool isEditing = false}) {
    isExpandedNotifier.value = node.isExpanded;
    _recomputeSizeWithStrategy(node, isEditing: isEditing);
    sizeNotifier.value = node.size;
    lineCountNotifier.value = node.lineCount;
  }

  /// Called when only visual properties change (no size impact).
  void onStyleChanged() {
    styleNotifier.value++;
  }

  /// Called during resize drag to set the temporary width.
  void updateDragWidth(double width) {
    dragWidthNotifier.value = width;
  }

  @override
  void setDragWidth(double? width) => dragWidthNotifier.value = width;

  @override
  void setDragPosition(Offset position) => positionNotifier.value = position;

  @override
  double? get dragWidth => dragWidthNotifier.value;

  @override
  Offset get dragPosition => positionNotifier.value;

  void dispose() {
    positionNotifier.removeListener(_invalidateGeometry);
    sizeNotifier.removeListener(_invalidateGeometry);
    dragWidthNotifier.removeListener(_invalidateGeometry);
    positionNotifier.dispose();
    sizeNotifier.dispose();
    isExpandedNotifier.dispose();
    dragWidthNotifier.dispose();
    lineCountNotifier.dispose();
    styleNotifier.dispose();
  }
}
