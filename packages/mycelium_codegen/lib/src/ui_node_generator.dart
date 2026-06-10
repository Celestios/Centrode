import 'dart:async';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

class UiNodeGenerator extends Generator {
  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    // Check if the current library is graph_node.dart
    if (!buildStep.inputId.path.endsWith('graph_node.dart')) {
      return '';
    }

    // Resolve the FFI nodes.dart library
    final ffiAssetId = AssetId('mycelium', 'lib/src/rust/domain/nodes.dart');
    if (!await buildStep.canRead(ffiAssetId)) {
      log.warning("Could not read nodes FFI asset at $ffiAssetId");
      return '';
    }
    final ffiLibrary = await buildStep.resolver.libraryFor(ffiAssetId);
    final ffiReader = LibraryReader(ffiLibrary);

    // List of classes ending in Node, excluding the Nodes union wrappers
    final nodeClasses = ffiReader.classes
        .where(
          (c) =>
              c.name != null &&
              c.name!.endsWith('Node') &&
              !c.name!.startsWith('Nodes_'),
        )
        .toList();

    final buffer = StringBuffer();
    buffer.writeln("// GENERATED CODE - DO NOT MODIFY BY HAND\n");
    buffer.writeln("part of 'graph_node.dart';\n");

    // Generate the UiNodes enum dynamically based on the FFI classes!
    buffer.writeln("enum UiNodes {");
    for (int i = 0; i < nodeClasses.length; i++) {
      final ffiClassName = nodeClasses[i].name ?? '';
      if (ffiClassName.isEmpty) continue;
      final enumName = _getEnumName(ffiClassName);
      final comma = i == nodeClasses.length - 1 ? "" : ",";
      buffer.writeln("  $enumName$comma");
    }
    buffer.writeln("}\n");

