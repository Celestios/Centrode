import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../presentation/graph_metrics.dart';
import '../store/graph_repository.dart';

/// Exclusively manages volatile screen state (selections, overlays, toolbars).
///
/// This controller bypasses the FFI pipeline entirely and depends on
/// [GraphDataController] solely for existential geometric/data checks.
/// It coordinates with the data layer's sub-services through the controller's
/// public API:
///
/// - **SpatialIndexer**: Via [GraphDataController.spatialHash] for viewport culling
/// - **GraphStore**: Via [GraphDataController.nodeLookup] and [GraphDataController.relations]
/// - **GraphSyncService**: Via [GraphDataController.deleteNode] for entity deletion
///
/// See also:
/// - [GraphDataController] for the composite data orchestrator
/// - [GraphStore] for canonical in-memory storage
/// - [SpatialIndexer] for spatial indexing operations
class GraphUIController extends ChangeNotifier {
  final Logger _log = Logger('GraphUIController');
  final GraphDataController _dataController;
  Rect? _lastBufferRect;

  GraphUIController(this._dataController) {
    _dataController.addListener(_onDataChanged);
  }

  void _onDataChanged() {
    _syncAtomicUIState();
  }

  /// Ensures that all UI-specific collections (zOrder, selection, etc.)
  /// are strictly subset of the current canonical data.
  void _syncAtomicUIState() {
    final keys = _dataController.nodeLookup.keys.toSet();

    // 1. Purge zOrder of non-existent or uninitialized nodes
    zOrder.removeWhere(
      (id) => !keys.contains(id) || !_dataController.viewStates.containsKey(id),
    );

    // 2. Add new nodes that are now ready
    for (final id in keys) {
      if (!zOrder.contains(id) && _dataController.viewStates.containsKey(id)) {
        zOrder.add(id);
      }
    }

    // 3. Clean up volatile/transient states
    selectedEntities.removeWhere((id) => !keys.contains(id));

    if (activeEditId != null && !keys.contains(activeEditId)) {
      activeEditId = null;
    }

    if (nodeShowingDeleteMenu != null &&
        !keys.contains(nodeShowingDeleteMenu)) {
      nodeShowingDeleteMenu = null;
    }

    // 4. Update visible set if we have a known viewport
    if (_lastBufferRect != null) {
      updateVisibleSet(_lastBufferRect!);
    } else {
      // Fallback cleanup if no viewport is registered yet
      if (visibleNodeIds.value.any((id) => !keys.contains(id))) {
        visibleNodeIds.value = visibleNodeIds.value
            .where(keys.contains)
            .toSet();
      }
    }

    _log.fine('UI State synchronized: ${zOrder.length} nodes in render stack.');
    notifyListeners();
  }

  // Volatile State
  final ValueNotifier<Set<String>> visibleNodeIds = ValueNotifier({});
  final ValueNotifier<Offset> toolbarOffsetNotifier = ValueNotifier(
    AppConfig.toolbar.singleOffset,
  );
  final ValueNotifier<Offset> multiToolbarOffsetNotifier = ValueNotifier(
    AppConfig.toolbar.multiOffset,
  );

  // Canonical Z-Order storage for hit-testing
  final List<String> zOrder = [];

  String? activeEditId;
  String? nodeShowingDeleteMenu;
  Set<String> selectedEntities = {};

  @override
  void dispose() {
    _log.fine('Disposing GraphUIController and volatile notifiers.');
    _dataController.removeListener(_onDataChanged);
    visibleNodeIds.dispose();
    toolbarOffsetNotifier.dispose();
    multiToolbarOffsetNotifier.dispose();
    super.dispose();
  }

  void updateVisibleSet(Rect bufferRect) {
    _lastBufferRect = bufferRect;
    final newVisible = _dataController.spatialHash.queryRect(bufferRect);
    _log.finer(
      'updateVisibleSet: Spatial index returned ${newVisible.length} visible nodes.',
    );
    visibleNodeIds.value = newVisible;
  }

  void moveToFront(String id) {
    if (zOrder.remove(id)) {
      zOrder.add(id);
      _log.finer('Moved entity to front of Z-order: $id');
      notifyListeners();
    }
  }

  void selectEntity(String? id) {
    if (id == null) {
      if (selectedEntities.isEmpty) return;
      selectedEntities.clear();
    } else {
      // Existential check against Mathematical Truth
      if (!_dataController.nodeLookup.containsKey(id) &&
          !_dataController.relations.any((r) => r.id == id)) {
        _log.warning('Attempted to select non-existent entity: $id');
        return;
      }
      if (selectedEntities.length == 1 && selectedEntities.first == id) return;
      selectedEntities = {id};
    }
    _log.fine('Selection updated: $selectedEntities');
    notifyListeners();
  }

  void selectEntities(Iterable<String> ids) {
    selectedEntities = ids.toSet();
    _log.fine('Marquee selection updated: ${selectedEntities.length} entities');
    notifyListeners();
  }

  void deleteSelectedEntities() {
    if (selectedEntities.isEmpty) return;
    _log.info(
      'Executing batch deletion for ${selectedEntities.length} entities.',
    );
    final idsToDelete = selectedEntities.toList();
    selectEntity(null); // Clear selection visually immediately

    for (final id in idsToDelete) {
      _dataController.deleteNode(id);
    }
  }

  void enterEditMode(String id) {
    activeEditId = id;
    _log.fine('Entering edit mode for entity: $id');
    notifyListeners();
  }

  void cancelActiveEdit() {
    activeEditId = null;
    notifyListeners();
  }

  void showDeleteMenu(String nodeId) {
    if (nodeShowingDeleteMenu != nodeId) {
      _log.fine('Showing delete menu for node: $nodeId');
      nodeShowingDeleteMenu = nodeId;
      notifyListeners();
    }
  }

  void hideDeleteMenu() {
    if (nodeShowingDeleteMenu != null) {
      _log.fine('Hiding delete menu.');
      nodeShowingDeleteMenu = null;
      notifyListeners();
    }
  }
}
