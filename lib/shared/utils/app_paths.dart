import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppPaths {
  static String? _cachedDevRoot;

  static Future<String> get _appDataRoot async {
    if (!kReleaseMode &&
        (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      return _getDevRoot();
    }
    final support = await getApplicationSupportDirectory();
    return support.path;
  }

  static Future<String> get mapsDirectory async {
    return p.join(await _appDataRoot, 'maps');
  }

  static Future<String> get attachmentsDirectory async {
    final dir = p.join(await mapsDirectory, 'attachments');
    final d = Directory(dir);
    if (!d.existsSync()) {
      d.createSync(recursive: true);
    }
    return dir;
  }

  static Future<String> get dataDirectory async {
    return p.join(await _appDataRoot, 'data');
  }

  static Future<String> get settingsFile async {
    return p.join(await dataDirectory, 'settings.json');
  }

  static Future<String> get recentMapsFile async {
    return p.join(await dataDirectory, 'recent.json');
  }

  static Future<String> resolveMapPath(String name) async {
    return p.join(await mapsDirectory, '$name.db');
  }

  static Future<String> getDevRoot() => _getDevRoot();

  static Future<String> _getDevRoot() async {
    if (_cachedDevRoot != null) return _cachedDevRoot!;

    // 1. Try walking up from Directory.current.path
    var dir = Directory.current.path;
    for (var i = 0; i < 10; i++) {
      final pubspec = File(p.join(dir, 'pubspec.yaml'));
      if (pubspec.existsSync()) {
        final content = pubspec.readAsStringSync();
        if (content.contains('name: centrode')) {
          _cachedDevRoot = dir;
          return dir;
        }
      }
      final parent = p.dirname(dir);
      if (parent == dir) break;
      dir = parent;
    }

    // 2. Try walking up from Platform.resolvedExecutable
    dir = p.dirname(Platform.resolvedExecutable);
    for (var i = 0; i < 10; i++) {
      final pubspec = File(p.join(dir, 'pubspec.yaml'));
      if (pubspec.existsSync()) {
        final content = pubspec.readAsStringSync();
        if (content.contains('name: centrode')) {
          _cachedDevRoot = dir;
          return dir;
        }
      }
      final parent = p.dirname(dir);
      if (parent == dir) break;
      dir = parent;
    }

    // 3. Fallback: walk up from Directory.current checking for any pubspec.yaml
    dir = Directory.current.path;
    for (var i = 0; i < 10; i++) {
      if (File(p.join(dir, 'pubspec.yaml')).existsSync()) {
        _cachedDevRoot = dir;
        return dir;
      }
      final parent = p.dirname(dir);
      if (parent == dir) break;
      dir = parent;
    }

    _cachedDevRoot = Directory.current.path;
    return _cachedDevRoot!;
  }

  static Future<void> deleteMapStorage(String rawPath) async {
    final path = p.canonicalize(rawPath);
    for (var attempt = 0; attempt < 10; attempt++) {
      try {
        if (Directory(path).existsSync()) {
          await Directory(path).delete(recursive: true);
        } else if (File(path).existsSync()) {
          await File(path).delete();
        }
        return;
      } catch (e) {
        if (attempt == 9) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    }
  }

  static Future<void> renameMapStorage(
    String rawOldPath,
    String rawNewPath,
  ) async {
    final oldPath = p.canonicalize(rawOldPath);
    final newPath = p.canonicalize(rawNewPath);
    if (!Directory(oldPath).existsSync() && !File(oldPath).existsSync()) {
      return;
    }

    for (var attempt = 0; attempt < 10; attempt++) {
      try {
        if (Directory(oldPath).existsSync()) {
          await Directory(oldPath).rename(newPath);
        } else if (File(oldPath).existsSync()) {
          await File(oldPath).rename(newPath);
        }
        return;
      } catch (e) {
        if (attempt == 9) {
          // If direct atomic rename failed due to OS file locks on Windows, fall back to recursive copy + delete
          if (Directory(oldPath).existsSync()) {
            await _copyDirectory(Directory(oldPath), Directory(newPath));
            await deleteMapStorage(oldPath);
            return;
          } else if (File(oldPath).existsSync()) {
            await File(oldPath).copy(newPath);
            await deleteMapStorage(oldPath);
            return;
          }
          rethrow;
        }
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
    }
  }

  static Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(recursive: false)) {
      final newPath = p.join(destination.path, p.basename(entity.path));
      if (entity is Directory) {
        await _copyDirectory(entity, Directory(newPath));
      } else if (entity is File) {
        await entity.copy(newPath);
      }
    }
  }

  static Future<void> ensureDirectories() async {
    final mapsDir = Directory(await mapsDirectory);
    if (!mapsDir.existsSync()) {
      mapsDir.createSync(recursive: true);
    }
    final dataDir = Directory(await dataDirectory);
    if (!dataDir.existsSync()) {
      dataDir.createSync(recursive: true);
    }
  }
}
