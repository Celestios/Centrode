import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'nodes.dart';

/// Manages reactive spatial state for a node, decoupling high-frequency
/// position updates from the structural graph state.
class NodeViewState {
  // Mutable to allow ID swapping during optimistic updates (Pillar 2 fix)
  String nodeId;
  final ValueNotifier<Offset> positionNotifier;
  final ValueNotifier<Size> sizeNotifier; // Synchronous mathematical truth

  // [NEW] Volatile UI States (Not persisted to DB)
  final ValueNotifier<bool> isExpandedNotifier = ValueNotifier(false);
  final ValueNotifier<double?> dragWidthNotifier = ValueNotifier(null);
  int lineCount = 1;

  NodeViewState(UiNode node)
    : nodeId = node.id,
      positionNotifier = ValueNotifier<Offset>(node.position),
      sizeNotifier = ValueNotifier<Size>(
        node.size,
      ); // Synchronous initialization

  /// Atomically updates the ID during an optimistic swap.
  /// This ensures that widgets and hit-testers using this ViewState
  /// immediately reference the canonical Database ID.
  void updateId(String newId) {
    nodeId = newId;
  }

  /// Re-hydrates the existing ViewState with data from a restored node.
  /// This prevents widget detachment by keeping memory addresses (notifiers) stable.
  void rehydrate(UiNode node) {
    nodeId = node.id;
    positionNotifier.value = node.position;
    sizeNotifier.value = node.size;
    // Reset volatile UI states to prevent stale interaction artifacts
    isExpandedNotifier.value = false;
    dragWidthNotifier.value = null;
  }

  /// Returns the bounding rect combining position and size.
  Rect get rect => positionNotifier.value & sizeNotifier.value;

  // --- NEW: DRY Geometry Getters ---
  /// Returns the exact coordinate for the output port (Right-Center)
  Offset get rightPort =>
      positionNotifier.value +
      Offset(sizeNotifier.value.width, sizeNotifier.value.height / 2);

  /// Returns the exact coordinate for the input port (Left-Center)
  Offset get leftPort =>
      positionNotifier.value + Offset(0, sizeNotifier.value.height / 2);

  /// Returns the precise hit-test area for the right-edge resize interaction
  Rect get resizeHitbox =>
      Rect.fromLTRB(rect.right - 15, rect.top, rect.right, rect.bottom);
  // ---------------------------------

  // updateSize(Size newSize) removed to ensure domain-driven constraints

  /// Updates position by a delta amount during drag operations.
  void updatePosition(Offset delta) {
    positionNotifier.value += delta;
  }

  /// Updates position by a screen delta, accounting for the current zoom scale.
  /// Used during drag operations where the delta is in screen coordinates.
  void updatePositionWithScale(Offset screenDelta, double currentScale) {
    if (currentScale <= 0) return; // Scale constraint safety
    final Offset canvasDelta = screenDelta / currentScale;
    positionNotifier.value += canvasDelta;
  }

  /// Syncs the position back to the underlying UiNode after drag ends.
  void syncToNode(UiNode node) {
    node.position = positionNotifier.value;
  }

  /// [NEW] Synchronous headless geometry calculation
  /// Runs in O(1) time without waiting for the Flutter Render Object Tree.
  void recalculateSize(String text, double currentWidth, String fontFamily) {
    final tp = TextPainter(
      text: TextSpan(
        text: text.isEmpty ? "Empty Node" : text,
        style: TextStyle(fontSize: 12, fontFamily: fontFamily),
      ),
      textDirection: TextDirection.ltr,
    );

    // Account for 8.0 padding on left/right
    tp.layout(maxWidth: currentWidth > 20 ? currentWidth - 16 : 10);

    final metrics = tp.computeLineMetrics();
    lineCount = metrics.length;

    double textHeight = 0;

    if (lineCount > 4 && !isExpandedNotifier.value) {
      textHeight = metrics.take(3).fold(0.0, (sum, m) => sum + m.height);
      textHeight += 2.0; // Space for "Show More" toggle
    } else {
      textHeight = tp.height;
      if (lineCount > 3) textHeight += 5.0; // Space for "Show Less" toggle
    }

    // Base padding (16) + Task Node state badge safety margin (24)
    sizeNotifier.value = Size(currentWidth, textHeight + 20);
  }

  /// Disposes the internal ValueNotifiers.
  void dispose() {
    positionNotifier.dispose();
    sizeNotifier.dispose();
    isExpandedNotifier.dispose();
    dragWidthNotifier.dispose();
  }
}
