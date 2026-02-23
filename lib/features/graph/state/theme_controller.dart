import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:mycelium/src/rust/bridge/api.dart';
import '../../../core/config/app_config.dart';
import '../domain/styling.dart';

/// Exclusively manages global visual rules and theme persistence via FFI.
class ThemeController extends ChangeNotifier {
  final Logger _log = Logger('ThemeController');
  final AppHandle _api;

  ThemeConfig? activeTheme;
  List<ThemeConfig> availableThemes = [];
  String? errorMessage;

  ThemeController(this._api);

  Future<void> loadThemes() async {
    try {
      final ffiThemes = await _api.getAllThemes();
      availableThemes = ffiThemes
          .map(
            (t) => ThemeConfig.fromRawJson(
              t.id ?? AppConfig.core.unknownId,
              t.name,
              t.config,
            ),
          )
          .toList();

      final activeThemeId = await _api.getActiveThemeId();
      if (activeThemeId != null) {
        activeTheme = availableThemes.firstWhere(
          (t) => t.id == activeThemeId,
          orElse: () => availableThemes.isNotEmpty
              ? availableThemes.first
              : _createDefaultTheme(),
        );
      } else {
        activeTheme = availableThemes.isNotEmpty
            ? availableThemes.first
            : _createDefaultTheme();
      }
      notifyListeners();
    } catch (e) {
      _log.severe('Failed to load themes', e);
      errorMessage = "Theme load failed";
      notifyListeners();
    }
  }

  Future<void> setActiveTheme(String themeId) async {
    try {
      await _api.setActiveThemeId(themeId: themeId);
      activeTheme = availableThemes.firstWhere((t) => t.id == themeId);
      notifyListeners();
    } catch (e) {
      _log.severe('Failed to switch theme', e);
      errorMessage = "Theme switch failed";
      notifyListeners();
    }
  }

  ThemeConfig _createDefaultTheme() {
    return ThemeConfig(
      id: "default",
      name: "Default Theme",
      globalDefault: StyleProfile(),
      typeDefinitions: {
        "Info": StyleProfile(bgColor: AppConfig.graph.visual.defaultInfoBg),
        "Task": StyleProfile(bgColor: AppConfig.graph.visual.defaultTaskBg),
        "Inter": StyleProfile(bgColor: AppConfig.graph.visual.defaultInterBg),
      },
    );
  }
}
