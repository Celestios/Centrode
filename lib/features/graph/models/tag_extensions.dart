import 'package:centrode/src/rust/domain/types.dart';

extension TagExtensions on Tag {
  String get keyString => key.key.uuid;
}
