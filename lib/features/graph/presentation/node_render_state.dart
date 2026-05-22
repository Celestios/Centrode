import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'graph_metrics.dart';
import '../store/graph_data_controller.dart';
import '../store/graph_data_query.dart';
import 'view_state.dart';

/// Notifier pulsed to trigger relation painter repaints when node coordinates change.
class MovementNotifier extends ChangeNotifier {
  void pulse() => notifyListeners();
}

enum InspectorTab { appearance, data }

/// Exclusively manages volatile visual state (selections, overlays, toolbars, and viewState lifecycles).
///
/// This controller projects the canonical data model changes from [GraphDataController]
/// into visual-specific value notifiers ([NodeViewState]). It acts as the single source
/// of truth for all layout, selection, and transient UI rendering states.
class NodeRenderState extends ChangeNotifier {
  final Logger _log = Logger('NodeRenderState');
  final GraphDataController _dataController;

  /// Tracks the currently active inspector tab.
  final ValueNotifier<InspectorTab> activeInspectorTabNotifier = ValueNotifier(InspectorTab.appearance);

  /// ID of the node whose metadata is currently hovered on canvas.
  final ValueNotifier<String?> hoveredNodeMetadataNotifier = ValueNotifier(null);

  /// Map of currently active visual view states.
  final Map<String, NodeViewState> viewStates = {};

  /// Cache to prevent premature disposal of visual state during optimistic deletes,
  /// enabling seamless rehydration during FFI command rollbacks.
  final Map<String, NodeViewState> _quarantineCache = {};

  /// Set of node IDs currently being actively dragged by the user.
  final Set<String> draggingNodes = {};

  /// Notification trigger for canvas relation repaints.
  final MovementNotifier movementNotifier = MovementNotifier();

  /// Value notifier tracking unified toolbar offset for single selections.
  final ValueNotifier<Offset> toolbarOffsetNotifier = ValueNotifier(
    AppConfig.toolbar.singleOffset,
  );

  /// Value notifier tracking unified toolbar offset for multi-selections.
  final ValueNotifier<Offset> multiToolbarOffsetNotifier = ValueNotifier(
    AppConfig.toolbar.multiOffset,
  );

  /// Visual Z-Order stack determining painting and hit-testing hierarchy.
  final List<String> zOrder = [];

  /// ID of the entity currently in text inline edit mode.
  String? activeEditId;

  /// ID of the node currently prompting a floating delete menu.
  String? nodeShowingFloatingToolbar;

  /// Set of selected entity IDs (nodes or relations).
  Set<String> selectedEntities = {};

  StreamSubscription<GraphEntityUpdate>? _updateSubscription;

  NodeRenderState(this._dataController) {
    _dataController.addListener(_onDataChanged);
    _updateSubscription = _dataController.onEntityUpdate.listen(_handleEntityUpdate);
    _syncAtomicUIState(); // Initial synchronization projection
  }

  void _onDataChanged() {
    _syncAtomicUIState();
  }

