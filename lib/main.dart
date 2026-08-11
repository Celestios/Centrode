import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:centrode/shared/logging.dart';
import 'package:centrode/shared/traceable_notifier.dart';
import 'package:centrode/shared/utils/app_paths.dart';
import 'package:centrode/src/rust/frb_generated.dart';
import 'package:window_manager/window_manager.dart';
import 'infrastructure/telemetry/log_manager.dart';
import 'features/workspace/ui/workspace_hub_screen.dart';
import 'presentation/theme/app_theme.dart'; // from previous step
import 'presentation/theme/theme_repository.dart'; // from previous step
import 'presentation/theme/app_theme_manager.dart';
import 'package:centrode/shared/widgets/glass_panel/glass_panel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    DebugNotifierTracer.enabled = false;
    debugPrintRebuildDirtyWidgets = false;
    debugProfileBuildsEnabled = false;
  }

  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1280, 720),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
    );
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  await RustLib.init();
  await LogManager().init();
  await GlassShaderProvider.load();
  await AppPaths.ensureDirectories();

  final log = Logger('BootSequence');
  log.info('Rust FFI loaded. Centrode core ready.');

  final themes = await ThemeLoader.loadBundledThemes();
  final AppTheme initialTheme;
  if (themes.isEmpty) {
    log.severe(
      'No JSON themes found in assets. Falling back to bare defaults.',
    );
    initialTheme = AppTheme();
  } else {
    initialTheme = themes['dark'] ?? themes.values.first;
    log.info('Loaded themes: ${themes.keys.join(', ')}');
  }
  AppThemeManager.instance.themeNotifier = ValueNotifier(initialTheme);
  

  runApp(MyApp(allThemes: themes));
}

class MyApp extends StatelessWidget {
  final Map<String, AppTheme> allThemes;

  const MyApp({super.key, required this.allThemes});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: AppThemeManager.instance.themeNotifier,
      builder: (context, currentTheme, _) {
        return MaterialApp(
          title: 'Centrode',
          debugShowCheckedModeBanner: false,
          theme: currentTheme.toThemeData(),
          home: const WorkspaceHubScreen(),
        );
      },
    );
  }
}
