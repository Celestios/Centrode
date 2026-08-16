import 'package:flutter/material.dart';
import 'package:centrode/shared/logging.dart';
import 'package:centrode/shared/traceable_notifier.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
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
  final List<RawUuid> zOrder = [];

  /// Set of selected entity IDs (nodes or relations).
  Set<RawUuid> selectedEntities = {};

  SelectionState(this._dataQuery, this._dataCommand);

  Set<RawUuid> _expandGroups(Iterable<RawUuid> ids) {
    final result = <RawUuid>{};
    final groupIdsToInclude = <RawUuid>{};

    for (final id in ids) {
      result.add(id);
      final node = _dataQuery.nodeLookup[id];
      if (node != null && node.groupId != null) {
        groupIdsToInclude.add(node.groupId!);
      }
    }

    if (groupIdsToInclude.isNotEmpty) {
      for (final entry in _dataQuery.nodeLookup.entries) {
        if (entry.value.groupId != null && groupIdsToInclude.contains(entry.value.groupId)) {
          result.add(entry.key);
        }
      }
    }

    return result;
  }

  /// Selects a single entity on the canvas (expanding to group members if grouped).
  void selectEntity(RawUuid? id) {
    if (id == null) {
      if (selectedEntities.isEmpty) return;
      selectedEntities.clear();
    } else {
      if (!_dataQuery.nodeLookup.containsKey(id) &&
          !_dataQuery.relations.any((r) => r.id == id)) {
        _log.warning('Attempted to select non-existent entity: $id');
        return;
      }
      final expanded = _expandGroups([id]);
      if (selectedEntities.length == expanded.length && selectedEntities.containsAll(expanded)) return;
      selectedEntities = expanded;
    }
    _log.finer('Selection updated: $selectedEntities');
    notifyListeners();
  }

  /// Selects multiple entities simultaneously (expanding to group members if grouped).
  void selectEntities(Iterable<RawUuid> ids) {
    final validIds = ids.where(
      (id) =>
          _dataQuery.nodeLookup.containsKey(id) ||
          _dataQuery.relationLookup.containsKey(id),
    );
    selectedEntities = _expandGroups(validIds);
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
  void moveToFront(RawUuid id) {
    if (zOrder.remove(id)) {
      zOrder.add(id);
      _log.finer('Moved entity to front of Z-order: $id');
      notifyListeners();
    }
  }

  /// Syncs zOrder and selectedEntities with the current data store keys.
  void syncFromDataStore(Set<RawUuid> nodeKeys, Set<RawUuid> allValidKeys) {
    zOrder.removeWhere((id) => !nodeKeys.contains(id));
    for (final id in nodeKeys) {
      if (!zOrder.contains(id)) {
        zOrder.add(id);
      }
    }
    selectedEntities.removeWhere((id) => !allValidKeys.contains(id));
  }
}
