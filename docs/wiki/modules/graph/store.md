# Store & Sync

---

## Overview

The store layer manages the data pipeline between the Rust backend and the Dart frontend. It handles mutations, queries, caching, and real-time synchronization.

---

## Core Files

| File | Role |
|------|------|
| `store/graph_api.dart` | `GraphApi` composite interface + `RustGraphApi` FFI implementation |
| `store/api/api.dart` | Barrel for the 10 API sub-interfaces |
| `store/handlers/handlers.dart` | Barrel for the store command-handler layer |
| `store/in_memory_graph_api.dart` | `InMemoryGraphApi` — in-memory `GraphApi` implementation (tests/previews) |
| `store/command_processor.dart` | Single command execution |
| `store/command_queue_processor.dart` | Command queue with debouncing, delegates undo/redo to history handler |
| `store/graph_data_command.dart` | Data command abstractions |
| `store/graph_data_query.dart` | Query abstractions |
| `store/graph_data_query_controller.dart` | Query controller with caching |
| `store/invalidation_tracker.dart` | Tracks what needs repainting |
| `store/relation_engine_state.dart` | Relation engine state cache |
| `store/spatial_index.dart` | Spatial index for hit testing |

---

## API Interfaces (`api/`)

`GraphApi` is a composite interface:

```dart
abstract interface class GraphApi implements NodeApi, RelationApi, LayoutApi,
    HistoryApi, ThemeApi, TemplateApi, TagApi, AssetApi, MlApi, ViewportApi {}
```

Each sub-interface lives in its own file:

| Interface | File | Responsibility |
|-----------|------|----------------|
| `NodeApi` | `node_api.dart` | Node CRUD, cache updates, boundaries |
| `RelationApi` | `relation_api.dart` | Relation CRUD, routing, relation specs |
| `LayoutApi` | `layout_api.dart` | Layout optimization, auto-placement, OptArea |
| `HistoryApi` | `history_api.dart` | Undo/redo + counts |
| `ThemeApi` | `theme_api.dart` | Theme CRUD, active theme |
| `TemplateApi` | `template_api.dart` | Template save/instantiate/delete |
| `TagApi` | `tag_api.dart` | Tag CRUD |
| `AssetApi` | `asset_api.dart` | Attachment ingest/resolve |
| `MlApi` | `ml_api.dart` | Native embedder surface: `detectMapLanguage`, `predictRelationLabels`, `searchSimilarLabels`, `embedText`, `initEmbedderModel` |
| `ViewportApi` | `viewport_api.dart` | Viewport state persistence |

---

## Command Handlers (`handlers/`)

Command dispatch is routed through 6 domain handlers that own mutation logic and call the APIs:

| Handler | Responsibility |
|---------|----------------|
| `node_command_handler.dart` | Node create/move/resize/text commands |
| `relation_command_handler.dart` | Relation create/update/layout commands |
| `area_command_handler.dart` | Area/container/OptArea commands |
| `property_command_handler.dart` | Style & property update commands |
| `history_command_handler.dart` | Owns undo/redo stacks and counts |
| `template_command_handler.dart` | Template save/instantiate commands |

---

## Mutation Modules

`store/modules/` contains 12 specialized store modules:

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

## GraphApi Implementations

- **`RustGraphApi`** (`graph_api.dart`) — production implementation delegating to Rust via FRB
- **`InMemoryGraphApi`** (`in_memory_graph_api.dart`) — pure-Dart implementation used by tests and previews

Key method groups:
- Nodes: `createNode()`, `updateNode()`, `deleteNodeEntry()`
- Relations: `createRelation()`, `updateRelation()`, `deleteRelation()`, `computeRelations()`, `computeSingleRelation()`, `getRelationSpec()`, `listRelationSpecs()`
- Patches: `applyEntityMutation()` — generic patch application
- History: `undo()`, `redo()`, `undoCount()`, `redoCount()` (via `HistoryApi`)
- Snapshot/search: `getGraphSnapshot()`, `querySearch()`
- Files: `saveMapToFile()`, `loadMapFromFile()`
- Tags/templates/themes: `createTag()`, `saveTemplateFromSelection()`, `instantiateTemplate()`
- Assets: `ingestAsset()`, `getAssetAbsolutePath()`
- ML ([embedding service](../../backend/services.md)): `detectMapLanguage()`, `predictRelationLabels()`, `searchSimilarLabels()`, `embedText()`, `initEmbedderModel()`

---

## Sync Engine

`GraphSyncEngine` (in `modules/graph_sync_engine.dart`) consumes a `GraphApi` and subscribes to the Rust `GraphEvent` stream to process deltas:

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
