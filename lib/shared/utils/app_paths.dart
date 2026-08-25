import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppPaths {
  static const String mapsDirName = 'maps';
  static const String dataDirName = 'data';
  static const String attachmentsDirName = 'attachments';
  static const int maxIoRetries = 10;
  static const Duration ioRetryDelay = Duration(milliseconds: 20);

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
    return p.join(await _appDataRoot, mapsDirName);
  }

  static Future<String> get attachmentsDirectory async {
    final dir = p.join(await mapsDirectory, attachmentsDirName);
    final d = Directory(dir);
    if (!d.existsSync()) {
      d.createSync(recursive: true);
    }
    return dir;
  }

  static Future<String> attachmentsDirectoryForMap(String mapIdOrName) async {
    final dir = p.join(await mapsDirectory, attachmentsDirName, mapIdOrName);
    final d = Directory(dir);
    if (!d.existsSync()) {
      d.createSync(recursive: true);
    }
    return dir;
  }

  static Future<String> get dataDirectory async {
    return p.join(await _appDataRoot, dataDirName);
  }

  static Future<String> resolveMapPath(String name) async {
    return p.join(await mapsDirectory, '$name.db');
  }

  static Future<String> getDevRoot() => _getDevRoot();

  static Future<String> _getDevRoot() async {
    if (_cachedDevRoot != null) return _cachedDevRoot!;

    final root = _findCentrodeRoot(Directory.current.path) ??
        _findCentrodeRoot(p.dirname(Platform.resolvedExecutable));

    if (root != null) {
      _cachedDevRoot = root;
      return root;
    }

    _cachedDevRoot = Directory.current.path;
    return _cachedDevRoot!;
  }

  static String? _findCentrodeRoot(String startPath) {
    var dir = startPath;
    for (var i = 0; i < maxIoRetries; i++) {
      final pubspec = File(p.join(dir, 'pubspec.yaml'));
      if (pubspec.existsSync()) {
        final content = pubspec.readAsStringSync();
        if (content.contains('name: centrode')) {
          return dir;
        }
      }
      final parent = p.dirname(dir);
      if (parent == dir) break;
      dir = parent;
    }
    return null;
  }

  static Future<void> deleteMapStorage(String rawPath) async {
    final path = p.canonicalize(rawPath);
    for (var attempt = 0; attempt < maxIoRetries; attempt++) {
      try {
        if (Directory(path).existsSync()) {
          await Directory(path).delete(recursive: true);
        } else if (File(path).existsSync()) {
          await File(path).delete();
        }
        return;
      } catch (e) {
        if (attempt == maxIoRetries - 1) rethrow;
        await Future<void>.delayed(ioRetryDelay);
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

    for (var attempt = 0; attempt < maxIoRetries; attempt++) {
      try {
        if (Directory(oldPath).existsSync()) {
          await Directory(oldPath).rename(newPath);
        } else if (File(oldPath).existsSync()) {
          await File(oldPath).rename(newPath);
        }
        return;
      } catch (e) {
        if (attempt == maxIoRetries - 1) {
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
        await Future<void>.delayed(ioRetryDelay);
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
