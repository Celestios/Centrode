import 'package:centrode/shared/widgets/unravel_slider/domain/unravel_slider_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnravelSliderMetrics Mathematical Invariants', () {
    test('centers active option onto handle with machine precision across variants', () {
      final testCases = [
        (trackWidth: 230.0, itemCount: 6),
        (trackWidth: 180.0, itemCount: 3),
        (trackWidth: 350.0, itemCount: 8),
        (trackWidth: 500.0, itemCount: 16),
      ];

      for (final tc in testCases) {
        final metrics = UnravelSliderMetrics(
          trackWidth: tc.trackWidth,
          itemCount: tc.itemCount,
        );

        for (var k = 0; k < tc.itemCount; k++) {
          final u = metrics.anchorU(k);
          final xs = metrics.computeXs(u);
          final handleCenter = metrics.margin + u;

          expect(
            (xs[k] - handleCenter).abs(),
            lessThan(1e-9),
            reason: 'Item $k failed alignment for W=${tc.trackWidth}, N=${tc.itemCount}',
          );
        }
      }
    });

    test('snapping logic snaps to nearest anchor correctly', () {
      final metrics = UnravelSliderMetrics(trackWidth: 230.0, itemCount: 6);
      final step = metrics.handleTravel / 5.0;

      expect(metrics.snapU(0.0), equals(0.0));
      expect(metrics.snapU(step * 0.4), equals(0.0));
      expect(metrics.snapU(step * 0.6), closeTo(step, 1e-9));
      expect(metrics.snapU(step * 2.1), closeTo(step * 2, 1e-9));
      expect(metrics.snapU(metrics.handleTravel + 50.0), closeTo(metrics.handleTravel, 1e-9));
    });

    test('spatial focus ramps up smoothly and decays outside radius', () {
      final metrics = UnravelSliderMetrics(trackWidth: 230.0, itemCount: 6);
      const handleCenter = 100.0;

      // Exact center
      expect(metrics.spatialFocus(100.0, handleCenter), equals(1.0));

      // Halfway towards edge of focus radius
      final halfFocus = metrics.spatialFocus(100.0 + metrics.focusRadius / 2, handleCenter);
      expect(halfFocus, closeTo(0.5, 1e-4));

      // Beyond focus radius
      expect(metrics.spatialFocus(100.0 + metrics.focusRadius * 1.5, handleCenter), equals(0.0));
    });

    test('hit testing accurately locates clicked option', () {
      final metrics = UnravelSliderMetrics(trackWidth: 230.0, itemCount: 6);
      final u = metrics.anchorU(2);
      final xs = metrics.computeXs(u);

      expect(metrics.hitTest(xs[2], xs), equals(2));
      expect(metrics.hitTest(xs[0], xs), equals(0));
      expect(metrics.hitTest(xs[5], xs), equals(5));
    });
  });
}
