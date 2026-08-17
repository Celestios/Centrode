# Store & Sync

---

## Overview

The store layer manages the data pipeline between the Rust backend and the Dart frontend. It handles mutations, queries, caching, and real-time synchronization.

---

## Core Files

| File | Role |
|------|------|
| `store/graph_api.dart` | `GraphApi` abstract — decoupled FFI interface |
| `store/modules/graph_sync_engine.dart` | Sync engine — processes Rust stream events & implements GraphApi |
| `store/command_processor.dart` | Single command execution |
| `store/command_queue_processor.dart` | Command queue with debouncing |
| `store/graph_data_command.dart` | Data command abstractions |
| `store/graph_data_query.dart` | Query abstractions |
| `store/graph_data_query_controller.dart` | Query controller with caching |
| `store/invalidation_tracker.dart` | Tracks what needs repainting |
| `store/relation_engine_state.dart` | Relation engine state cache |
| `store/spatial_index.dart` | Spatial index for hit testing |

---

## Mutation Modules

`store/modules/` contains 12 specialized mutation modules:

| Module | Responsibility |
|--------|----------------|
| `graph_store.dart` | Core store — node/relation CRUD |
| `graph_sync_engine.dart` | Rust stream → Dart state sync |
| `graph_node_mutations.dart` | Node-specific mutations |
| `graph_relation_mutations.dart` | Relation-specific mutations |
| `graph_area_mutations.dart` | Area/container mutations |
| `graph_property_mutations.dart` | Property updates |
| `graph_style_mutations.dart` | Style mutations |
| `graph_tag_mutations.dart` | Tag CRUD |
| `graph_template_mutations.dart` | Template CRUD |
| `graph_text_mutations.dart` | Text content mutations |
| `graph_spatial.dart` | Spatial operations |
| `layout_tick_interpolator.dart` | Layout animation interpolation |

---

## GraphApi Interface

`GraphApi` is the abstract interface for all FFI calls. The concrete implementation (`GraphSyncEngine`) delegates to Rust via FRB.

Key methods:
- `createNode()`, `updateNode()`, `deleteNodeEntry()`
- `createRelation()`, `updateRelation()`, `deleteRelation()`
- `computeRelations()`, `computeSingleRelation()`
- `applyEntityMutation()` — generic patch application
- `undo()`, `redo()`, `undoCount()`, `redoCount()`
- `getGraphSnapshot()`, `querySearch()`
- `saveMapToFile()`, `loadMapFromFile()`
- `createTag()`, `updateTag()`, `deleteTag()`
- `saveTemplateFromSelection()`, `instantiateTemplate()`
- `ingestAsset()`, `getAssetAbsolutePath()` — file attachment I/O

---

## Sync Engine

`GraphSyncEngine` subscribes to the Rust `GraphEvent` stream and processes deltas:

1. Receives `GraphEvent` from FRB `StreamSink`
2. Extracts `GraphDelta` (node/relation changes)
3. Applies changes to local `ValueNotifier` maps
4. Triggers UI rebuild via notifier listeners
5. Updates spatial index and invalidation tracker

---

## Query Layer

`GraphDataQueryController` provides cached queries:
- Node lookups by ID
- Relation lookups by source/target
- Spatial queries (nodes in viewport)
- Full-text search via Rust `query_search()`
