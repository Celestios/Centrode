# Adding a Node Type

Step-by-step guide to adding a new node type to Centrode.

---

## 1. Rust Domain Type

**File**: `rust/centrode_core/src/domain/nodes.rs`

Add a new struct implementing `IsNode`:

```rust
pub struct MyNewNode {
    pub id: TypedRecordId,
    pub position: Coordinates,
    pub layer: String,
    pub created_at: i64,
    pub updated_at: i64,
    pub parent_container_id: Option<TypedRecordId>,
    // ... your fields
}

impl IsNode for MyNewNode { ... }
```

**File**: `rust/centrode_core/src/domain/types.rs`

Add variant to `Nodes` enum:

```rust
pub enum Nodes {
    // ... existing variants
    MyNewNode(MyNewNode),
}
```

---

## 2. SurrealDB Schema

**Auto-generated** — do not edit `map_schema.surql` directly.

After adding the Rust type, the schema generator will create the table definition. Run:

```bash
cd rust && cargo test
```

Verify `rust/centrode_daemon/src/map_schema.surql` contains your new table.

---

## 3. Repository CRUD

**File**: `rust/centrode_core/src/repo/nodes.rs`

Add CRUD operations for your new node type. Follow the pattern of existing node types.

---

## 4. FFI Endpoints

**File**: `rust/centrode_core/src/bridge/api.rs`

If the new node needs special FFI methods, add them to `AppHandle`. Otherwise, existing generic methods (`create_node`, `update_node`, etc.) work via the `Nodes` enum.

---

## 5. FRB Regeneration

```bash
flutter_rust_bridge_codegen generate
```

This generates Dart bindings for the new Rust type.

---

## 6. Dart UiNode

**File**: `lib/features/graph/models/graph_node.dart`

Add a new sealed subclass:

```dart
sealed class UiNode { ... }

class MyNewUiNode extends UiNode {
  // ... your fields
  // Implement toRust(), copyWith(), etc.
}
```

The `centrode_codegen` generator will auto-generate:
- `_$uiNodeFromRust()` mapping
- `_$uiNodeCopy()` utility
- `copyWith()` method

---

## 7. Regenerate Dart Code

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## 8. Rendering

**File**: `lib/features/graph/ui/canvas/painters/nodes/`

Add a renderer for your node type. Follow the pattern of `shape_node_renderer.dart` or `frame_node_renderer.dart`.

Register it in `node_render_entry.dart`.

---

## 9. Default Style

Add a default preview color in `graph_node.dart`:

```dart
Color get defaultPreviewColor => switch (this) {
  // ... existing
  MyNewUiNode() => const Color(0xFFXXXXXX),
};
```

---

## 10. Testing

- Add Rust tests in `rust/centrode_core/tests/` for the new type
- Add Dart tests in `test/features/graph/models/` for UiNode behavior
- Run full test suite: `flutter test && cd rust && cargo test`
