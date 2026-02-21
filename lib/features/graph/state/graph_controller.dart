import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:uuid/uuid.dart';

// Domain Imports
import '../domain/models.dart';

// FFI Imports (Adjust path to your generated code)
import 'package:mycelium/src/rust/bridge/api.dart';
import 'package:mycelium/src/rust/domain/relations.dart';

// -----------------------------------------------------------------------------
// Command Processor for Write-Behind Debouncing
// -----------------------------------------------------------------------------

/// Manages the lifecycle of state mutations with FIFO ordering for FFI calls.
/// Implements write-behind debouncing to batch high-frequency spatial updates.
class CommandProcessor {
  final Logger _log = Logger('CommandProcessor');
  final Map<String, Timer> _debouncers = {};
  final Map<String, GraphCommand> _pendingCommands = {};
  final ListQueue<GraphCommand> _executionQueue = ListQueue();
  bool _isProcessing = false;
  final Function(String) onError;

  CommandProcessor({required this.onError});

  /// Queues a command for execution with optional debouncing.
  /// Set [immediate] to true to bypass the debounce timer (e.g., for deletes).
  void queueCommand(GraphCommand cmd, {bool immediate = false}) {
    _log.finer(
      'Queueing command: ${cmd.runtimeType} [Target: ${cmd.targetId}] (Immediate: $immediate)',
    );

    // 1. Cancel existing debouncer for this entity
    _debouncers[cmd.targetId]?.cancel();
    _debouncers.remove(cmd.targetId);

    if (immediate) {
      _executionQueue.removeWhere((c) => c.targetId == cmd.targetId);
      _pendingCommands.remove(cmd.targetId);
      _executionQueue.addLast(cmd);
      _processQueue();
    } else {
      _pendingCommands[cmd.targetId] = cmd;
      _debouncers[cmd.targetId] = Timer(const Duration(milliseconds: 300), () {
        final pending = _pendingCommands.remove(cmd.targetId);
        if (pending != null) {
          _log.finer(
            'Debounce window closed. Promoting ${cmd.targetId} to execution queue.',
          );
          _executionQueue.addLast(pending);
          _processQueue();
        }
      });
    }
  }

  Future<void> _processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    _log.fine(
      'Flushing execution queue (${_executionQueue.length} operations pending)',
    );

    while (_executionQueue.isNotEmpty) {
      final cmd = _executionQueue.removeFirst();
      try {
        _log.finest('Executing FFI boundary command for ${cmd.targetId}');
        await cmd.execute();
        // Update canonical DB baseline on success
        if (cmd is MoveNodeCommand) cmd.onSuccess();
      } catch (e) {
        _log.severe(
          'FFI Synchronization failed for ${cmd.targetId}. Executing strict rollback.',
          e,
        );
        cmd.undo();
        // Drop pending mutations for this entity to prevent overriding the rollback
        _executionQueue.removeWhere((c) => c.targetId == cmd.targetId);
        _pendingCommands.remove(cmd.targetId);
        onError("Sync failed: $e");
      }
    }
    _isProcessing = false;
  }

  /// Flushes all pending commands immediately.
  /// Called during dispose to prevent ghost states.
  Future<void> flush() async {
    for (var timer in _debouncers.values) {
      timer.cancel();
    }
    _debouncers.clear();
    _executionQueue.addAll(_pendingCommands.values);
    _pendingCommands.clear();
    await _processQueue();
  }

  /// Synchronously terminates all debouncers and drops pending FFI operations.
  /// Mandatory for safe execution during synchronous UI teardown.
  void flushSync() {
    for (var timer in _debouncers.values) {
      timer.cancel();
    }
    _debouncers.clear();
    // Drop optimistic UI states that have not yet crossed the FFI boundary
    _executionQueue.clear();
    _pendingCommands.clear();
  }
}

/// A lightweight notifier that pulses during node movement.
/// Used to trigger relation repaints without full graph rebuilds.
class MovementNotifier extends ChangeNotifier {
  void pulse() => notifyListeners();
}

class GraphController extends ChangeNotifier {
  final AppHandle _api;
  final Logger _log = Logger('GraphController');

  // THE STATE
  // Access via .values for lists, but keep Map for lookups.
  final Map<String, UiNode> _nodes = {};
  final Map<String, UiRelation> _relations = {};

