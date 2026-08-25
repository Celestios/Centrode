import 'dart:async';
import 'package:centrode/src/rust/domain/id.dart';
import 'package:centrode/src/rust/domain/types.dart';

abstract interface class TemplateApi {
  Future<void> saveTemplateFromSelection({
    required String name,
    required List<TypedRecordId> nodeKeys,
    required List<TypedRecordId> relationKeys,
  });
  Future<void> instantiateTemplate({
    required String key,
    required double targetX,
    required double targetY,
  });
  Future<List<Template>> getAllTemplates();
  Future<void> deleteTemplate({required String key});
}
