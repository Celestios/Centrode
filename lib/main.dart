import 'dart:async';
import 'package:flutter/material.dart';
import 'infrastructure/bootstrap/app_bootstrap.dart';
import 'presentation/boot/boot_splash_screen.dart';
import 'features/workspace/ui/workspace_hub_screen.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/theme/app_theme_manager.dart';

Future<void> main() async {
  final appContext = await AppBootstrap.initializeFast();
  runApp(CentrodeApp(allThemes: appContext.allThemes));
}

class CentrodeApp extends StatelessWidget {
  final Map<String, AppTheme> allThemes;

  const CentrodeApp({super.key, this.allThemes = const {}});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppTheme>(
      valueListenable: AppThemeManager.instance.themeNotifier,
      builder: (context, currentTheme, _) {
        return MaterialApp(
          title: 'Centrode',
          color: Colors.transparent,
          debugShowCheckedModeBanner: false,
          theme: currentTheme.toThemeData(),
          home: const BootSplashScreen(
            child: WorkspaceHubScreen(),
          ),
        );
      },
    );
  }
}
