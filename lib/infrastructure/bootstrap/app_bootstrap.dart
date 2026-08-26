import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:centrode/shared/logging.dart';
import 'package:centrode/shared/traceable_notifier.dart';
import 'package:centrode/shared/utils/app_paths.dart';
import 'package:centrode/src/rust/frb_generated.dart';
import 'package:window_manager/window_manager.dart';
import '../telemetry/log_manager.dart';
import '../../presentation/theme/app_theme.dart';
import '../../presentation/theme/app_theme_manager.dart';
import '../../presentation/theme/theme_repository.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';
import 'package:centrode/shared/utils/boot_cache.dart';
import '../lifecycle/custodian_manager.dart';
import '../lifecycle/daemon_gateway.dart';
import '../../features/graph/presentation/map_manager.dart';

/// Container encapsulating initialized services and application state from bootstrapping.
class AppContext {
  final Map<String, AppTheme> allThemes;
  final AppTheme initialTheme;

  const AppContext({
    required this.allThemes,
    required this.initialTheme,
  });
}

/// Structured boot coordinator establishing deterministic startup phases.
class AppBootstrap {
  static final Logger _log = Logger('AppBootstrap');

  static const Size splashWindowSize = Size(640, 420);
  static const Size defaultWindowSize = Size(1280, 720);

  /// Preflight initialization completing in <50ms for instant frame 0 rendering.
  static Future<AppContext> initializeFast() async {
    WidgetsFlutterBinding.ensureInitialized();

    if (kDebugMode) {
      DebugNotifierTracer.enabled = false;
      debugPrintRebuildDirtyWidgets = false;
      debugProfileBuildsEnabled = false;
    }

    // Phase 1: Core System, FFI, Boot Cache & Telemetry
    await RustLib.init();
    await LogManager().init();
    await BootCache.init();
    await AppPaths.ensureDirectories();
    _log.info('Phase 1: Core FFI, boot cache and telemetry ready.');

    // Phase 2: Window & Platform Management
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      await windowManager.ensureInitialized();
      const windowOptions = WindowOptions(
        size: splashWindowSize,
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
      );
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.setAsFrameless();
        await windowManager.setHasShadow(false);
        await windowManager.show();
      });

      CustodianLifecycleCoordinator.instance.init();
      CustodianLifecycleCoordinator.instance.onBeforeShutdown =
          () => MapManager.instance.flushAndCloseAll();
      await CustodianLifecycleCoordinator.instance.onAppStartup();
      _log.info('Phase 2: Platform window & custodian ready.');
    }

    // Phase 3: Cached Theme Resolution
    final themes = await ThemeLoader.loadBundledThemes();
    final cachedThemeName = BootCache.cachedThemeName;
    final AppTheme initialTheme;
    if (themes.isEmpty) {
      initialTheme = AppTheme();
    } else {
      initialTheme = themes[cachedThemeName] ?? themes['dark'] ?? themes.values.first;
      _log.info('Phase 3: Active theme selected: $cachedThemeName');
    }
    AppThemeManager.instance.currentTheme = initialTheme;

    return AppContext(
      allThemes: themes,
      initialTheme: initialTheme,
    );
  }

  /// Asynchronous background worker preparing heavier storage and shader assets.
  static Future<void> initializeBackgroundServices([
    void Function(String status)? onProgress,
  ]) async {
    onProgress?.call('Loading shaders...');
    await GlassShaderProvider.load();

    onProgress?.call('Connecting storage daemon...');
    final coreDbDir = await AppPaths.mapsDirectory;
    await DaemonGateway.instance.init(coreDbDir);
    MapManager.instance.storageGateway = DaemonGateway.instance;
    _log.info('Background daemon storage connected.');

    onProgress?.call('Ready');
  }
}
