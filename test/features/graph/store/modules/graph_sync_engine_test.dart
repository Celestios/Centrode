import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mycelium/features/graph/models/models.dart';
import 'package:mycelium/features/graph/store/graph_data_query_controller.dart';
import 'package:mycelium/features/graph/store/command_queue_processor.dart';
import 'package:mycelium/features/graph/presentation/theme_manager.dart';
import 'package:mycelium/features/graph/presentation/style_manager.dart';
import 'package:mycelium/features/graph/presentation/strategies/node_layout_strategy.dart';
import 'package:mycelium/features/graph/presentation/strategies/node_style_strategy.dart';
import 'package:mycelium/features/graph/store/graph_api.dart';
import 'package:mycelium/features/graph/models/commands/patch_helpers.dart';
import 'package:mycelium/src/rust/domain/base_models.dart' as frb_base;
import 'package:mycelium/src/rust/domain/snapshot.dart';

import 'package:mycelium/presentation/theme/graph_theme.dart';

class MockGraphApi extends Mock implements GraphApi {}

class MockThemeController extends Mock implements ThemeController {
  @override
  GraphTheme get currentGraphTheme =>
      const GraphTheme(id: 'test', name: 'test');
}

void main() {
  group('GraphSyncEngine', () {
    late CommandQueueProcessor controller;
    late GraphDataQueryController queryController;
    late MockGraphApi mockApi;

    setUp(() {
      mockApi = MockGraphApi();

      when(
        () => mockApi.createGraphStream(),
      ).thenAnswer((_) => const Stream.empty());
      when(() => mockApi.getGraphSnapshot()).thenAnswer(
        (_) async => GraphSnapshot(
          nodes: [],
          relations: [],
          metadata: const MapData(
            mapName: '',
            viewportState: frb_base.ViewportState(
              xOffset: 0,
              yOffset: 0,
              zoomLevel: 1,
              activeView: '',
            ),
            displayMode: frb_base.DisplayMode.importance,
          ),
        ),
      );

      queryController = GraphDataQueryController(mockApi);
      controller = CommandQueueProcessor(mockApi, queryController);
    });

    tearDown(() {
      controller.dispose();
    });

    test('loadGraph fetches state and updates canvas bounds', () async {
      await controller.loadGraph();

      when(
        () => mockApi.createGraphStream(),
      ).thenAnswer((_) => const Stream.empty());
      when(() => mockApi.getGraphSnapshot()).thenAnswer(
        (_) async => GraphSnapshot(
          nodes: [],
          relations: [],
          metadata: MapData(
            mapName: '',
            viewportState: frb_base.ViewportState(
              xOffset: 0,
              yOffset: 0,
              zoomLevel: 1,
              activeView: '',
            ),
            displayMode: frb_base.DisplayMode.importance,
          ),
        ),
      );

      verify(() => mockApi.getGraphSnapshot()).called(1);
      verify(() => mockApi.createGraphStream()).called(1);
    });

    test('loadGraph hydrates node formatting and layout size', () async {
      // Configure style, resolver, and size calculator on controller
      final styleManager = StyleManager(queryController.store);
      styleManager.setTheme(const GraphTheme(id: 'test', name: 'test'));
      controller.sizeCalculator = NodeLayoutStrategy.calculateSize;
      controller.styleResolver = (node) => NodeStyleStrategy.resolveStyle(node);
      controller.styleUpdater = styleManager;

      // Mock snapshot containing a node with unparsed plain text content
      final rawNode = INode(
        id: parseTypedRecordId('INode', 'node_1'),
        content: const Content(
          text: 'This is **bold** text with a [link](https://test.com)',
          blocks: [
            ContentBlock(
              blockType: BlockType.paragraph,
              content: [
                InlineElement(
                  inlineType: InlineType.text,
                  text: 'This is **bold** text with a [link](https://test.com)',
                )
              ],
            )
          ],
        ),
        layer: 'default',
        position: const frb_base.Coordinates(x: 100, y: 100),
        size: const frb_base.Size(width: 100, height: 80),
        expandable: false,
        isExpanded: false,
        locked: false,
        tags: const [],
        aliases: const [],
        comments: const [],
        significance: 0,
        createdAt: 0,
        updatedAt: 0,
        lineCount: 1,
      );

      when(
        () => mockApi.createGraphStream(),
      ).thenAnswer((_) => const Stream.empty());
      when(() => mockApi.getGraphSnapshot()).thenAnswer(
        (_) async => GraphSnapshot(
          nodes: [Nodes.iNode(rawNode)],
          relations: const [],
          metadata: MapData(
            mapName: '',
            viewportState: frb_base.ViewportState(
              xOffset: 0,
              yOffset: 0,
              zoomLevel: 1,
              activeView: '',
            ),
            displayMode: frb_base.DisplayMode.importance,
          ),
        ),
      );

      await controller.loadGraph();

      // Verify node loaded
      final loadedNode = queryController.nodeLookup['node_1'];
      expect(loadedNode, isNotNull);

      // Verify content blocks are hydrated (markdown parsed)
      final blocks = loadedNode!.content.blocks;
      expect(blocks, isNotEmpty);
      expect(blocks[0].content.length, greaterThan(1));

      final boldInline = blocks[0].content.firstWhere((i) => i.text == 'bold');
      expect(boldInline.marks, isNotNull);
      expect(boldInline.marks!.any((m) => m.markType == MarkType.bold), isTrue);

      // Verify styles are resolved and layout is calculated
      expect(loadedNode.resolvedStyle, isNotNull);
      expect(loadedNode.size, isNot(const Size(100, 80)));
    });

    test('undo triggers FFI undo and reloads graph', () async {
      when(() => mockApi.undo()).thenAnswer((_) async => null);

      await controller.undo();

      verify(() => mockApi.undo()).called(1);
    });

    test('redo triggers FFI redo and reloads graph', () async {
      when(() => mockApi.redo()).thenAnswer((_) async => null);

      await controller.redo();

      verify(() => mockApi.redo()).called(1);
    });
  });
}
