// lib/features/graph/state/interaction_context.dart
import 'dart:ui';
import '../models/models.dart';
import '../presentation/view_state.dart';

/// Scoped capability interface for active interaction states.
///
/// This interface isolates the environment data and callbacks from the
/// controller's lifecycle methods, enabling the GoF State Pattern where
/// state objects can interact with the context without direct coupling
/// to the controller implementation.
abstract interface class InteractionContext {
  /// Registry of all node view states for hit-testing and position updates.
  Map<String, NodeViewState> get nodeViewStates;

  /// Z-order tracking for proper hit-testing (last item is topmost).
  List<String> get zOrder;

  /// Returns all relations for hit-testing relation labels.
  Iterable<UiRelation> getRelations();

  /// Callback when a node move operation completes.
  void onNodeMove(String id, Offset pos);

  /// Callback when a relation is created between two nodes.
  void onRelationCreate(String from, String to);

  /// Callback to trigger relation layer repaint during node drag.
  void onNodeDragUpdate();

  /// Registers a node dragging state to protect its volatile position from store overrides.
  void setNodeDragging(String id, bool dragging);

  /// Callback to commit the active text edit.
  void onCommitActiveEdit();

  /// Returns the ID of the entity currently being edited, or null.
  String? getActiveEditId();

  /// Callback to enter edit mode for an entity (node or relation).
  void onEnterEditMode(String id);

  /// Callback to create a new node at the specified position.
  void onCreateNode(Offset position);

  /// Callback when a node resize operation completes.
  void updateNodeWidth(String id, double leftEdge, double rightEdge);

  /// Callback when a node expansion state is toggled.
  void toggleNodeExpansion(String id);

  /// Callback to set the active selected entity (node or relation), or clear if null.
  void onSelectEntity(String? id);

  /// Gets the IDs of the currently selected entities.
  Set<String> getSelectedEntities();

  /// Callback to set multiple entities as selected (Marquee).
  void onSelectEntities(Iterable<String> ids);

  /// Gets the current relative offset for the floating toolbar.
  Offset getToolbarOffset();

  /// Sets the relative offset for the floating toolbar.
  void setToolbarOffset(Offset offset);

  /// Executes the delete command for all currently selected entities.
  void onDeleteSelectedEntities();

  /// Returns the current set of visible node IDs for O(V) hit testing.
  Set<String> getVisibleNodeIds();

  /// Gets the current scale factor of the canvas viewport.
  double get currentScale;
}
