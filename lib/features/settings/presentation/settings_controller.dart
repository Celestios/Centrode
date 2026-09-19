import 'package:flutter/material.dart';
import 'package:centrode/shared/logging.dart';
import 'package:centrode/shared/utils/boot_cache.dart';
import 'package:centrode/presentation/theme/app_theme.dart';
import 'package:centrode/presentation/theme/app_theme_manager.dart';
import 'package:centrode/presentation/theme/theme_repository.dart';
import 'settings_category.dart';

class SettingsController extends ChangeNotifier {
  final Logger _log = Logger('SettingsController');

  SettingsCategory _selectedCategory = SettingsCategory.appearance;
  String _searchQuery = '';
  bool _disposed = false;

  void Function(SettingsCategory category)? onRequestScrollToCategory;

  String _currentThemeName = BootCache.cachedThemeName;
  Map<String, AppTheme> _availableThemes = const {};

  bool _enableLiquidGlass = true;
  double _refractionStrength = 0.16;
  double _blurRadius = 7.0;

  double _gridSpacing = 20.0;
  bool _snapToGrid = true;
  double _snapDistance = 40.0;

  SettingsController() {
    _loadInitialThemes();
  }

  SettingsCategory get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  String get currentThemeName => _currentThemeName;
  Map<String, AppTheme> get availableThemes => _availableThemes;

  bool get enableLiquidGlass => _enableLiquidGlass;
  double get refractionStrength => _refractionStrength;
  double get blurRadius => _blurRadius;

  double get gridSpacing => _gridSpacing;
  bool get snapToGrid => _snapToGrid;
  double get snapDistance => _snapDistance;

  void selectCategory(SettingsCategory category, {bool requestScroll = true}) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
    if (requestScroll) {
      onRequestScrollToCategory?.call(category);
    }
  }

  void onSectionVisible(SettingsCategory category) {
    if (_selectedCategory != category) {
      _selectedCategory = category;
      notifyListeners();
    }
  }

  void updateSearchQuery(String query) {
    _searchQuery = query.trim().toLowerCase();
    notifyListeners();
  }

  Future<void> _loadInitialThemes() async {
    _availableThemes = await ThemeLoader.loadBundledThemes();
    if (_disposed) return;
    notifyListeners();
  }

  void setTheme(String themeName) {
    if (_currentThemeName == themeName) return;
    final theme = _availableThemes[themeName];
    if (theme != null) {
      _currentThemeName = themeName;
      BootCache.cachedThemeName = themeName;
      AppThemeManager.instance.currentTheme = theme;
      _log.info('Theme changed to: $themeName');
      notifyListeners();
    }
  }

  void setEnableLiquidGlass(bool value) {
    _enableLiquidGlass = value;
    notifyListeners();
  }

  void setRefractionStrength(double value) {
    _refractionStrength = value;
    notifyListeners();
  }

  void setBlurRadius(double value) {
    _blurRadius = value;
    notifyListeners();
  }

  void setGridSpacing(double value) {
    _gridSpacing = value;
    notifyListeners();
  }

  void setSnapToGrid(bool value) {
    _snapToGrid = value;
    notifyListeners();
  }

  void setSnapDistance(double value) {
    _snapDistance = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
