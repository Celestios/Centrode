# Persistence

---

## Overview

The persistence layer manages SurrealDB — an embedded document database. No separate database server is required; data is stored locally using the Surrealkv storage backend.

---

## Connection

`persistence/db.rs` sets up the SurrealDB connection:
- Embedded mode (no network)
- Surrealkv storage backend
- Database file stored per-map in `maps/` directory

---

## Schema

`persistence/schema.surql` defines all tables and fields. **Never edit directly** — it's auto-generated from Rust domain structs.

### Tables

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
| `IRelation` | RELATION | Connections between nodes |
| `Tag` | SCHEMAFULL | Tag definitions |
| `MapTheme` | SCHEMAFULL | Map themes |
| `MapData` | SCHEMALESS | Map metadata |
| `History` | SCHEMAFULL | Undo/redo records |
| `Template` | SCHEMALESS | Node templates |

---

## Repository

`persistence/repo.rs` and `persistence/repo/` implement CRUD operations:

| File | Responsibility |
|------|----------------|
| `nodes.rs` | Node CRUD (create, read, update, delete) |
| `relations.rs` | Relation CRUD |
| `tags.rs` | Tag management |
| `templates.rs` | Template storage |
| `themes.rs` | Theme persistence |
| `history.rs` | History records (undo/redo) |
| `patches.rs` | Patch storage |
| `snapshot.rs` | Graph snapshot import/export |
| `analysis.rs` | Graph analysis queries |

---

## History Engine

`persistence/history.rs` manages undo/redo:

1. Each mutation creates a `SymmetricEntityPatch`
2. Patch stored as `HistoryRecord` in the `History` table
3. Undo: apply patch in reverse direction
4. Redo: apply patch in forward direction
5. `undo_count()` / `redo_count()` for UI indicators

---

## Schema Generator

`persistence/schema_gen/` auto-generates `schema.surql` from Rust types:

| File | Responsibility |
|------|----------------|
| `nodes.rs` | Generates node table field definitions |
| `relations.rs` | Generates relation table definitions |
| `auxiliary.rs` | Generates tag, theme, history, template definitions |
| `writer.rs` | Writes the final `.surql` file |

Run via `cargo test` or dedicated schema gen command.
