import 'package:flutter_test/flutter_test.dart';
import 'package:mycelium/features/graph/models/commands.dart';
import 'package:mycelium/features/graph/store/command_processor.dart';
import 'package:mycelium/shared/domain/raw_uuid.dart';

class FakeCommand extends GraphCommand {
  @override
  RawUuid targetId;

  @override
  final CommandCategory category;

  bool isExecuted = false;
  bool isUndone = false;
  bool shouldFail = false;

  FakeCommand(RawUuid targetId, this.category, {this.shouldFail = false})
      : targetId = targetId;

  @override
  Future<void> execute() async {
    if (shouldFail) {
      throw Exception('Fake failure');
    }
    isExecuted = true;
  }

  @override
  void undo() {
    isUndone = true;
  }
}

void main() {
  group('CommandProcessor', () {
    late CommandProcessor processor;
    late List<String> errors;

    setUp(() {
      errors = [];
      processor = CommandProcessor(onError: (err) => errors.add(err));
    });

    test('executes immediate command right away', () async {
      final cmd = FakeCommand(RawUuid.fromString('node-1'), CommandCategory.spatial);

      processor.queueCommand(cmd, immediate: true);

      // Allow async event loop to process
      await Future.delayed(Duration.zero);

      expect(cmd.isExecuted, isTrue);
      expect(errors, isEmpty);
    });

    test('debounces non-immediate command', () async {
      final cmd = FakeCommand(RawUuid.fromString('node-2'), CommandCategory.spatial);

      processor.queueCommand(cmd, immediate: false);

      await Future.delayed(const Duration(milliseconds: 100));
      expect(cmd.isExecuted, isFalse); // Not yet executed

      await Future.delayed(const Duration(milliseconds: 250));
      expect(cmd.isExecuted, isTrue); // Should be executed after 300ms
    });

    test('overwrites previous pending command of same category', () async {
      final cmd1 = FakeCommand(RawUuid.fromString('node-3'), CommandCategory.spatial);
      final cmd2 = FakeCommand(
        RawUuid.fromString('node-3'),
        CommandCategory.spatial,
      ); // Same ID and Category

      processor.queueCommand(cmd1, immediate: false);
      processor.queueCommand(cmd2, immediate: false);

      await Future.delayed(const Duration(milliseconds: 350));

      expect(cmd1.isExecuted, isFalse); // Was overwritten
      expect(cmd2.isExecuted, isTrue);
    });

    test('keeps pending commands of different categories', () async {
      final cmd1 = FakeCommand(RawUuid.fromString('node-4'), CommandCategory.spatial);
      final cmd2 = FakeCommand(
        RawUuid.fromString('node-4'),
        CommandCategory.content,
      ); // Different Category

      processor.queueCommand(cmd1, immediate: false);
      processor.queueCommand(cmd2, immediate: false);

      await Future.delayed(const Duration(milliseconds: 350));

      expect(cmd1.isExecuted, isTrue);
      expect(cmd2.isExecuted, isTrue);
    });

    test('undoes command on failure and reports error', () async {
      final cmd = FakeCommand(
        RawUuid.fromString('node-5'),
        CommandCategory.lifecycle,
        shouldFail: true,
      );

      processor.queueCommand(cmd, immediate: true);

      await Future.delayed(Duration.zero);

      expect(cmd.isExecuted, isFalse);
      expect(cmd.isUndone, isTrue);
      expect(errors.length, 1);
      expect(errors.first, contains('Fake failure'));
    });

    test('forceFlush executes pending commands instantly', () async {
      final cmd = FakeCommand(RawUuid.fromString('node-6'), CommandCategory.spatial);

      processor.queueCommand(cmd, immediate: false);

      await processor.forceFlush();

      expect(cmd.isExecuted, isTrue);
    });

    test('notifyIdSwap updates pending commands to use real DB id', () async {
      final cmd = FakeCommand(RawUuid.fromString('temp-uuid'), CommandCategory.content);

      processor.queueCommand(cmd, immediate: false);

      processor.notifyIdSwap(RawUuid.fromString('temp-uuid'), RawUuid.fromString('real-db-id'));

      await processor.forceFlush();

      expect(cmd.targetId, 'real-db-id'); // Target ID should be updated
      expect(cmd.isExecuted, isTrue);
    });
  });
}
