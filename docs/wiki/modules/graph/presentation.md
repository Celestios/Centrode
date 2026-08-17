# Presentation Layer

---

## Overview

The presentation layer manages view state, style resolution, viewport transforms, and coordinates between the interaction engine and the UI rendering.

---

## Core Files

| File | Role |
|------|------|
| `presentation/editor_state.dart` | Editor state — active tool, mode |
| `presentation/view_state.dart` | View state — zoom, pan, selection |
| `presentation/viewport_state.dart` | Viewport transform state |
| `presentation/selection_state.dart` | Selection management |
| `presentation/drag_state.dart` | Drag operation state |
| `presentation/node_render_state.dart` | Node render state cache |
| `presentation/style_manager.dart` | Style resolution and caching |
| `presentation/style_flyweight.dart` | Flyweight pattern for style instances |
| `presentation/theme_manager.dart` | Theme integration |
| `presentation/map_manager.dart` | Map (project) management |
| `presentation/node_ports.dart` | Port position calculations |
| `presentation/relation_utils.dart` | Relation utility functions |
| `presentation/view_state_geometry.dart` | Geometry calculations for view state |
| `presentation/palette_action_registry.dart` | Palette action registration |
| `presentation/workspace_tabs_controller.dart` | Multi-tab session management |

---

## Strategies

`presentation/strategies/` contains strategy pattern implementations:

| Strategy | File | Responsibility |
|----------|------|----------------|
| `NodeLayoutStrategy` | `node_layout_strategy.dart` | Determines node layout parameters |
| `NodeStyleStrategy` | `node_style_strategy.dart` | Resolves node visual styles |
| `RelationStyleStrategy` | `relation_style_strategy.dart` | Resolves relation visual styles |
| `ContainerZoomStrategy` | `container_zoom_strategy.dart` | Zoom-to-fit for containers |
| `SignificanceStrategy` | `significance_strategy.dart` | Visual significance levels |
| `NodeTextSpanBuilder` | `node_text_span_builder.dart` | Builds text spans for rendering |

---

## Action Handlers

`presentation/handlers/` processes user actions:

| Handler | File | Responsibility |
|---------|------|----------------|
| `ContentActionHandler` | `content_action_handler.dart` | Text/content operations |
| `SpatialActionHandler` | `spatial_action_handler.dart` | Position/size operations |
| `TopologyActionHandler` | `topology_action_handler.dart` | Connection/relation operations |

---

## Viewport System

The viewport manages pan/zoom transforms:
- `ViewportController` wraps `TransformationController`
- Persists viewport state to Rust (per-map)
- Restores viewport on map load
- Supports viewport animations (zoom-to-fit, etc.)

---

## Style Resolution

Styles are resolved in layers:
1. **Base style**: Node type defaults
2. **Custom style**: User-applied `NodeStyle`
3. **Theme style**: Active map theme overrides
4. **Resolved style**: Final computed style (cached in `resolvedStyle`)

`StyleFlyweight` caches resolved styles to avoid recomputation.
