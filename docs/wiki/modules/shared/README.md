# Shared Module

---

## Overview

The shared module contains reusable widgets, utilities, and domain helpers used across all features.

---

## Structure

```
lib/shared/
├── color_utils.dart                   # Color manipulation utilities
├── copy_buffer.dart                   # Copy/paste buffer management
├── logging.dart                       # Logger setup (Logger class)
├── traceable_notifier.dart            # Debug notifier tracer
├── domain/
│   └── raw_uuid.dart                  # UUID v4 type
├── elements/                          # Shared UI elements
│   ├── centrode_button.dart           # Primary button
│   ├── centrode_icon_button.dart      # Icon button
│   ├── centrode_icon_tile.dart        # Icon tile
│   ├── centrode_segmented_control.dart # Segmented control
│   ├── glass_divider.dart             # Glass-styled divider
│   ├── glass_presets.dart             # Glass rendering presets
│   ├── history_badge_button.dart      # Undo/redo badge
│   ├── hover_expandable_menu_bar.dart # Expanding menu
│   ├── logo_home_button.dart          # Logo/home button
│   ├── ribbon_capsule.dart            # Capsule-shaped ribbon
│   ├── submenu_button_data.dart       # Submenu data model
│   ├── window_control_buttons.dart    # Min/max/close buttons
│   └── window_title_bar.dart          # Custom title bar
├── utils/
│   ├── app_paths.dart                 # Application directory paths
│   ├── color_harmony_generator.dart   # Color harmony algorithms
│   ├── color_utils.dart               # Color utilities
│   ├── date_utils.dart                # Date formatting
│   ├── geometry.dart                  # Geometric calculations
│   ├── map_scanner.dart               # Maps directory scanner
│   ├── name_generator.dart            # Random name generation
│   └── recent_maps_store.dart         # Recent maps persistence
└── widgets/
    ├── canvas_interactive_viewer.dart  # Custom InteractiveViewer
    ├── context_menu_overlay.dart       # Context menu system
    ├── unbounded_stack.dart            # Stack without bounds
    ├── color_palette/
    │   └── color_palette.dart          # Color palette picker
    └── glass_panel/                    # Glassmorphic panel widget
        ├── glass_panel.dart            # Barrel export
        └── src/
            ├── glass_alert_dialog.dart
            ├── glass_group.dart
            ├── glass_mode.dart
            ├── glass_panel_widget.dart
            ├── glass_settings.dart
            ├── glass_shader_provider.dart
            └── glass_stage.dart
```

---

## Key Components

### Glass Panel

The glass panel system (`shared/widgets/glass_panel/`) provides glassmorphic UI containers:
- `GlassPanelWidget` — main glass container
- `GlassShaderProvider` — compiles and caches the GLSL shader
- `GlassSettings` — glass effect parameters
- `GlassAlertDialog` — glass-styled dialogs
- `GlassGroup` — grouped glass elements

See [Glass Panel documentation](glass-panel.md) for details.

### Canvas Interactive Viewer

`CanvasInteractiveViewer` extends Flutter's `InteractiveViewer` with:
- Custom pan/zoom constraints
- Mouse wheel zoom
- Canvas-space coordinate transforms

### Elements

Shared UI primitives used across all features — buttons, dividers, menu bars, window controls.
