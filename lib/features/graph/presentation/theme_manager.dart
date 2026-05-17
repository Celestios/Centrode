import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:mycelium/presentation/theme/graph_theme.dart';
import 'package:mycelium/src/rust/bridge/api.dart';
import 'package:mycelium/src/rust/domain/theme.dart' as frb;

class ThemeController extends ChangeNotifier {
  final AppHandle _appHandle;
  final Logger _log = Logger('ThemeController');

  GraphTheme? _currentGraphTheme;
  GraphTheme? get currentGraphTheme => _currentGraphTheme;

  ThemeController(this._appHandle);

  Future<void> initialize(ThemeData globalTheme) async {
    final activeId = await _appHandle.getActiveThemeId();

    if (activeId != null) {
      final frb.Theme? saved = await _appHandle.getTheme(key: activeId);
      if (saved != null) {
        final loaded = GraphTheme.fromRust(saved);
        _currentGraphTheme = GraphTheme.fromRust(saved);
        _log.info('Loaded existing graph theme: ${loaded.name}');
        notifyListeners();
        return;
      }
    }

    // 2. No persisted theme → one-time snapshot from global ThemeData
    final defaultTheme = GraphTheme.fromThemeData(globalTheme);
    _currentGraphTheme = defaultTheme;
    _log.info('Created default graph theme from global theme');
    notifyListeners();

    // 3. Persist in background, keep in‑memory theme regardless of failure
    _persistAndActivate(defaultTheme).catchError((e, st) {
      _log.severe('Failed to persist default graph theme', e, st);
    });
  }

  Future<void> selectTheme(String themeId) async {
    final frb.Theme? rustTheme = await _appHandle.getTheme(key: themeId);
    if (rustTheme != null) {
      _currentGraphTheme = GraphTheme.fromRust(rustTheme);
      await _appHandle.setActiveThemeId(themeId: themeId);
      notifyListeners();
    }
  }

  Future<void> _persistAndActivate(GraphTheme theme) async {
    final (String key, frb.ThemeFields fields) = theme.toRust();
    await _appHandle.createTheme(key: key, fields: fields);
    await _appHandle.setActiveThemeId(themeId: theme.id);
  }
}
