import 'package:flutter_test/flutter_test.dart';
import 'package:mycelium/features/graph/presentation/strategies/relation_body_strategy.dart';

void main() {
  group('RelationBodyStrategy.fromType', () {
    test('returns NoneRelationBodyStrategy for "none"', () {
      final strategy = RelationBodyStrategy.fromType('none');
      expect(strategy, isA<NoneRelationBodyStrategy>());
    });

    test('returns TaperRelationBodyStrategy for "taper"', () {
      final strategy = RelationBodyStrategy.fromType('taper');
      expect(strategy, isA<TaperRelationBodyStrategy>());
    });

    test('returns WidthModulateRelationBodyStrategy for "widthModulate"', () {
      final strategy = RelationBodyStrategy.fromType('widthModulate');
      expect(strategy, isA<WidthModulateRelationBodyStrategy>());
    });

    test('returns NoneRelationBodyStrategy for unknown type', () {
      final strategy = RelationBodyStrategy.fromType('unknown');
      expect(strategy, isA<NoneRelationBodyStrategy>());
    });
  });

  group('NoneRelationBodyStrategy', () {
    test('widthAt returns baseWidth for all t', () {
      final strategy = NoneRelationBodyStrategy();
      expect(strategy.widthAt(0.0, 2.0), 2.0);
      expect(strategy.widthAt(0.5, 2.0), 2.0);
      expect(strategy.widthAt(1.0, 2.0), 2.0);
    });
  });

  group('TaperRelationBodyStrategy', () {
    test('widthAt interpolates from startWidth to endWidth', () {
      final strategy = TaperRelationBodyStrategy(startWidth: 4.0, endWidth: 1.0);
      expect(strategy.widthAt(0.0, 2.0), 4.0);
      expect(strategy.widthAt(0.5, 2.0), 2.5);
      expect(strategy.widthAt(1.0, 2.0), 1.0);
    });
  });

  group('WidthModulateRelationBodyStrategy', () {
    test('widthAt oscillates around baseWidth', () {
      final strategy = WidthModulateRelationBodyStrategy(amplitude: 1.0, frequency: 2.0);
      final w0 = strategy.widthAt(0.0, 2.0);
      final w0125 = strategy.widthAt(0.125, 2.0);
      expect(w0, 2.0); // sin(0) = 0
      expect(w0125, closeTo(3.0, 0.01)); // sin(pi/2) = 1
    });
  });
}
