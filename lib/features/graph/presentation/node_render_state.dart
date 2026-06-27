import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mycelium/shared/logging.dart';
import 'package:mycelium/shared/traceable_notifier.dart';
import '../store/graph_data_query.dart';
import '../store/graph_data_command.dart';
import '../store/spatial_index.dart';
import '../store/relation_engine_state.dart';
import 'view_state.dart';
import '../models/models.dart';
import 'editor_state.dart';
import 'selection_state.dart';
import 'drag_state.dart';

/// Notifier pulsed to trigger relation painter repaints when node coordinates change.
class MovementNotifier extends ChangeNotifier with TraceableNotifier {
  @override
  String get notifierName => 'MovementNotifier';

  void pulse() => notifyListeners();
}

enum InspectorTab { appearance, data }

/// Thin coordinator that owns the data subscription and wires three focused sub-controllers:
/// [EditorState], [SelectionState], and [DragState].
class NodeRenderState extends ChangeNotifier with TraceableNotifier implements GraphDataQuery {
  @override
  String get notifierName => 'NodeRenderState';
  final Logger _log = Logger('NodeRenderState');
  final GraphDataQuery _dataQuery;
  final GraphDataCommand _dataCommand;

  /// Tracks the currently active left panel type (e.g. tags, templates, drawing, none).
  final ValueNotifier<LeftPanelType> activeLeftPanelNotifier = ValueNotifier(
    LeftPanelType.none,
  );

  /// Tracks the currently active inspector tab.
  final ValueNotifier<InspectorTab> activeInspectorTabNotifier = ValueNotifier(
    InspectorTab.appearance,
  );

  /// ID of the node whose metadata is currently hovered on canvas.
  final ValueNotifier<String?> hoveredNodeMetadataNotifier = ValueNotifier(
    null,
  );

  /// ID of the node currently hovered on canvas (for port display).
  final ValueNotifier<String?> hoveredNodeNotifier = ValueNotifier(null);

  /// Map of currently active visual view states.
  final Map<String, NodeViewState> viewStates = {};

  /// Notification trigger for canvas relation repaints.
  final MovementNotifier movementNotifier = MovementNotifier();

  /// Notification trigger for relation data changes (add/delete/reorder).
  final ChangeNotifier relationDataNotifier = ChangeNotifier();

  /// Focused sub-controllers.
  late final EditorState editorState;
  late final SelectionState selectionState;
  late final DragState dragState;

  StreamSubscription<GraphEntityUpdate>? _updateSubscription;

  NodeRenderState(this._dataQuery, this._dataCommand) {
    editorState = EditorState(_dataQuery, viewStates);
    selectionState = SelectionState(_dataQuery, _dataCommand);
    dragState = DragState();

    editorState.addListener(notifyListeners);
    selectionState.addListener(notifyListeners);

    _updateSubscription = _dataQuery.onEntityUpdate.listen(
      _handleEntityUpdate,
    );
    _syncAtomicUIState();
  }

  bool _syncNodeToViewState(String id, UiNode node) {
    final vs = viewStates[id];
    if (vs == null) return false;

    bool changed = false;

    if (!dragState.isNodeDragging(id) && vs.positionNotifier.value != node.position) {
      vs.positionNotifier.value = node.position;
      movementNotifier.pulse();
      changed = true;
    }
    if (vs.isExpandedNotifier.value != node.isExpanded) {
      vs.isExpandedNotifier.value = node.isExpanded;
      changed = true;
    }
    if (vs.lineCountNotifier.value != node.lineCount) {
      vs.lineCountNotifier.value = node.lineCount;
      changed = true;
    }
    if (vs.sizeNotifier.value != node.size) {
      vs.dragWidthNotifier.value = null;
      vs.onSizeChanged(node);
      changed = true;
    }
    return changed;
  }

