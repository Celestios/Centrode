import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../../../core/config/app_config.dart';
import '../domain/models.dart';
import 'canvas_interaction_states.dart';
import 'interaction_context.dart';

/// The Interaction Controller (FSM Engine)
///
/// This engine circumvents the Gesture Arena by processing raw PointerEvents.
/// It centralizes all pointer events into a math-driven FSM that operates in
/// canvas space, decoupling user intent from the Flutter Widget tree.
///
/// Implements the GoF State Pattern where state objects handle their own
/// event processing, enabling polymorphic dispatch without switch statements.
/// The controller implements [InteractionContext] to provide capabilities
/// to state objects while maintaining encapsulation.
class InteractionController implements InteractionContext {
  final Logger _log = Logger('InteractionController');

  /// The current interaction state of the canvas.
  final ValueNotifier<CanvasInteractionState> state = ValueNotifier(
    const CanvasIdle(),
  );

  /// Controller for canvas transformations (pan/zoom).
  final TransformationController transformController;

  /// Registry of all node view states for hit-testing.
  @override
  final Map<String, NodeViewState> nodeViewStates;

  /// Callback when a node move operation completes.
  final Function(String id, Offset pos) _onNodeMove;

  /// Callback when a relation is created between two nodes.
  final Function(String from, String to) _onRelationCreate;

  /// Callback to trigger relation layer repaint during node drag.
  final VoidCallback _onNodeDragUpdate;

  /// Getter to check if there's an active text edit in progress.
  final String? Function() _getActiveEditId;

  /// Callback to enter edit mode for an entity (node or relation).
  final Function(String id) _onEnterEditMode;

  /// Callback to commit the active edit.
  final VoidCallback _onCommitActiveEdit;

  /// Callback to create a new node at the specified position.
  final Function(Offset position) _onCreateNode;

  /// Getter for all relations (for hit-testing relation labels).
  final Iterable<UiRelation> Function() _getRelations;

  /// Callback when a node resize operation completes.
  final Function(String id, double newWidth) _onNodeResizeEnd;

  /// Callback to select an entity.
  final Function(String? id) _onSelectEntity;

  /// Callback to select multiple entities (Marquee).
  final Function(Iterable<String> ids) _onSelectEntities;

  /// Getter for the currently selected entities.
  final Set<String> Function() _getSelectedEntities;

  /// Getter for the toolbar offset.
  final Offset Function() _getToolbarOffset;

  /// Callback to update the toolbar offset.
  final Function(Offset) _updateToolbarOffset;

  /// Callback to delete selected entities.
  final VoidCallback _onDeleteSelectedEntities;

  /// Getter for visible node IDs.
  final Set<String> Function() _getVisibleNodeIds;

  /// Getter for Z-order tracking for proper hit-testing (last item is topmost).
  ///
  /// Now retrieves canonical truth from UI Controller instead of maintaining
  /// local state.
  @override
  List<String> get zOrder => _getZOrder();

  final List<String> Function() _getZOrder;

  // Double-tap detection state
  DateTime? _lastPointerDownTime;
  Offset? _lastPointerDownPos;

  InteractionController({
    required this.transformController,
    required this.nodeViewStates,
    required Function(String id, Offset pos) onNodeMove,
    required Function(String from, String to) onRelationCreate,
    required VoidCallback onNodeDragUpdate,
    required String? Function() getActiveEditId,
    required Function(String id) onEnterEditMode,
    required VoidCallback onCommitActiveEdit,
    required Function(Offset position) onCreateNode,
    required Iterable<UiRelation> Function() getRelations,
    required Function(String id, double newWidth) onNodeResizeEnd,
    required Function(String? id) onSelectEntity,
    required Function(Iterable<String> ids) onSelectEntities,
    required Set<String> Function() getSelectedEntities,
    required Offset Function() getToolbarOffset,
    required Function(Offset) updateToolbarOffset,
    required VoidCallback onDeleteSelectedEntities,
    required Set<String> Function() getVisibleNodeIds,
    required List<String> Function() getZOrder,
  }) : _onNodeMove = onNodeMove,
       _onRelationCreate = onRelationCreate,
       _onNodeDragUpdate = onNodeDragUpdate,
       _getActiveEditId = getActiveEditId,
       _onEnterEditMode = onEnterEditMode,
       _onCommitActiveEdit = onCommitActiveEdit,
       _onCreateNode = onCreateNode,
       _getRelations = getRelations,
       _onNodeResizeEnd = onNodeResizeEnd,
       _onSelectEntity = onSelectEntity,
       _onSelectEntities = onSelectEntities,
       _getSelectedEntities = getSelectedEntities,
       _getToolbarOffset = getToolbarOffset,
       _updateToolbarOffset = updateToolbarOffset,
       _onDeleteSelectedEntities = onDeleteSelectedEntities,
       _getVisibleNodeIds = getVisibleNodeIds,
       _getZOrder = getZOrder;

