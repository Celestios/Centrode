import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart' as logging;
import 'package:mycelium/features/graph/models/models.dart';
import 'package:mycelium/src/rust/domain/nodes.dart';
import 'package:mycelium/features/graph/presentation/style_manager.dart';
import 'package:mycelium/features/graph/store/modules/graph_store.dart';
import 'package:mycelium/presentation/theme/graph_theme.dart';
import 'package:mycelium/shared/domain/raw_uuid.dart';

void main() {
  test('StyleManager should resolve style for DrawingUiNode without warning logs', () {
    final store = GraphStore();
    final styleManager = StyleManager(store);
    
    // Set a test theme
    styleManager.setTheme(const GraphTheme(
      id: RawUuid.fromString('test'),
      name: 'test',
      primaryColor: Color(0xFF123456),
      fontFamily: 'Roboto',
      bodyFontSize: 14.0,
      borderRadius: 8.0,
    ));

    // Create a DrawingUiNode
    final drawingNode = DrawingUiNode(
      id: RawUuid.fromString('drawing_node_1'),
      position: const Offset(10, 20),
      size: const Size(100, 100),
      brushType: BrushType.pencil,
      brushThickness: 2.0,
      brushColor: '#FF0000',
      paths: ['10,20;30,40'],
    );

    // Put it in the store
    store.nodeLookup[drawingNode.id] = drawingNode;

    // Set up a log listener to check for the unknown type warning
    final warnings = <String>[];
    final subscription = logging.Logger.root.onRecord.listen((record) {
      if (record.level >= logging.Level.WARNING) {
        warnings.add(record.message);
      }
    });

    try {
      styleManager.updateAllStyles([drawingNode], []);

      // Check if warnings were logged
      expect(warnings, isEmpty);
      
      // Check if resolvedStyle is correctly resolved
      expect(drawingNode.resolvedStyle, isNotNull);
      expect(drawingNode.resolvedStyle!.strategyType, equals('drawing'));
    } finally {
      subscription.cancel();
    }
  });
}
