# Workspace Module

---

## Overview

The workspace module provides the home screen / project management hub. It's the entry point after app boot, where users select, create, and manage maps (knowledge graphs).

---

## Structure

```
lib/features/workspace/
├── presentation/
│   └── workspace_hub_controller.dart     # WorkspaceHubController (ChangeNotifier) —
│                                         #   map create/open/delete orchestration via
│                                         #   MapManager + MapStorageGateway
└── ui/
    ├── workspace_hub_screen.dart          # Main workspace screen
    └── widgets/
        ├── left_panel/
        │   ├── left_panel.dart            # Left sidebar
        │   ├── quick_actions_section.dart # Quick action buttons
        │   └── panel_footer_section.dart  # Footer with settings
        ├── main_content/
        │   ├── main_content_area.dart     # Central content area
        │   ├── analytics_box.dart         # Usage analytics display
        │   ├── empty_section_card.dart    # Empty state placeholder
        │   ├── map_section.dart           # Single map display
        │   ├── maps_section.dart          # Maps grid/list
        │   ├── project_card.dart          # Project card widget
        │   ├── projects_section.dart      # Projects grid/list
        │   ├── recent_section.dart        # Recent maps
        │   └── templates_section.dart     # Templates display
        └── shared/
            ├── horizontal_scroll_row.dart # Horizontal scroll utility
            └── section_header.dart        # Section header widget
```

---

## Key Components

- **WorkspaceHubScreen** — Root screen, assembles left panel + main content
- **LeftPanel** — Navigation sidebar with quick actions
- **MainContentArea** — Displays maps, projects, templates, recent items
- **MapSection/MapsSection** — Map cards with preview, open, delete actions
- **ProjectsSection** — Project management
- **TemplatesSection** — Template browsing and instantiation

---

## Test Harness

`LiquidGlassDemo` lives in `test/prototype/liquid_glass_test_screen.dart`, outside the production workspace UI. It provides draggable [glass panels](../shared/glass-panel.md) and shader parameter sliders for testing. `test/liquid_glass_rendering_test.dart` mounts it in a `MaterialApp` and checks for four `GlassPanel` widgets and one `GlassGroup`.

---

## Data Sources

- Maps are stored as local SurrealDB databases managed by the daemon's `EngineManager` (`<data_local>/centrode/data`)
- Map lifecycle operations go through the [`MapStorageGateway`](../graph/presentation.md) abstraction, implemented by [DaemonGateway](../infrastructure/README.md) (wraps the Rust `DaemonHandle`: list/recent/create/delete/rename/duplicate/touch)
- Recent maps tracked in `data/recent.json`
- Filesystem scanning via `shared/utils/map_scanner.dart` complements daemon-backed listing