  void _handleEntityUpdate(GraphEntityUpdate update) {
    final id = update.id;
    final node = _dataQuery.nodeLookup[id];

    switch (update.type) {
      case GraphUpdateType.position:
        if (node != null) _syncNodeToViewState(id, node);
        break;
      case GraphUpdateType.size:
        if (node != null) {
          final vs = viewStates[id];
          if (vs != null) {
            final Size newSize = update.payload as Size;
            if (vs.sizeNotifier.value != newSize) {
              vs.dragWidthNotifier.value = null;
              vs.onSizeChanged(node);
            }
          }
        }
        break;
      case GraphUpdateType.expansion:
        if (node != null) _syncNodeToViewState(id, node);
        break;
      case GraphUpdateType.text:
        if (node != null) {
          final vs = viewStates[id];
          if (vs != null) vs.lineCountNotifier.value = node.lineCount;
        }
        break;
      case GraphUpdateType.style:
        if (node != null) {
          final vs = viewStates[id];
          if (vs != null) {
            final oldSize = vs.sizeNotifier.value;
            vs.onSizeChanged(node, isEditing: id == editorState.activeEditId);
            if (vs.sizeNotifier.value == oldSize) vs.onStyleChanged();
          }
        }
        break;
      case GraphUpdateType.nodeAdded:
      case GraphUpdateType.nodeDeleted:
      case GraphUpdateType.relationAdded:
      case GraphUpdateType.relationDeleted:
      case GraphUpdateType.relationLayout:
      case GraphUpdateType.tags:
      case GraphUpdateType.comments:
      case GraphUpdateType.reset:
        _syncAtomicUIState();
        if (update.type == GraphUpdateType.relationLayout ||
            update.type == GraphUpdateType.relationAdded ||
            update.type == GraphUpdateType.relationDeleted) {
          movementNotifier.pulse();
        }
        break;
      case GraphUpdateType.boundary:
        break;
    }
  }

  /// Pulsates the movement notifier to redraw connected relations in real-time.
  void notifyNodeDragUpdate() {
    movementNotifier.pulse();
  }

  /// Projects canonical changes in the data store into active visual states.
  void _syncAtomicUIState() {
    final keys = _dataQuery.nodeLookup.keys.toSet();

    final removedIds = viewStates.keys.toSet().difference(keys);
    for (final id in removedIds) {
      final vs = viewStates.remove(id);
      if (vs != null) {
        dragState.quarantine(id, vs);
      }
    }

    for (final entry in _dataQuery.nodeLookup.entries) {
      final id = entry.key;
      final node = entry.value;

      if (!viewStates.containsKey(id)) {
        final quarantinedVs = dragState.tryRehydrate(id);
        if (quarantinedVs != null) {
          quarantinedVs.rehydrate(node);
          viewStates[id] = quarantinedVs;
        } else {
          viewStates[id] = NodeViewState(node);
        }
      } else {
        _syncNodeToViewState(id, node);
      }
    }

    final allValidKeys = keys.union(_dataQuery.relationLookup.keys.toSet());
    selectionState.syncFromDataStore(keys, allValidKeys);
    editorState.cleanupStaleState(keys);

    _log.finest(
      'NodeRenderState synchronized: ${selectionState.zOrder.length} nodes in render stack.',
    );
    notifyListeners();
    relationDataNotifier.notifyListeners();
  }

  // ===========================================================================
  // Backward-compatible delegates — callers can still access via NodeRenderState
  // ===========================================================================

  Set<String> get selectedEntities => selectionState.selectedEntities;
  List<String> get zOrder => selectionState.zOrder;
  String? get activeEditId => editorState.activeEditId;
  String? get nodeShowingFloatingToolbar => editorState.nodeShowingFloatingToolbar;
  Set<String> get draggingNodes => dragState.draggingNodes;

  ValueNotifier<Offset> get toolbarOffsetNotifier => editorState.toolbarOffsetNotifier;
  ValueNotifier<Offset> get multiToolbarOffsetNotifier => editorState.multiToolbarOffsetNotifier;
  ValueNotifier<TextSelection?> get activeTextSelectionNotifier => editorState.activeTextSelectionNotifier;
  ValueNotifier<TextAlign> get currentTextAlignNotifier => editorState.currentTextAlignNotifier;

  void Function(dynamic formatType, {String? url})? get applyFormatCallback => editorState.applyFormatCallback;
  set applyFormatCallback(void Function(dynamic formatType, {String? url})? value) => editorState.applyFormatCallback = value;

  void Function(dynamic headingType)? get toggleHeadingCallback => editorState.toggleHeadingCallback;
  set toggleHeadingCallback(void Function(dynamic headingType)? value) => editorState.toggleHeadingCallback = value;

  void Function()? get clearBlockFormatCallback => editorState.clearBlockFormatCallback;
  set clearBlockFormatCallback(void Function()? value) => editorState.clearBlockFormatCallback = value;

  void Function()? get cycleFontFamilyCallback => editorState.cycleFontFamilyCallback;
  set cycleFontFamilyCallback(void Function()? value) => editorState.cycleFontFamilyCallback = value;

  void Function(String fontFamily)? get setFontFamilyCallback => editorState.setFontFamilyCallback;
  set setFontFamilyCallback(void Function(String fontFamily)? value) => editorState.setFontFamilyCallback = value;

  void Function()? get cycleTextColorCallback => editorState.cycleTextColorCallback;
  set cycleTextColorCallback(void Function()? value) => editorState.cycleTextColorCallback = value;

