import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

void main() {
  test('RawUuid equality and fastHashCode map collision invariant', () {
    final bytes1 = Uint8List.fromList([
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
    ]);
    final bytes2 = Uint8List.fromList([
      1,
      2,
      3,
      4,
      5,
      6,
      7,
      8,
      9,
      10,
      11,
      12,
      13,
      14,
      15,
      16,
    ]);

    final uuid1 = RawUuid(bytes1);
    final uuid2 = RawUuid(bytes2);

    expect(uuid1 == uuid2, isTrue);
    expect(uuid1.fastHashCode, equals(uuid2.fastHashCode));

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
}
