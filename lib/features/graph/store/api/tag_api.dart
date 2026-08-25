import 'dart:async';
import 'package:centrode/src/rust/domain/tags.dart';

abstract interface class TagApi {
  Future<void> createTag({required Tag tag});
  Future<Tag?> getTag({required String key});
  Future<List<Tag>> getAllTags();
  Future<void> updateTag({required Tag tag});
  Future<void> deleteTag({required String key});
}
