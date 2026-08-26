# Backend Overview

The Rust backend is a Cargo workspace of three crates:

- **`centrode_macros`** — proc-macro crate that generates domain enums (`Nodes`, `Relations`), traits, and SurQL schema impls via `define_domain_types!`
- **`centrode_core`** — core business logic, persistence repositories, and computation engines (FRB host)
- **`centrode_daemon`** — standalone daemon binary: owns the SurrealKV storage engine, schema generation, map registry, system tray and IPC

---

## Module Map

```
rust/
├── centrode_macros/src/        # Proc-macro codegen (11 files)
│   ├── surql_schema_field.rs   # #[derive(SurqlSchemaField)]
│   ├── surreal_enum.rs         # #[derive(SurrealEnum)]
│   ├── surreal_table.rs        # #[derive(SurrealTable)]
│   └── typesystem/             # AST + generators for Nodes/Relations & SurQL output
├── centrode_core/src/
│   ├── lib.rs                  # Crate root — module declarations + init_core()
│   ├── frb_generated.rs        # AUTO-GENERATED — FRB bindings
│   ├── bridge.rs               # Module root
│   ├── bridge/                 # FFI endpoints exposed to Flutter (4 files)
│   │   ├── api.rs              # AppHandle — all FFI methods
│   │   ├── stream.rs           # GraphEvent stream types
│   │   └── daemon_conversions.rs # AUTO-GENERATED — dart scripts/sync_domain.dart
│   ├── domain.rs               # Module root
│   ├── domain/                 # Core domain types (15 files)
│   │   ├── base_models.rs      # Coordinates, BoundingBox, ViewportState
│   │   ├── contents.rs         # Content types (markdown blocks)
│   │   ├── id.rs               # TypedRecordId, UUID handling
│   │   ├── nodes.rs            # Node type definitions + IsNode trait
│   │   ├── patches.rs          # SymmetricEntityPatch for undo/redo
│   │   ├── relations.rs        # IRelation type
│   │   ├── routing.rs          # Point, RoutingMode
│   │   ├── schema.rs           # SurQL schema trait impls
│   │   ├── snapshot.rs         # GraphSnapshot for import/export
│   │   ├── styles.rs           # NodeStyle, RelationStyle, PortSide
│   │   ├── tags.rs             # Tag type
│   │   ├── templates.rs        # Template type
│   │   ├── theme.rs            # MapTheme, ThemeFields
│   │   ├── traits.rs           # Shared traits
│   │   └── types.rs            # Node/relation structs; Nodes/Relations enums are macro-generated
│   ├── repo.rs                 # Module root — Repositories aggregate struct
│   ├── repo/                   # SurrealDB CRUD repositories (12 files)
│   │   ├── nodes.rs            # Node CRUD
│   │   ├── relations.rs        # Relation CRUD
│   │   ├── tags.rs             # Tag management
│   │   ├── templates.rs        # Template storage
│   │   ├── themes.rs           # Theme persistence
│   │   ├── history.rs          # History records (undo/redo storage)
│   │   ├── patches.rs          # Patch storage
│   │   ├── snapshot.rs         # Graph snapshot import/export
│   │   ├── analysis.rs         # Graph analysis + layout repository queries
│   │   ├── dictionaries.rs     # Custom-word dictionary storage
│   │   └── traits.rs           # Repository traits
│   ├── relation_engine/        # Relation routing (35 files)
│   │   ├── engine.rs           # Main relation engine
│   │   ├── path_finder/        # 8 routing algorithms
│   │   ├── shaper/             # 8 path shaping strategies
│   │   └── compose/            # 5 post-routing composers
│   ├── layout_engine/          # Force-directed layout (15 files)
│   │   ├── engine.rs           # Main layout engine
│   │   ├── forces/             # 8 physics force implementations
│   │   └── ...                 # config, integration, port optimizer
│   ├── services.rs             # Module root — service layer (9 files)
│   │   ├── graph_service.rs    # GraphService facade
│   │   ├── graph_service/      # node, relation, history, layout, metadata
│   │   ├── asset_vault.rs      # Binary attachment vault
│   │   └── embedding_service.rs # Native candle BERT embedder (384-dim vectors)
│   ├── format/packager.rs      # .cent zip package format
│   └── telemetry.rs            # Tracing subscriber → Flutter bridge
└── centrode_daemon/src/
    ├── main.rs                 # `centrode-daemon` binary — DaemonWorker::start()
    ├── lib.rs                  # DaemonWorker
    ├── engine.rs               # EngineManager — SurrealKV connections, per-map DBs
    ├── schema.rs               # Schema + Seeder
    ├── schema_gen/             # AUTO-GENERATOR → map_schema.surql (4 files)
    ├── map_schema.surql        # AUTO-GENERATED — graph tables
    ├── system_schema.surql     # MapRegistry, SystemSetting tables
    ├── services/daemon_service.rs  # DaemonService — map lifecycle + settings
    ├── ipc.rs                  # Daemon IPC protocol
    ├── custodian.rs            # Custodian IPC server
    └── domain/                 # Daemon-side mirror of core domain types (15 files)
```

---

## Crate Root

`rust/centrode_core/src/lib.rs` declares all modules and exposes `init_core()`:

```rust
pub fn init_core() {
    telemetry::init_telemetry();
}
```

Called once during app startup via FRB. Engine initialization is separate: the app calls `yield_daemon_if_running()`, then `init_core_engine(storage_path)`, which wires the daemon's [EngineManager](services.md) before any [AppHandle](../ffi/README.md) is constructed.

---

## Key Design Decisions

- **SurrealDB embedded**: Uses Surrealkv storage backend via the daemon's `EngineManager`; no separate database server. The daemon hands out per-map `Surreal<Db>` handles to core services.
- **Macro-driven domain codegen**: `Nodes`/`Relations` enums, entity traits, and SurQL schema impls are generated by `centrode_macros` from plain struct declarations in `domain/types.rs`
- **Symmetric patches**: Undo/redo via `SymmetricEntityPatch` — same patch format forward and backward
- **Stream-based sync**: All mutations broadcast via `GraphEvent` stream, not polling
- **Strategy pattern**: Relation routing and layout use strategy pattern for extensibility
- **Schema auto-generation**: `centrode_daemon/schema_gen/` derives `map_schema.surql` from Rust domain types (run via `cargo run --bin generate-schema` from `centrode_core`); never hand-edited
