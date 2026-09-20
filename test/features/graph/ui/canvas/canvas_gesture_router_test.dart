import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:centrode/features/graph/ui/canvas/canvas_gesture_router.dart';
import 'package:centrode/features/graph/engine/interaction_engine.dart';
import 'package:centrode/features/graph/engine/interaction_context.dart';

class MockInteractionController extends Mock implements InteractionController {}

class MockInteractionContext extends Mock implements InteractionContext {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(const PointerDownEvent());
    registerFallbackValue(const PointerMoveEvent());
    registerFallbackValue(const PointerUpEvent());
    registerFallbackValue(const PointerCancelEvent());
    registerFallbackValue(const PointerHoverEvent());
  });

  late MockInteractionController mockInteraction;
  late ValueNotifier<Offset?> mousePositionNotifier;
  late ValueNotifier<MouseCursor> cursorNotifier;

  setUp(() {
    mockInteraction = MockInteractionController();
    mousePositionNotifier = ValueNotifier<Offset?>(null);
    cursorNotifier = ValueNotifier<MouseCursor>(SystemMouseCursors.basic);

    when(() => mockInteraction.cursor).thenReturn(cursorNotifier);
    when(() => mockInteraction.handlePointerDown(any())).thenReturn(null);
    when(() => mockInteraction.handlePointerMove(any())).thenReturn(null);
    when(() => mockInteraction.handlePointerUp(any())).thenReturn(null);
    when(() => mockInteraction.handlePointerCancel(any())).thenReturn(null);
    when(() => mockInteraction.handlePointerHover(any())).thenReturn(null);
  });

  tearDown(() {
    mousePositionNotifier.dispose();
    cursorNotifier.dispose();
  });

  group('CanvasGestureRouter Tests', () {
    testWidgets(
      'Right-click tap without drag triggers onContextMenuRequested',
      (tester) async {
        Offset? requestedContextPos;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CanvasGestureRouter(
                interactionController: mockInteraction,
                mousePositionNotifier: mousePositionNotifier,
                onContextMenuRequested: (pos) => requestedContextPos = pos,
                child: Container(
                  key: const Key('canvas_target'),
                  color: Colors.blue,
                  width: 500,
                  height: 500,
                ),
              ),
            ),
          ),
        );

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryMouseButton,
        );

        await gesture.down(const Offset(100, 100));
        verify(() => mockInteraction.handlePointerDown(any())).called(1);

        await gesture.up();
        verify(() => mockInteraction.handlePointerUp(any())).called(1);

        expect(requestedContextPos, const Offset(100, 100));
      },
    );

    testWidgets(
      'Right-click drag exceeding 5px threshold suppresses context menu',
      (tester) async {
        Offset? requestedContextPos;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CanvasGestureRouter(
                interactionController: mockInteraction,
                mousePositionNotifier: mousePositionNotifier,
                onContextMenuRequested: (pos) => requestedContextPos = pos,
                child: Container(color: Colors.blue, width: 500, height: 500),
              ),
            ),
          ),
        );

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
          buttons: kSecondaryMouseButton,
        );

        await gesture.down(const Offset(100, 100));
        // Move 10 pixels (greater than 5.0px threshold)
        await gesture.moveTo(const Offset(110, 100));
        await gesture.up();

        expect(requestedContextPos, isNull);
      },
    );

    testWidgets('PointerCancel resets right click tracking', (tester) async {
      Offset? requestedContextPos;
      bool hoverExited = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CanvasGestureRouter(
              interactionController: mockInteraction,
              mousePositionNotifier: mousePositionNotifier,
              onContextMenuRequested: (pos) => requestedContextPos = pos,
              onHoverExit: () => hoverExited = true,
              child: Container(color: Colors.blue, width: 500, height: 500),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );

      await gesture.down(const Offset(100, 100));
      await gesture.cancel();

      verify(() => mockInteraction.handlePointerCancel(any())).called(1);
      expect(requestedContextPos, isNull);
      expect(mousePositionNotifier.value, isNull);
      expect(hoverExited, isTrue);
    });
  });
}
