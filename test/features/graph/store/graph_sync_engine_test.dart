import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mycelium/features/graph/store/modules/graph_sync_engine.dart';
import 'package:mycelium/features/graph/store/command_queue_processor.dart';
import 'package:mycelium/features/graph/store/command_processor.dart';
import 'package:mycelium/features/graph/store/graph_api.dart';

class MockCommandQueueProcessor extends Mock implements CommandQueueProcessor {}
class MockGraphApi extends Mock implements GraphApi {}
class MockCommandProcessor extends Mock implements CommandProcessor {}

void main() {
  group('GraphSyncEngine', () {
    late MockCommandQueueProcessor mockController;
    late MockGraphApi mockApi;
    late MockCommandProcessor mockProcessor;
    late GraphSyncEngine syncEngine;

    setUp(() {
      mockController = MockCommandQueueProcessor();
      mockApi = MockGraphApi();
      mockProcessor = MockCommandProcessor();

      syncEngine = GraphSyncEngine(
        controller: mockController,
        api: mockApi,
        processor: mockProcessor,
      );
    });

    test('initial savedViewportState returns null when no metadata is loaded', () {
      expect(syncEngine.savedViewportState, isNull);
    });

    test('canvasBounds has default initial values', () {
      expect(syncEngine.canvasBounds.minX, -500);
      expect(syncEngine.canvasBounds.maxX, 500);
    });
  });
}
