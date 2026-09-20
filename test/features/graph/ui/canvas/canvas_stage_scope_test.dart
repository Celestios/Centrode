import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:centrode/features/graph/ui/canvas/canvas_stage_scope.dart';
import 'package:centrode/features/graph/presentation/canvas_lifecycle_coordinator.dart';

class MockCanvasLifecycleCoordinator extends Mock
    implements CanvasLifecycleCoordinator {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCanvasLifecycleCoordinator mockCoordinator;

  setUpAll(() {
    registerFallbackValue(Size.zero);
  });

  setUp(() {
    mockCoordinator = MockCanvasLifecycleCoordinator();
    when(
      () => mockCoordinator.updateViewportDimensions(any()),
    ).thenReturn(null);
  });

  group('CanvasStageScope Tests', () {
    testWidgets(
      'Exposes CanvasStageData and notifies coordinator on initial layout',
      (tester) async {
        CanvasStageData? capturedData;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 800,
                  height: 600,
                  child: CanvasStageScope(
                    lifecycleCoordinator: mockCoordinator,
                    child: Builder(
                      builder: (context) {
                        capturedData = CanvasStageScope.of(context);
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump();

        expect(capturedData, isNotNull);
        expect(capturedData!.size, const Size(800, 600));
        verify(
          () => mockCoordinator.updateViewportDimensions(const Size(800, 600)),
        ).called(1);
      },
    );

    testWidgets(
      'Does not re-notify coordinator if layout constraints do not change',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 800,
                  height: 600,
                  child: CanvasStageScope(
                    lifecycleCoordinator: mockCoordinator,
                    child: const SizedBox(),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        verify(
          () => mockCoordinator.updateViewportDimensions(const Size(800, 600)),
        ).called(1);

        // Re-pump widget with identical dimensions
        await tester.pump();
        verifyNever(() => mockCoordinator.updateViewportDimensions(any()));
      },
    );
  });
}