  // Spatial Hash Grid for O(1) viewport culling queries
  final SpatialHashGrid spatialHash = SpatialHashGrid();

  // Reactive ViewState Registry for granular position updates
  // Renamed to allNodeViewStates to indicate it holds ALL nodes (not just visible)
  final Map<String, NodeViewState> allNodeViewStates = {};

  // Visible node set for viewport culling (updated by canvas transform)
  final ValueNotifier<Set<String>> visibleNodeIds = ValueNotifier({});

  // Invalidation signal for relation layer repaints
  final MovementNotifier movementNotifier = MovementNotifier();

  // Command Processor for write-behind debouncing
  late final CommandProcessor _processor;

  // Tracks the last confirmed DB positions to prevent "Superseded Rollback Traps"
  final Map<String, Offset> _lastConfirmedDbPositions = {};

  // The entity currently being edited in the UI (node or relation ID)
  // Used to trigger inline text editing mode and auto-focus
  // [REFACTORED]: UI primitives (TextEditingController, FocusNode) purged to decouple domain from UI.
  // The overlay now manages its own ephemeral editing state.
  String? activeEditId;

  // Public Getter (ReadOnly view for UI)
  List<UiNode> get nodes => _nodes.values.toList();
  List<UiRelation> get relations => _relations.values.toList();
  Map<String, UiNode> get nodeLookup => _nodes;
  bool isLoading = false;
  String? errorMessage;

  // Interaction State (for delete menu only - other interactions handled by InteractionController)
  String? nodeShowingDeleteMenu;

