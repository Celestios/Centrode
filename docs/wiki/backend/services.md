# Services

> Last verified: 2026-08-16
> Tier: 3 (Domain)

---

## Overview

The services layer provides high-level APIs that orchestrate lower-level modules (persistence, engines, streams).

---

## GraphService

`services/graph_service.rs` is the primary service, wrapping all operations:

```
services/
├── graph_service.rs          # Root — GraphService struct & dispatch
└── graph_service/            # Domain operation submodules
    ├── node.rs               # Node CRUD & cache management
    ├── relation.rs           # Relation CRUD, routing & boundaries
    ├── history.rs            # Undo/redo operations
    ├── layout.rs             # Layout engine operations & OptArea
    └── metadata.rs           # Theme, tag, template operations & search
```

---

## Responsibilities

### Node Operations (`node.rs`)
- `create_node()`, `update_node()`, `delete_node_entry()`
- `get_node()`, `rebuild_node_cache()`
- `update_node_cache_positions()`

### Relation Operations (`relation.rs`)
- `create_relation()`, `update_relation()`, `delete_relation()`
- `reroute_relation()`
- `compute_relations()`, `compute_single_relation()`
- `broadcast_boundaries()`

### History Operations (`history.rs`)
- `undo()`, `redo()`
- `undo_count()`, `redo_count()`
- `apply_history_record_patch()`

### Layout Operations (`layout.rs`)
- `trigger_layout_optimization()`
- `compute_auto_placement()`
- `set_alignment_constraint()`
- `add_anchor_spring()`
- `set_opt_area()`, `get_opt_area()`

### Metadata Operations (`metadata.rs`)
- Theme CRUD: `get_all_themes()`, `create_theme()`, `update_theme()`, `set_active_theme()`
- Tag CRUD: `create_tag()`, `update_tag()`, `delete_tag()`, `get_all_tags()`
- Template CRUD: `save_template_from_selection()`, `instantiate_template()`, `delete_template()`
- Search: `query_search()`
- Snapshot: `get_graph_snapshot()`
- File I/O: `save_map_to_file()`, `load_map_from_file()`

---

## Stream Broadcasting

`GraphService` manages the `GraphEvent` stream:
- `create_graph_stream(sink)` — subscribes a Flutter StreamSink
- After each mutation, broadcasts `GraphDelta` with changed entities
- Enables real-time UI updates without polling
