import 'package:flutter/material.dart';
import 'package:mycelium/shared/logging.dart';
import 'package:mycelium/shared/traceable_notifier.dart';
import 'package:mycelium/shared/domain/raw_uuid.dart';
import 'view_state.dart';

/// Manages drag protection and quarantine cache for optimistic deletes.
class DragState extends ChangeNotifier with TraceableNotifier {
  @override
  String get notifierName => 'DragState';
  final Logger _log = Logger('DragState');

  /// Set of node IDs currently being actively dragged by the user.
  final Set<RawUuid> draggingNodes = {};

  /// Cache to prevent premature disposal of visual state during optimistic deletes,
  /// enabling seamless rehydration during FFI command rollbacks.
  final Map<RawUuid, NodeViewState> _quarantineCache = {};

  DragState();

  /// Registers a node dragging state to protect its volatile position from store overrides.
  void setNodeDragging(RawUuid id, bool dragging) {
    final wasDragging = draggingNodes.contains(id);
    if (wasDragging == dragging) return;
    if (dragging) {
      draggingNodes.add(id);
    } else {
      draggingNodes.remove(id);
    }
    _log.finest('Dragging state updated: $id -> dragging=$dragging');
    notifyListeners();
  }

  /// Returns true if the given node is currently being dragged.
  bool isNodeDragging(RawUuid id) => draggingNodes.contains(id);

  /// Moves a ViewState into quarantine to prevent premature disposal during optimistic deletes.
  void quarantine(RawUuid id, NodeViewState vs) {
    _quarantineCache[id] = vs;
    _log.finest('QUARANTINE: Node $id ViewState quarantined in DragState.');
  }

  /// Evicts and disposes a quarantined ViewState when deletion is finalized.
  void evictQuarantine(RawUuid id) {
    final vs = _quarantineCache.remove(id);
    if (vs != null) {
      vs.dispose();
      _log.finest('QUARANTINE: Node $id ViewState evicted and disposed.');
    }
  }

  /// Purges any quarantined ViewStates whose IDs are not in the valid active keys set.
  void cleanupStaleQuarantine(Set<RawUuid> activeKeys) {
    final staleIds = _quarantineCache.keys.toSet().difference(activeKeys);
    for (final id in staleIds) {
      evictQuarantine(id);
    }
  }

  /// Attempts to rehydrate a quarantined ViewState for the given node ID.
  /// Returns the rehydrated ViewState, or null if not in quarantine.
  NodeViewState? tryRehydrate(RawUuid id) {
    final vs = _quarantineCache.remove(id);
    if (vs != null) {
      _log.finest(
        'QUARANTINE: Node $id ViewState rehydrated from DragState quarantine.',
      );
    }
    return vs;
  }

  @override
  void dispose() {
    for (final vs in _quarantineCache.values) {
      vs.dispose();
    }
    _quarantineCache.clear();
    super.dispose();
  }
}
