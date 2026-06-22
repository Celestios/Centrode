import 'package:flutter/material.dart';
import 'package:mycelium/shared/logging.dart';
import 'package:mycelium/shared/traceable_notifier.dart';
import '../store/graph_data_query.dart';
import '../store/graph_data_command.dart';

/// Manages selection set, multi-select, z-order tracking, and entity deletion.
class SelectionState extends ChangeNotifier with TraceableNotifier {
  @override
  String get notifierName => 'SelectionState';
  final Logger _log = Logger('SelectionState');
  final GraphDataQuery _dataQuery;
  final GraphDataCommand _dataCommand;

  /// Visual Z-Order stack determining painting and hit-testing hierarchy.
  final List<String> zOrder = [];

  /// Set of selected entity IDs (nodes or relations).
  Set<String> selectedEntities = {};

  SelectionState(this._dataQuery, this._dataCommand);

  /// Selects a single entity on the canvas.
  void selectEntity(String? id) {
    if (id == null) {
      if (selectedEntities.isEmpty) return;
      selectedEntities.clear();
    } else {
      if (!_dataQuery.nodeLookup.containsKey(id) &&
          !_dataQuery.relations.any((r) => r.id == id)) {
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
    selectEntity(null);

    for (final id in idsToDelete) {
      if (_dataQuery.nodeLookup.containsKey(id)) {
        _dataCommand.deleteNode(id);
      } else if (_dataQuery.relationLookup.containsKey(id)) {
        _dataCommand.deleteRelation(id);
      }
    }
  }

  /// Brings the selected entity to the front of the Z-stack.
  void moveToFront(String id) {
    if (zOrder.remove(id)) {
      zOrder.add(id);
      _log.finer('Moved entity to front of Z-order: $id');
      notifyListeners();
    }
  }

  /// Syncs zOrder and selectedEntities with the current data store keys.
  void syncFromDataStore(Set<String> nodeKeys, Set<String> allValidKeys) {
    zOrder.removeWhere((id) => !nodeKeys.contains(id));
    for (final id in nodeKeys) {
      if (!zOrder.contains(id)) {
        zOrder.add(id);
      }
    }
    selectedEntities.removeWhere((id) => !allValidKeys.contains(id));
  }
}
