import 'package:flutter_test/flutter_test.dart';
import 'package:mycelium/features/graph/presentation/strategies/snake_layout_strategy.dart';

void main() {
  group('SnakeRelationLayoutStrategy', () {
    test('creates with default amplitude and frequency', () {
      final strategy = SnakeRelationLayoutStrategy();
      expect(strategy.amplitude, 20.0);
      expect(strategy.frequency, 3.0);
    });

    test('creates with custom amplitude and frequency', () {
      final strategy = SnakeRelationLayoutStrategy(amplitude: 30.0, frequency: 5.0);
      expect(strategy.amplitude, 30.0);
      expect(strategy.frequency, 5.0);
    });
  });
}
