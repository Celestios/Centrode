import 'package:mycelium/shared/domain/raw_uuid.dart';

enum CommandCategory { spatial, content, aesthetic, lifecycle }

/// Abstract base class for all graph mutation commands.
/// Implements the Command Pattern for undoable operations with FFI sync.
abstract class GraphCommand {
  /// The ID of the entity being modified.
  /// Mutable to allow ID swapping for optimistic commands (temp ID → real DB ID).
  abstract RawUuid targetId;

  /// Forced namespace for the debouncer to create composite keys.
  CommandCategory get category;

  /// Executes the command (typically an FFI call).
  Future<void> execute();

  /// Rolls back local state on FFI failure.
  void undo();

  /// Lifecycle hook called after successful FFI execution.
  void onSuccess() {}
}
