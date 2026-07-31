// lib/core/theme/theme_loader.dart
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:centrode/presentation/theme/app_theme.dart';

class ThemeLoader {
  static Future<Map<String, AppTheme>> loadBundledThemes() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    final allAssets = manifest.listAssets();
    final themePaths = allAssets.where(
      (path) => path.startsWith('assets/themes/') && path.endsWith('.json'),
    );

    final themes = <String, AppTheme>{};
    for (final path in themePaths) {
      final jsonString = await rootBundle.loadString(path);
      final map = json.decode(jsonString) as Map<String, dynamic>;
      final name = path.split('/').last.replaceAll('.json', '');
      themes[name] = AppTheme.fromMap(map);
    }
    return themes;
  }
}
