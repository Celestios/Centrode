import 'dart:async';
import 'package:centrode/src/rust/domain/base_models.dart';

abstract interface class AssetApi {
  Future<Attachment> ingestAsset({
    required String assetDir,
    required String fileName,
    required List<int> fileBytes,
    required String mimeType,
  });
  Future<String> getAssetAbsolutePath({
    required String assetDir,
    required String hash,
    required String extension,
  });
  Future<void> loadMapFromFile({
    required String filePath,
    required String attachmentDir,
  });
  Future<void> saveMapToFile({
    required String filePath,
    required String attachmentDir,
  });
}
