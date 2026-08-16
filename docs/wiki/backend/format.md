# Format (.cent Package)

> Last verified: 2026-08-16
> Tier: 3 (Domain)

---

## Overview

The `.cent` format is a portable zip archive that packages an entire knowledge graph for import/export.

---

## Implementation

`format/packager.rs` handles serialization and deserialization.

---

## Archive Structure

```
map_name.cent (zip archive)
├── graph.msgpack          # Full graph snapshot (MessagePack binary)
├── attachments/           # Bundled file attachments
│   ├── image1.png
│   ├── document.pdf
│   └── ...
└── metadata.json          # Map metadata (optional)
```

---

## Serialization Format

### graph.msgpack

The graph snapshot is serialized using **MessagePack** — a compact binary format.

Contains:
- All nodes (all 9 types)
- All relations
- Tags
- Themes
- Templates
- History records

### Attachments

Local file/media attachments referenced by nodes are collected and bundled into the archive. Paths are rewritten to be relative to the archive root.

---

## Save Flow

1. `GraphService.save_map_to_file(file_path, attachment_dir)`
2. `Repository.get_graph_snapshot()` — dump all data
3. Collect attachment files from referenced paths
4. Serialize snapshot to MessagePack
5. Create zip archive with snapshot + attachments

## Load Flow

1. `GraphService.load_map_from_file(file_path, attachment_dir)`
2. Open zip archive
3. Deserialize MessagePack → `GraphSnapshot`
4. Extract attachments to `attachment_dir`
5. Import snapshot into SurrealDB
6. Broadcast full graph event to Flutter

---

## FFI Endpoints

```rust
// Save
pub async fn save_map_to_file(&self, file_path: String, attachment_dir: String)

// Load
pub async fn load_map_from_file(&self, file_path: String, attachment_dir: String)
```
