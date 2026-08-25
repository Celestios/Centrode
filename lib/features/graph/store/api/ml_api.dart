import 'dart:async';
import 'dart:typed_data';
import 'package:centrode/src/rust/domain/styles.dart';

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
    required BigInt limit,
  });
  Future<Float32List> embedText({required String text});
  Future<void> initEmbedderModel({
    required Uint8List weightsBytes,
    required Uint8List tokenizerBytes,
    Uint8List? configBytes,
  });
  Future<RelationStyle?> getRelationSpec({required String verb});
  Future<List<(String, RelationStyle)>> listRelationSpecs();
}