    for (final clazz in nodeClasses) {
      final ffiClassName = clazz.name ?? '';
      if (ffiClassName.isEmpty) continue;

      final uiClassName = _getUiClassName(ffiClassName);

      // Extract all fields
      final fields = clazz.fields;

      // Group fields into common (inherited from UiNode) and subclass-specific
      final commonFieldNames = {
        'id',
        'position',
        'layer',
        'createdAt',
        'updatedAt',
        'size',
        'content',
        'style',
        'resolvedStyle',
        'layout',
        'resolvedLayout',
        'lineCount',
        'expandable',
        'isExpanded',
        'locked',
        'significance',
      };

      final subclassFields = fields.where((f) {
        final name = f.name ?? '';
        if (name.isEmpty || name == 'hashCode' || name == 'runtimeType') {
          return false;
        }

        // Mismatch: InterNode's style is String?, but UiNode's style is NodeStyle?
        if (name == 'style' && f.type.toString() != 'NodeStyle?') {
          return true; // Treat as subclass specific
        }

        return !commonFieldNames.contains(name);
      }).toList();

      final commonFields = fields.where((f) {
        final name = f.name ?? '';
        if (name.isEmpty || name == 'hashCode' || name == 'runtimeType') {
          return false;
        }

        // Mismatch: InterNode's style is String?, but UiNode's style is NodeStyle?
        if (name == 'style' && f.type.toString() != 'NodeStyle?') {
          return false; // Not a common field for this class
        }

        return commonFieldNames.contains(name);
      }).toList();

      buffer.writeln("class $uiClassName extends UiNode {");

      // Declare subclass-specific fields
      for (final field in subclassFields) {
        final fieldName = field.name ?? '';
        if (fieldName.isEmpty) continue;
        final uiFieldName = _getUiFieldName(fieldName, field.type);
        final uiType = _mapFfiTypeToUi(field.type);
        if (uiFieldName == 'text') {
          buffer.writeln("  @override");
        }
        buffer.writeln("  $uiType $uiFieldName;");
      }
      if (subclassFields.isNotEmpty) {
        buffer.writeln("");
      }

      // Constructor
      buffer.writeln("  $uiClassName({");
      // Required common fields: position is required in UiNode
      buffer.writeln("    required super.position,");

      // Other common fields that are present in this FFI class
      for (final field in commonFields) {
        final fieldName = field.name ?? '';
        if (fieldName == 'position' || fieldName.isEmpty) continue;

        if (fieldName == 'expandable') {
          buffer.writeln("    super.initialExpandable,");
        } else {
          buffer.writeln("    super.$fieldName,");
        }
      }

      // Subclass-specific fields in constructor
      for (final field in subclassFields) {
        final fieldName = field.name ?? '';
        if (fieldName.isEmpty) continue;
        final uiFieldName = _getUiFieldName(fieldName, field.type);

        if (uiFieldName == 'state' && ffiClassName == 'TaskNode') {
          buffer.writeln("    this.state = 'Not Done',");
        } else {
          final isList = field.type.isDartCoreList;
          final isNullable = field.type.nullabilitySuffix.name == 'question';
          if (isList) {
            buffer.writeln("    this.$uiFieldName = const [],");
          } else if (isNullable) {
            buffer.writeln("    this.$uiFieldName,");
          } else {
            buffer.writeln("    required this.$uiFieldName,");
          }
        }
      }
      buffer.writeln("  });");
      buffer.writeln("");

      // tableName getter
      buffer.writeln("  @override");
      buffer.writeln("  String get tableName => '$ffiClassName';");
      buffer.writeln("");

      // toRust() method
      buffer.writeln("  @override");
      buffer.writeln("  Nodes toRust() {");
      buffer.writeln(
        "    return Nodes.${_decapitalize(_getVariantName(ffiClassName))}(",
      );
      buffer.writeln("      $ffiClassName(");
      buffer.writeln(
        "        id: frb.RecordStrings(table: tableName, key: id),",
      );
      buffer.writeln(
        "        position: frb.Coordinates(x: position.dx.round(), y: position.dy.round()),",
      );
      buffer.writeln("        layer: layer,");
      buffer.writeln("        createdAt: createdAt,");
      buffer.writeln("        updatedAt: updatedAt,");

      // Common fields present in FFI
      for (final field in commonFields) {
        final fieldName = field.name ?? '';
        if (fieldName.isEmpty ||
            [
              'id',
              'position',
              'layer',
              'createdAt',
              'updatedAt',
            ].contains(fieldName)) {
          continue;
        }
        if (fieldName == 'size') {
          buffer.writeln(
            "        size: frb.Size(width: size.width.round(), height: size.height.round()),",
          );
        } else {
          buffer.writeln("        $fieldName: $fieldName,");
        }
      }

      // Subclass fields in toRust
      for (final field in subclassFields) {
        final fieldName = field.name ?? '';
        if (fieldName.isEmpty) continue;
        final conversion = _toRustConversion(field);
        buffer.writeln("        $fieldName: $conversion,");
      }

      buffer.writeln("      ),");
      buffer.writeln("    );");
      buffer.writeln("  }");
      buffer.writeln("");

      // fromRust() factory
      buffer.writeln("  factory $uiClassName.fromRust($ffiClassName node) {");
      buffer.writeln("    return $uiClassName(");
      buffer.writeln("      id: node.id.key,");
      buffer.writeln("      createdAt: node.createdAt,");
      buffer.writeln("      updatedAt: node.updatedAt,");
      buffer.writeln("      layer: node.layer,");
      buffer.writeln(
        "      position: Offset(node.position.x.toDouble(), node.position.y.toDouble()),",
      );

      // Check common fields present in FFI
      for (final field in commonFields) {
        final fieldName = field.name ?? '';
        if (fieldName.isEmpty ||
            [
              'id',
              'position',
              'layer',
              'createdAt',
              'updatedAt',
            ].contains(fieldName)) {
          continue;
        }
        if (fieldName == 'size') {
          buffer.writeln(
            "      size: Size(node.size.width.toDouble(), node.size.height.toDouble()),",
          );
        } else if (fieldName == 'expandable') {
          buffer.writeln("      initialExpandable: node.expandable,");
        } else {
          buffer.writeln("      $fieldName: node.$fieldName,");
        }
      }

      // Subclass fields in fromRust
      for (final field in subclassFields) {
        final fieldName = field.name ?? '';
        if (fieldName.isEmpty) continue;
        final uiFieldName = _getUiFieldName(fieldName, field.type);
        final conversion = _fromRustConversion(field);
        buffer.writeln("      $uiFieldName: $conversion,");
      }

      buffer.writeln("    );");
      buffer.writeln("  }");
      buffer.writeln("");

      // copyWith() method
      buffer.writeln("  $uiClassName copyWith({");
      buffer.writeln("    String? id,");
      buffer.writeln("    int? createdAt,");
      buffer.writeln("    int? updatedAt,");
      buffer.writeln("    String? layer,");
      buffer.writeln("    Offset? position,");

      // Common fields in copyWith
      for (final field in commonFields) {
        final fieldName = field.name ?? '';
        if (fieldName.isEmpty ||
            [
              'id',
              'position',
              'layer',
              'createdAt',
              'updatedAt',
            ].contains(fieldName)) {
          continue;
        }
        final uiType = _mapFfiTypeToUi(field.type);
        final finalType = uiType.endsWith('?') ? uiType : '$uiType?';
        buffer.writeln("    $finalType $fieldName,");
      }

      // Subclass fields in copyWith
      for (final field in subclassFields) {
        final fieldName = field.name ?? '';
        if (fieldName.isEmpty) continue;
        final uiFieldName = _getUiFieldName(fieldName, field.type);
        final uiType = _mapFfiTypeToUi(field.type);
        final finalType = uiType.endsWith('?') ? uiType : '$uiType?';
        buffer.writeln("    $finalType $uiFieldName,");
      }
      buffer.writeln("  }) {");
      buffer.writeln("    return $uiClassName(");
      buffer.writeln("      id: id ?? this.id,");
      buffer.writeln("      createdAt: createdAt ?? this.createdAt,");
      buffer.writeln("      updatedAt: updatedAt ?? this.updatedAt,");
      buffer.writeln("      layer: layer ?? this.layer,");
      buffer.writeln("      position: position ?? this.position,");

      // Common fields instantiation in copyWith
      for (final field in commonFields) {
        final fieldName = field.name ?? '';
        if (fieldName.isEmpty ||
            [
              'id',
              'position',
              'layer',
              'createdAt',
              'updatedAt',
            ].contains(fieldName)) {
          continue;
        }
        if (fieldName == 'expandable') {
          buffer.writeln(
            "      initialExpandable: expandable ?? this.expandable,",
          );
        } else {
          buffer.writeln("      $fieldName: $fieldName ?? this.$fieldName,");
        }
      }

      // Subclass fields instantiation in copyWith
      for (final field in subclassFields) {
        final fieldName = field.name ?? '';
        if (fieldName.isEmpty) continue;
        final uiFieldName = _getUiFieldName(fieldName, field.type);
        buffer.writeln(
          "      $uiFieldName: $uiFieldName ?? this.$uiFieldName,",
        );
      }

      buffer.writeln("    );");
      buffer.writeln("  }");

      buffer.writeln("}\n");
    }

