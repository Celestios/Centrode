# FFI Overview

---

## Flutter Rust Bridge (FRB v2)

Centrode uses Flutter Rust Bridge to connect Dart and Rust. FRB auto-generates type-safe bindings from Rust API definitions.

---

## Architecture

```
Dart (Flutter)                    Rust
─────────────                    ────
GraphApi (abstract)
  └─ GraphSyncEngine
       └─ FRB generated bindings ──→ AppHandle (struct)
                                      ├─ GraphService
                                      │   ├─ Repository
                                      │   │   └─ SurrealDB
                                      │   ├─ RelationEngine
                                      │   └─ LayoutEngine
                                      └─ GraphEvent stream
                                           └─ StreamSink ──→ Dart stream
```

---

## Key Files

| File | Side | Role |
|------|------|------|
| `rust/centrode_core/src/bridge/api.rs` | Rust | FFI API surface — `AppHandle` + all endpoints |
| `rust/centrode_core/src/bridge/stream.rs` | Rust | `GraphEvent`, `GraphDelta` stream types |
| `lib/src/rust/bridge/api.dart` | Dart | Auto-generated Dart bindings for FFI |
| `lib/src/rust/bridge/stream.dart` | Dart | Auto-generated stream types |
| `lib/features/graph/store/graph_api.dart` | Dart | `GraphApi` abstract interface |
| `flutter_rust_bridge.yaml` | Config | FRB codegen configuration |

---

## AppHandle

The Rust-side entry point for all FFI calls:

```rust
pub struct AppHandle {
    pub service: Arc<GraphService>,
}
```

Created via:
```rust
AppHandle::new(storage_path, name)  // Opens/creates a map
AppHandle::with_repository(repo)    // Wraps existing repositories
```

---

## Stream Bridge

Rust → Dart communication uses FRB's `StreamSink`:

1. Dart calls `create_graph_stream()` → passes `StreamSink<GraphEvent>` to Rust
2. Rust spawns a tokio task that forwards `GraphEvent` to the sink
3. Dart receives events via `Stream<GraphEvent>`
4. `GraphSyncEngine` processes events and updates UI

---

## Initialization

1. `RustLib.init()` — loads native library, calls `init_core()`
2. Map opened via `AppHandle::new(path, name)`
3. `create_graph_stream()` establishes event stream
4. Initial snapshot fetched via `get_graph_snapshot()`

---

## Configuration

`flutter_rust_bridge.yaml` controls codegen:
- Input: `rust/centrode_core/src/bridge/api.rs`
- Output: `lib/src/rust/` (Dart bindings), `rust/centrode_core/src/frb_generated.rs` (Rust side)
