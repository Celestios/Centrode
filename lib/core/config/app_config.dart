import 'package:flutter/material.dart';

/// Centralized Single Source of Truth for all Flutter-side magic numbers.
/// Uses static const for compile-time optimization and zero runtime overhead.
abstract class AppConfig {
  static const core = _CoreConfig();
  static const graph = _GraphConfig();

  // Static const values for use in default parameters (compile-time constants)
  static const String defaultFont = 'Inter';
  static const String defaultShape = 'rectangle';
  static const String circleShape = 'circle';
}

class _CoreConfig {
  const _CoreConfig();
  final String dbSeparator = ':';
  final String unknownId = 'unknown';
  final String tempIdPrefix = 'temp_';
}

class _SchemaConfig {
  const _SchemaConfig();
  final String infoTable = 'inode';
  final String taskTable = 'task_node';
  final String interTable = 'inter_node';
  final String themeTable = 'theme';
}

class _GraphConfig {
  const _GraphConfig();

  final canvas = const _CanvasConfig();
  final interaction = const _InteractionConfig();
  final node = const _NodeConfig();
  final toolbar = const _ToolbarConfig();
  final visual = const _VisualConfig();
  final relation = const _RelationConfig();
  final editor = const _EditorConfig();
  final schema = const _SchemaConfig();
}

class _CanvasConfig {
  const _CanvasConfig();
  final double boundaryMargin = 1000.0;
  final double minScale = 0.1;
  final double maxScale = 5.0;
  final double initialSize = 5000.0;
  final double overscanRatio = 0.25; // 25% inflation for culling buffer
}

class _InteractionConfig {
  const _InteractionConfig();
  final int doubleTapMs = 300;
  final double doubleTapDistance = 20.0;
  final double snapDistance = 40.0;
  final double portHitArea = 30.0;
  final double resizeEdgeWidth = 15.0;
  final Size relationLabelHitArea = const Size(100, 40);
}

class _NodeConfig {
  const _NodeConfig();
  final double defaultWidth = 150.0;
  final double minWidth = 80.0;
  final double resizeHandleVisualWidth = 10.0;
  final int collapsedLineLimit = 3;
  final Size defaultSize = const Size(100, 60);
  final Offset editorOffset = const Offset(8, 25);
}

class _ToolbarConfig {
  const _ToolbarConfig();
  final double singleWidth = 80.0;
  final double multiWidth = 100.0;
  final double height = 36.0;
  final Offset singleOffset = const Offset(10, -46);
  final Offset multiOffset = const Offset(0, 40);
}

class _VisualConfig {
  const _VisualConfig();
  final Color selectionAccent = const Color(0xFF42A5F5);
  final Color defaultInfoBg = const Color(0xFFBBDEFB);
  final Color defaultTaskBg = const Color(0xFFC8E6C9);
  final Color defaultInterBg = const Color(0xFFFFF9C4);
  final String defaultFont = 'Inter';
  final String defaultShape = 'rectangle';
  final String circleShape = 'circle';
}

class _RelationConfig {
  const _RelationConfig();
  final double strokeWidth = 1.5;
  final double selectedStrokeWidth = 3.0;
  final double labelFontSize = 10.0;
  final Offset startFallback = const Offset(100, 30);
  final Offset endFallback = const Offset(0, 30);
  final double editorVerticalOffset = 15.0;
}

class _EditorConfig {
  const _EditorConfig();
  final double minWidth = 84.0;
  final double padding = 16.0;
  final double fontSizeNode = 12.0;
  final double fontSizeRelation = 10.0;
}
