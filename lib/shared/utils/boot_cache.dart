import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Lightweight, transient startup cache for frame-0 preflight visuals.
///
/// Stores only the minimal visual metadata (e.g. cached active theme name)
/// required to render the initial frame before the SurrealDB system database
/// and daemon are fully connected. Persistent app settings are stored in the
/// system database, not here.
class BootCache {
  static final Map<String, dynamic> _data = <String, dynamic>{};
  static File? _cacheFile;
  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<void> init() async {
    if (_initialized) return;

    try {
      final cachePath = await _resolveCachePath();
      _cacheFile = File(cachePath);

      if (_cacheFile!.existsSync()) {
        final content = await _cacheFile!.readAsString();
        if (content.trim().isNotEmpty) {
          final decoded = json.decode(content);
          if (decoded is Map<String, dynamic>) {
            _data.addAll(decoded);
          }
        }
      }
    } catch (e) {
      debugPrint('[BootCache] Init fallback: $e');
    } finally {
      _initialized = true;
    }
  }

  static String get cachedThemeName =>
      (_data['cached_theme_name'] as String?) ?? 'dark';

  static set cachedThemeName(String theme) {
    _data['cached_theme_name'] = theme;
    _save();
  }

  static Future<void> _save() async {
    if (_cacheFile == null) return;
    try {
      if (!_cacheFile!.parent.existsSync()) {
        _cacheFile!.parent.createSync(recursive: true);
      }
      await _cacheFile!.writeAsString(json.encode(_data));
    } catch (e) {
      debugPrint('[BootCache] Failed to save boot cache: $e');
    }
  }

  static Future<String> _resolveCachePath() async {
    if (!kReleaseMode &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return p.join(Directory.current.path, 'boot_cache.json');
    }

    if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null) {
        return p.join(appData, 'centrode', 'boot_cache.json');
      }
    }

    final supportDir = await getApplicationSupportDirectory();
    return p.join(supportDir.path, 'boot_cache.json');
  }
}
