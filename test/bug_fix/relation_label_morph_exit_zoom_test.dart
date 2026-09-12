import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:centrode/features/graph/store/graph_data_query.dart';
import 'package:centrode/features/graph/store/graph_data_command.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/shared/widgets/canvas_interactive_viewer.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/features/graph/models/models.dart';

class MockGraphDataQuery extends Mock implements GraphDataQuery {}
class MockGraphDataCommand extends Mock implements GraphDataCommand {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('CanvasInteractiveViewer scaleEnabled updates when activeEditId is cancelled', (tester) async {
    final query = MockGraphDataQuery();
    final command = MockGraphDataCommand();
    when(() => query.onEntityUpdate).thenAnswer((_) => const Stream.empty());
    when(() => query.nodeLookup).thenReturn(<RawUuid, UiNode>{});
    when(() => query.relationLookup).thenReturn(<RawUuid, UiRelation>{});
    when(() => query.relations).thenReturn(<UiRelation>[]);

    final renderState = NodeRenderState(query, command);
    final panScaleEnabled = ValueNotifier<bool>(true);
    final isTransitioning = ValueNotifier<bool>(false);
    final elasticMargins = ValueNotifier<EdgeInsets>(EdgeInsets.zero);
    final transformController = TransformationController();

    // Replicating the current structure in GraphCanvas (without ListenableBuilder on editorState)
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ValueListenableBuilder<EdgeInsets>(
            valueListenable: elasticMargins,
            builder: (context, margins, _) {
              return ValueListenableBuilder<bool>(
                valueListenable: panScaleEnabled,
                builder: (context, panScale, child) {
                  return ValueListenableBuilder<bool>(
                    valueListenable: isTransitioning,
                    builder: (context, transitioning, _) {
                      return ValueListenableBuilder<RawUuid?>(
                        valueListenable: renderState.activeEditIdNotifier,
                        builder: (context, activeEditId, _) {
                          final isEditing = activeEditId != null;
                          final viewerPanEnabled =
                              panScale &&
                              !isEditing &&
                              !transitioning;
                          return CanvasInteractiveViewer(
                            transformationController: transformController,
                            panEnabled: viewerPanEnabled,
                            scaleEnabled: viewerPanEnabled,
                            child: const SizedBox(width: 1000, height: 1000),
                          );
                        },
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );

    // Initial state: idle, not editing -> scaleEnabled should be true
    var viewer = tester.widget<CanvasInteractiveViewer>(find.byType(CanvasInteractiveViewer));
    expect(viewer.scaleEnabled, isTrue);

    // Enter edit mode (as happens when relation label morph editor opens)
    renderState.enterEditMode(RawUuid.fromString('00000000-0000-0000-0000-000000000001'));
    // Trigger a rebuild during edit (e.g. panScale transition or pointer event)
    panScaleEnabled.value = false;
    await tester.pump();
    panScaleEnabled.value = true;
    await tester.pump();

    viewer = tester.widget<CanvasInteractiveViewer>(find.byType(CanvasInteractiveViewer));
    expect(viewer.scaleEnabled, isFalse, reason: 'scaleEnabled should be false while editing');

    // Now user exits the relation label morph editor
    renderState.cancelActiveEdit();
    await tester.pump();

    // Verify whether viewer.scaleEnabled is restored!
    viewer = tester.widget<CanvasInteractiveViewer>(find.byType(CanvasInteractiveViewer));
    debugPrint('scaleEnabled after cancelActiveEdit: ${viewer.scaleEnabled}');
    expect(viewer.scaleEnabled, isTrue, reason: 'scaleEnabled MUST be restored to true after cancelActiveEdit without needing user clicks!');
  });
}
