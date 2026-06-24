import 'dart:ui';

/// Interface for view state mutations during engine drag operations.
///
/// This is the intentionally designed 'volatile state' protocol:
/// the engine writes temporary position/size to view state during a drag,
/// and the view layer reads it reactively. When the drag ends (handlePointerUp),
/// the engine commits the final values to the canonical data store.
abstract class VolatileNodeState {
  void setDragWidth(double? width);
  void setDragPosition(Offset position);
  double? get dragWidth;
  Offset get dragPosition;
}
