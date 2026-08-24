# FFI API Surface

All methods on `AppHandle` (`rust/centrode_core/src/bridge/api.rs`) that are callable from Dart via FRB.

---

## Lifecycle

| Method | Signature | Description |
|--------|-----------|-------------|
| `new` | `(storage_path: String, name: String) -> Result<Self>` | Create/open a map |
| `with_repository` | `(repo: Repository) -> Self` | Wrap existing repo |
| `close` | `() -> Result<()>` | Close the map |
| `create_graph_stream` | `(sink: StreamSink<GraphEvent>) -> Result<()>` | Subscribe to graph events |

---

## Nodes

| Method | Signature | Description |
|--------|-----------|-------------|
| `create_node` | `(input: Nodes) -> Result<()>` | Create a node |
| `get_node` | `(id: TypedRecordId) -> Result<Option<Nodes>>` | Get node by ID |
| `update_node` | `(input: Nodes) -> Result<()>` | Update a node |
| `delete_node_entry` | `(id: TypedRecordId) -> Result<()>` | Delete a node |
| `apply_entity_mutation` | `(mutation: SymmetricEntityPatch) -> Result<()>` | Apply a patch |
| `update_node_cache_positions` | `(positions: Vec<(TypedRecordId, f64, f64, f64, f64)>)` | Batch update positions |
| `broadcast_boundaries` | `() -> ()` | Recalculate and broadcast boundaries |
| `rebuild_node_cache` | `() -> ()` | Rebuild internal node cache |

---

## Relations

| Method | Signature | Description |
|--------|-----------|-------------|
| `create_relation` | `(input: IRelation) -> Result<()>` | Create a relation |
| `update_relation` | `(input: IRelation) -> Result<()>` | Update a relation |
| `delete_relation` | `(id: TypedRecordId) -> Result<()>` | Delete a relation |
| `reroute_relation` | `(record, from, to: TypedRecordId) -> Result<()>` | Change relation endpoints |
| `compute_relations` | `(config, relation_ids?) -> Result<Vec<ComputedRelation>>` | Batch compute relation paths |
| `compute_single_relation` | `(config, edge_id, from, to, ...) -> Result<ComputedRelation>` | Compute single relation path |

---

## History

| Method | Signature | Description |
|--------|-----------|-------------|
| `undo` | `() -> Result<Option<HistoryRecord>>` | Undo last mutation |
| `redo` | `() -> Result<Option<HistoryRecord>>` | Redo last undo |
| `undo_count` | `() -> Result<u32>` | Available undo count |
| `redo_count` | `() -> Result<u32>` | Available redo count |
| `apply_history_record_patch` | `(record, is_forward) -> Result<Option<GraphDelta>>` | Apply history patch |

---

## Themes

| Method | Signature | Description |
|--------|-----------|-------------|
| `get_all_themes` | `() -> Result<Vec<MapTheme>>` | List all themes |
| `get_theme` | `(key: String) -> Result<Option<MapTheme>>` | Get theme by key |
| `create_theme` | `(key, fields) -> Result<()>` | Create a theme |
| `update_theme` | `(theme: MapTheme) -> Result<()>` | Update a theme |
| `set_active_theme` | `(theme_key: String) -> Result<()>` | Set active theme |
| `set_active_theme_id` | `(theme_id: String) -> Result<()>` | Set active theme by ID |
| `get_active_theme_id` | `() -> Result<Option<String>>` | Get active theme ID |

---

## Tags

| Method | Signature | Description |
|--------|-----------|-------------|
| `create_tag` | `(tag: Tag) -> Result<()>` | Create a tag |
| `update_tag` | `(tag: Tag) -> Result<()>` | Update a tag |
| `get_tag` | `(key: String) -> Result<Option<Tag>>` | Get tag by key |
| `get_all_tags` | `() -> Result<Vec<Tag>>` | List all tags |
| `delete_tag` | `(key: String) -> Result<()>` | Delete a tag |

---

## Templates

| Method | Signature | Description |
|--------|-----------|-------------|
| `save_template_from_selection` | `(name, node_keys, relation_keys) -> Result<()>` | Save selection as template |
| `instantiate_template` | `(key, target_x, target_y) -> Result<()>` | Instantiate template at position |
| `get_all_templates` | `() -> Result<Vec<Template>>` | List all templates |
| `delete_template` | `(key: String) -> Result<()>` | Delete a template |

---

## Layout Engine

| Method | Signature | Description |
|--------|-----------|-------------|
| `trigger_layout_optimization` | `(config, live_positions) -> Result<()>` | Run layout simulation |
| `compute_auto_placement` | `(source_id, port_side) -> Result<(f64, f64)>` | Compute auto-placement position |
| `set_alignment_constraint` | `(node_ids, axis) -> Result<()>` | Set alignment constraint |
| `add_anchor_spring` | `(node_id, x, y, strength) -> Result<()>` | Add anchor spring |
| `set_opt_area` | `(bounds: Option<BoundingBox>) -> Result<()>` | Set optimization area |
| `get_opt_area` | `() -> Result<Option<BoundingBox>>` | Get optimization area |

---

## Snapshot & Search

| Method | Signature | Description |
|--------|-----------|-------------|
| `get_graph_snapshot` | `() -> Result<GraphSnapshot>` | Get full graph snapshot |
| `query_search` | `(query: String) -> Result<Vec<Nodes>>` | Full-text search |
| `save_map_to_file` | `(file_path, attachment_dir) -> Result<()>` | Export .cent file |
| `load_map_from_file` | `(file_path, attachment_dir) -> Result<()>` | Import .cent file |
| `update_viewport_state` | `(state: ViewportState) -> Result<()>` | Save viewport state |

---

## Asset Vault

| Method | Signature | Description |
|--------|-----------|-------------|
| `ingest_asset` | `(asset_dir, file_name, file_bytes, mime_type) -> Result<Attachment>` | Ingest file into CAS, return attachment metadata |
| `get_asset_absolute_path` | `(asset_dir, hash, extension) -> Result<String>` | Resolve asset hash to absolute file path |

---

## Telemetry (standalone, no AppHandle)

| Function | Signature | Description |
|----------|-----------|-------------|
| `setup_logger` | `() -> Result<()>` | Initialize telemetry |
| `create_log_stream` | `(sink: StreamSink<LogState>) -> Result<()>` | Stream logs to Dart |