    // Helper functions:
    // 1. _$uiNodeFromRust(Object rustNode)
    buffer.writeln("UiNode _\$uiNodeFromRust(Object rustNode) {");
    for (final clazz in nodeClasses) {
      final ffiClassName = clazz.name ?? '';
      if (ffiClassName.isEmpty) continue;
      final uiClassName = _getUiClassName(ffiClassName);
      buffer.writeln(
        "  if (rustNode is $ffiClassName) { return $uiClassName.fromRust(rustNode); }",
      );
    }
    // Also handle when the object wrapped inside Nodes enum is passed directly
    for (final clazz in nodeClasses) {
      final ffiClassName = clazz.name ?? '';
      if (ffiClassName.isEmpty) continue;
      final uiClassName = _getUiClassName(ffiClassName);
      buffer.writeln(
        "  if (rustNode is Nodes_$ffiClassName) { return $uiClassName.fromRust(rustNode.field0); }",
      );
    }
    buffer.writeln(
      "  throw ArgumentError('Unsupported Rust node type: \${rustNode.runtimeType}');",
    );
    buffer.writeln("}\n");

    // 2. _$uiNodeCopy(UiNode? node)
    buffer.writeln("UiNode? _\$uiNodeCopy(UiNode? node) {");
    buffer.writeln("  if (node == null) { return null; }");
    for (final clazz in nodeClasses) {
      final ffiClassName = clazz.name ?? '';
      if (ffiClassName.isEmpty) continue;
      final uiClassName = _getUiClassName(ffiClassName);
      buffer.writeln("  if (node is $uiClassName) { return node.copyWith(); }");
    }
    buffer.writeln("  throw ArgumentError('Unsupported node type: \${node.runtimeType}');");
    buffer.writeln("}\n");

