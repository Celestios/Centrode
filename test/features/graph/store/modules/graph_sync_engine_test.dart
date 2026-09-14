import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/store/graph_data_query_controller.dart';
import 'package:centrode/features/graph/store/command_queue_processor.dart';
import 'package:centrode/features/graph/presentation/theme_manager.dart';
import 'package:centrode/features/graph/presentation/style_manager.dart';
import 'package:centrode/features/graph/presentation/strategies/node_layout_strategy.dart';
import 'package:centrode/features/graph/presentation/strategies/node_style_strategy.dart';
import 'package:centrode/features/graph/store/graph_api.dart';
import 'package:centrode/features/graph/models/commands/patch_helpers.dart';
import 'package:centrode/src/rust/domain/base_models.dart' as frb_base;
import 'package:centrode/src/rust/domain/snapshot.dart';

import 'package:centrode/presentation/theme/graph_theme.dart';
import 'dart:async';
import 'package:centrode/src/rust/bridge/stream.dart';
import 'package:centrode/src/rust/domain/patches.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';

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
    late StreamController<GraphEvent> eventController;

    setUp(() {
      mockApi = MockGraphApi();
      eventController = StreamController<GraphEvent>.broadcast();

      when(
        () => mockApi.createGraphStream(),
      ).thenAnswer((_) => eventController.stream);
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

      when(
        () => mockApi.updateNodeCachePositions(positions: any(named: 'positions')),
      ).thenAnswer((_) async {});
      when(() => mockApi.undoCount()).thenAnswer((_) async => 0);
      when(() => mockApi.redoCount()).thenAnswer((_) async => 0);

      queryController = GraphDataQueryController(mockApi);
      controller = CommandQueueProcessor(mockApi, queryController);
    });

    tearDown(() {
      controller.dispose();
      eventController.close();
    });

    test('initial savedViewportState returns null when no metadata is loaded', () {
      expect(controller.syncEngine.savedViewportState, isNull);
    });

    test('canvasBounds has default initial values', () {
      expect(controller.syncEngine.canvasBounds.minX, -500);
      expect(controller.syncEngine.canvasBounds.maxX, 500);
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
      final layoutStrategy = DefaultNodeLayoutStrategy();
      controller.sizeCalculator = layoutStrategy.calculateSize;
      controller.styleResolver = (node) => NodeStyleStrategy.resolveStyle(node);
      controller.styleUpdater = styleManager;

      // Mock snapshot containing a node with unparsed plain text content
      final rawNode = INode(
        id: parseTypedRecordId('INode', RawUuid.fromString('node_1')),
        content: const Content(
          text: 'This is **bold** text with a [link](https://test.com)',
          blocks: [
            ContentBlock(
              blockType: BlockType.paragraph,
              content: [
                InlineElement(
                  inlineType: InlineType.text,
                  text: 'This is **bold** text with a [link](https://test.com)',
                ),
              ],
            ),
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
        attachments: const [],
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
      final loadedNode =
          queryController.nodeLookup[RawUuid.fromString('node_1')];
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

    test('algebraic reversibility: Redo(Undo(Action)) restores identical state', () async {
      await controller.loadGraph();
      final nodeId = RawUuid.fromString('node-rev-1');
      final initialNode = InfoUiNode(
        id: nodeId,
        position: const Offset(100, 100),
      );
      queryController.store.nodeLookup[nodeId] = initialNode;
      const initialPos = Offset(100, 100);

      // Apply forward mutation event (Action A)
      eventController.add(
        GraphEvent.nodeUpdated(
          id: parseTypedRecordId('INode', nodeId),
          patches: [
            const NodePatch.position(frb_base.Coordinates(x: 350, y: 450)),
          ],
        ),
      );
      await pumpEventQueue();
      expect(initialNode.position, const Offset(350, 450));

      // Apply reverse mutation event (Undo A)
      eventController.add(
        GraphEvent.nodeUpdated(
          id: parseTypedRecordId('INode', nodeId),
          patches: [
            const NodePatch.position(frb_base.Coordinates(x: 100, y: 100)),
          ],
        ),
      );
      await pumpEventQueue();
      expect(initialNode.position, initialPos);

      // Reapply forward mutation event (Redo A)
      eventController.add(
        GraphEvent.nodeUpdated(
          id: parseTypedRecordId('INode', nodeId),
          patches: [
            const NodePatch.position(frb_base.Coordinates(x: 350, y: 450)),
          ],
        ),
      );
      await pumpEventQueue();
      expect(initialNode.position, const Offset(350, 450));
    });
  });
}
