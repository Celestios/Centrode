import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'package:centrode/features/graph/models/models.dart';
import 'package:centrode/features/graph/models/node_style_resolver.dart';

void main() {
  group('node_style_resolver tests', () {
    test('fallbackStyle returns default rectangle style with expected font', () {
      final style = fallbackStyle(120.0, 80.0, 14.0);
      expect(style.width, 120);
      expect(style.height, 80);
      expect(style.fontSize, 14.0);
      expect(style.fontFamily, 'Inter');
      expect(style.shape, 'rectangle');
    });

    test('scaleStyle computes proportional padding and strokeWidth', () {
      final base = fallbackStyle(100.0, 80.0, 28.0); // 2x reference scale
      final scaled = scaleStyle(base);
      expect(scaled.strokeWidth, 2);
      expect(scaled.borderRadius, 16.0);
    });

    test('resolveStyle assigns drawing style for DrawingUiNode', () {
      final drawingNode = DrawingUiNode(
        id: RawUuid.v4(),
        position: const Offset(10, 10),
        brushType: BrushType.pencil,
        brushThickness: 2.0,
        brushColor: '#000000',
      );
      final style = resolveStyle(drawingNode);
      expect(style.strategyType, 'drawing');
      expect(style.bgColor, 0x00000000);
      expect(style.strokeColor, 0x00000000);
    });

    test('resolveStyle assigns container styling for ContainerUiNode', () {
      final containerNode = ContainerUiNode(
        id: RawUuid.v4(),
        title: 'Container 1',
        position: const Offset(100, 100),
        size: const Size(400, 300),
        isClosed: true,
        childCount: 0,
      );
      final style = resolveStyle(containerNode);
      expect(style.bgColor, 0x1A2196F3);
      expect(style.strokeColor, 0xFF64B5F6);
      expect(style.textColor, 0xFFFFFFFF);
    });
  });
}
