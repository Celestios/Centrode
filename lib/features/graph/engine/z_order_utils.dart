import 'package:mycelium/shared/domain/raw_uuid.dart';

/// Resolves z-order string IDs back to RawUuid keys in nodeViewStates,
/// preserving the z-order (reversed = front-to-back).
///
/// Returns node IDs in hit-test priority order (front to back).
List<RawUuid> resolveZOrderToNodeIds(
  List<String> zOrder,
  Map<RawUuid, dynamic> nodeViewStates,
) {
  if (zOrder.isEmpty || nodeViewStates.isEmpty) {
    return nodeViewStates.keys.toList().reversed.toList();
  }
  final keys = nodeViewStates.keys.toList();
  return zOrder.reversed
      .map((id) => keys.firstWhere(
            (k) => k.toUuidString() == id,
            orElse: () => keys.first,
          ))
      .toList();
}
