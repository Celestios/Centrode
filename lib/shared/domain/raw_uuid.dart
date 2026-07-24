import 'dart:typed_data';
import 'package:uuid/uuid.dart';

/// Lightweight wrapper around a 16-byte Uint8List key.
class RawUuid {
  final Uint8List bytes;

  const RawUuid(this.bytes);

  factory RawUuid.v4() {
    final list = Uint8List(16);
    Uuid.parse(const Uuid().v4(), buffer: list);
    return RawUuid(list);
  }

  factory RawUuid.fromBytes(Uint8List list) {
    assert(list.length == 16, 'RawUuid must be exactly 16 bytes');
    return RawUuid(list);
  }

  /// Converts to standard 36-character hyphenated UUID string for display/logging.
  String toUuidString() => Uuid.unparse(bytes);

  /// Fast hash code for HashMap key lookup (`Map<RawUuid, int> slotMap`).
  int get fastHashCode {
    final bd = ByteData.sublistView(bytes);
    return bd.getInt64(0) ^ bd.getInt64(8);
  }

  @override
  int get hashCode => fastHashCode;

  /// Explicit byte-wise content equality operator.
  /// Compares 16-byte buffers via 2 fast 64-bit int comparisons (O(1)).
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! RawUuid) return false;
    final bd1 = ByteData.sublistView(bytes);
    final bd2 = ByteData.sublistView(other.bytes);
    return bd1.getInt64(0) == bd2.getInt64(0) && bd1.getInt64(8) == bd2.getInt64(8);
  }

  @override
  String toString() => toUuidString();
}

/// Slot index manager mapping 128-bit RawUuid keys to contiguous array slots (0..N) in SpatialBuffer.
/// Avoids array index hash collisions by using exact RawUuid equality in HashMap lookups.
class SpatialBufferSlotManager {
  final Map<RawUuid, int> _slotMap = {};
  int _nextSlot = 0;

  int getOrAssignSlot(RawUuid id) {
    return _slotMap.putIfAbsent(id, () => _nextSlot++);
  }

  int? getSlot(RawUuid id) => _slotMap[id];
}
