# Adding a Command

> Last verified: 2026-08-16

Step-by-step guide to adding a new graph mutation command.

---

## 1. Create Command File

**File**: `lib/features/graph/models/commands/my_command.dart`

```dart
import 'package:centrode/shared/domain/raw_uuid.dart';
import 'base.dart';

class MyCommand extends GraphCommand {
  @override
  RawUuid targetId;

  @override
  CommandCategory get category => CommandCategory.spatial; // or content, aesthetic, lifecycle

  MyCommand({required this.targetId});

  @override
  Future<void> execute() async {
    // 1. Call GraphApi method (FFI call)
    // 2. On success, update local state
  }

  @override
  void undo() {
    // Reverse local state changes
  }

  @override
  void onSuccess() {
    // Optional: post-execution cleanup
  }
}
```

---

## 2. Register in Barrel Export

**File**: `lib/features/graph/models/commands.dart`

```dart
export 'commands/my_command.dart';
```

---

## 3. Wire to Interaction/Handler

Commands are invoked from:

- **Interaction states** (`engine/states/`) — for direct gesture-driven mutations
- **Action handlers** (`presentation/handlers/`) — for toolbar/menu actions
- **Other commands** — for composed mutations

Example in a handler:

```dart
void onMyAction() {
  final cmd = MyCommand(targetId: selectedNodeId);
  commandProcessor.enqueue(cmd);
}
```

---

## 4. Debouncing (Optional)

If the command should be debounced (e.g., during drag), the `CommandQueueProcessor` handles this based on `category` and `targetId`:

- Same category + same target → coalesced into latest value
- Different category or target → separate execution

---

## 5. Testing

Add tests in `test/features/graph/`:

```dart
test('MyCommand executes and undoes correctly', () async {
  // Setup mock GraphApi
  // Execute command
  // Verify state changes
  // Undo command
  // Verify state restored
});
```
