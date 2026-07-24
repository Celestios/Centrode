import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mycelium/features/graph/ui/canvas/text/canvas_text_editor.dart';
import 'package:mycelium/features/graph/models/models.dart';
import 'package:mycelium/features/graph/presentation/node_render_state.dart';
import 'package:mycelium/shared/domain/raw_uuid.dart';

class MockNodeRenderState extends Mock
    with ChangeNotifier
    implements NodeRenderState {
  @override
  RawUuid? get activeEditId => 'test-node-1';

  @override
  final ValueNotifier<TextSelection?> activeTextSelectionNotifier = ValueNotifier(null);

  @override
  final ValueNotifier<TextAlign> currentTextAlignNotifier = ValueNotifier(TextAlign.center);
}

void main() {
  setUpAll(() {
    registerFallbackValue(const Content(text: '', blocks: []));
  });

  testWidgets('CanvasTextEditor inserts tab when Tab key is pressed', (
    WidgetTester tester,
  ) async {
    final mockRenderState = MockNodeRenderState();
    
    // Stub callbacks
    mockRenderState.applyFormatCallback = null;
    mockRenderState.toggleHeadingCallback = null;
    mockRenderState.clearBlockFormatCallback = null;

    when(() => mockRenderState.updateActiveTextSelection(any())).thenReturn(null);
    when(() => mockRenderState.updateEntityTextLive(any(), any())).thenReturn(null);

    final initialContent = ContentFactory.fromText('Hello');

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChangeNotifierProvider<NodeRenderState>.value(
            value: mockRenderState,
            child: CanvasTextEditor(
              entityId: 'test-node-1',
              content: initialContent,
              textStyle: const TextStyle(),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify it focuses and has text Hello
    final editableTextFinder = find.byType(EditableText);
    expect(editableTextFinder, findsOneWidget);

    final EditableTextState state = tester.state(editableTextFinder);
    expect(state.widget.controller.text, equals('Hello'));

    // Press Tab
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();

    // The Tab should be inserted at the cursor position (starts selected, so it replaces the whole text)
    expect(state.widget.controller.text, equals('    '));
  });
}
