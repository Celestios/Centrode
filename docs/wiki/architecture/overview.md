# Architecture Overview

Centrode is a bilingual Flutter + Rust application: a canvas-based visual knowledge graph with SurrealDB backend via Flutter Rust Bridge (FRB v2).

---

## System Diagram

```mermaid
graph TD
    UI[Flutter Canvas UI] -->|Commands / Input| Ctrl[GraphDataController]
    Ctrl -->|API Calls / Queries| FFI[Flutter Rust Bridge]
    FFI -->|Rust FFI Calls| AppH[AppHandle]
    AppH -->|Commands & Patches| Repo[Repository]
    Repo -->|Persists Snapshot & History| DB[(SurrealDB)]
    Repo -->|Calculates Boundaries / Events| Stream[Graph Stream Sink]
    Stream -->|Broadcast Events| UI
```

---

## Module Map

### Flutter Frontend (`lib/`)

| Module | Path | Responsibility |
|--------|------|----------------|
| **Graph** | `lib/features/graph/` | Core feature — canvas, node editing, routing, store |
| **Workspace** | `lib/features/workspace/` | Project/map management hub |
| **Infrastructure** | `lib/infrastructure/` | Telemetry, logging, error handling |
| **Presentation** | `lib/presentation/` | Theme system, shared presentation widgets |
| **Shared** | `lib/shared/` | Common widgets, glass panel, utilities |

### Rust Workspace (`rust/`)

| Module | Path | Responsibility |
|--------|------|----------------|
| **Core Bridge** | `rust/centrode_core/src/bridge/` | FFI endpoints exposed to Flutter |
| **Core Domain** | `rust/centrode_core/src/domain/` | Core types: nodes, relations, patches, styles |
| **Core Repo** | `rust/centrode_core/src/repo/` | SurrealDB connection, CRUD, history queries |
| **Relation Engine** | `rust/centrode_core/src/relation_engine/` | Routing algorithms, path finding, composition |
| **Layout Engine** | `rust/centrode_core/src/layout_engine/` | Force-directed graph layout, physics forces |
| **Services** | `rust/centrode_core/src/services/` | High-level graph service layer, asset vault, candle embedding service |
| **Format** | `rust/centrode_core/src/format/` | `.cent` zip package format |
| **Telemetry** | `rust/centrode_core/src/telemetry.rs` | Tracing subscriber bridged to Flutter |
| **Macros** | `rust/centrode_macros/` | Proc-macro codegen — `Nodes`/`Relations` enums, SurQL schema impls |
| **Daemon** | `rust/centrode_daemon/` | Standalone binary — SurrealKV storage engine (`EngineManager`), schema generation, map registry, tray, Custodian IPC |

---

## Boot Sequence

1. `lib/main.dart` — `WidgetsFlutterBinding.ensureInitialized()`
2. Window manager setup (desktop platforms)
3. `RustLib.init()` — load FRB native library, initialize Rust side
4. `LogManager().init()` — set up Dart-side logging
5. `GlassShaderProvider.load()` — compile liquid glass GLSL shader
6. `AppPaths.ensureDirectories()` — create data directories
7. `ThemeLoader.loadBundledThemes()` — load JSON themes from `assets/themes/`
8. `runApp(MyApp)` — start Flutter app with `WorkspaceHubScreen` as home

On the Rust side, `init_core()` (called via FRB init) sets up the `tracing` telemetry subscriber. Engine initialization follows: the app calls `yield_daemon_if_running()` (handshake with any already-running daemon), then `init_core_engine(storage_path)`, which wires the daemon's `EngineManager`.

---

## Key Entry Points

| File | Role |
|------|------|
| `lib/main.dart` | App entry — boots Rust FFI, loads themes |
| `lib/features/workspace/ui/workspace_hub_screen.dart` | Home screen — map/project selector |
| `lib/features/graph/ui/graph_screen.dart` | Graph editor — main canvas scaffold |
| `lib/features/graph/ui/canvas/graph_canvas.dart` | Infinite canvas — core interaction + rendering |
| `lib/features/graph/store/graph_api.dart` | Store API — data access facade |
| `lib/features/graph/store/modules/graph_sync_engine.dart` | Sync engine — Rust FFI sync bridge |
| `rust/centrode_core/src/bridge/api.rs` | FFI API surface — all endpoints callable from Flutter |
| `rust/centrode_core/src/repo.rs` | Repository — `Repositories` aggregate, SurrealDB CRUD layer |
| `rust/centrode_core/src/relation_engine.rs` | Relation engine — routing + geometry |
| `rust/centrode_core/src/layout_engine.rs` | Layout engine — force-directed graph layout & OptArea physics |
| `rust/centrode_daemon/src/engine.rs` | `EngineManager` — SurrealKV connections, per-map databases |

---

## Cross-Cutting Concerns

- **Continuous Infinite Zoom**: Nested container hierarchy with world-space coordinate resolution and boundary expansion
- **Undo/Redo**: Symmetric entity patches stored in SurrealDB `History` table, applied via `apply_history_record_patch`
- **Dynamic Snap & Routing**: Dynamic port alignment, snap guidelines, and live relation rerouting during dragging
- **Bounded Layout Optimization (OptArea)**: Sub-graph physics layout constrained to user-defined rectangular optimization regions
- **File Attachments**: Content-addressable asset vault (SHA-256 CAS), multi-attachment support on InfoNode/TaskNode, singular on MediaNode
- **Streaming**: Rust broadcasts `GraphEvent` to Flutter via FRB `StreamSink`, enabling real-time UI updates
- **Telemetry**: Rust `tracing` → `TelemetryLayer` → FFI stream → Dart `LogManager`
- **Themes**: JSON files in `assets/themes/` → `AppTheme` objects → `AppThemeManager` → `ValueListenableBuilder`

---

## Platform Support

| Platform | Status |
|----------|--------|
| Windows | Primary development target |
| Linux | Supported |
| macOS | Supported |
| Android | Supported |
| iOS | Not configured |
| Web | Not supported (native Rust required) |
