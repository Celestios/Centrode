# Workspace Module

---

## Overview

The workspace module provides the home screen / project management hub. It's the entry point after app boot, where users select, create, and manage maps (knowledge graphs).

---

## Structure

```
lib/features/workspace/ui/
├── workspace_hub_screen.dart          # Main workspace screen
├── liquid_glass_test_screen.dart      # Glass shader test screen
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

## Data Sources

- Maps are stored as local SurrealDB databases in `maps/` directory
- Recent maps tracked in `data/recent.json`
- Map scanning via `shared/utils/map_scanner.dart`
