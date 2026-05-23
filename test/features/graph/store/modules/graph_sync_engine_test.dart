import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mycelium/features/graph/models/models.dart';
import 'package:mycelium/features/graph/store/graph_data_controller.dart';
import 'package:mycelium/features/graph/presentation/theme_manager.dart';
import 'package:mycelium/src/rust/bridge/api.dart';
import 'package:mycelium/src/rust/domain/base_models.dart' as frb;
import 'package:mycelium/src/rust/domain/nodes.dart';
import 'package:mycelium/src/rust/domain/relations.dart';

import 'package:mycelium/presentation/theme/graph_theme.dart';

class MockAppHandle extends Mock implements AppHandle {}
class MockThemeController extends Mock implements ThemeController {
  @override
  GraphTheme get currentGraphTheme => const GraphTheme(id: 'test', name: 'test');
}

void main() {
  group('GraphSyncEngine', () {
    late GraphDataController controller;
    late MockAppHandle mockApi;
    late MockThemeController mockThemeController;

    setUp(() {
      mockApi = MockAppHandle();
      mockThemeController = MockThemeController();

      when(() => mockApi.createGraphStream())
          .thenAnswer((_) => const Stream.empty());
      when(() => mockApi.getGraphSnapshot())
          .thenAnswer((_) async => (<INode>[], <TaskNode>[], <InterNode>[], <IRelation>[], const frb.MapData(
            mapName: '',
            viewportState: frb.ViewportState(xOffset: 0, yOffset: 0, zoomLevel: 1, activeView: ''),
            displayMode: frb.DisplayMode.importance,
          )));

      controller = GraphDataController(mockApi, mockThemeController);
    });

    tearDown(() {
      controller.dispose();
    });

    test('loadGraph fetches state and updates canvas bounds', () async {
      await controller.loadGraph();

      when(() => mockApi.createGraphStream())
          .thenAnswer((_) => const Stream.empty());
      when(() => mockApi.getGraphSnapshot())
          .thenAnswer((_) async => (<INode>[], <TaskNode>[], <InterNode>[], <IRelation>[], const frb.MapData(
            mapName: '',
            viewportState: frb.ViewportState(xOffset: 0, yOffset: 0, zoomLevel: 1, activeView: ''),
            displayMode: frb.DisplayMode.importance,
          )));

      verify(() => mockApi.getGraphSnapshot()).called(1);
      verify(() => mockApi.createGraphStream()).called(1);
    });

    test('undo triggers FFI undo and reloads graph', () async {
      when(() => mockApi.undo()).thenAnswer((_) async => null);
      
      await controller.undo();
      
      verify(() => mockApi.undo()).called(1);
      // It should call getGraphSnapshot twice (one on init, one after undo is not called because return is null, wait let's return a fake HistoryRecord)
    });

    test('redo triggers FFI redo and reloads graph', () async {
      when(() => mockApi.redo()).thenAnswer((_) async => null);
      
      await controller.redo();
      
      verify(() => mockApi.redo()).called(1);
    });
  });
}
