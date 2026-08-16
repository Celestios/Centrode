# Commands

> Last verified: 2026-08-16
> Tier: 2 (Interaction & Controllers)

---

## Command Pattern

All graph mutations go through the `GraphCommand` abstract class (`models/commands/base.dart`).

### GraphCommand Interface

```dart
abstract class GraphCommand {
  abstract RawUuid targetId;
  CommandCategory get category;
  bool get isUndoable => true;
  Future<void> execute();
  void undo();
  void onSuccess() {}
}
```

### Command Categories

| Category | Description |
|----------|-------------|
| `spatial` | Position/size changes (move, resize) |
| `content` | Text/content changes |
| `aesthetic` | Style/visual changes |
| `lifecycle` | Create/delete operations |

## Command Structure

The `lib/features/graph/models/commands/` directory contains **21 files**:
- **18 concrete commands** implementing specific canvas operations
- **3 core support files**: `base.dart` (`GraphCommand` interface & `CommandCategory`), `graph_command_context.dart` (dependency container), and `patch_helpers.dart` (symmetric patch utilities).

---

## Concrete Commands Matrix

| Command | Category | Debounced? | Undoable? | FFI Target / API Method |
|:---|:---|:---:|:---:|:---|
| `CreateNodeCommand` | `lifecycle` | No | Yes | `GraphApi.createNode()` |
| `DeleteNodeCommand` | `lifecycle` | No | Yes | `GraphApi.deleteNodeEntry()` |
| `MoveNodeCommand` | `spatial` | **Yes** (by target) | Yes | `GraphApi.applyEntityMutation()` |
| `UpdateTextCommand` | `content` | **Yes** | Yes | `GraphApi.applyEntityMutation()` |
| `CreateRelationCommand` | `lifecycle` | No | Yes | `GraphApi.createRelation()` |
| `DeleteRelationCommand` | `lifecycle` | No | Yes | `GraphApi.deleteRelation()` |
| `UpdateRelationLayoutCommand` | `aesthetic` | No | Yes | `GraphApi.updateRelation()` |
| `UpdateRelationsLayoutCommand` | `aesthetic` | No | Yes | `GraphApi.applyEntityMutation()` |
| `UpdateNodeStyleCommand` | `aesthetic` | No | Yes | `GraphApi.applyEntityMutation()` |
| `UpdateNodesStyleCommand` | `aesthetic` | No | Yes | `GraphApi.applyEntityMutation()` |
| `UpdateTagsCommand` | `content` | No | Yes | `GraphApi.applyEntityMutation()` |
| `UpdateCommentsCommand` | `content` | No | Yes | `GraphApi.applyEntityMutation()` |
| `InstantiateTemplateCommand` | `lifecycle` | No | Yes | `GraphApi.instantiateTemplate()` |
| `CreateTagCommand` | `lifecycle` | No | Yes | `GraphApi.createTag()` |
| `DeleteTagCommand` | `lifecycle` | No | Yes | `GraphApi.deleteTag()` |
| `UpdateTagCommand` | `aesthetic` | No | Yes | `GraphApi.updateTag()` |
| `SaveTemplateCommand` | `lifecycle` | No | No (meta) | `GraphApi.saveTemplateFromSelection()` |
| `DeleteTemplateCommand` | `lifecycle` | No | No (meta) | `GraphApi.deleteTemplate()` |

---

## Command Execution Flow

1. **Creation**: Interaction state or action handler creates a command
2. **Queue**: Command added to `CommandQueueProcessor`
3. **Debouncing**: Commands of same category and target are debounced (coalesced)
4. **Execute**: `command.execute()` → `GraphApi` method → FFI call
5. **Success**: `command.onSuccess()` called, command added to undo stack
6. **Failure**: `command.undo()` called to roll back local state

---

## Undo/Redo Integration

- `CommandQueueProcessor` maintains undo/redo stacks
- Undo pops from undo stack, pushes to redo stack
- Redo pops from redo stack, pushes to undo stack
- New mutations clear the redo stack
- Each command's `undo()` method reverses local state changes
- FFI-level undo uses `SymmetricEntityPatch` from the `History` table

---

## Helpers

| File | Purpose |
|------|---------|
| `commands/graph_command_context.dart` | Context object passed to commands (store access, etc.) |
| `commands/patch_helpers.dart` | Utilities for building `SymmetricEntityPatch` objects |
