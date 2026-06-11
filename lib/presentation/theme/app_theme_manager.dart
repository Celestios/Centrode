import 'package:flutter/foundation.dart';
import 'package:mycelium/presentation/theme/app_theme.dart';

class AppThemeManager {
  static final AppThemeManager instance = AppThemeManager._();
  AppThemeManager._();

  late final ValueNotifier<AppTheme> themeNotifier;

  AppTheme get currentTheme => themeNotifier.value;
  set currentTheme(AppTheme theme) => themeNotifier.value = theme;
}
