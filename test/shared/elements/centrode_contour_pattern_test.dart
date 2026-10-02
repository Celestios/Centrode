import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/shared/elements/elements.dart';

void main() {
  Finder findContourCustomPaint() {
    return find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter is CentrodeContourPainter,
    );
  }

  group('CentrodeContourPattern Widget & Painter', () {
    testWidgets('renders topographic pattern by default with CustomPaint', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 120,
              child: CentrodeContourPattern(),
            ),
          ),
        ),
      );

      final paintFinder = findContourCustomPaint();
      expect(paintFinder, findsOneWidget);
      final customPaint = tester.widget<CustomPaint>(paintFinder);
      expect(customPaint.painter, isA<CentrodeContourPainter>());
      final painter = customPaint.painter as CentrodeContourPainter;
      expect(painter.config.style, equals(ContourStyle.topographic));
    });

    testWidgets('renders flowingWaves pattern via named constructor', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 120,
              child: CentrodeContourPattern.waves(),
            ),
          ),
        ),
      );

      final paintFinder = findContourCustomPaint();
      expect(paintFinder, findsOneWidget);
      final customPaint = tester.widget<CustomPaint>(paintFinder);
      final painter = customPaint.painter as CentrodeContourPainter;
      expect(painter.config.style, equals(ContourStyle.flowingWaves));
    });

    testWidgets('clips to borderRadius when provided', (tester) async {
      const radius = BorderRadius.all(Radius.circular(16));
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 120,
              child: CentrodeContourPattern(
                borderRadius: radius,
              ),
            ),
          ),
        ),
      );

      final clipRRectFinder = find.byType(ClipRRect);
      expect(clipRRectFinder, findsOneWidget);
      final clipRRect = tester.widget<ClipRRect>(clipRRectFinder);
      expect(clipRRect.borderRadius, equals(radius));
    });

    testWidgets('renders child widget on top of pattern', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              height: 120,
              child: CentrodeContourPattern(
                child: Center(
                  child: Text('Overlay Content'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Overlay Content'), findsOneWidget);
      expect(findContourCustomPaint(), findsOneWidget);
    });

    test('ContourConfig copyWith preserves unmodified fields and updates specified ones', () {
      const original = ContourConfig(
        style: ContourStyle.topographic,
        layerCount: 5,
        amplitude: 0.25,
        frequency: 1.5,
        strokeWidth: 1.0,
      );

      final updated = original.copyWith(
        style: ContourStyle.flowingWaves,
        layerCount: 8,
        amplitude: 0.40,
      );

      expect(updated.style, equals(ContourStyle.flowingWaves));
      expect(updated.layerCount, equals(8));
      expect(updated.amplitude, equals(0.40));
      expect(updated.frequency, equals(1.5));
      expect(updated.strokeWidth, equals(1.0));
      expect(updated.origin, equals(original.origin));
    });

    test('ContourConfig equality and hashCode work correctly', () {
      const config1 = ContourConfig(seed: 123, layerCount: 4);
      const config2 = ContourConfig(seed: 123, layerCount: 4);
      const config3 = ContourConfig(seed: 456, layerCount: 4);

      expect(config1, equals(config2));
      expect(config1.hashCode, equals(config2.hashCode));
      expect(config1, isNot(equals(config3)));
    });
  });
}
