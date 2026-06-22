import 'package:flutter/material.dart';
import 'package:mycelium/shared/logging.dart';
import 'package:mycelium/shared/traceable_notifier.dart';
import 'view_state.dart';

/// Manages drag protection and quarantine cache for optimistic deletes.
class DragState extends ChangeNotifier with TraceableNotifier {
  @override
  String get notifierName => 'DragState';
  final Logger _log = Logger('DragState');

  /// Set of node IDs currently being actively dragged by the user.
  final Set<String> draggingNodes = {};

  /// Cache to prevent premature disposal of visual state during optimistic deletes,
  /// enabling seamless rehydration during FFI command rollbacks.
  final Map<String, NodeViewState> _quarantineCache = {};

  DragState();

  /// Registers a node dragging state to protect its volatile position from store overrides.
  void setNodeDragging(String id, bool dragging) {
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
  bool isNodeDragging(String id) => draggingNodes.contains(id);

  /// Moves a ViewState into quarantine to prevent premature disposal during optimistic deletes.
  void quarantine(String id, NodeViewState vs) {
    _quarantineCache[id] = vs;
    _log.finest('QUARANTINE: Node $id ViewState quarantined in DragState.');
  }

  /// Attempts to rehydrate a quarantined ViewState for the given node ID.
  /// Returns the rehydrated ViewState, or null if not in quarantine.
  NodeViewState? tryRehydrate(String id) {
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
