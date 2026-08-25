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

  /// Executes the complete multi-phase boot sequence.
  static Future<AppContext> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();

    if (kDebugMode) {
      DebugNotifierTracer.enabled = false;
      debugPrintRebuildDirtyWidgets = false;
      debugProfileBuildsEnabled = false;
    }

    // Phase 1: Core System, FFI & Telemetry
    await RustLib.init();
    await LogManager().init();
    await GlassShaderProvider.load();
    await AppPaths.ensureDirectories();
    _log.info('Phase 1: Core FFI and telemetry ready.');

    // Phase 2: Window & Platform Management
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      await windowManager.ensureInitialized();
      const windowOptions = WindowOptions(
        size: Size(1280, 720),
        center: true,
        backgroundColor: Colors.transparent,
        skipTaskbar: false,
        titleBarStyle: TitleBarStyle.hidden,
      );
      await windowManager.waitUntilReadyToShow(windowOptions, () async {
        await windowManager.show();
        await windowManager.focus();
      });

      CustodianLifecycleCoordinator.instance.init();
      CustodianLifecycleCoordinator.instance.onBeforeShutdown =
          () => MapManager.instance.flushAndCloseAll();
      await CustodianLifecycleCoordinator.instance.onAppStartup();
      _log.info('Phase 2: Platform window & custodian ready.');
    }

    // Phase 3: Engine & Persistence Storage
    final coreDbDir = await AppPaths.mapsDirectory;
    await DaemonGateway.instance.init(coreDbDir);
    MapManager.instance.storageGateway = DaemonGateway.instance;
    _log.info('Phase 3: Daemon storage gateway connected.');

    // Phase 4: Bundled Themes & Presentation
    final themes = await ThemeLoader.loadBundledThemes();
    final AppTheme initialTheme;
    if (themes.isEmpty) {
      _log.severe('No JSON themes found in assets. Falling back to bare defaults.');
      initialTheme = AppTheme();
    } else {
      initialTheme = themes['dark'] ?? themes.values.first;
      _log.info('Phase 4: Loaded themes: ${themes.keys.join(', ')}');
    }
    AppThemeManager.instance.themeNotifier = ValueNotifier(initialTheme);

    return AppContext(
      allThemes: themes,
      initialTheme: initialTheme,
    );
  }
}