    return buffer.toString();
  }

  String _getUiClassName(String ffiName) {
    if (ffiName == 'INode') return 'InfoUiNode';
    return ffiName.replaceAll('Node', 'UiNode');
  }

  String _getEnumName(String ffiName) {
    if (ffiName == 'INode') return 'info';
    return _decapitalize(ffiName.replaceAll('Node', ''));
  }

  String _getVariantName(String ffiName) {
    if (ffiName == 'INode') return 'iNode';
    return _decapitalize(ffiName);
  }

  String _getUiFieldName(String ffiName, DartType type) {
    if (ffiName == 'style' && type.toString() != 'NodeStyle?') {
      return 'styleName';
    }
    return ffiName;
  }

  String _decapitalize(String s) =>
      s.isEmpty ? s : s[0].toLowerCase() + s.substring(1);

  String _mapFfiTypeToUi(DartType ffiType) {
    final typeStr = ffiType.toString();
    if (typeStr == 'RecordStrings') return 'String';
    if (typeStr == 'Coordinates') return 'Offset';
    if (typeStr == 'Size') return 'Size';
    if (typeStr == 'PlatformInt64') return 'int';
    if (typeStr == 'PlatformInt64?') return 'int?';
    if (typeStr == 'List<TagEdge>') return 'List<Tag>';
    return typeStr;
  }

  String _toRustConversion(FieldElement field) {
    final typeStr = field.type.toString();
    final fieldName = field.name ?? '';
    final uiFieldName = _getUiFieldName(fieldName, field.type);
    if (typeStr == 'Offset') {
      return 'frb.Coordinates(x: $uiFieldName.dx.round(), y: $uiFieldName.dy.round())';
    }
    if (typeStr == 'Size') {
      return 'frb.Size(width: $uiFieldName.width.round(), height: $uiFieldName.height.round())';
    }
    if (typeStr == 'List<TagEdge>') {
      return '$uiFieldName.map((tag) => TagEdge.hydrated(tag)).toList()';
    }
    return uiFieldName;
  }

  String _fromRustConversion(FieldElement field) {
    final typeStr = field.type.toString();
    final fieldName = field.name ?? '';
    if (typeStr == 'Coordinates') {
      return 'Offset(node.$fieldName.x.toDouble(), node.$fieldName.y.toDouble())';
    }
    if (typeStr == 'Size') {
      return 'Size(node.$fieldName.width.toDouble(), node.$fieldName.height.toDouble())';
    }
    if (typeStr == 'List<TagEdge>') {
      return '''node.$fieldName.map((edge) {
        return edge.when(
          hydrated: (tag) => tag,
          pointer: (record) => Tag(
            key: record.key,
            fields: TagFields(
              name: record.key,
              color: 0xFF78909C,
              createdAt: DateTime.now().millisecondsSinceEpoch,
              updatedAt: DateTime.now().millisecondsSinceEpoch,
            ),
          ),
        );
      }).toList()''';
    }
    return 'node.$fieldName';
  }
}
