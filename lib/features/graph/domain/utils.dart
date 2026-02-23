import '../../../core/config/app_config.dart';

/// Strips the SurrealDB 'table:' prefix to ensure stable Map keys.
/// SurrealDB returns IDs as 'table:id', but creation returns just the ID.
String stripTablePrefix(String? raw) {
  if (raw == null) return AppConfig.core.unknownId;
  final parts = raw.split(AppConfig.core.dbSeparator);
  return parts.length > 1
      ? parts.sublist(1).join(AppConfig.core.dbSeparator)
      : raw;
}
