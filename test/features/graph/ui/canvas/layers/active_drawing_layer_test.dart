import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:centrode/features/graph/ui/canvas/layers/active_drawing_layer.dart';
import 'package:centrode/features/graph/ui/canvas/painters/active_drawing_painter.dart';
import 'package:centrode/features/graph/presentation/workspace_tabs_controller.dart';
import 'package:centrode/features/graph/engine/drawing_interceptor.dart';

class MockTabSession extends Mock implements TabSession {}

class MockDrawingGestureInterceptor extends Mock
    implements DrawingGestureInterceptor {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockTabSession mockSession;
  late MockDrawingGestureInterceptor mockInterceptor;
  late ValueNotifier<List<Offset>> activeStrokeNotifier;
  late ValueNotifier<String> brushColorNotifier;
  late ValueNotifier<double> brushThicknessNotifier;
  late ValueNotifier<String> brushTypeNotifier;

  setUp(() {
    mockSession = MockTabSession();
    mockInterceptor = MockDrawingGestureInterceptor();

    activeStrokeNotifier = ValueNotifier<List<Offset>>([]);
    brushColorNotifier = ValueNotifier<String>('#00E5FF');
    brushThicknessNotifier = ValueNotifier<double>(4.0);
    brushTypeNotifier = ValueNotifier<String>('pen');

    when(() => mockInterceptor.activeStroke).thenReturn(activeStrokeNotifier);
    when(() => mockSession.brushColorNotifier).thenReturn(brushColorNotifier);
    when(
      () => mockSession.brushThicknessNotifier,
    ).thenReturn(brushThicknessNotifier);
    when(() => mockSession.brushTypeNotifier).thenReturn(brushTypeNotifier);
  });

  tearDown(() {
    activeStrokeNotifier.dispose();
    brushColorNotifier.dispose();
    brushThicknessNotifier.dispose();
    brushTypeNotifier.dispose();
  });

  group('ActiveDrawingLayer Tests', () {
    testWidgets('Renders empty when stroke is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActiveDrawingLayer(
              drawingInterceptor: mockInterceptor,
              session: mockSession,
            ),
          ),
        ),
      );

      final finder = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is ActiveDrawingPainter,
      );
      expect(finder, findsNothing);
    });

    testWidgets(
      'Renders CustomPaint with ActiveDrawingPainter when stroke is present',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ActiveDrawingLayer(
                drawingInterceptor: mockInterceptor,
                session: mockSession,
              ),
            ),
          ),
        );

        activeStrokeNotifier.value = [
          const Offset(10, 10),
          const Offset(20, 20),
        ];
        await tester.pump();

        final finder = find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is ActiveDrawingPainter,
        );
        expect(finder, findsOneWidget);
        expect(find.byType(RepaintBoundary), findsWidgets);
        expect(find.byType(IgnorePointer), findsWidgets);

        final customPaint = tester.widget<CustomPaint>(finder);
        final painter = customPaint.painter as ActiveDrawingPainter;
        expect(painter.brushColor, '#00E5FF');
        expect(painter.brushThickness, 4.0);
      },
    );

    testWidgets('Updates painter when brush color or thickness changes', (
      tester,
    ) async {
      activeStrokeNotifier.value = [const Offset(10, 10), const Offset(20, 20)];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActiveDrawingLayer(
              drawingInterceptor: mockInterceptor,
              session: mockSession,
            ),
          ),
        ),
      );

      brushColorNotifier.value = '#FF0055';
      brushThicknessNotifier.value = 8.0;
      await tester.pump();

      final finder = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is ActiveDrawingPainter,
      );
      final customPaint = tester.widget<CustomPaint>(finder);
      final painter = customPaint.painter as ActiveDrawingPainter;
      expect(painter.brushColor, '#FF0055');
      expect(painter.brushThickness, 8.0);
    });
  });
}