  GraphController(this._api) {
    _processor = CommandProcessor(
      onError: (msg) {
        errorMessage = msg;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    // Replaces the hazardous async flush() with strict synchronous teardown
    _processor.flushSync();
    // Dispose all NodeViewState instances
    for (var state in allNodeViewStates.values) {
      state.dispose();
    }
    // [DELETED]: activeTextController and activeFocusNode disposal removed.
    // The overlay now manages its own ephemeral editing state.
    visibleNodeIds.dispose();
    movementNotifier.dispose();
    super.dispose();
  }

  /// Syncs the ViewState registry with the current nodes.
  /// Removes ViewStates for deleted nodes and adds new ones.
  /// Also updates the spatial hash grid.
  void _syncViewStates() {
    // Cleanup removed nodes from both ViewState and SpatialHash
    allNodeViewStates.removeWhere((id, state) {
      if (!_nodes.containsKey(id)) {
        spatialHash.remove(id, state.positionNotifier.value);
        state.dispose();
        return true;
      }
      return false;
    });
    // Add new nodes to both ViewState and SpatialHash
    for (var node in _nodes.values) {
      allNodeViewStates.putIfAbsent(node.id, () {
        spatialHash.insert(node.id, node.position);
        return NodeViewState(node);
      });
    }
  }

  // ---------------------------------------------------------------------------
  // 1. READ OPERATIONS
  // ---------------------------------------------------------------------------

  /// Fetches the fresh state from Rust.
  /// Used on App Start or explicit "Reload".
  Future<void> loadGraph() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Rust returns a tuple/record: (nodes, relations, config)
      final snapshot = await _api.getGraphSnapshot();

      _nodes.clear();
      _relations.clear();

      // The FFI generator typically maps Vec<NodeOutput> to List<NodeOutput>
      // We iterate and convert them to our Domain Model.
      for (final ffiNode in snapshot.$1) {
        // Assuming $1 is the nodes list
        final uiNode = UiNode.fromFFI(ffiNode);
        _nodes[uiNode.id] = uiNode;
      }

      // Load and cache relations
      for (final ffiRel in snapshot.$2) {
        final uiRel = UiRelation.fromFFI(ffiRel);
        _relations[uiRel.id] = uiRel;
      }

      // Sync ViewStates after populating nodes
      _syncViewStates();
    } catch (e) {
      errorMessage = "Failed to load graph: $e";
      _log.severe('Failed to load graph snapshot', e);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // 2. WRITE OPERATIONS (OPTIMISTIC)
  // ---------------------------------------------------------------------------

  /// Creates a node optimistically with immediate UI injection (T=0.0ms pattern).
  /// Injects a temp ID first, then swaps to real ID after FFI confirmation.
  /// Implements the Optimistic Creation Pattern for instant UI feedback.
  Future<void> createNode(UiNodeType type, Offset position) async {
    final tempId = "temp_${const Uuid().v4()}";
    _log.fine('Optimistic Injection: $tempId at $position');

    // 1. Instantiate UI Model based on type
    UiNode node;
    switch (type) {
      case UiNodeType.task:
        node = TaskUiNode(
          id: tempId,
          position: position,
          text: "New Task",
          state: "TODO",
        );
        break;
      case UiNodeType.inter:
        node = InterUiNode(id: tempId, position: position, verb: "connects");
        break;
      case UiNodeType.info:
        node = InfoUiNode(id: tempId, position: position, text: "New Note");
        break;
    }

    // 2. Inject into UI immediately (T=0) - Optimistic Pattern
    _nodes[tempId] = node;
    allNodeViewStates[tempId] = NodeViewState(node);
    spatialHash.insert(tempId, position);

    // [FIX]: Force visibility if the canvas has been panned/zoomed
    if (visibleNodeIds.value.isNotEmpty) {
      visibleNodeIds.value = {...visibleNodeIds.value, tempId};
    }

    enterEditMode(tempId); // Signal intent to edit
    notifyListeners();

    try {
      // 3. Background Sync - Await FFI confirmation
      final realId = await _api.createNode(input: node.toInput());

      // 4. ID Swap - Seamlessly transfer state from temp to real ID
      final activeNode = _nodes.remove(tempId);
      final activeVs = allNodeViewStates.remove(tempId);

      if (activeNode != null && activeVs != null) {
        activeNode.id = realId;
        _nodes[realId] = activeNode;
        allNodeViewStates[realId] = activeVs;

        // Update spatial hash with new ID
        spatialHash.remove(tempId, activeNode.position);
        spatialHash.insert(realId, activeNode.position);

        // [FIX]: Migrate visibility to real ID
        if (visibleNodeIds.value.isNotEmpty) {
          final newSet = {...visibleNodeIds.value};
          newSet.remove(tempId);
          newSet.add(realId);
          visibleNodeIds.value = newSet;
        }

        // Transfer active edit state if still editing
        if (activeEditId == tempId) {
          activeEditId = realId;
        }

        _log.info('ID Swap Complete: $tempId -> $realId');
      }

      notifyListeners();
    } catch (e) {
      _log.severe('Optimistic sync failed', e);
      // Rollback - remove the optimistic node
      _nodes.remove(tempId);
      final vs = allNodeViewStates.remove(tempId);
      vs?.dispose();
      spatialHash.remove(tempId, position);

      if (activeEditId == tempId) {
        activeEditId = null;
      }

      errorMessage = "Creation failed: $e";
      notifyListeners();
    }
  }

  /// Syncs position from ViewState to UiNode and persists to backend.
  /// Called when drag ends (not during drag for performance).
  Future<void> syncAndPersistPosition(String id) async {
    final node = _nodes[id];
    final viewState = allNodeViewStates[id];
    if (node == null || viewState == null) return;

    final oldPosition = node.position;

    // A. Sync from ViewState to UiNode
    viewState.syncToNode(node);

    // B. Update spatial hash with new position
    spatialHash.update(id, oldPosition, node.position);

    // C. Sync with Rust
    try {
      // [FIX] Double-encode the inner layout object into a string
      final patchJson = jsonEncode({
        "visual_formatting": jsonEncode({
          "layout": {
            "graph": {"x": node.position.dx, "y": node.position.dy},
          },
        }),
      });

      // We call 'patch_node_properties'.
      // Note: We need to know the 'table' (node type) for the API call.
      // For now, we might need a helper to get table name from type,
      // or update the Rust API to just take ID if possible.
      // Assuming we pass the table name string based on type:
      String tableName;
      if (node is TaskUiNode) {
        tableName = "task_node";
      } else if (node is InterUiNode) {
        tableName = "inter_node";
      } else {
        tableName = "inode";
      }

      await _api.patchNodeProperties(
        table: tableName,
        id: id,
        jsonPatch: patchJson,
      );
    } catch (e) {
      // D. Rollback - restore old position in both ViewState and UiNode
      _log.warning('Failed to move node, rolling back', e);
      spatialHash.update(
        id,
        node.position,
        oldPosition,
      ); // Rollback spatial hash
      viewState.positionNotifier.value = oldPosition;
      node.position = oldPosition;
      movementNotifier.pulse(); // Trigger relation repaint
    }
  }

  /// Commits a node position change from drag end, updating spatial hash.
  /// This is the primary method for position persistence with viewport culling.
  /// Implements the Data Projection Pattern to prevent stale payload issues.
  Future<void> commitNodePosition(String id) async {
    final oldNode = _nodes[id];
    final viewState = allNodeViewStates[id];

    if (oldNode == null || viewState == null) return;

    final newPosition = viewState.positionNotifier.value;
    final oldPosition = oldNode.position;

    // A. The Data Projection Pattern: Update the mathematical domain model
    final updatedNode = oldNode.copyWith(position: newPosition);
    _nodes[id] = updatedNode;

    try {
      // [FIX] Double-encode the inner layout object into a string
      final patchJson = jsonEncode({
        "visual_formatting": jsonEncode({
          "layout": {
            "graph": {
              "x": updatedNode.position.dx,
              "y": updatedNode.position.dy,
            },
          },
        }),
      });

      final tableName = _getTableName(updatedNode);

      // C. FFI Boundary Call
      await _api.patchNodeProperties(
        table: tableName,
        id: id,
        jsonPatch: patchJson,
      );
    } catch (e) {
      _log.warning(
        'Rust synchronization failed. Rolling back to mathematical truth',
        e,
      );

      // D. Strict Rollback
      _nodes[id] = oldNode; // Revert Domain Model
      viewState.positionNotifier.value =
          oldPosition; // Revert ViewModel ($S_{vol}$)
      spatialHash.update(id, newPosition, oldPosition); // Revert Hit-Test Grid

      movementNotifier.pulse(); // Snap the lines back visually
      notifyListeners();
    }
  }

  /// Updates node position with write-behind debouncing via CommandProcessor.
  /// Tracks the last confirmed DB position to prevent "Superseded Rollback Traps".
  Future<void> updateNodePosition(String id, Offset newPosition) async {
    final node = _nodes[id];
    final viewState = allNodeViewStates[id];
    if (node == null || viewState == null) return;

    // Track the LAST confirmed position if this is a new sequence of moves
    _lastConfirmedDbPositions.putIfAbsent(id, () => node.position);

    final cmd = MoveNodeCommand(
      targetId: id,
      newPosition: newPosition,
      rollbackPosition: _lastConfirmedDbPositions[id]!,
      nodeViewState: viewState,
      spatialGrid: spatialHash,
      api: _api,
      tableName: _getTableName(node),
      onSuccess: () => _lastConfirmedDbPositions[id] = newPosition,
      onUndo: (pos) {
        node.position = pos;
        movementNotifier
            .pulse(); // Visually snap vectors back to the recovered state
      },
    );

    // Update optimistic local state (Persistent model)
    final oldPosition = node.position;
    spatialHash.update(id, oldPosition, newPosition);
    node.position = newPosition;

    // Queue command with debouncing (300ms delay)
    _processor.queueCommand(cmd);
  }

  /// Helper to get the table name for a node type.
  String _getTableName(UiNode node) {
    if (node is TaskUiNode) return "task_node";
    if (node is InterUiNode) return "inter_node";
    return "inode";
  }

  /// Commits text changes from inline editing with debounced write-behind sync.
  /// Handles both node text and relation labels with appropriate field mapping.
  void commitEntityText(String id, String newText) {
    final node = _nodes[id];
    final rel = _relations[id];
    final oldText = node?.text ?? rel?.label ?? "";

    // No change - just clear edit state
    if (newText == oldText) {
      activeEditId = null;
      notifyListeners();
      return;
    }

    // Update Local Model optimistically
    if (node != null) {
      node.text = newText;
      if (node is InterUiNode) {
        node.verb = newText;
      }
    } else if (rel != null) {
      _relations[id] = UiRelation(
        id: rel.id,
        fromNodeId: rel.fromNodeId,
        toNodeId: rel.toNodeId,
        label: newText,
        color: rel.color,
      );
    }

    // Clear edit state - the overlay manages its own controllers
    activeEditId = null;

    // Queue FFI Patch with debouncing
    _processor.queueCommand(
      UpdateTextCommand(
        targetId: id,
        tableName: node != null ? _getTableName(node) : "relates_to",
        newText: newText,
        oldText: oldText,
        isRelation: rel != null,
        api: _api,
        onUndo: () {
          // Rollback local state on FFI failure
          if (node != null) {
            node.text = oldText;
            if (node is InterUiNode) {
              node.verb = oldText;
            }
          } else if (rel != null) {
            _relations[id] = UiRelation(
              id: rel.id,
              fromNodeId: rel.fromNodeId,
              toNodeId: rel.toNodeId,
              label: oldText,
              color: rel.color,
            );
          }
          notifyListeners();
        },
      ),
    );

    notifyListeners();
  }

  /// Cancels the active text edit without committing changes.
  void cancelActiveEdit() {
    activeEditId = null;
    notifyListeners();
  }

  /// Sets the active edit ID and notifies the UI to mount the overlay.
  void enterEditMode(String id) {
    activeEditId = id;
    notifyListeners();
  }

  /// Updates the visible node set based on the current viewport bounds.
  /// Called by the canvas when the transform changes (pan/zoom).
  void updateVisibleSet(Rect bufferRect) {
    visibleNodeIds.value = spatialHash.queryRect(bufferRect);
  }

  // ---------------------------------------------------------------------------
  // INTERACTION METHODS
  // ---------------------------------------------------------------------------

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

  /// Deletes a node with immediate command execution (bypasses debounce timer).
  /// Handles deletion race condition by ensuring delete executes before any pending moves.
  Future<void> deleteNode(String id) async {
    final node = _nodes[id];
    if (node == null) return;

    _log.info('Initiating optimistic UI teardown for node: $id');

    // Optimistic Update
    _nodes.remove(id);
    if (nodeShowingDeleteMenu == id) nodeShowingDeleteMenu = null;
    _syncViewStates(); // Cleanup ViewState for removed node
    notifyListeners();

    // Create delete command with rollback support
    final cmd = DeleteNodeCommand(
      targetId: id,
      api: _api,
      tableName: _getTableName(node),
      nodeData: node,
      onUndo: (restoredNode) {
        _log.warning(
          'Deletion rejected by database. Re-hydrating node: $id from cache.',
        );
        _nodes[id] = restoredNode;
        _syncViewStates();
        notifyListeners();
      },
      spatialGrid: spatialHash,
    );

    // Immediate execution bypasses the 300ms move timer
    _processor.queueCommand(cmd, immediate: true);

    // Clean up the last confirmed position tracking
    _lastConfirmedDbPositions.remove(id);
  }

  /// Creates a relation between two nodes.
  /// Called by InteractionController when relation drawing completes.
  /// Implements pre-flight validation to prevent duplicate relation crashes.
  Future<void> createRelation(String from, String to) async {
    final fromNode = _nodes[from];
    final toNode = _nodes[to];
    if (fromNode == null || toNode == null) return;

    // A. Pre-flight Validation (O(1) duplicate check)
    // Prevents "SurrealDB index unique_relation already contains..." crashes.
    final bool relationExists = _relations.values.any(
      (r) => r.fromNodeId == from && r.toNodeId == to,
    );

    if (relationExists) {
      _log.fine(
        'Pre-flight Validation: Relation $from -> $to already exists. Aborting quietly.',
      );
      return;
    }

    // B. Create Relation Input - Must inject table prefixes to satisfy Rust's DB parser
    final input = RelationInput(
      from: "${_getTableName(fromNode)}:$from",
      to: "${_getTableName(toNode)}:$to",
      props: IRelation(
        id: null,
        inId: null,
        outId: null,
        verb: "related",
        aesthetics: null,
        directionless: false,
        layer: 0,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );

    try {
      // C. Pessimistic FFI Call
      await _api.createRelation(input: input);

      // D. Hydrate the UI with the confirmed mathematical state
      await loadGraph();
    } catch (e) {
      _log.severe('Failed to create relation', e);
      errorMessage = "Link failed";
      notifyListeners();
    }
  }
}
