import 'package:flutter/foundation.dart';
import 'package:centrode/presentation/theme/app_theme.dart';

class AppThemeManager {
  static final AppThemeManager instance = AppThemeManager._();
  AppThemeManager._();

  ValueNotifier<AppTheme> themeNotifier = ValueNotifier(AppTheme.fromMap({}));

  AppTheme get currentTheme => themeNotifier.value;
  set currentTheme(AppTheme theme) => themeNotifier.value = theme;
}
