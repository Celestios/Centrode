import 'package:flutter/material.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import '../../../models/models.dart';
import '../../../store/relation_engine_state.dart';
import '../painters/canvas_nodes_painter.dart';
import '../painters/node_render_entry.dart';

class CanvasNodesHost extends StatefulWidget {
  final List<NodeRenderEntry> entries;
  final ValueNotifier<RawUuid?> hoveredNodeNotifier;
  final double cameraScale;
  final ViewportScope activeScope;
  final Map<RawUuid, UiNode> nodeLookup;
  final Iterable<UiRelation>? relations;
  final RelationEngineState? relationEngine;

  const CanvasNodesHost({
    super.key,
    required this.entries,
    required this.hoveredNodeNotifier,
    required this.cameraScale,
    required this.activeScope,
    required this.nodeLookup,
    this.relations,
    this.relationEngine,
  });

  @override
  State<CanvasNodesHost> createState() => _CanvasNodesHostState();
}

class _CanvasNodesHostState extends State<CanvasNodesHost> {
  final Set<RawUuid> _dirtyNodeIds = {};
  final Set<RawUuid> _positionOnlyNodeIds = {};
  final Map<RawUuid, VoidCallback> _listeners = {};
  final Map<RawUuid, VoidCallback> _positionListeners = {};
  CanvasNodesPainter? _painter;
  final ValueNotifier<int> _repaintTrigger = ValueNotifier(0);
  bool _disposed = false;

  RawUuid? _lastHoveredId;

  @override
  void initState() {
    super.initState();
    _subscribeAll();
    _createPainter();
    _lastHoveredId = widget.hoveredNodeNotifier.value;
    _painter?.hoveredNodeId = _lastHoveredId;
    widget.hoveredNodeNotifier.addListener(_onHoverChanged);
  }

  void _onHoverChanged() {
    final newHovered = widget.hoveredNodeNotifier.value;
    if (_lastHoveredId != newHovered) {
      if (_lastHoveredId != null) _dirtyNodeIds.add(_lastHoveredId!);
      if (newHovered != null) _dirtyNodeIds.add(newHovered);
      _lastHoveredId = newHovered;
      _painter?.hoveredNodeId = newHovered;
      _repaintTrigger.value++;
    }
  }

  @override
  void didUpdateWidget(covariant CanvasNodesHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hoveredNodeNotifier != widget.hoveredNodeNotifier) {
      oldWidget.hoveredNodeNotifier.removeListener(_onHoverChanged);
      widget.hoveredNodeNotifier.addListener(_onHoverChanged);
    }
    _unsubscribeEntries(oldWidget.entries);
    _disposeNodeCache();
    _subscribeAll();
    _createPainter();
    _repaintTrigger.value++;
  }

  @override
  void dispose() {
    _disposed = true;
    widget.hoveredNodeNotifier.removeListener(_onHoverChanged);
    _unsubscribeEntries(widget.entries);
    _disposeNodeCache();
    _repaintTrigger.dispose();
    super.dispose();
  }

  void _disposeNodeCache() {
    _painter?.disposeCaches();
  }

  void _createPainter() {
    _painter = CanvasNodesPainter(
      repaint: _repaintTrigger,
      entries: widget.entries,
      dirtyNodeIds: _dirtyNodeIds,
      positionOnlyNodeIds: _positionOnlyNodeIds,
      cameraScale: widget.cameraScale,
      activeScope: widget.activeScope,
      nodeLookup: widget.nodeLookup,
      relations: widget.relations,
      relationEngine: widget.relationEngine,
    );
    _painter?.hoveredNodeId = _lastHoveredId;
  }

  void _subscribeAll() {
    for (final entry in widget.entries) {
      final id = entry.node.id;
      void markDirty() {
        if (_disposed) return;
        _dirtyNodeIds.add(id);
        _repaintTrigger.value++;
      }

      void markPosition() {
        if (_disposed) return;
        _positionOnlyNodeIds.add(id);
        _repaintTrigger.value++;
      }

      final vs = entry.viewState;
      vs.positionNotifier.addListener(markPosition);
      vs.sizeNotifier.addListener(markDirty);
      vs.dragWidthNotifier.addListener(markDirty);
      vs.visualScaleNotifier.addListener(markDirty);
      vs.isExpandedNotifier.addListener(markDirty);
      vs.lineCountNotifier.addListener(markDirty);
      vs.styleNotifier.addListener(markDirty);

      _listeners[id] = markDirty;
      _positionListeners[id] = markPosition;
    }
  }

  void _unsubscribeEntries(List<NodeRenderEntry> entries) {
    for (final entry in entries) {
      final id = entry.node.id;
      final vs = entry.viewState;
      final markDirty = _listeners.remove(id);
      final markPos = _positionListeners.remove(id);
      if (markDirty != null) {
        vs.sizeNotifier.removeListener(markDirty);
        vs.dragWidthNotifier.removeListener(markDirty);
        vs.visualScaleNotifier.removeListener(markDirty);
        vs.isExpandedNotifier.removeListener(markDirty);
        vs.lineCountNotifier.removeListener(markDirty);
        vs.styleNotifier.removeListener(markDirty);
      }
      if (markPos != null) {
        vs.positionNotifier.removeListener(markPos);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _painter,
      size: Size.infinite,
    );
  }
}
