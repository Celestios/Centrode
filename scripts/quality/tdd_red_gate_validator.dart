import 'dart:convert';
import 'dart:io';

class GateEvaluation {
  final bool isLegitimateRed;
  final String status;
  final String message;
  final List<String> errorDetails;

  GateEvaluation({
    required this.isLegitimateRed,
    required this.status,
    required this.message,
    required this.errorDetails,
  });

  @override
  String toString() =>
      '=== TDD RED GATE EVALUATION ===\nStatus: $status\nResult: ${isLegitimateRed ? "PASSED (Valid Red)" : "BLOCKED"}\nMessage: $message\n${errorDetails.isNotEmpty ? "Details:\n  ${errorDetails.join('\n  ')}" : ""}';
}

class TddRedGateValidator {
  Future<GateEvaluation> evaluateTestRun(List<String> testFiles) async {
    final process = await Process.start(
      'flutter',
      ['test', '--reporter=json', ...testFiles],
      runInShell: true,
    );

    final lines = process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    bool foundExpectationFailure = false;
    bool foundUnimplementedInSut = false;
    final List<String> setupErrors = [];
    int successCount = 0;

    await for (final line in lines) {
      if (!line.startsWith('{')) continue;
      try {
        final event = jsonDecode(line) as Map<String, dynamic>;

        if (event['type'] == 'testDone') {
          final result = event['result'] as String?;
          final hidden = event['hidden'] as bool? ?? false;

          if (!hidden && result == 'success') {
            successCount++;
          }
        }

        if (event['type'] == 'error') {
          final errorMsg = event['error'] as String? ?? '';
          final stackTrace = event['stackTrace'] as String? ?? '';
          final isFailure = event['isFailure'] as bool? ?? false;

          if (isFailure) {
            foundExpectationFailure = true;
            continue;
          }

          if (errorMsg.contains('UnimplementedError') ||
              errorMsg.contains('todo!') ||
              errorMsg.contains('not yet implemented')) {
            if (_isStackTraceFromProductionCode(stackTrace)) {
              foundUnimplementedInSut = true;
              continue;
            }
          }

          // Common test setup/harness errors
          if (errorMsg.contains('No Directionality widget found') ||
              errorMsg.contains('No MediaQuery widget found') ||
              errorMsg.contains('MissingPluginException') ||
              errorMsg.contains('NoSuchMethodError') ||
              errorMsg.contains('late initialization error')) {
            setupErrors.add('SETUP ERROR: $errorMsg');
          }
        }
      } catch (_) {}
    }

    final exitCode = await process.exitCode;

    if (setupErrors.isNotEmpty) {
      return GateEvaluation(
        isLegitimateRed: false,
        status: 'RED_GATE_SETUP_ERROR',
        message:
            'Test failed due to harness setup/environment error, NOT SUT behavioral failure.',
        errorDetails: setupErrors,
      );
    }

    if (exitCode == 0 && successCount > 0 && !foundExpectationFailure) {
      return GateEvaluation(
        isLegitimateRed: false,
        status: 'RED_GATE_PASSED_UNEXPECTEDLY',
        message:
            'Test passed against baseline/unimplemented code. Tautological or redundant test.',
        errorDetails: ['All $successCount tests passed.'],
      );
    }

    if (foundExpectationFailure || foundUnimplementedInSut) {
      return GateEvaluation(
        isLegitimateRed: true,
        status: 'RED_GATE_PASSED',
        message:
            'Verified legitimate behavioral failure or SUT stub hit.',
        errorDetails: [],
      );
    }

    return GateEvaluation(
      isLegitimateRed: false,
      status: 'RED_GATE_UNKNOWN_FAILURE',
      message: 'Test execution failed with unexpected state.',
      errorDetails: ['Exit code: $exitCode'],
    );
  }

  bool _isStackTraceFromProductionCode(String stackTrace) {
    return stackTrace.contains('package:centrode/features/') ||
        stackTrace.contains('package:centrode/shared/') ||
        stackTrace.contains('package:centrode/infrastructure/') ||
        stackTrace.contains('rust/src/');
  }
}

void main(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart tdd_red_gate_validator.dart <test_file_path>');
    exit(1);
  }

  final validator = TddRedGateValidator();
  final evaluation = await validator.evaluateTestRun(args);
  print(evaluation);

  if (evaluation.isLegitimateRed) {
    exit(0);
  } else {
    exit(1);
  }
}
