# Persistence

---

## Overview

Persistence is split across two crates:

- **`centrode_core/src/repo.rs` + `repo/`** — repository traits and SurrealDB CRUD implementations
- **`centrode_daemon/src/engine.rs` (`EngineManager`)** — owns the embedded SurrealDB storage engine and hands out per-map `Surreal<Db>` connections

No separate database server is required; data is stored locally using the Surrealkv storage backend under `default_storage_path()` (`<data_local>/centrode/data`).

> A compatibility alias `pub mod persistence { pub use crate::repo::*; }` remains in `centrode_core/src/lib.rs`, but new code should use `repo`.

---

## Connection

`EngineManager` (daemon, `engine.rs`) manages all database connections:
- Embedded mode (no network), Surrealkv storage backend
- `system_db()` — registry database (`MapRegistry`, `SystemSetting`)
- `map_db(map_id)` / `open_map_db(map_id)` — per-map database handles
- `GraphService::new()` calls `EngineManager::open_map_db` / `connect`

---

## Schema

Two schema files live in `centrode_daemon/src/`. **Never edit directly** — both are auto-generated from Rust domain structs.

### Map schema (`map_schema.surql`)

| Table | Type | Description |
|-------|------|-------------|
| `INode` | SCHEMAFULL | Info nodes (with `attachments` array) |
| `TaskNode` | SCHEMAFULL | Task nodes (with `attachments` array) |
| `InterNode` | SCHEMAFULL | Relation intersection nodes |
| `CommentNode` | SCHEMAFULL | Comment nodes |
| `DrawingNode` | SCHEMAFULL | Drawing nodes |
| `ShapeNode` | SCHEMAFULL | Shape nodes |
| `FrameNode` | SCHEMAFULL | Frame nodes |
| `ContainerNode` | SCHEMAFULL | Container nodes (with `child_count`, `locked`) |
| `MediaNode` | SCHEMAFULL | Media nodes (with singular `attachment`) |
| `IRelation` | RELATION (SCHEMAFULL) | Connections between nodes |
| `Tag` | SCHEMAFULL | Tag definitions |
| `MapTheme` | SCHEMAFULL | Map themes |
| `MapData` | SCHEMALESS | Map metadata |
| `History` | SCHEMAFULL | Undo/redo records |
| `Template` | SCHEMALESS | Node templates |

### System schema (`system_schema.surql`)

| Table | Description |
|-------|-------------|
| `MapRegistry` | Map descriptors — id, name, timestamps, recency |
| `SystemSetting` | Key/value application settings |

---

## Repositories

`repo.rs` declares the aggregate `Repositories` struct and `repo/` implements CRUD operations:

| File | Responsibility |
|------|----------------|
| `nodes.rs` | Node CRUD (create, read, update, delete) |
| `relations.rs` | Relation CRUD |
| `tags.rs` | Tag management |
| `templates.rs` | Template storage |
| `themes.rs` | Theme persistence |
| `history.rs` | History records (undo/redo storage) |
| `patches.rs` | Patch storage |
| `snapshot.rs` | Graph snapshot import/export |
| `analysis.rs` | Graph analysis queries + layout repository |
| `dictionaries.rs` | Custom-word dictionary storage (`SurrealDictionaryRepository`) |
| `traits.rs` | Repository traits (incl. `DictionaryRepository`) |

---

## History Engine

Storage lives in `repo/history.rs` (`SurrealHistoryRepository`); undo/redo orchestration lives in [GraphService history ops](services.md):

1. Each mutation creates a `SymmetricEntityPatch`
2. Patch stored as `HistoryRecord` in the `History` table
3. Undo: apply patch in reverse direction
4. Redo: apply patch in forward direction
5. `undo_count()` / `redo_count()` for UI indicators

---

## Schema Generator

`centrode_daemon/src/schema_gen/` auto-generates `map_schema.surql` from Rust domain types:

| File | Responsibility |
|------|----------------|
| `nodes.rs` | Generates node table field definitions |
| `relations.rs` | Generates relation table definitions |
| `auxiliary.rs` | Generates tag, theme, history, template definitions |
| `writer.rs` | Writes the final `.surql` file |

Run via:
```bash
cd rust/centrode_core && cargo run --bin generate-schema
```
This writes `../centrode_daemon/src/map_schema.surql`.
