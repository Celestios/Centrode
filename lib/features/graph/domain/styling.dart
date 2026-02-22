import 'dart:convert';
import 'package:flutter/material.dart';

class StyleProfile {
  final String shape;
  final Color bgColor;
  final Color strokeColor;
  final double strokeWidth;
  final String fontFamily;
  final double width; // [NEW] Canonical Node Width

  StyleProfile({
    this.shape = 'rectangle',
    this.bgColor = Colors.white,
    this.strokeColor = Colors.black,
    this.strokeWidth = 1.0,
    this.fontFamily = 'Inter',
    this.width = 100.0,
  });

  factory StyleProfile.fromJson(Map<String, dynamic> json) {
    return StyleProfile(
      shape: json['shape'] ?? 'rectangle',
      bgColor: _parseColor(json['bg_color'] ?? '#FFFFFF'),
      strokeColor: _parseColor(json['stroke_color'] ?? '#000000'),
      strokeWidth: (json['stroke_width'] ?? 1.0).toDouble(),
      fontFamily: json['font_family'] ?? 'Inter',
      width: (json['width'] ?? 150.0).toDouble(), // [NEW]
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shape': shape,
      'bg_color': _colorToHex(bgColor),
      'stroke_color': _colorToHex(strokeColor),
      'stroke_width': strokeWidth,
      'font_family': fontFamily,
      'width': width, // [NEW]
    };
  }

  StyleProfile copyWith({
    String? shape,
    Color? bgColor,
    Color? strokeColor,
    double? strokeWidth,
    String? fontFamily,
    double? width, // [NEW]
  }) {
    return StyleProfile(
      shape: shape ?? this.shape,
      bgColor: bgColor ?? this.bgColor,
      strokeColor: strokeColor ?? this.strokeColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      fontFamily: fontFamily ?? this.fontFamily,
      width: width ?? this.width, // [NEW]
    );
  }

  static Color _parseColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF' + hex;
    return Color(int.parse(hex, radix: 16));
  }

  static String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
  }

  /// Merges another style profile into this one (shallow merge of properties)
  StyleProfile merge(StyleProfile other) {
    // In our case, we might want to handle partial updates.
    // However, if we store the whole object, we can just use copyWith or a full property copy.
    return copyWith(
      shape: other.shape != 'rectangle'
          ? other.shape
          : this.shape, // Simple heuristic for now
      bgColor: other.bgColor != Colors.white ? other.bgColor : this.bgColor,
      strokeColor: other.strokeColor != Colors.black
          ? other.strokeColor
          : this.strokeColor,
      strokeWidth: other.strokeWidth != 1.0
          ? other.strokeWidth
          : this.strokeWidth,
      fontFamily: other.fontFamily != 'Inter'
          ? other.fontFamily
          : this.fontFamily,
      width: other.width != 150.0 ? other.width : this.width, // [NEW]
    );
  }
}

class ThemeConfig {
  final String id;
  final String name;
  final StyleProfile globalDefault;
  final Map<String, StyleProfile> typeDefinitions;

  ThemeConfig({
    required this.id,
    required this.name,
    required this.globalDefault,
    required this.typeDefinitions,
  });

  factory ThemeConfig.fromRawJson(String id, String name, String configJson) {
    final Map<String, dynamic> data = jsonDecode(configJson);
    final Map<String, dynamic> typeDefsJson = data['type_definitions'] ?? {};

    final typeDefinitions = typeDefsJson.map(
      (key, value) =>
          MapEntry(key, StyleProfile.fromJson(value as Map<String, dynamic>)),
    );

    return ThemeConfig(
      id: id,
      name: name,
      globalDefault: StyleProfile.fromJson(data['global_default'] ?? {}),
      typeDefinitions: typeDefinitions,
    );
  }

  String toRawJson() {
    return jsonEncode({
      'global_default': globalDefault.toJson(),
      'type_definitions': typeDefinitions.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
    });
  }

  /// Resolves the final style for a specific node type
  StyleProfile resolveStyle(String nodeType, [StyleProfile? aesthetics]) {
    final typeStyle = typeDefinitions[nodeType] ?? globalDefault;
    if (aesthetics != null) {
      // Per implementation plan: Aesthetics is a snapshot or incremental update.
      // For now, let's assume Aesthetics contains all properties if it's not null.
      return aesthetics;
    }
    return typeStyle;
  }
}
