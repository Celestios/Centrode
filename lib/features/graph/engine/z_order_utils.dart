import 'package:centrode/shared/domain/raw_uuid.dart';

/// Resolves z-order IDs back to RawUuid keys in nodeViewStates,
/// preserving the z-order (reversed = front-to-back).
///
/// Returns node IDs in hit-test priority order (front to back).
List<RawUuid> resolveZOrderToNodeIds(
  List<RawUuid> zOrder,
  Map<RawUuid, dynamic> nodeViewStates,
) {
  if (zOrder.isEmpty || nodeViewStates.isEmpty) {
    return nodeViewStates.keys.toList().reversed.toList();
  }
  final keys = nodeViewStates.keys.toSet();
  return zOrder.reversed.where(keys.contains).toList();
}
