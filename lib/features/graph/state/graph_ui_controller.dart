import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../../../core/config/app_config.dart';
import 'graph_data_controller.dart';

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

  GraphUIController(this._dataController);

  // Volatile State
  final ValueNotifier<Set<String>> visibleNodeIds = ValueNotifier({});
  final ValueNotifier<Offset> toolbarOffsetNotifier = ValueNotifier(
    AppConfig.graph.toolbar.singleOffset,
  );
  final ValueNotifier<Offset> multiToolbarOffsetNotifier = ValueNotifier(
    AppConfig.graph.toolbar.multiOffset,
  );

  // NEW: Canonical Z-Order storage for hit-testing
  final List<String> zOrder = [];

  String? activeEditId;
  String? nodeShowingDeleteMenu;
  Set<String> selectedEntities = {};

  @override
  void dispose() {
    _log.fine('Disposing GraphUIController and volatile notifiers.');
    visibleNodeIds.dispose();
    toolbarOffsetNotifier.dispose();
    multiToolbarOffsetNotifier.dispose();
    super.dispose();
  }

  void updateVisibleSet(Rect bufferRect) {
    final newVisible = _dataController.spatialHash.queryRect(bufferRect);
    visibleNodeIds.value = newVisible;

    // THE FIX: Removed zOrder mutation.
    // Z-Order is now a persistent, canonical hierarchy immune to camera panning.
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
    final idsToDelete = selectedEntities.toList();
    selectEntity(null); // Clear selection visually immediately

    for (final id in idsToDelete) {
      _dataController.deleteNode(id);
      _cleanVolatileStateFor(id);
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
      nodeShowingDeleteMenu = nodeId;
      notifyListeners();
    }
  }

  void hideDeleteMenu() {
    if (nodeShowingDeleteMenu != null) {
      nodeShowingDeleteMenu = null;
      notifyListeners();
    }
  }

  /// Synchronizes volatile state when the data layer promotes a temp ID to a real DB ID.
  void handleIdSwap(String tempId, String realId) {
    if (visibleNodeIds.value.contains(tempId)) {
      final newVisible = Set<String>.from(visibleNodeIds.value);
      newVisible.remove(tempId);
      newVisible.add(realId);
      visibleNodeIds.value = newVisible;
    }

    // Sync Z-order during ID swap
    final idx = zOrder.indexOf(tempId);
    if (idx != -1) zOrder[idx] = realId;

    if (activeEditId == tempId) {
      activeEditId = realId;
      notifyListeners();
    }

    if (selectedEntities.contains(tempId)) {
      selectedEntities.remove(tempId);
      selectedEntities.add(realId);
      notifyListeners();
    }
  }

  /// Cleans up any dangling UI states when a node is deleted by the Data layer
  void _cleanVolatileStateFor(String id) {
    if (nodeShowingDeleteMenu == id) hideDeleteMenu();
    if (activeEditId == id) cancelActiveEdit();
    if (visibleNodeIds.value.contains(id)) {
      final newVisible = Set<String>.from(visibleNodeIds.value)..remove(id);
      visibleNodeIds.value = newVisible;
    }

    // THE FIX: Symmetric Deletion.
    // Ensure the ID is purged from the canonical hit-testing stack.
    zOrder.remove(id);
  }
}
