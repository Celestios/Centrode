# Graph Module

The graph module is the core feature of Centrode — an infinite canvas for creating, editing, and connecting knowledge nodes.

---

## Module Structure

```
lib/features/graph/
├── domain/behaviors/       # Node bounds & containment behaviors [Tier 3]
├── engine/                 # Interaction FSM, gesture handling [Tier 2]
│   └── states/             # 11 FSM states + 2 utility managers
├── models/                 # UiNode types, commands, DTOs [Tier 3]
│   └── commands/           # 18 concrete commands (21 files)
├── presentation/           # View state, strategies, handlers [Tier 2]
│   ├── handlers/           # Action handlers (content, spatial, topology)
│   ├── strategies/         # Layout, style, text, container zoom strategies
│   └── dtos/               # Data transfer objects
├── store/                  # Sync engine, mutations, queries [Tier 3]
│   └── modules/            # 12 store mutation modules (incl. graph_spatial)
└── ui/                     # Canvas widgets, rendering [Tier 1]
    ├── canvas/             # Canvas, painters, layers, text
    │   ├── layers/         # 5 paint layers
    │   ├── painters/       # 15 painter/renderer files
    │   ├── text/           # Text editing system
    │   ├── utils/          # Paint utilities (container, dashed box, perimeter dock)
    │   └── widgets/        # Canvas child widgets (attachment shelf, media node)
    └── widgets/            # Sidebars, overlays, inspectors
```

---

## Key Files

| File | Role |
|------|------|
| `ui/graph_screen.dart` | Main scaffold — assembles canvas + overlays |
| `ui/canvas/graph_canvas.dart` | Infinite canvas widget — core interaction + rendering |
| `engine/interaction_engine.dart` | FSM engine — processes raw PointerEvents |
| `engine/base_interaction_state.dart` | Sealed base class for all interaction states |
| `models/graph_node.dart` | `UiNode` sealed class — all 9 node types |
| `models/commands/base.dart` | `GraphCommand` abstract — command pattern base |
| `store/graph_api.dart` | `GraphApi` abstract — FFI interface |
| `store/modules/graph_sync_engine.dart` | Sync engine — Rust stream → Dart state |
| `presentation/editor_state.dart` | Editor state management |
| `presentation/viewport_state.dart` | Viewport pan/zoom state |

---

## Subsystems

- [Canvas & Rendering](canvas.md) — painting pipeline, layers, node renderers
- [Interaction Engine](interaction-engine.md) — FSM states, gesture handling
- [Node Types](node-types.md) — all 9 node types, UiNode sealed class, attachments
- [Commands](commands.md) — command pattern, 18 commands (21 files), undo/redo
- [Store & Sync](store.md) — sync engine, mutations, queries, spatial index
- [Presentation Layer](presentation.md) — view state, strategies, viewport
- **File Attachments** — content-addressable asset vault, attachment shelf widget, multi-attachment support on INode/TaskNode

---

## Data Flow Summary

```
User Input → InteractionController (FSM) → GraphCommand → GraphApi → FFI
                                                                       ↓
UI Rebuild ← ValueNotifier ← GraphSyncEngine ← StreamSink ← Rust Service
```
