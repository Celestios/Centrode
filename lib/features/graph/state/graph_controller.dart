import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart'; // Add 'uuid' to pubspec.yaml

// Domain Imports
import '../domain/models.dart';

// FFI Imports (Adjust path to your generated code)
import 'package:mycelium/src/rust/bridge/api.dart';
import 'package:mycelium/src/rust/domain/relations.dart';
// We assume 'AppHandle' and 'GraphSnapshot' are generated here.

class GraphController extends ChangeNotifier {
  final AppHandle _api;
  final Uuid _uuid = const Uuid();

  // THE STATE
  // Access via .values for lists, but keep Map for lookups.
  final Map<String, UiNode> _nodes = {};
  final Map<String, UiRelation> _relations = {};

  // Public Getter (ReadOnly view for UI)
  List<UiNode> get nodes => _nodes.values.toList();
  List<UiRelation> get relations => _relations.values.toList();
  Map<String, UiNode> get nodeLookup => _nodes;
  bool isLoading = false;
  String? errorMessage;

  // Interaction State
  String? nodeShowingDeleteMenu;
  String? draggingRelationSourceNode;
  Offset? draggingRelationCurrentPosition;

  GraphController(this._api);

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

      // The FFI generator typically maps Vec<NodeOutput> to List<NodeOutput>
      // We iterate and convert them to our Domain Model.
      for (final ffiNode in snapshot.$1) { // Assuming $1 is the nodes list
        final uiNode = UiNode.fromFFI(ffiNode);
        _nodes[uiNode.id] = uiNode;
      }

      // TODO: Handle Relations (snapshot.$2) and Config (snapshot.$3) similarly

    } catch (e) {
      errorMessage = "Failed to load graph: $e";
      print(errorMessage);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // 2. WRITE OPERATIONS (OPTIMISTIC)
  // ---------------------------------------------------------------------------

  /// Creates a node immediately in UI, then syncs with DB.
  Future<void> addNode(UiNodeType type, Offset position) async {
    // A. Generate Temporary Identity
    final tempId = "temp_${_uuid.v4()}";

    // B. Create the Optimistic Object
    UiNode newNode;
    switch (type) {
      case UiNodeType.task:
        newNode = TaskUiNode(
            id: tempId,
            position: position,
            text: "New Task",
            state: "TODO");
        break;
      case UiNodeType.inter:
         newNode = InterUiNode(
             id: tempId,
             position: position,
             verb: "connects");
         break;
      case UiNodeType.info:
        newNode = InfoUiNode(
            id: tempId,
            position: position,
            text: "New Note");
        break;
    }

    // C. UPDATE UI INSTANTLY
    _nodes[tempId] = newNode;
    notifyListeners();

    // D. ASYNC SYNC
    try {
      // Convert UI Model -> FFI Input Model
      final input = newNode.toInput();

      // Call Rust
      final realId = await _api.createNode(input: input);

      // E. RECONCILIATION (Swap Temp ID for Real ID)
      if (_nodes.containsKey(tempId)) {
        final node = _nodes.remove(tempId)!; // Remove old key
        node.id = realId;                     // Update internal ID
        _nodes[realId] = node;                // Re-insert with new key

        // No notifyListeners() needed if visual properties didn't change,
        // but beneficial to ensure IDs are consistent in UI widgets.
        notifyListeners();
      }
    } catch (e) {
      // F. ROLLBACK ON ERROR
      print("Failed to create node: $e");
      _nodes.remove(tempId); // Delete the fake node
      errorMessage = "Save failed";
      notifyListeners();
    }
  }

  /// Updates position immediately, debounces the network call (optional),
  /// and handles failure.
  Future<void> updateNodePosition(String id, Offset newPosition) async {
    final node = _nodes[id];
    if (node == null) return;

    final oldPosition = node.position;

    // A. Optimistic Update
    node.position = newPosition;
    notifyListeners();

    // B. Sync with Rust
    // (In a real app, use a Debouncer here to avoid spamming Rust 60 times/sec)
    try {
      final patchJson = jsonEncode({
        "visual_formatting": {
            "layout": {
                "graph": {
                    "x": newPosition.dx,
                    "y": newPosition.dy
                }
            }
        }
      });

      // We call 'patch_node_properties'.
      // Note: We need to know the 'table' (node type) for the API call.
      // For now, we might need a helper to get table name from type,
      // or update the Rust API to just take ID if possible.
      // Assuming we pass the table name string based on type:
      String tableName;
      if (node is TaskUiNode) {
        tableName = "task_node";
      } else if (node is InterUiNode) tableName = "inter_node";
      else tableName = "inode";

      await _api.patchNodeProperties(
          table: tableName,
          id: id,
          jsonPatch: patchJson
      );

    } catch (e) {
      // C. Rollback
      print("Failed to move node: $e");
      node.position = oldPosition;
      notifyListeners();
    }
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

  Future<void> deleteNode(String id) async {
    final node = _nodes[id];
    if (node == null) return;

    // Optimistic Update
    _nodes.remove(id);
    if (nodeShowingDeleteMenu == id) nodeShowingDeleteMenu = null;
    notifyListeners();

    try {
      // Determine table based on type
      String table;
      switch (node.type) {
        case UiNodeType.task: table = "task_node"; break;
        case UiNodeType.inter: table = "inter_node"; break;
        case UiNodeType.info: table = "inode"; break;
      }

      await _api.deleteNodeEntry(table: table, id: id);
    } catch (e) {
      print("Delete failed: $e");
      _nodes[id] = node; // Rollback
      errorMessage = "Delete failed";
      notifyListeners();
    }
  }

  // Relation Creation Logic
  void startRelationDrag(String sourceId, Offset startPos) {
    draggingRelationSourceNode = sourceId;
    draggingRelationCurrentPosition = startPos;
    notifyListeners();
  }

  void updateRelationDrag(Offset currentPos) {
    draggingRelationCurrentPosition = currentPos;
    notifyListeners();
  }

  Future<void> endRelationDrag() async {
    final sourceId = draggingRelationSourceNode;
    final endPos = draggingRelationCurrentPosition;

    // Reset state immediately
    draggingRelationSourceNode = null;
    draggingRelationCurrentPosition = null;
    notifyListeners();

    if (sourceId == null || endPos == null) return;

    // Hit Test: Find target node
    String? targetId;
    for (final node in _nodes.values) {
      if (node.id == sourceId) continue;

      final rect = Rect.fromLTWH(
        node.position.dx,
        node.position.dy,
        node.size.width,
        node.size.height
      );

      if (rect.contains(endPos)) {
        targetId = node.id;
        break;
      }
    }

    if (targetId != null) {
      await createRelation(sourceId, targetId);
    }
  }

  Future<void> createRelation(String from, String to) async {
    // 1. Create Relation Input
    // Note: 'props' must match your Rust IRelation struct.
    // We use default values for a generic connection.
    final input = RelationInput(
      from: from,
      to: to,
      props: const IRelation(
        id: null, // Let DB generate
        verb: "related",
        visualFormatting: null,
        directionless: false,
        layer: 0,
      ),
    );

    try {
      await _api.createRelation(input: input);
      // Ideally reload graph or optimistically add relation here.
      // For now, we rely on the next loadGraph or stream update.
      await loadGraph();
    } catch (e) {
      print("Failed to create relation: $e");
      errorMessage = "Link failed";
      notifyListeners();
    }
  }
}