  void _handleEntityUpdate(GraphEntityUpdate update) {
    final id = update.id;
    switch (update.type) {
      case GraphUpdateType.position:
        final vs = viewStates[id];
        if (vs != null && !draggingNodes.contains(id)) {
          final Offset newPos = update.payload as Offset;
          if (vs.positionNotifier.value != newPos) {
            vs.positionNotifier.value = newPos;
            movementNotifier.pulse();
          }
        }
        break;
      case GraphUpdateType.size:
        final vs = viewStates[id];
        if (vs != null) {
          final Size newSize = update.payload as Size;
          if (vs.sizeNotifier.value != newSize) {
            vs.dragWidthNotifier.value = null; // Reset volatile drag width
            final node = _dataController.nodeLookup[id];
            if (node != null) {
              vs.onContentOrStyleChanged(
                node,
                isEditing: id == activeEditId,
              );
            }
          }
        }
        break;
      case GraphUpdateType.expansion:
        final vs = viewStates[id];
        if (vs != null) {
          final bool newExpanded = update.payload as bool;
          vs.isExpandedNotifier.value = newExpanded;
        }
        break;
      case GraphUpdateType.text:
        final vs = viewStates[id];
        if (vs != null) {
          final node = _dataController.nodeLookup[id];
          if (node != null) {
            vs.lineCountNotifier.value = node.lineCount;
          }
        }
        break;
      case GraphUpdateType.style:
        final vs = viewStates[id];
        if (vs != null) {
          final node = _dataController.nodeLookup[id];
          if (node != null) {
            vs.onContentOrStyleChanged(
              node,
              isEditing: id == activeEditId,
            );
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
        if (update.type == GraphUpdateType.relationLayout ||
            update.type == GraphUpdateType.relationAdded ||
            update.type == GraphUpdateType.relationDeleted) {
          movementNotifier.pulse();
        }
        break;
    }
  }

  /// Registers a node dragging state to protect its volatile position from store overrides.
  void setNodeDragging(String id, bool dragging) {
    if (dragging) {
      draggingNodes.add(id);
    } else {
      draggingNodes.remove(id);
    }
    _log.finest('Dragging state updated: $id -> dragging=$dragging');
  }

  /// Pulsates the movement notifier to redraw connected relations in real-time.
  void notifyNodeDragUpdate() {
    movementNotifier.pulse();
  }

  /// Projects canonical changes in the data store into active visual states.
  void _syncAtomicUIState() {
    final keys = _dataController.nodeLookup.keys.toSet();

    // 1. Detect removed nodes (optimistic delete) and place in quarantine
    final removedIds = viewStates.keys.toSet().difference(keys);
    for (final id in removedIds) {
      final vs = viewStates.remove(id);
      if (vs != null) {
        _quarantineCache[id] = vs;
        _log.finest(
          'QUARANTINE: Node $id ViewState quarantined in NodeRenderState.',
        );
      }
    }

    // 2. Synchronize active node viewStates
    for (final entry in _dataController.nodeLookup.entries) {
      final id = entry.key;
      final node = entry.value;

      if (!viewStates.containsKey(id)) {
        // Attempt to restore pointer from quarantine cache
        final quarantinedVs = _quarantineCache.remove(id);
        if (quarantinedVs != null) {
          _log.finest(
            'QUARANTINE: Node $id ViewState rehydrated from NodeRenderState quarantine.',
          );
          quarantinedVs.rehydrate(node);
          viewStates[id] = quarantinedVs;
        } else {
          viewStates[id] = NodeViewState(node);
        }
      } else {
        // Reactive projection: update value notifiers if canonical position/size was mutated
        final vs = viewStates[id]!;
        if (!draggingNodes.contains(id)) {
          if (vs.positionNotifier.value != node.position) {
            vs.positionNotifier.value = node.position;
            movementNotifier.pulse();
          }
        }
        if (vs.isExpandedNotifier.value != node.isExpanded) {
          vs.isExpandedNotifier.value = node.isExpanded;
        }
        if (vs.lineCountNotifier.value != node.lineCount) {
          vs.lineCountNotifier.value = node.lineCount;
        }
        if (vs.sizeNotifier.value != node.size) {
          vs.dragWidthNotifier.value = null; // Reset volatile drag width
          vs.onContentOrStyleChanged(
            node,
            isEditing: node.id == activeEditId,
          ); // Recomputes height strategy
        }
      }
    }

    // 3. Purge zOrder of deleted nodes
    zOrder.removeWhere((id) => !keys.contains(id));

    // 4. Add newly created nodes to zOrder
    for (final id in keys) {
      if (!zOrder.contains(id)) {
        zOrder.add(id);
      }
    }

    // 5. Clean up volatile selected entities, active edits, and menu flags
    final validKeys = keys.union(_dataController.relationLookup.keys.toSet());
    selectedEntities.removeWhere((id) => !validKeys.contains(id));

    if (activeEditId != null && !keys.contains(activeEditId)) {
      activeEditId = null;
    }

    if (nodeShowingFloatingToolbar != null &&
        !keys.contains(nodeShowingFloatingToolbar)) {
      nodeShowingFloatingToolbar = null;
    }

    _log.finest(
      'NodeRenderState synchronized: ${zOrder.length} nodes in render stack.',
    );
    notifyListeners();
  }

  /// Brings the selected entity to the front of the Z-stack.
  void moveToFront(String id) {
    if (zOrder.remove(id)) {
      zOrder.add(id);
      _log.finer('Moved entity to front of Z-order: $id');
      notifyListeners();
    }
  }

  /// Selects a single entity on the canvas.
  void selectEntity(String? id) {
    if (id == null) {
      if (selectedEntities.isEmpty) return;
      selectedEntities.clear();
    } else {
      // Confirm entity existence in data controller before selection
      if (!_dataController.nodeLookup.containsKey(id) &&
          !_dataController.relations.any((r) => r.id == id)) {
        _log.warning('Attempted to select non-existent entity: $id');
        return;
      }
      if (selectedEntities.length == 1 && selectedEntities.first == id) return;
      selectedEntities = {id};
    }
    _log.finer('Selection updated: $selectedEntities');
    notifyListeners();
  }

  /// Selects multiple entities simultaneously (e.g., marquee selection).
  void selectEntities(Iterable<String> ids) {
    selectedEntities = ids.toSet();
    _log.finer(
      'Marquee selection updated: ${selectedEntities.length} entities',
    );
    notifyListeners();
  }

  /// Triggers deletion for all currently selected entities.
  void deleteSelectedEntities() {
    if (selectedEntities.isEmpty) return;
    _log.info(
      'Executing batch deletion for ${selectedEntities.length} entities.',
    );
    final idsToDelete = selectedEntities.toList();
    selectEntity(null); // Instantly clear selection visually

    for (final id in idsToDelete) {
      if (_dataController.nodeLookup.containsKey(id)) {
        _dataController.deleteNode(id);
      } else if (_dataController.relationLookup.containsKey(id)) {
        _dataController.deleteRelation(id);
      }
    }
  }

  /// Focuses and opens inline text editor mode for an entity.
  void enterEditMode(String id) {
    activeEditId = id;
    _log.finer('Entering edit mode for entity: $id');
    notifyListeners();
  }

  /// Aborts and closes active inline editing mode.
  void cancelActiveEdit() {
    activeEditId = null;
    notifyListeners();
  }

  /// Triggers the delete menu to float near the specified node.
  void showFloatingToolbar(String nodeId) {
    if (nodeShowingFloatingToolbar != nodeId) {
      _log.finer('Showing delete menu for node: $nodeId');
      nodeShowingFloatingToolbar = nodeId;
      notifyListeners();
    }
  }

  /// Hides the floating delete menu.
  void hideFloatingToolbar() {
    if (nodeShowingFloatingToolbar != null) {
      _log.finer('Hiding delete menu.');
      nodeShowingFloatingToolbar = null;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _log.fine('Disposing NodeRenderState and volatile notifiers.');
    _dataController.removeListener(_onDataChanged);
    _updateSubscription?.cancel();

    for (final vs in viewStates.values) {
      vs.dispose();
    }
    viewStates.clear();

    for (final vs in _quarantineCache.values) {
      vs.dispose();
    }
    _quarantineCache.clear();

    movementNotifier.dispose();
    toolbarOffsetNotifier.dispose();
    multiToolbarOffsetNotifier.dispose();
    activeInspectorTabNotifier.dispose();
    hoveredNodeMetadataNotifier.dispose();
    super.dispose();
  }
}
