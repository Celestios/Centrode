import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:mycelium/shared/logging.dart';
import 'package:mycelium/shared/domain/raw_uuid.dart';
import 'package:mycelium/features/graph/models/models.dart';
import 'package:mycelium/features/graph/models/port.dart';
import 'package:mycelium/features/graph/presentation/node_ports.dart';
import 'package:mycelium/features/graph/presentation/strategies/node_layout_strategy.dart';
import 'package:mycelium/features/graph/engine/volatile_node_state.dart';
import 'package:mycelium/features/graph/presentation/view_state_geometry.dart';

class NodeViewState implements VolatileNodeState {
  final RawUuid nodeId;
  final ValueNotifier<Offset> positionNotifier;
  final ValueNotifier<Size> sizeNotifier;
  final ValueNotifier<bool> isExpandedNotifier;
  final ValueNotifier<double?> dragWidthNotifier = ValueNotifier(null);
  final ValueNotifier<int> lineCountNotifier = ValueNotifier(0);
  final ValueNotifier<int> styleNotifier = ValueNotifier(0);
  NodePorts? _cachedPorts;

  int get lineCount => lineCountNotifier.value;

  final Logger _log = Logger('NodeViewState');

  static ({Size size, int lineCount}) Function(UiNode, {bool isEditing})
  _sizeComputer = NodeLayoutStrategy.calculateSize;

  static void setSizeComputer(
    ({Size size, int lineCount}) Function(UiNode, {bool isEditing}) computer,
  ) {
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
    _cachedPorts = null;
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

  NodePorts get ports {
    if (_cachedPorts == null) {
      final scale = currentScale;
      _cachedPorts = NodePorts.compute(
        sizeNotifier.value,
        scale,
        nodePosition: positionNotifier.value,
      );
    }
    return _cachedPorts!;
  }

  double get currentScale {
    final node = _currentNode;
    if (node == null) return 1.0;
    final style = node.resolvedStyle ?? node.style;
    if (style == null) return 1.0;
    return style.fontSize / 14.0;
  }

  UiNode? _currentNode;

  set currentNode(UiNode? node) {
    _currentNode = node;
    _cachedPorts = null;
  }

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

  static const List<PortSide> portSides = [
    PortSide.left,
    PortSide.right,
    PortSide.top,
    PortSide.bottom,
    PortSide.topLeft,
    PortSide.topRight,
    PortSide.bottomLeft,
    PortSide.bottomRight,
  ];

  Offset getPortPosition(PortSide side) {
    switch (side) {
      case PortSide.top:
        return topPort;
      case PortSide.bottom:
        return bottomPort;
      case PortSide.left:
        return leftPort;
      case PortSide.right:
        return rightPort;
      case PortSide.topLeft:
        return topLeftPort;
      case PortSide.topRight:
        return topRightPort;
      case PortSide.bottomLeft:
        return bottomLeftPort;
      case PortSide.bottomRight:
        return bottomRightPort;
      case PortSide.auto:
        return rightPort;
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

  Port? getClosestPortNew(Offset point) => ports.getClosestPort(point);

  Port? getMiddlePort(PortSide side) => ports.getMiddlePortForSide(side);

  List<Port> getMiddlePorts() {
    return [PortSide.top, PortSide.right, PortSide.bottom, PortSide.left]
        .map((side) => ports.getMiddlePortForSide(side))
        .whereType<Port>()
        .toList();
  }

  /// Finds the position of the port on this node closest to a given point.
  ({PortSide side, Offset position}) getClosestPort(Offset point) {
    double bestDist = double.infinity;
    PortSide bestSide = PortSide.right;
    Offset bestPos = rightPort;
    for (final side in portSides) {
      final portPos = getPortPosition(side);
      final dist = (point - portPos).distance;
      if (dist < bestDist) {
        bestDist = dist;
        bestSide = side;
        bestPos = portPos;
      }
    }
    return (side: bestSide, position: bestPos);
  }

  /// Finds the closest pair of ports between two nodes (from and to).
  /// Returns a record containing the start port side/position and the end port side/position.
  static ({
    PortSide startSide,
    Offset startPos,
    PortSide endSide,
    Offset endPos,
  })
  getClosestPortsBetween(NodeViewState fromVs, NodeViewState toVs) {
    double bestDist = double.infinity;
    PortSide bestStartSide = PortSide.right;
    Offset bestStartPos = fromVs.rightPort;
    PortSide bestEndSide = PortSide.left;
    Offset bestEndPos = toVs.leftPort;

    for (final fromSide in portSides) {
      final fromPortPos = fromVs.getPortPosition(fromSide);
      for (final toSide in portSides) {
        final toPortPos = toVs.getPortPosition(toSide);
        final dist = (fromPortPos - toPortPos).distance;
        if (dist < bestDist) {
          bestDist = dist;
          bestStartSide = fromSide;
          bestStartPos = fromPortPos;
          bestEndSide = toSide;
          bestEndPos = toPortPos;
        }
      }
    }

    return (
      startSide: bestStartSide,
      startPos: bestStartPos,
      endSide: bestEndSide,
      endPos: bestEndPos,
    );
  }

  Rect get rightResizeHitbox {
    return _cachedRightResizeHitbox ??= NodeHitboxCalculator.rightResizeHitbox(
      positionNotifier.value,
      sizeNotifier.value,
      dragWidthNotifier.value,
    );
  }

  Rect get leftResizeHitbox {
    return _cachedLeftResizeHitbox ??= NodeHitboxCalculator.leftResizeHitbox(
      positionNotifier.value,
      sizeNotifier.value,
    );
  }

  Rect getExpandToggleHitbox(UiNode node) {
    return _cachedExpandToggleHitbox ??=
        NodeHitboxCalculator.expandToggleHitbox(
          positionNotifier.value,
          sizeNotifier.value,
          node,
          isExpandedNotifier.value,
        );
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