  void Function({String? colorUrl})? get toggleHighlightCallback => editorState.toggleHighlightCallback;
  set toggleHighlightCallback(void Function({String? colorUrl})? value) => editorState.toggleHighlightCallback = value;

  void Function()? get cycleHighlightColorCallback => editorState.cycleHighlightColorCallback;
  set cycleHighlightColorCallback(void Function()? value) => editorState.cycleHighlightColorCallback = value;

  void Function()? get cycleTextAlignCallback => editorState.cycleTextAlignCallback;
  set cycleTextAlignCallback(void Function()? value) => editorState.cycleTextAlignCallback = value;

  void updateActiveTextSelection(TextSelection? selection) => editorState.updateActiveTextSelection(selection);
  void enterEditMode(String id) => editorState.enterEditMode(id);
  void cancelActiveEdit() => editorState.cancelActiveEdit();
  void showFloatingToolbar(String nodeId) => editorState.showFloatingToolbar(nodeId);
  void hideFloatingToolbar() => editorState.hideFloatingToolbar();
  Offset? calculateToolbarAnchor(Iterable<String> selectedIds) => editorState.calculateToolbarAnchor(selectedIds);

  void selectEntity(String? id) => selectionState.selectEntity(id);
  void selectEntities(Iterable<String> ids) => selectionState.selectEntities(ids);
  void deleteSelectedEntities() => selectionState.deleteSelectedEntities();
  void moveToFront(String id) => selectionState.moveToFront(id);

  void setNodeDragging(String id, bool dragging) => dragState.setNodeDragging(id, dragging);

  // ===========================================================================
  // Proxy Query & Mutation Delegate Methods
  // ===========================================================================

  UiNode? getNode(String id) => _dataQuery.nodeLookup[id];
  UiRelation? getRelation(String id) => _dataQuery.relationLookup[id];

  // ===========================================================================
  // GraphDataQuery Implementation (delegates to _dataQuery)
  // ===========================================================================

  @override
  bool get isLoading => _dataQuery.isLoading;

  @override
  String? get errorMessage => _dataQuery.errorMessage;

  @override
  SpatialHashGrid get spatialGrid => _dataQuery.spatialGrid;

  @override
  Map<String, UiNode> get nodeLookup => _dataQuery.nodeLookup;

  @override
  Map<String, UiRelation> get relationLookup => _dataQuery.relationLookup;

  @override
  Iterable<UiRelation> get relations => _dataQuery.relations;

  @override
  BoundingBox get canvasBounds => _dataQuery.canvasBounds;

  @override
  RelationEngineState get relationEngine => _dataQuery.relationEngine;

  @override
  Stream<GraphEntityUpdate> get onEntityUpdate => _dataQuery.onEntityUpdate;

  void updateRelationsLayout(List<String> ids, {String? strategyType}) {
    _dataCommand.updateRelationsLayout(ids, strategyType: strategyType);
  }

  void updateNodesStyle(List<String> ids, NodeStyle Function(NodeStyle style) updateFn) {
    _dataCommand.updateNodesStyle(ids, updateFn);
  }

  void addTagToNode(String nodeId, String name, int color) {
    _dataCommand.addTagToNode(nodeId, name, color);
  }

  void removeTagFromNode(String nodeId, String tagKey) {
    _dataCommand.removeTagFromNode(nodeId, tagKey);
  }

  void addCommentToNode(String nodeId, String text) {
    _dataCommand.addCommentToNode(nodeId, text);
  }

  void removeCommentFromNode(String nodeId, Comment comment) {
    _dataCommand.removeCommentFromNode(nodeId, comment);
  }

  void commitEntityText(String id, dynamic newTextOrContent, {dynamic originalTextOrContent}) {
    _dataCommand.commitEntityText(
      id,
      newTextOrContent,
      originalTextOrContent: originalTextOrContent,
    );
  }

  void updateEntityTextLive(String id, dynamic newTextOrContent) {
    _dataCommand.updateEntityTextLive(id, newTextOrContent);
  }

  bool _disposed = false;

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _log.fine('Disposing NodeRenderState and volatile notifiers.');
    _updateSubscription?.cancel();

    editorState.removeListener(notifyListeners);
    selectionState.removeListener(notifyListeners);

    for (final vs in viewStates.values) {
      vs.dispose();
    }
    viewStates.clear();

    movementNotifier.dispose();
    relationDataNotifier.dispose();
    activeLeftPanelNotifier.dispose();
    activeInspectorTabNotifier.dispose();
    hoveredNodeMetadataNotifier.dispose();
    hoveredNodeNotifier.dispose();

    editorState.dispose();
    selectionState.dispose();
    dragState.dispose();

    super.dispose();
  }
}
