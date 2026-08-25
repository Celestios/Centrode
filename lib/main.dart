import 'dart:async';
import 'package:flutter/material.dart';
import 'infrastructure/bootstrap/app_bootstrap.dart';
import 'features/workspace/ui/workspace_hub_screen.dart';
import 'presentation/theme/app_theme.dart';
import 'presentation/theme/app_theme_manager.dart';

Future<void> main() async {
  final appContext = await AppBootstrap.initialize();
  runApp(MyApp(allThemes: appContext.allThemes));
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
