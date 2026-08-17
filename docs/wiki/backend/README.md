# Backend Overview

The Rust backend (`centrode_core` crate) provides the core business logic, persistence, and computation engines.

---

## Module Map

```
rust/src/
├── lib.rs                    # Crate root — module declarations + init_core()
├── frb_generated.rs          # AUTO-GENERATED — FRB bindings
├── bridge/                   # FFI endpoints exposed to Flutter
│   ├── api.rs                # AppHandle — all FFI methods
│   └── stream.rs             # GraphEvent/GraphDelta stream types
├── domain/                   # Core domain types (14 files)
│   ├── base_models.rs        # Coordinates, BoundingBox, ViewportState
│   ├── contents.rs           # Content types (markdown blocks)
│   ├── id.rs                 # TypedRecordId, UUID handling
│   ├── nodes.rs              # Node type definitions + IsNode trait
│   ├── patches.rs            # SymmetricEntityPatch for undo/redo
│   ├── relations.rs          # IRelation type
│   ├── schema.rs             # SurrealDB schema definitions
│   ├── snapshot.rs           # GraphSnapshot for import/export
│   ├── styles.rs             # NodeStyle, RelationStyle, PortSide
│   ├── tags.rs               # Tag type
│   ├── templates.rs          # Template type
│   ├── theme.rs              # MapTheme, ThemeFields
│   ├── traits.rs             # Shared traits
│   └── types.rs              # Nodes enum, all node structs
├── persistence/              # SurrealDB layer (20 files)
│   ├── db.rs                 # Database connection setup
│   ├── history.rs            # HistoryRecord, undo/redo engine
│   ├── schema.rs             # Schema definitions
│   ├── schema.surql          # AUTO-GENERATED — SurrealQL schema
│   ├── repo.rs               # Repository module root
│   ├── repo/                 # CRUD implementations (9 files)
│   └── schema_gen/           # Schema auto-generator (4 files)
├── relation_engine/          # Relation routing (36 files)
│   ├── engine.rs             # Main relation engine
│   ├── computed.rs           # ComputedRelation output type
│   ├── config.rs             # RelationEngineConfig, RoutingMode
│   ├── path_finder/          # 8 routing algorithms
│   ├── shaper/               # 8 path shaping strategies
│   ├── compose/              # 5 post-routing composers
│   └── ...                   # geometry, endpoints, state, etc.
├── layout_engine/            # Force-directed layout (14 files)
│   ├── engine.rs             # Main layout engine
│   ├── forces/               # 8 physics force implementations
│   ├── config.rs             # LayoutConfig
│   ├── integration.rs        # Verlet integration
│   └── ...                   # state, types, port optimizer
├── services/                 # High-level service layer (7 files)
│   └── graph_service/        # Node, relation, history, layout, metadata
├── format/                   # .cent package format (1 file)
│   └── packager.rs           # Zip + MessagePack serialization
├── plugin_system/            # Extension system (1 file)
│   └── runner.rs
└── telemetry.rs              # Tracing subscriber → Flutter bridge
```

---

## Crate Root

`rust/src/lib.rs` declares all modules and exposes `init_core()`:

```rust
pub fn init_core() {
    telemetry::init_telemetry();
}
```

Called once during app startup via FRB.

---

## Key Design Decisions

- **SurrealDB embedded**: Uses Surrealkv storage backend, no separate database server
- **Symmetric patches**: Undo/redo via `SymmetricEntityPatch` — same patch format forward and backward
- **Stream-based sync**: All mutations broadcast via `GraphEvent` stream, not polling
- **Strategy pattern**: Relation routing and layout use strategy pattern for extensibility
- **Schema auto-generation**: SurrealDB schema derived from Rust domain types, never hand-edited
