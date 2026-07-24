// lib/features/graph/state/interaction_context.dart
import 'dart:ui';
import '../models/models.dart';
import '../presentation/view_state.dart';
import '../store/spatial_index.dart';
import '../store/relation_engine_state.dart';
import 'package:mycelium/shared/domain/raw_uuid.dart';

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
  Set<RawUuid> getVisibleNodeIds();
}

/// Interface segregating selection and toolbar actions.
abstract interface class SelectionCapability {
  /// Callback to set the active selected entity (node or relation), or clear if null.
  void onSelectEntity(RawUuid? id);

  /// Gets the IDs of the currently selected entities.
  Set<RawUuid> getSelectedEntities();

  /// Callback to set multiple entities as selected (Marquee).
  void onSelectEntities(Iterable<RawUuid> ids);

  /// Gets the current relative offset for the floating toolbar.
  Offset getToolbarOffset();

  /// Sets the relative offset for the floating toolbar.
  void setToolbarOffset(Offset offset);

  /// Executes the delete command for all currently selected entities.
  void onDeleteSelectedEntities();

  /// Triggers saving the current selection as a template.
  void onSaveTemplate();

  /// Opens the right property panel and switches to the Data tab for the specified node.
  void openDataInspector(RawUuid nodeId);

  /// Calculates the visual anchor point for the floating toolbar based on selected entities.
  Offset? calculateToolbarAnchor(Iterable<RawUuid> selectedIds);
}

/// Read-only query interface for node/relation geometry data.
abstract interface class QueryCapability {
  Map<String, NodeViewState> get nodeViewStates;
  RelationEngineState get relationEngine;
  List<String> get zOrder;
  SpatialHashGrid get spatialGrid;
  Iterable<UiRelation> getRelations();
  UiNode? getNode(RawUuid id);
}

/// Write/mutation interface for structural layout, node/relation edits.
abstract interface class MutationCapability {
  void onNodeMove(RawUuid id, Offset pos);

  void onRelationCreate(
    RawUuid from,
    RawUuid to, {
    PortSide? fromSide,
    PortSide? toSide,
    String? verb,
  });

  void onRelationUpdateLayout(
    RawUuid id, {
    RawUuid? fromNodeId,
    RawUuid? toNodeId,
    PortSide? fromSide,
    PortSide? toSide,
    String? strategyType,
  });

  void onRelationUpdateStyle(RawUuid id, RelationStyle newStyle);

  void onNodeDragUpdate();

  void onNodesDrag(List<(RawUuid, Offset)> updates);

  void setNodeDragging(RawUuid id, bool dragging);

  void onCommitActiveEdit();

  RawUuid? getActiveEditId();

  void onEnterEditMode(RawUuid id);

  void onCreateNode(Offset position);

  void updateNodeWidth(RawUuid id, double leftEdge, double rightEdge);

  void toggleNodeExpansion(RawUuid id);

  void updateNodeStyle(RawUuid id, NodeStyle Function(NodeStyle style) updateFn);

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
