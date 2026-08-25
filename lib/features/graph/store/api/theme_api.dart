import 'dart:async';
import 'package:centrode/src/rust/domain/theme.dart';

abstract interface class ThemeApi {
  Future<void> createTheme({required String key, required ThemeFields fields});
  Future<MapTheme?> getTheme({required String key});
  Future<List<MapTheme>> getAllThemes();
  Future<void> updateTheme({required MapTheme theme});
  Future<void> setActiveTheme({required String themeKey});
  Future<void> setActiveThemeId({required String themeId});
  Future<String?> getActiveThemeId();
}
