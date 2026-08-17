# Theme System

---

## Overview

Centrode uses a JSON-based theme system. Themes define colors, typography, and shape properties for the entire application.

---

## Theme Files

Located in `assets/themes/`:
- `dark.json` — Dark theme (default)
- `light.json` — Light theme
- `forest.json` — Forest/nature theme

---

## AppTheme

`lib/presentation/theme/app_theme.dart` defines the `AppTheme` class:

### Core Palette
- `primaryColor`, `secondaryColor`, `accentColor`
- `canvasAccentColor`, `scaffoldBackgroundColor`
- `cardColor`, `dividerColor`, `textColor`

### Typography
- `fontFamily`, `bodyFontSize`, `bodyFontWeight`
- `bodyTextColor`

### Shape
- `borderRadius`

### AppBar
- `appBarBackgroundColor`, `appBarForegroundColor`
- `appBarElevation`, `appBarTitleFontSize`, `appBarTitleFontWeight`

### Material 3
- `useMaterial3`, `brightness`

---

## Theme Loading

1. `ThemeLoader.loadBundledThemes()` reads JSON files from `assets/themes/`
2. Each JSON parsed into `AppTheme` objects
3. Stored in `Map<String, AppTheme>` (key = theme name)
4. Default theme: `dark`

---

## Theme Management

`AppThemeManager` singleton manages active theme:

```dart
AppThemeManager.instance.themeNotifier = ValueNotifier(initialTheme);
```

Widgets react via `ValueListenableBuilder`:

```dart
ValueListenableBuilder<AppTheme>(
  valueListenable: AppThemeManager.instance.themeNotifier,
  builder: (context, currentTheme, _) {
    return MaterialApp(theme: currentTheme.toThemeData());
  },
)
```

---

## Map Themes

Separate from app themes — per-map theme stored in SurrealDB:

- `MapTheme` — Rust type with `ThemeFields`
- Managed via FFI: `create_theme()`, `update_theme()`, `set_active_theme()`
- Applied to nodes and relations within a specific map

---

## Color Harmony

`shared/utils/color_harmony_generator.dart` provides algorithms for:
- Complementary colors
- Analogous colors
- Triadic colors
- Used for auto-generating tag colors and node palettes

---

## Full Spec

See [gui_specification.yaml](../gui_specification.yaml) for the complete color palette, interaction states, and visual specifications (1700+ lines).
