// lib/features/graph/state/interaction_context.dart
import 'dart:ui';
import '../models/models.dart';
import '../presentation/view_state.dart';
import '../store/spatial_index.dart';

/// Scoped capability interface for active interaction states.
///
/// This interface isolates the environment data and callbacks from the
/// controller's lifecycle methods, enabling the GoF State Pattern where
/// state objects can interact with the context without direct coupling
/// to the controller implementation.
/// Interface segregating viewport capability from the rest of the context.
abstract interface class ViewportCapability {
  /// Gets the current scale factor of the canvas viewport.
  double get currentScale;

  /// Returns the current set of visible node IDs for O(V) hit testing.
  Set<String> getVisibleNodeIds();
}

/// Interface segregating selection and toolbar actions.
abstract interface class SelectionCapability {
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

  /// Triggers saving the current selection as a template.
  void onSaveTemplate();

  /// Opens the right property panel and switches to the Data tab for the specified node.
  void openDataInspector(String nodeId);

  /// Calculates the visual anchor point for the floating toolbar based on selected entities.
  Offset? calculateToolbarAnchor(Iterable<String> selectedIds);
}

/// Interface segregating structural layout, node/relation geometry, and edits.
abstract interface class GeometryCapability {
  /// Registry of all node view states for hit-testing and position updates.
  Map<String, NodeViewState> get nodeViewStates;

  /// Cache of computed relation paths for obstacle avoidance.
  Map<String, List<Offset>> get relationPathCache;

  /// Z-order tracking for proper hit-testing (last item is topmost).
  List<String> get zOrder;

  /// Spatial hash grid for O(1) node lookups by position.
  SpatialHashGrid get spatialGrid;

  /// Returns all relations for hit-testing relation labels.
  Iterable<UiRelation> getRelations();

  /// Retrieves a node by its ID from the data store lookup.
  UiNode? getNode(String id);

  /// Callback when a node move operation completes.
  void onNodeMove(String id, Offset pos);

  /// Callback when a relation is created between two nodes.
  void onRelationCreate(
    String from,
    String to, {
    String? fromSide,
    String? toSide,
  });

  /// Callback when a relation layout/endpoints are updated.
  void onRelationUpdateLayout(
    String id, {
    String? fromNodeId,
    String? toNodeId,
    String? fromSide,
    String? toSide,
    String? strategyType,
  });

  /// Updates the style of the specified relation.
  void onRelationUpdateStyle(String id, RelationStyle newStyle);

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

  /// Updates the style of the specified node.
  void updateNodeStyle(String id, NodeStyle Function(NodeStyle style) updateFn);

  /// Sets the currently hovered metadata node ID to show/hide the preview card.
  void setHoveredNodeMetadata(String? nodeId);

  /// Creates a drawing node with the specified brush and geometry options.
  void onCreateDrawingNode({
    required Offset position,
    required List<String> paths,
    required String brushType,
    required double brushThickness,
    required String brushColor,
    required Size size,
  });
}

/// Composite interface for capabilities that need both geometry and viewport access.
abstract interface class GeometryAndViewportCapability
    implements GeometryCapability, ViewportCapability {}

/// Scoped capability interface for active interaction states.
///
/// This interface isolates the environment data and callbacks from the
/// controller's lifecycle methods, enabling the GoF State Pattern where
/// state objects can interact with the context without direct coupling
/// to the controller implementation.
abstract interface class InteractionContext
    implements SelectionCapability, GeometryAndViewportCapability {}
