import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:centrode/features/graph/presentation/map_manager.dart';
import 'package:centrode/shared/logging.dart';
import 'package:centrode/shared/utils/app_paths.dart';
import 'package:centrode/src/rust/bridge/api.dart';
import 'package:window_manager/window_manager.dart';

class CustodianLifecycleCoordinator with WindowListener {
  static final CustodianLifecycleCoordinator instance =
      CustodianLifecycleCoordinator._();
  CustodianLifecycleCoordinator._();

  final Logger _log = Logger('CustodianLifecycleCoordinator');
  bool _isShuttingDown = false;

  /// Controls whether closing the window automatically launches the detached standalone daemon.
  /// Set to true for testing; can be toggled to false or gated on !kDebugMode later.
  bool enableDaemonSpawn = true;

  void init() {
    _log.info('Initializing CustodianLifecycleCoordinator');
    windowManager.addListener(this);
    windowManager.setPreventClose(true);
  }

  /// Called on app startup to request any running standalone daemon to yield the database lock.
  Future<void> onAppStartup() async {
    _log.info('Checking if standalone daemon is holding storage lock...');
    final yielded = await yieldDaemonIfRunning();
    if (yielded) {
      _log.info('Standalone daemon yielded database baton successfully.');
    } else {
      _log.info('No active standalone daemon detected. Proceeding normally.');
    }
  }

  @override
  void onWindowClose() async {
    if (_isShuttingDown) return;
    _isShuttingDown = true;
    _log.info('onWindowClose intercepted. Starting graceful teardown...');

    // 1. Flush and close all open tabs
    await MapManager.instance.flushAndCloseAll();

    // 2. Release SurrealKV engine lock
    _log.info('Releasing SurrealKV root engine locks...');
    await shutdownCoreEngine();
    _log.info('SurrealKV locks released successfully.');

    // 3. Spawn detached standalone daemon if enabled
    if (enableDaemonSpawn) {
      await _spawnDetachedDaemon();
    }

    _log.info('Destroying window and exiting process.');
    await windowManager.destroy();
  }

  Future<void> _spawnDetachedDaemon() async {
    try {
      final daemonPath = await _resolveDaemonExecutable();
      if (daemonPath != null && File(daemonPath).existsSync()) {
        _log.info('Spawning detached daemon process at $daemonPath');
        await Process.start(
          daemonPath,
          [],
          mode: ProcessStartMode.detached,
        );
        _log.info('Detached daemon process launched successfully.');
      } else {
        _log.warning(
            'Daemon executable not found at resolved path: $daemonPath');
      }
    } catch (e, stack) {
      _log.warning('Failed to spawn detached daemon: $e', stack);
    }
  }

  Future<String?> _resolveDaemonExecutable() async {
    final binaryNames = Platform.isWindows
        ? const ['centrode-daemon.exe', 'centrode_daemon.exe']
        : const ['centrode-daemon', 'centrode_daemon'];

    // 1. Adjacent to executable (e.g. in Release bundle)
    final exeDir = p.dirname(Platform.resolvedExecutable);
    for (final name in binaryNames) {
      final adjacent = p.join(exeDir, name);
      if (File(adjacent).existsSync()) {
        return adjacent;
      }
    }

    // 2. In rust/target/debug or release
    final devRoot = await AppPaths.getDevRoot();
    final searchDirs = [
      p.join(devRoot, 'rust', 'target', 'debug'),
      p.join(devRoot, 'rust', 'target', 'release'),
    ];

    for (final dir in searchDirs) {
      for (final name in binaryNames) {
        final candidate = p.join(dir, name);
        if (File(candidate).existsSync()) {
          return candidate;
        }
      }
    }

    return p.join(devRoot, 'rust', 'target', 'debug', binaryNames.first);
  }

  void dispose() {
    windowManager.removeListener(this);
  }
}
