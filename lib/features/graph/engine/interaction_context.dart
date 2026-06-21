// lib/features/graph/state/interaction_context.dart
import 'dart:ui';
import '../models/models.dart';
import '../models/port.dart';
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

/// Read-only query interface for node/relation geometry data.
abstract interface class QueryCapability {
  Map<String, NodeViewState> get nodeViewStates;
  Map<String, List<Offset>> get relationPathCache;
  List<String> get zOrder;
  SpatialHashGrid get spatialGrid;
  Iterable<UiRelation> getRelations();
  UiNode? getNode(String id);
}

/// Write/mutation interface for structural layout, node/relation edits.
abstract interface class MutationCapability {
  void onNodeMove(String id, Offset pos);

  void onRelationCreate(
    String from,
    String to, {
    PortSide? fromSide,
    PortSide? toSide,
    String? verb,
  });

  void onRelationUpdateLayout(
    String id, {
    String? fromNodeId,
    String? toNodeId,
    PortSide? fromSide,
    PortSide? toSide,
    String? strategyType,
  });

  void onRelationUpdateStyle(String id, RelationStyle newStyle);

  void onNodeDragUpdate();

  void setNodeDragging(String id, bool dragging);

  void onCommitActiveEdit();

  String? getActiveEditId();

  void onEnterEditMode(String id);

  void onCreateNode(Offset position);

  void updateNodeWidth(String id, double leftEdge, double rightEdge);

  void toggleNodeExpansion(String id);

  void updateNodeStyle(String id, NodeStyle Function(NodeStyle style) updateFn);

  void setHoveredNodeMetadata(String? nodeId);

  void setHoveredNode(String? nodeId);

  void onCreateDrawingNode({
    required Offset position,
    required List<String> paths,
    required String brushType,
    required double brushThickness,
    required String brushColor,
    required Size size,
  });
}

abstract interface class GeometryCapability
    implements MutationCapability, QueryCapability {}

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
