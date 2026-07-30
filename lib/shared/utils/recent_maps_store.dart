import 'dart:convert';
import 'dart:io';
import 'package:mycelium/shared/logging.dart';
import 'app_paths.dart';

class RecentMapsStore {
  static final Logger _log = Logger('RecentMapsStore');
  static Map<String, DateTime>? _cache;

  static Future<Map<String, DateTime>> _load() async {
    if (_cache != null) return _cache!;
    final file = File(await AppPaths.recentMapsFile);
    if (!file.existsSync()) {
      _cache = {};
      return _cache!;
    }
    try {
      final content = await file.readAsString();
      final map = jsonDecode(content) as Map<String, dynamic>;
      _cache = map.map((k, v) => MapEntry(k, DateTime.parse(v as String)));
    } catch (e, st) {
      _log.severe('Error reading recent maps JSON file: $e', e, st);
      _cache = {};
    }
    return _cache!;
  }

  static Future<void> _save() async {
    if (_cache == null) return;
    final file = File(await AppPaths.recentMapsFile);
    final content = jsonEncode(
      _cache!.map((k, v) => MapEntry(k, v.toIso8601String())),
    );
    await file.writeAsString(content);
  }

  static Future<void> touch(String storagePath) async {
    final data = await _load();
    data[storagePath] = DateTime.now();
    await _save();
  }

  static Future<DateTime?> getLastAccessed(String storagePath) async {
    final data = await _load();
    return data[storagePath];
  }

  static Future<Map<String, DateTime>> getAll() async {
    return _load();
  }

  static Future<void> remove(String storagePath) async {
    final data = await _load();
    if (data.remove(storagePath) != null) {
      await _save();
    }
  }

  static Future<void> rename(String oldPath, String newPath) async {
    final data = await _load();
    final time = data.remove(oldPath);
    if (time != null) {
      data[newPath] = time;
      await _save();
    }
  }
}
