import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mycelium/shared/domain/raw_uuid.dart';

void main() {
  test('RawUuid equality and fastHashCode map collision invariant', () {
    final bytes1 = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);
    final bytes2 = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);

    final uuid1 = RawUuid(bytes1);
    final uuid2 = RawUuid(bytes2);

    // Operator == byte-wise content equality test
    expect(uuid1 == uuid2, isTrue);
    expect(uuid1.fastHashCode, equals(uuid2.fastHashCode));

    // Map slot lookup invariant
    final slotMap = <RawUuid, int>{};
    slotMap[uuid1] = 42;
    expect(slotMap[uuid2], equals(42));
    expect(slotMap.length, equals(1));
  });

  test('RawUuid v4 generation and string conversion', () {
    final uuid = RawUuid.v4();
    expect(uuid.bytes.length, equals(16));
    final str = uuid.toUuidString();
    expect(str.length, equals(36));
  });

  test('SpatialBufferSlotManager slot allocation', () {
    final manager = SpatialBufferSlotManager();
    final bytes1 = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]);
    final bytes2 = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 16, 15]);

    final id1 = RawUuid(bytes1);
    final id2 = RawUuid(bytes2);

    final slot1 = manager.getOrAssignSlot(id1);
    final slot2 = manager.getOrAssignSlot(id2);
    final slot1Again = manager.getOrAssignSlot(id1);

    expect(slot1, equals(0));
    expect(slot2, equals(1));
    expect(slot1Again, equals(0));
    expect(manager.getSlot(id1), equals(0));
    expect(manager.getSlot(id2), equals(1));
  });
}
