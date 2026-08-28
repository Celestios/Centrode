import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/presentation/node_render_state.dart';
import 'package:centrode/features/graph/presentation/editor_state.dart';
import 'package:centrode/features/graph/presentation/relation_label_suggestion_controller.dart';
import 'package:centrode/features/graph/engine/interaction_context.dart';
import 'package:centrode/features/graph/ui/canvas/widgets/relation_label_morph_editor.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

class MockNodeRenderState extends Mock implements NodeRenderState {}
class MockEditorState extends Mock implements EditorState {}
class MockRelationLabelSuggestionController extends Mock
    implements RelationLabelSuggestionController {}
class MockInteractionContext extends Mock implements InteractionContext {}

void main() {
  testWidgets('RelationLabelMorphEditor renders without RenderFlex overflow and closes smoothly on outside tap',
      (tester) async {
    final mockUiController = MockNodeRenderState();
    final mockEditorState = MockEditorState();
    final mockSuggestionController = MockRelationLabelSuggestionController();
    final mockInteractionContext = MockInteractionContext();

    when(() => mockUiController.editorState).thenReturn(mockEditorState);
    when(() => mockSuggestionController.value).thenReturn(
      const RelationSuggestionState(
        language: 'en',
        contextualVerbs: ['causes', 'supports'],
        autocompleteVerbs: ['contradicts'],
        mapVerbs: {'leads_to': 2},
        flatList: ['causes', 'supports', 'contradicts', 'leads_to'],
      ),
    );

    final relation = InfoUiRelation(
      id: RawUuid.fromString('00000000-0000-0000-0000-000000000001'),
      fromNodeId: RawUuid.fromString('00000000-0000-0000-0000-000000000002'),
      fromNodeTable: 'INode',
      toNodeId: RawUuid.fromString('00000000-0000-0000-0000-000000000003'),
      toNodeTable: 'INode',
      verb: 'depends_on',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: Container(color: Colors.transparent),
              ),
              RelationLabelMorphEditor(
                relation: relation,
                labelCenter: const Offset(200, 200),
                suggestionController: mockSuggestionController,
                uiController: mockUiController,
                interactionContext: mockInteractionContext,
                onCommit: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    // Initial pump (collapsed state)
    expect(tester.takeException(), isNull);

    // Pump animation during expand
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);

    // Settle to expanded state
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget);

    // Tap outside (at top-left corner of canvas)
    await tester.tapAt(const Offset(10, 10));
    await tester.pump(); // Start closing animation

    // Verify closing animation is running smoothly without errors
    await tester.pump(const Duration(milliseconds: 100));
    expect(tester.takeException(), isNull);

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
