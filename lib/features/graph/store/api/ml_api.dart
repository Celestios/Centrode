import 'dart:async';
import 'dart:typed_data';
import 'package:centrode/src/rust/domain/styles.dart' show RelationStyle;
import 'package:centrode/src/rust/services/knowledge_graph_engine.dart';

abstract interface class MlApi {
  Future<String> detectMapLanguage({required List<String> nodeTexts});
  Future<List<String>> predictRelationLabels({
    required String sourceText,
    required String targetText,
    String? language,
    required BigInt limit,
  });
  Future<List<String>> searchSimilarLabels({
    required String query,
    String? category,
    String? language,
    required BigInt limit,
  });
  Future<Float32List> embedText({required String text});
  Future<void> initEmbedderModel({
    Uint8List? weightsBytes,
    String? unpackedModelPath,
    required Uint8List tokenizerBytes,
    Uint8List? configBytes,
  });
  Future<void> initKnowledgeGraphEngine({
    required List<int> conceptsBytes,
    required List<int> conceptsDictBytes,
    required List<int> relationsBytes,
    required List<int> relationsMetaBytes,
  });
  Future<List<ConceptPrediction>> suggestNextNodes({
    required String head,
    required String relation,
    required BigInt limit,
  });
  Future<ConnectionAuditResult?> auditConnectionSanity({
    required String source,
    required String relation,
    required String target,
  });
  Future<List<ConceptPrediction>> searchSimilarConcepts({
    required String concept,
    required BigInt limit,
  });
  Future<RelationStyle?> getRelationSpec({required String verb});
  Future<List<(String, RelationStyle)>> listRelationSpecs();
}
