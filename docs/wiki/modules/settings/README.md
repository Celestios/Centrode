# Settings Module

---

## Overview

The settings module provides a standalone, frameless, dual-pod Smart Glass modal for customizing Centrode. It allows users to configure application themes, GLSL liquid glass shaders, canvas grid snapping, and will host deep layout, relation, and persistence options.

---

## Structure

```
lib/features/settings/
├── presentation/
│   ├── settings_category.dart           # SettingsCategory enum (6 categories, icons, labels)
│   └── settings_controller.dart         # SettingsController (ChangeNotifier, scroll-spy, search, theme)
└── ui/
    ├── settings_screen.dart             # Modal host, outer contrasting shell, workspace blur & un-minimize animation
    └── widgets/
        ├── settings_category_sidebar.dart # Left pod (195px, vertical category navigation)
        ├── settings_canvas_pod.dart       # Right pod (continuous scrollable canvas, Telegram-style blur header)
        └── sections/
            ├── top_sections.dart              # Theme, Shader, and Canvas settings cards
            ├── ontology_settings_section.dart # Node types and taxonomy settings
            ├── physics_settings_section.dart  # Force-directed layout and simulation settings
            ├── relations_settings_section.dart# Default routing and line style settings
            └── storage_settings_section.dart  # Auto-save and persistence settings
```

---

## Key Components

- **SettingsScreen** — Frameless modal dialog rendered on top of the workspace with a soft workspace backdrop blur and click-outside dismissal barrier. Anchored with an un-minimize scale/fade animation originating from the launcher button.
- **SettingsCategorySidebar** — Narrow left pod displaying active category pills with bidirectional scroll-spy synchronization.
- **SettingsCanvasPod** — Right scrollable content pod with continuous section spacing and bottom clearance, topped by a Telegram-style feathered dissipation blur overlay.
- **SettingsTopControlsBar** — Expandable search field (`130px` resting, `240px` focused) paired with a circular `#E53935` close button.
- **SettingsController** — Single reactive coordinator managing category selection, live search query filtering, and scroll navigation callbacks.

---

## Architecture & Design Invariants

- **Dual-Pod Smart Glass**: Both pods sit on an outer contrasting shell (`Color(0xFF0A0A0E)` in dark mode) and utilize `ContinuousRectangleBorder` with matching `podCornerRadius = 32.0` squircle curvature.
- **Telegram-Style Feathered Blur**: Uses `ShaderMask` with continuous cubic alpha decay and `BackdropFilter` clipped to the pod's exact squircle shape to dissolve scrolling content without hard boundary lines.
- **Zero Fallbacks**: Clean event dispatching from UI widgets to `SettingsController` without defensive null fallbacks.

---

## Related Specifications

- [Theme System](../../design/themes.md) — Application themes and color palettes
- [Shaders](../../design/shaders.md) — GLSL liquid glass shader parameters
- [Glass Panel](../shared/glass-panel.md) — Glassmorphic rendering components
