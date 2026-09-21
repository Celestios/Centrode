# Theme System

---

## Overview

---

## Overview

Centrode uses a JSON-based theme system. Themes define colors, typography, and shape properties for the entire application.

---

## Theme Files

Located in `assets/themes/`:
- `dark.json` — Dark theme (default)
- `light.json` — Light theme (calibrated cool neutral mist `#EAECEF` to avoid pure white glare)
- `forest.json` — Forest/nature theme
- `dracula.json` — Dracula theme (vibrant purple `#BD93F9` & gothic dark `#282A36`)
- `nord.json` — Nord theme (arctic frost `#88C0D0` & dark polar night `#2E3440`)
- `catppuccin.json` — Catppuccin Mocha theme (mauve `#CBA6F7` & deep crust `#1E1E2E`)
- `catppuccin_latte.json` — Catppuccin Latte theme (warm light pastel `#8839EF` & latte crust `#E6E9EF`)
- `tokyo_night.json` — Tokyo Night theme (neon blue `#7AA2F7` & night dark `#1A1B26`)

---

## AppTheme

`lib/presentation/theme/app_theme.dart` defines the `AppTheme` class:

### Core Palette (5 Chromatic Anchors)
Themes in `assets/themes/*.json` define exactly **5 independent chromatic anchors**:
- `primaryColor`, `secondaryColor`, `tertiaryColor`
- `accentColor`, `canvasAccentColor`

All neutral surfaces (`scaffoldBackgroundColor`, `cardColor`, `dividerColor`), typography colors (`textColor`, `bodyTextColor`), app bar styling, and the theme `brightness` are **automatically and deterministically derived** at runtime from these 5 anchors using `ColorTheoryEngine.deriveThemeSurfaces` and `ColorTheoryEngine.deriveBrightness`.

See [Color Philosophy](color-philosophy.md) for the derivation rules and semantic mapping of these 5 anchors into 20+ specialized element tokens.

### Typography & Shape (Configured in JSON)
- `fontFamily`, `bodyFontSize`, `bodyFontWeight`
- `borderRadius`, `appBarElevation`, `appBarTitleFontSize`, `appBarTitleFontWeight`
- `useMaterial3`

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

`shared/utils/color_theory_engine.dart` provides algorithms for:
- Complementary, analogous, triadic, tetradic, and monochromatic color harmonies in OKLCH space
- Dynamic polarity and optical elevation model (`elevationStep = 0.04`, `microElevationStep = 0.025`, `recessedStep = 0.05`)
- Symmetrical recessed/elevated control surfaces and glare-free calibrated canvas grounds
- Used for auto-generating tag colors, node palettes, and universal surface hierarchies (see [Color Philosophy](color-philosophy.md))

---

## Full Spec

See [gui_specification.yaml](../gui_specification.yaml) for the complete color palette, interaction states, and visual specifications (1700+ lines).