  // ---------------------------------------------------------------------------
  // InteractionContext Implementation
  // ---------------------------------------------------------------------------

  @override
  void onNodeMove(String id, Offset pos) => _onNodeMove(id, pos);

  @override
  void onRelationCreate(String from, String to) => _onRelationCreate(from, to);

  @override
  void onNodeDragUpdate() => _onNodeDragUpdate();

  @override
  String? getActiveEditId() => _getActiveEditId();

  @override
  void onEnterEditMode(String id) => _onEnterEditMode(id);

  /// Callback to commit the active edit.
  ///
  /// With nodes now handling their own editing internally via `_NodeInternalEditor`
  /// and relations via the refactored `InlineEditorOverlay`, this method serves
  /// as a cleanup fallback. The internal widgets now handle their own commit
  /// via TapOutside and Enter key events.
  @override
  void onCommitActiveEdit() {
    final activeId = _getActiveEditId();
    if (activeId != null) {
      // Internal widgets now handle their own commit via TapOutside/Enter
      // This remains as a cleanup fallback
      _onCommitActiveEdit();
    }
  }

  @override
  void onCreateNode(Offset position) => _onCreateNode(position);

  @override
  Iterable<UiRelation> getRelations() => _getRelations();

  @override
  void onNodeResizeEnd(String id, double newWidth) =>
      _onNodeResizeEnd(id, newWidth);

  @override
  void onSelectEntity(String? id) => _onSelectEntity(id);

  @override
  void onSelectEntities(Iterable<String> ids) => _onSelectEntities(ids);

  @override
  Set<String> getSelectedEntities() => _getSelectedEntities();

  @override
  Offset getToolbarOffset() => _getToolbarOffset();

  @override
  void updateToolbarOffset(Offset delta) => _updateToolbarOffset(delta);

  @override
  void onDeleteSelectedEntities() => _onDeleteSelectedEntities();

  @override
  Set<String> getVisibleNodeIds() => _getVisibleNodeIds();

  // ---------------------------------------------------------------------------
  // FSM Engine
  // ---------------------------------------------------------------------------

  /// Centralized state mutation to guarantee FSM observability.
  /// Logs state transitions for telemetry and debugging purposes.
  void _transitionTo(CanvasInteractionState newState) {
    if (state.value.runtimeType != newState.runtimeType) {
      _log.fine(
        'FSM Transition: ${state.value.runtimeType} -> ${newState.runtimeType}',
      );
    }
    state.value = newState;
  }

  /// Converts a screen position to canvas coordinates.
  Offset _screenToCanvas(Offset screenPos) {
    final transform = transformController.value;

    // Guard against singular matrix (scale = 0)
    if (transform.determinant() == 0.0) return screenPos;

    return MatrixUtils.transformPoint(Matrix4.inverted(transform), screenPos);
  }

  /// Processes double-tap detection and returns true if this is a double-tap.
  bool _processDoubleTap(Offset pCanvas) {
    final now = DateTime.now();
    bool isDoubleTap = false;

    if (_lastPointerDownTime != null &&
        now.difference(_lastPointerDownTime!).inMilliseconds <
            AppConfig.graph.interaction.doubleTapMs &&
        _lastPointerDownPos != null &&
        (_lastPointerDownPos! - pCanvas).distance <
            AppConfig.graph.interaction.doubleTapDistance) {
      isDoubleTap = true;
    }

    _lastPointerDownTime = now;
    _lastPointerDownPos = pCanvas;

    return isDoubleTap;
  }

  /// Handles pointer down events with polymorphic dispatch.
  /// Delegates to the current state's handlePointerDown method.
  void handlePointerDown(PointerDownEvent e) {
    final pCanvas = _screenToCanvas(e.localPosition);
    final isDoubleTap = _processDoubleTap(pCanvas);

    // Polymorphic dispatch to state object
    final newState = state.value.handlePointerDown(
      e,
      pCanvas,
      this,
      isDoubleTap,
    );
    _transitionTo(newState);
  }

  /// Handles pointer move events with polymorphic dispatch.
  /// Delegates to the current state's handlePointerMove method.
  void handlePointerMove(PointerMoveEvent e) {
    final pCanvas = _screenToCanvas(e.localPosition);
    _transitionTo(state.value.handlePointerMove(e, pCanvas, this));
  }

  /// Handles pointer up events with polymorphic dispatch.
  /// Delegates to the current state's handlePointerUp method.
  void handlePointerUp(PointerUpEvent e) {
    _transitionTo(state.value.handlePointerUp(e, this));
  }

  /// Handles pointer cancel events with polymorphic dispatch.
  /// Delegates to the current state's handlePointerCancel method.
  void handlePointerCancel(PointerCancelEvent e) {
    _log.warning('Pointer event cancelled by OS. Resetting FSM to Idle.');
    _transitionTo(state.value.handlePointerCancel(e, this));
  }

  /// Disposes the state notifier.
  void dispose() {
    state.dispose();
  }
}
