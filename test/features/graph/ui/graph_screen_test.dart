import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mycelium/features/graph/ui/graph_screen.dart';
import 'package:mycelium/features/graph/presentation/workspace_tabs_controller.dart';
import 'package:mycelium/features/graph/presentation/theme_manager.dart';
import 'package:mycelium/features/graph/store/graph_data_query_controller.dart';
import 'package:mycelium/features/graph/store/command_queue_processor.dart';
import 'package:mycelium/features/graph/presentation/node_render_state.dart';
import 'package:mycelium/presentation/theme/graph_theme.dart';

class MockWorkspaceTabsController extends Mock implements WorkspaceTabsController {}
class MockTabSession extends Mock implements TabSession {}
class MockThemeController extends Mock implements ThemeController {}
class MockGraphDataQueryController extends Mock implements GraphDataQueryController {}
class MockCommandQueueProcessor extends Mock implements CommandQueueProcessor {}
class MockNodeRenderState extends Mock implements NodeRenderState {}

void main() {
  setUpAll(() {
    registerFallbackValue(ThemeData.dark());
  });

  testWidgets('GraphScreen renders without crashing', (
    WidgetTester tester,
  ) async {
    final mockTabsController = MockWorkspaceTabsController();
    final mockSession = MockTabSession();
    final mockTheme = MockThemeController();
    final mockQuery = MockGraphDataQueryController();
    final mockCommand = MockCommandQueueProcessor();
    final mockRenderState = MockNodeRenderState();

    // Stub session properties
    when(() => mockSession.id).thenReturn('test-session');
    when(() => mockSession.storagePath).thenReturn('');
    when(() => mockSession.name).thenReturn('Test Map');
    when(() => mockSession.isInitialized).thenReturn(true);
    when(() => mockSession.themeController).thenReturn(mockTheme);
    when(() => mockSession.queryController).thenReturn(mockQuery);
    when(() => mockSession.commandProcessor).thenReturn(mockCommand);
    when(() => mockSession.nodeRenderState).thenReturn(mockRenderState);
    when(() => mockSession.toolModeNotifier).thenReturn(ValueNotifier<String>('select'));
    when(() => mockSession.brushColorNotifier).thenReturn(ValueNotifier<String>('#00E5FF'));
    when(() => mockSession.brushThicknessNotifier).thenReturn(ValueNotifier<double>(4.0));
    when(() => mockSession.brushTypeNotifier).thenReturn(ValueNotifier<String>('pen'));
    when(() => mockSession.showLeftPanel).thenReturn(ValueNotifier<bool>(true));
    when(() => mockSession.showRightPanel).thenReturn(ValueNotifier<bool>(true));
    when(() => mockSession.showBottomPanel).thenReturn(ValueNotifier<bool>(false));
    when(() => mockSession.initialize(any())).thenAnswer((_) async {});
    when(() => mockSession.addListener(any())).thenAnswer((_) {});
    when(() => mockSession.removeListener(any())).thenAnswer((_) {});

    // Stub tabsController properties
    when(() => mockTabsController.tabs).thenReturn([mockSession]);
    when(() => mockTabsController.activeIndex).thenReturn(0);
    when(() => mockTabsController.activeSession).thenReturn(mockSession);
    when(() => mockTabsController.notifierName).thenReturn('WorkspaceTabsController');
    when(() => mockTabsController.addListener(any())).thenAnswer((_) {});
    when(() => mockTabsController.removeListener(any())).thenAnswer((_) {});

    // Stub theme properties
    when(() => mockTheme.currentGraphTheme).thenReturn(const GraphTheme(id: 'test', name: 'test'));
    when(() => mockTheme.addListener(any())).thenAnswer((_) {});
    when(() => mockTheme.removeListener(any())).thenAnswer((_) {});

    // Stub query controller streams/lookups
    when(() => mockQuery.onEntityUpdate).thenAnswer((_) => const Stream.empty());
    when(() => mockQuery.relations).thenReturn([]);
    when(() => mockQuery.nodeLookup).thenReturn({});
    when(() => mockQuery.relationLookup).thenReturn({});
    when(() => mockQuery.isLoading).thenReturn(false);
    when(() => mockQuery.errorMessage).thenReturn(null);

    await tester.pumpWidget(
      MaterialApp(
        home: GraphScreen(
          storagePath: '',
          tabsController: mockTabsController,
        ),
      ),
    );

    expect(find.byType(Scaffold), findsWidgets);
  });
}
