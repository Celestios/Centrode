import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:centrode/features/graph/engine/base_interaction_state.dart';
import 'package:centrode/features/graph/engine/interaction_context.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/presentation/view_state.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

class MockGeometryAndViewportCapability extends Mock
    implements GeometryAndViewportCapability {}

void main() {
  setUpAll(() {
    registerFallbackValue(Offset.zero);
    registerFallbackValue(RawUuid.fromString('fallback-id'));
  });

  group('NodeDragging continuous movement and pause snapping', () {
    late MockGeometryAndViewportCapability mockCtx;
    late RawUuid nodeId;
    late NodeViewState viewState;

    setUp(() {
      mockCtx = MockGeometryAndViewportCapability();
      nodeId = RawUuid.fromString('node-1');
      final node = InfoUiNode(
        id: nodeId,
        position: const Offset(100, 100),
        size: const Size(80, 40),
      );
      viewState = NodeViewState(node);

      when(() => mockCtx.nodeViewStates).thenReturn({nodeId: viewState});
      when(() => mockCtx.currentScale).thenReturn(1.0);
      when(() => mockCtx.viewportSize).thenReturn(const Size(1000, 800));
      when(() => mockCtx.panViewport(any())).thenReturn(null);
      when(() => mockCtx.screenToCanvas(any()))
          .thenAnswer((i) => i.positionalArguments.first as Offset);
      when(() => mockCtx.setNodeDragging(nodeId, any())).thenReturn(null);
      when(() => mockCtx.onNodesDrag(any())).thenReturn(null);
      when(() => mockCtx.onNodeMove(any(), any())).thenReturn(null);
    });

    test(
      'updates position continuously and sends quantized updates during move',
      () {
        final state = NodeDragging(nodeId, Offset.zero);

        // Move to unquantized canvas position (107.4, 113.8)
        final event = PointerMoveEvent(position: const Offset(107.4, 113.8));
        state.handlePointerMove(event, const Offset(107.4, 113.8), mockCtx);

        // Node view state positionNotifier should reflect continuous raw position
        expect(viewState.positionNotifier.value, const Offset(107.4, 113.8));

        // onNodesDrag should receive quantized position (100.0, 120.0) for grid baseSize=20
        verify(
          () => mockCtx.onNodesDrag(
            any(
              that: predicate<List<(RawUuid, Offset)>>((list) {
                return list.length == 1 &&
                    list.first.$1 == nodeId &&
                    list.first.$2 == const Offset(120.0, 120.0);
              }),
            ),
          ),
        ).called(1);
      },
    );

    testWidgets('snaps position to grid when movement pauses for snapPauseMs', (
      tester,
    ) async {
      final state = NodeDragging(nodeId, Offset.zero);

      final event = PointerMoveEvent(position: const Offset(107.4, 113.8));
      state.handlePointerMove(event, const Offset(107.4, 113.8), mockCtx);

      expect(viewState.positionNotifier.value, const Offset(107.4, 113.8));

      // Fast-forward 150ms to trigger pause snap timer
      await tester.pump(const Duration(milliseconds: 150));

      // Now view state position should be snapped to grid (100.0, 120.0)
      expect(viewState.positionNotifier.value, const Offset(120.0, 120.0));
    });

    test('snaps final position and commits on handlePointerUp', () {
      final state = NodeDragging(nodeId, Offset.zero);

      final event = PointerMoveEvent(position: const Offset(107.4, 113.8));
      state.handlePointerMove(event, const Offset(107.4, 113.8), mockCtx);

      final upEvent = PointerUpEvent(position: const Offset(107.4, 113.8));
      state.handlePointerUp(upEvent, mockCtx);

      // Final position in viewState should be snapped to (100.0, 120.0)
      expect(viewState.positionNotifier.value, const Offset(120.0, 120.0));

      // onNodeMove committed with final snapped position
      verify(
        () => mockCtx.onNodeMove(nodeId, const Offset(120.0, 120.0)),
      ).called(1);
    });
  });

  group('GroupDragging continuous movement and pause snapping', () {
    late MockGeometryAndViewportCapability mockCtx;
    late RawUuid anchorId;
    late RawUuid otherId;
    late NodeViewState anchorVs;
    late NodeViewState otherVs;

    setUp(() {
      mockCtx = MockGeometryAndViewportCapability();
      anchorId = RawUuid.fromString('anchor-node');
      otherId = RawUuid.fromString('other-node');

      final anchorNode = InfoUiNode(
        id: anchorId,
        position: const Offset(100, 100),
        size: const Size(80, 40),
      );
      final otherNode = InfoUiNode(
        id: otherId,
        position: const Offset(200, 100),
        size: const Size(80, 40),
      );

      anchorVs = NodeViewState(anchorNode);
      otherVs = NodeViewState(otherNode);

      when(
        () => mockCtx.nodeViewStates,
      ).thenReturn({anchorId: anchorVs, otherId: otherVs});
      when(() => mockCtx.currentScale).thenReturn(1.0);
      when(() => mockCtx.viewportSize).thenReturn(const Size(1000, 800));
      when(() => mockCtx.panViewport(any())).thenReturn(null);
      when(() => mockCtx.screenToCanvas(any()))
          .thenAnswer((i) => i.positionalArguments.first as Offset);
      when(() => mockCtx.setNodeDragging(any(), any())).thenReturn(null);
      when(() => mockCtx.onNodesDrag(any())).thenReturn(null);
      when(() => mockCtx.onNodeMove(any(), any())).thenReturn(null);
    });

    test('updates group positions continuously on handlePointerMove', () {
      final originalPositions = {
        anchorId: const Offset(100, 100),
        otherId: const Offset(200, 100),
      };
      final state = GroupDragging(
        nodeIds: [anchorId, otherId],
        anchorNodeId: anchorId,
        grabOffset: Offset.zero,
        originalPositions: originalPositions,
      );

      final event = PointerMoveEvent(position: const Offset(107.4, 113.8));
      state.handlePointerMove(event, const Offset(107.4, 113.8), mockCtx);

      // Raw positions offset by delta (7.4, 13.8)
      expect(anchorVs.positionNotifier.value, const Offset(107.4, 113.8));
      expect(otherVs.positionNotifier.value, const Offset(207.4, 113.8));
    });

    testWidgets('snaps group positions on pause timer', (tester) async {
      final originalPositions = {
        anchorId: const Offset(100, 100),
        otherId: const Offset(200, 100),
      };
      final state = GroupDragging(
        nodeIds: [anchorId, otherId],
        anchorNodeId: anchorId,
        grabOffset: Offset.zero,
        originalPositions: originalPositions,
      );

      final event = PointerMoveEvent(position: const Offset(107.4, 113.8));
      state.handlePointerMove(event, const Offset(107.4, 113.8), mockCtx);

      await tester.pump(const Duration(milliseconds: 150));

      expect(anchorVs.positionNotifier.value, const Offset(120.0, 120.0));
      expect(otherVs.positionNotifier.value, const Offset(240.0, 120.0));
    });
  });

  group('AutoPanManager camera follow calculations', () {
    const viewportSize = Size(1000, 800);

    test('returns zero delta for pointer in central canvas region', () {
      final delta = AutoPanManager.calculatePanDelta(
        const Offset(500, 400),
        viewportSize,
      );
      expect(delta, Offset.zero);
    });

    test('calculates correct pan delta for right edge threshold', () {
      final delta = AutoPanManager.calculatePanDelta(
        const Offset(980, 400),
        viewportSize,
      );
      expect(delta.dx, lessThan(0));
      expect(delta.dy, equals(0));
    });

    test('calculates correct pan delta for left edge threshold', () {
      final delta = AutoPanManager.calculatePanDelta(
        const Offset(20, 400),
        viewportSize,
      );
      expect(delta.dx, greaterThan(0));
      expect(delta.dy, equals(0));
    });

    test('calculates correct pan delta for bottom edge threshold', () {
      final delta = AutoPanManager.calculatePanDelta(
        const Offset(500, 780),
        viewportSize,
      );
      expect(delta.dx, equals(0));
      expect(delta.dy, lessThan(0));
    });

    test('calculates correct pan delta for top edge threshold', () {
      final delta = AutoPanManager.calculatePanDelta(
        const Offset(500, 20),
        viewportSize,
      );
      expect(delta.dx, equals(0));
      expect(delta.dy, greaterThan(0));
    });
  });
}
