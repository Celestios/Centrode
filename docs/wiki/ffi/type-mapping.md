# Type Mapping

Dart ↔ Rust type correspondence across the FFI boundary.

---

## Primitive Types

| Dart | Rust | Notes |
|------|------|-------|
| `int` | `i64` / `u64` | Depends on context |
| `double` | `f64` | |
| `bool` | `bool` | |
| `String` | `String` | UTF-8 |
| `List<T>` | `Vec<T>` | |
| `Map<K, V>` | `HashMap<K, V>` | |

---

## Domain Types

| Dart (`lib/src/rust/domain/`) | Rust (`rust/centrode_core/src/domain/`) | Notes |
|------|------|-------|
| `TypedRecordId` | `TypedRecordId` | SurrealDB record ID |
| `RawUuid` | — (Dart-only) | UUID v4 wrapper |
| `Nodes` (enum) | `Nodes` (enum) | 9 node variants |
| `INode` / `InfoUiNode` | `INode` | Info node |
| `TaskNode` / `TaskUiNode` | `TaskNode` | Task node |
| `CommentNode` / `CommentUiNode` | `CommentNode` | Comment node |
| `DrawingNode` / `DrawingUiNode` | `DrawingNode` | Drawing node |
| `ShapeNode` / `ShapeUiNode` | `ShapeNode` | Shape node |
| `FrameNode` / `FrameUiNode` | `FrameNode` | Frame node |
| `ContainerNode` / `ContainerUiNode` | `ContainerNode` | Container node |
| `MediaNode` / `MediaUiNode` | `MediaNode` | Media node |
| `InterNode` / `InterUiNode` | `InterNode` | Intersection node |
| `IRelation` | `IRelation` | Relation |
| `SymmetricEntityPatch` | `SymmetricEntityPatch` | Undo/redo patch |
| `NodeStyle` | `NodeStyle` | Node visual style |
| `RelationStyle` | `RelationStyle` | Relation visual style |
| `NodeLayout` | `NodeLayout` | Node layout config |
| `RelationLayout` | `RelationLayout` | Relation layout config |
| `Tag` | `Tag` | Tag definition |
| `Template` | `Template` | Template |
| `MapTheme` | `MapTheme` | Map theme |
| `ThemeFields` | `ThemeFields` | Theme field values |
| `Content` | `Content` | Rich text content |
| `GraphSnapshot` | `GraphSnapshot` | Full graph export |
| `HistoryRecord` | `HistoryRecord` | Undo/redo record |
| `BoundingBox` | `BoundingBox` | Bounding rectangle |
| `ViewportState` | `ViewportState` | Pan/zoom state |
| `Coordinates` | `Coordinates` | x/y position |

---

## Engine Types

| Dart | Rust | Notes |
|------|------|-------|
| `ComputedRelation` | `ComputedRelation` | Computed relation geometry |
| `RelationEngineConfig` | `RelationEngineConfig` | Relation engine config |
| `RoutingMode` | `RoutingMode` | Routing algorithm selector |
| `PortSide` | `PortSide` | Connection port position |
| `LayoutConfig` | `LayoutConfig` | Layout engine config |
| `LayoutPatch` | `LayoutPatch` | Layout position update |
| `Axis` | `Axis` | Alignment axis |

---

## Stream Types

| Dart | Rust | Notes |
|------|------|-------|
| `GraphEvent` | `GraphEvent` | Stream event enum |
| `GraphDelta` | `GraphDelta` | Mutation delta |
| `LogState` | `LogState` | Telemetry log entry |

---

## UiNode ↔ Nodes Mapping

The `centrode_codegen` generator creates `_$uiNodeFromRust()`:

```dart
// Dart UiNode types (graph_node.dart) ↔ Rust Nodes variants
InfoUiNode      ↔ Nodes::INode
TaskUiNode      ↔ Nodes::TaskNode
CommentUiNode   ↔ Nodes::CommentNode
DrawingUiNode   ↔ Nodes::DrawingNode
ShapeUiNode     ↔ Nodes::ShapeNode
FrameUiNode     ↔ Nodes::FrameNode
ContainerUiNode ↔ Nodes::ContainerNode
MediaUiNode     ↔ Nodes::MediaNode
InterUiNode     ↔ Nodes::InterNode
```
