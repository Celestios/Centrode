import 'package:flutter/material.dart';
import 'package:mycelium/shared/logging.dart';
import 'package:mycelium/shared/traceable_notifier.dart';
import '../engine/config.dart';
import '../store/graph_data_query.dart';
import 'view_state.dart';

/// Manages edit lifecycle, formatting callbacks, toolbar positioning, and floating menus.
class EditorState extends ChangeNotifier with TraceableNotifier {
  @override
  String get notifierName => 'EditorState';
  final Logger _log = Logger('EditorState');
  final GraphDataQuery _dataQuery;
  bool _disposed = false;

  /// Reference to the shared viewStates map owned by NodeRenderState.
  final Map<String, NodeViewState> viewStates;

  /// ID of the entity currently in text inline edit mode.
  String? activeEditId;

  /// ID of the node currently prompting a floating delete menu.
  String? nodeShowingFloatingToolbar;

  /// Tracks active text selection during inline editing.
  final ValueNotifier<TextSelection?> activeTextSelectionNotifier = ValueNotifier(null);

  /// Value notifier tracking unified toolbar offset for single selections.
  final ValueNotifier<Offset> toolbarOffsetNotifier = ValueNotifier(
    AppConfig.toolbar.singleOffset,
  );

  /// Value notifier tracking unified toolbar offset for multi-selections.
  final ValueNotifier<Offset> multiToolbarOffsetNotifier = ValueNotifier(
    AppConfig.toolbar.multiOffset,
  );

  /// Tracks the current paragraph's alignment for the toolbar icon.
  final ValueNotifier<TextAlign> currentTextAlignNotifier = ValueNotifier(TextAlign.center);

  /// Decoupled callbacks for text formatting in the UI layer.
  void Function(dynamic formatType, {String? url})? applyFormatCallback;
  void Function(dynamic headingType)? toggleHeadingCallback;
  void Function()? clearBlockFormatCallback;
  void Function()? cycleFontFamilyCallback;
  void Function(String fontFamily)? setFontFamilyCallback;
  void Function()? cycleTextColorCallback;
  void Function({String? colorUrl})? toggleHighlightCallback;
  void Function()? cycleHighlightColorCallback;
  void Function()? cycleTextAlignCallback;
  void Function()? commitActiveEditCallback;

  EditorState(this._dataQuery, this.viewStates);

  void updateActiveTextSelection(TextSelection? selection) {
    if (activeTextSelectionNotifier.value != selection) {
      activeTextSelectionNotifier.value = selection;
    }
  }

  /// Focuses and opens inline text editor mode for an entity.
  void enterEditMode(String id) {
    activeEditId = id;
    _log.finer('Entering edit mode for entity: $id');
    notifyListeners();
  }

  /// Commits changes in the active inline editor if possible, otherwise cancels.
  void commitActiveEdit() {
    if (commitActiveEditCallback != null) {
      commitActiveEditCallback!();
    } else {
      cancelActiveEdit();
    }
  }

  /// Aborts and closes active inline editing mode.
  void cancelActiveEdit() {
    activeEditId = null;
    activeTextSelectionNotifier.value = null;
    applyFormatCallback = null;
    toggleHeadingCallback = null;
    clearBlockFormatCallback = null;
    cycleFontFamilyCallback = null;
    setFontFamilyCallback = null;
    cycleTextColorCallback = null;
    toggleHighlightCallback = null;
    cycleHighlightColorCallback = null;
    cycleTextAlignCallback = null;
    commitActiveEditCallback = null;
    currentTextAlignNotifier.value = TextAlign.center;
    notifyListeners();
  }

  /// Triggers the delete menu to float near the specified node.
  void showFloatingToolbar(String nodeId) {
    if (nodeShowingFloatingToolbar != nodeId) {
      _log.finer('Showing delete menu for node: $nodeId');
      nodeShowingFloatingToolbar = nodeId;
      notifyListeners();
    }
  }

  /// Hides the floating delete menu.
  void hideFloatingToolbar() {
    if (nodeShowingFloatingToolbar != null) {
      _log.finer('Hiding delete menu.');
      nodeShowingFloatingToolbar = null;
      notifyListeners();
    }
  }

  /// Calculates the visual anchor point for the floating toolbar based on selected entities.
  Offset? calculateToolbarAnchor(Iterable<String> selectedIds) {
    if (selectedIds.isEmpty) return null;
    if (selectedIds.length > 1) {
      return _calculateMultiSelectAnchor(selectedIds);
    }
    return _calculateSingleSelectAnchor(selectedIds.first);
  }

  Offset? _calculateMultiSelectAnchor(Iterable<String> selectedIds) {
    double minX = double.infinity, minY = double.infinity,
        maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (final id in selectedIds) {
      final vs = viewStates[id];
      if (vs == null) continue;
      final rect = vs.rect;
      if (rect.left < minX) minX = rect.left;
      if (rect.top < minY) minY = rect.top;
      if (rect.right > maxX) maxX = rect.right;
      if (rect.bottom > maxY) maxY = rect.bottom;
    }
    if (minX == double.infinity) return null;
    final centerX = minX + (maxX - minX) / 2;
    return Offset(
      centerX - (AppConfig.toolbar.multiWidth / 2),
      minY - AppConfig.toolbar.height - 10,
    );
  }

  Offset? _calculateSingleSelectAnchor(String id) {
    final vs = viewStates[id];
    if (vs != null) return vs.positionNotifier.value;

    final rel = _dataQuery.relationLookup[id];
    if (rel == null) return null;

    final cached = _dataQuery.relationEngine.cache[id];
    if (cached != null) {
      return Offset(cached.labelPosition.x, cached.labelPosition.y);
    }
    return null;
  }

  /// Cleans up volatile editor state when entities are removed from the data store.
  void cleanupStaleState(Set<String> validKeys) {
    if (activeEditId != null && !validKeys.contains(activeEditId)) {
      activeEditId = null;
    }
    if (nodeShowingFloatingToolbar != null &&
        !validKeys.contains(nodeShowingFloatingToolbar)) {
      nodeShowingFloatingToolbar = null;
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    activeTextSelectionNotifier.dispose();
    toolbarOffsetNotifier.dispose();
    multiToolbarOffsetNotifier.dispose();
    currentTextAlignNotifier.dispose();
    super.dispose();
  }
}
