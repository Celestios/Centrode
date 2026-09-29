# Shared Module

---

## Overview

The shared module contains reusable widgets, elements, surface abstractions, utilities, and domain helpers used across all features.

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
├── elements/                          # Unified Centrode shared UI elements
│   ├── elements.dart                  # Master barrel export
│   ├── centrode_badge.dart            # History & notification badge
│   ├── centrode_button.dart           # Primary button
│   ├── centrode_close_button.dart     # Circular 34px close button
│   ├── centrode_color_controls.dart   # Color adjustments & actions
│   ├── centrode_color_picker.dart     # Color picker widget
│   ├── centrode_compact_slider.dart   # Debossed groove & crystal lens slider
│   ├── centrode_context_menu.dart     # Centralized context menu & overlay
│   ├── centrode_declarative_dialog.dart # Corner toast banner & capillary bar
│   ├── centrode_divider.dart          # Horizontal and vertical divider lines
│   ├── centrode_dropdown.dart         # Droplet morphing dropdown selector
│   ├── centrode_expandable_menu_bar.dart # Title bar expandable menu
│   ├── centrode_icon_button.dart      # Icon button
│   ├── centrode_icon_tile.dart        # Icon tile
│   ├── centrode_modal_dialog.dart     # Detached floating island modal dialog
│   ├── centrode_panel.dart            # Compatibility surface wrapper
│   ├── centrode_segmented_control.dart # Fluid stretch-glide segmented control
│   ├── centrode_toggle.dart           # Liquid glass switch toggle
│   ├── centrode_window_controls.dart  # Window control buttons (min, max, close)
│   ├── centrode_window_title_bar.dart # Frameless window title bar
│   ├── logo_home_button.dart          # Logo/home button
│   ├── ribbon_capsule.dart            # Capsule-shaped ribbon
│   ├── submenu_button_data.dart       # Submenu data model
│   └── surfaces/                      # Surface primitives and mechanics
│       ├── surfaces.dart              # Surfaces barrel export
│       ├── surface_mode.dart          # CentrodeSurfaceMode (quality vs perf)
│       ├── double_edge_surface.dart   # Double stepped specular bevel container
│       ├── double_edge_painter.dart   # Custom canvas stepped specular bevel painter
│       ├── inset_surface.dart         # Debossed wells, capillary channels, fields
│       └── gliding_lens.dart          # Volume-conserving fluid lens selector
├── utils/
│   ├── app_paths.dart                 # Application directory paths
│   ├── boot_cache.dart                # Boot-phase cache helpers
│   ├── color_theory_engine.dart       # OKLCH perceptual color theory engine
│   ├── color_utils.dart               # Color utilities
│   ├── date_utils.dart                # Date formatting
│   ├── geometry.dart                  # Geometric calculations
│   ├── map_scanner.dart               # Maps directory scanner
│   └── name_generator.dart            # Random name generation
└── widgets/
    ├── canvas_camera_physics.dart       # Rubber-band & spring math
    ├── canvas_interactive_viewer.dart  # Custom InteractiveViewer (re-exports interactive_viewer/)
    ├── context_menu/
    │   ├── context_menu_item.dart      # Context menu data and item models
    │   └── context_menu_layout_delegate.dart # Custom single-child layout delegate
    ├── unbounded_stack.dart            # Stack without bounds
    ├── color_palette/
    │   └── color_palette.dart          # Color palette picker
    ├── unravel_slider/                 # Sigmoid unravelling segmented slider
    │   ├── unravel_slider.dart         # Barrel export
    │   ├── domain/
    │   │   └── unravel_slider_metrics.dart # Pure mathematical layout engine
    │   └── presentation/
    │       ├── unravel_slider.dart     # Generic interactive slider widget
    │       └── unravel_slider_theme.dart # Configurable styling & theme
    └── interactive_viewer/             # CanvasInteractiveViewer internals, modularized:
        ├── canvas_geometry_utils.dart  # Coordinate/geometry transforms
        ├── canvas_gesture_classifier.dart # Gesture intent classification
        ├── canvas_viewport_physics.dart   # Viewport spring physics
        └── canvas_viewport_transformer.dart # Pan/zoom transform application
```

---

## Key Components

### Surface System & Glass Panel

The surface system (`shared/elements/surfaces/` and `shared/elements/centrode_panel.dart`) provides glassmorphic UI containers and fluid optical mechanics:
- `CentrodePanel` (`GlassPanel`) — main surface container backed by `CentrodeDoubleEdgeSurface`
- `CentrodeDoubleEdgeSurface` — two-step stepped specular bevel container with ambient dye bloom
- `CentrodeGlidingLens` — reusable volume-conserving fluid lens selector
- `CentrodeInsetSurface` & `CentrodeInsetPainter` — debossed wells, capillary channels, and fields
- `CentrodeSurfaceMode` — dual surface mode (quality refractive optics vs lightweight performance)

See [Glass Panel & Surfaces documentation](glass-panel.md) for details.

### Canvas Interactive Viewer

`CanvasInteractiveViewer` extends Flutter's `InteractiveViewer` with:
- Custom pan/zoom constraints with elastic boundary spring-back
- Rubber-band overscroll feedback via `CanvasCameraPhysics`
- Mouse wheel zoom
- Canvas-space coordinate transforms
- `onElasticOverscroll` callback for visual layer reactions

Its internals are modularized under `widgets/interactive_viewer/`: geometry utilities (`canvas_geometry_utils.dart`), gesture classification (`canvas_gesture_classifier.dart`), viewport physics (`canvas_viewport_physics.dart`), and transform application (`canvas_viewport_transformer.dart`).

### Unravel Slider

The unravel slider system (`shared/widgets/unravel_slider/`) provides a non-linear, fisheye-style segmented control:
- `UnravelSlider<T>` — generic segmented slider supporting touch drag, trackpad scrolling, and keyboard arrow keys
- `UnravelSliderMetrics` — pure mathematical domain engine caching logit/sigmoid anchor vectors
- `UnravelSliderThemeData` — typography, colors, padding, and border theming

### Elements

Unified shared UI primitives under `lib/shared/elements/` with the `Centrode` prefix:
- `CentrodeButton`, `CentrodeIconButton`, `CentrodeIconTile`
- `CentrodeDropdown<T>` — droplet morphing dropdown selector with vertical gliding lens
- `CentrodeContextMenu` — centralized context menu overlay with gliding lens support
- `CentrodeSegmentedControl` — fluid stretch-glide segmented control
- `CentrodeCompactSlider` — debossed groove channel and crystal ball lens handle
- `CentrodeToggle` — liquid glass switch toggle
- `CentrodeBadge` — micro-refractive jewel pill with animated counters
- `CentrodeDivider` — etched horizontal and vertical divider lines
- `CentrodeExpandableMenuBar` — title bar expandable menu
- `CentrodeModalDialog` & `CentrodeDeclarativeDialog` — floating island dialogs and toast banners
- `CentrodeWindowTitleBar` & `CentrodeWindowControls` — frameless desktop window controls
