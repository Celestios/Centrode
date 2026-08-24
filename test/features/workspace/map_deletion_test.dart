import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:centrode/shared/utils/app_paths.dart';
import 'package:centrode/features/graph/presentation/map_manager.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Map Storage Deletion & Teardown Tests', () {
    late Directory tempDir;

    setUp(() async {
      await MapManager.instance.flushAndCloseAll();
      tempDir = await Directory.systemTemp.createTemp('centrode_map_test_');
    });

    tearDown(() async {
      await MapManager.instance.flushAndCloseAll();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });


    test(
      'deleteMapStorage deletes both single files and SurrealKV directories',
      () async {
        final fileMap = p.join(tempDir.path, 'single_file.db');
        await File(fileMap).writeAsString('dummy');
        expect(File(fileMap).existsSync(), isTrue);

        await AppPaths.deleteMapStorage(fileMap);
        expect(File(fileMap).existsSync(), isFalse);

        final dirMap = p.join(tempDir.path, 'dir_map.db');
        final innerDir = Directory(dirMap);
        await innerDir.create(recursive: true);
        await File(p.join(dirMap, 'manifest')).writeAsString('manifest data');
        expect(innerDir.existsSync(), isTrue);

        await AppPaths.deleteMapStorage(dirMap);
        expect(innerDir.existsSync(), isFalse);
      },
    );

    test(
      'renameMapStorage renames both single files and directories correctly',
      () async {
        final oldDir = p.join(tempDir.path, 'old_map.db');
        final newDir = p.join(tempDir.path, 'new_map.db');
        await Directory(oldDir).create(recursive: true);
        await File(p.join(oldDir, 'data.bin')).writeAsString('content');

        await AppPaths.renameMapStorage(oldDir, newDir);
        expect(Directory(oldDir).existsSync(), isFalse);
        expect(Directory(newDir).existsSync(), isTrue);
        expect(File(p.join(newDir, 'data.bin')).existsSync(), isTrue);
      },
    );

    test(
      'MapManager handles canonical paths correctly during closeByPath',
      () async {
        final mapPath = p.join(tempDir.path, 'canonical_test.db');
        expect(MapManager.instance.isPathOpen(mapPath), isFalse);

        // closeByPath on unopened map is safe no-op
        await MapManager.instance.closeByPath(mapPath);
        expect(MapManager.instance.isPathOpen(mapPath), isFalse);
      },
    );
  });
}
