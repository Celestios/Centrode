# Services

---

## Overview

The services layer provides high-level APIs that orchestrate lower-level modules ([repositories](persistence.md), engines, streams). `GraphService` obtains its SurrealDB connections from the daemon's `EngineManager`.

---

## GraphService

`services/graph_service.rs` is the primary service, wrapping all operations:

```
services.rs                   # Module root
├── graph_service.rs          # GraphService struct & dispatch
├── asset_vault.rs            # Content-addressable asset storage (SHA-256 CAS)
├── embedding_service.rs      # Native candle BERT embedder (384-dim vectors)
└── graph_service/            # Domain operation submodules
    ├── node.rs               # Node CRUD & cache management
    ├── relation.rs           # Relation CRUD, routing & boundaries
    ├── history.rs            # Undo/redo operations
    ├── layout.rs             # Layout engine operations & OptArea
    └── metadata.rs           # Theme, tag, template, dictionary ops & search
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
- Relation specs: `get_relation_spec(verb)`, `list_relation_specs()`
- Search: `query_search()`
- Snapshot: `get_graph_snapshot()`
- File I/O: `save_map_to_file()`, `load_map_from_file()`

### Asset Vault (`asset_vault.rs`)
- `compute_hash(bytes)` — SHA-256 hex digest
- `ingest_bytes(asset_dir, file_name, bytes, mime_type)` — CAS write, returns `Attachment`
- `resolve_path(asset_dir, hash, ext)` — resolve hash to absolute file path

### Embedding Service (`embedding_service.rs`)
Native BERT embedder built on candle (MiniLM-L6, 384-dim vectors), with a hash-based fallback embedder when no model weights are loaded:
- `init_model(weights, tokenizer, config)` — load candle model artifacts
- `embed_text(text)` — produce a 384-dim vector
- `cosine_similarity(a, b)` — vector similarity

Exposed through [GraphService / AppHandle](../ffi/api-surface.md) as `store_embedding`, `search_similar_labels`, `predict_relation_labels`, `detect_map_language`, `embed_text`, `init_embedder_model`.

---

## Stream Broadcasting

`GraphService` manages the `GraphEvent` stream:
- `create_graph_stream(sink)` — subscribes a Flutter StreamSink
- After each mutation, broadcasts `GraphDelta` with changed entities
- Enables real-time UI updates without polling
