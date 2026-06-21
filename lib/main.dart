import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mycelium/infrastructure/telemetry/logging.dart';
import 'package:mycelium/src/rust/frb_generated.dart';
import 'package:window_manager/window_manager.dart';
import 'infrastructure/telemetry/log_manager.dart';
import 'features/workspace/ui/project_selector_screen.dart'; // your existing screen
import 'presentation/theme/app_theme.dart'; // from previous step
import 'presentation/theme/theme_repository.dart'; // from previous step
import 'presentation/theme/app_theme_manager.dart';
import 'package:mycelium/shared/widgets/glass_panel/glass_panel.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    debugPrintRebuildDirtyWidgets = true;
    debugProfileBuildsEnabled = true;
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

  final log = Logger('BootSequence');
  log.info('Rust FFI loaded. Mycelium core ready.');

  final themes = await ThemeLoader.loadBundledThemes();
  if (themes.isEmpty) {
    log.severe(
      'No JSON themes found in assets. Falling back to bare defaults.',
    );
    AppThemeManager.instance.themeNotifier = ValueNotifier(AppTheme());
  } else {
    final initialTheme = themes['dark'] ?? themes.values.first;
    AppThemeManager.instance.themeNotifier = ValueNotifier(initialTheme);
    log.info('Loaded themes: ${themes.keys.join(', ')}');
  }

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
          title: 'Mycelium',
          theme: currentTheme.toThemeData(),
          home: const ProjectSelectorScreen(),
        );
      },
    );
  }
}
