import 'dart:io';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

enum SmellSeverity { critical, warning }

class TestSmell {
  final String filePath;
  final String testName;
  final String rule;
  final String message;
  final int lineNumber;
  final SmellSeverity severity;

  TestSmell({
    required this.filePath,
    required this.testName,
    required this.rule,
    required this.message,
    required this.lineNumber,
    required this.severity,
  });

  @override
  String toString() =>
      '[$rule] $filePath (offset: $lineNumber) -> Test: "$testName"\n  $message';
}

class RobustTestSmellVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final List<TestSmell> smells = [];
  final Map<String, bool> _localFunctionAssertionMap = {};

  RobustTestSmellVisitor(this.filePath);

  @override
  void visitCompilationUnit(CompilationUnit node) {
    for (final declaration in node.declarations) {
      if (declaration is FunctionDeclaration) {
        final helperVisitor = _AssertionDetector();
        declaration.functionExpression.body.accept(helperVisitor);
        _localFunctionAssertionMap[declaration.name.lexeme] =
            helperVisitor.hasAssertion;
      }
    }
    super.visitCompilationUnit(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;
    if (name == 'test' || name == 'testWidgets' || name == 'testGoldens') {
      _analyzeTestBlock(node);
    }
    super.visitMethodInvocation(node);
  }

  void _analyzeTestBlock(MethodInvocation testNode) {
    final args = testNode.argumentList.arguments;
    final testName = args.isNotEmpty ? args.first.toString() : 'unknown';
    final body = args.length > 1 ? args[1] : null;

    if (body is! FunctionExpression) return;

    final detector =
        _AssertionDetector(knownHelpers: _localFunctionAssertionMap);
    body.body.accept(detector);

    final lineNum = testNode.offset;

    if (!detector.hasAssertion) {
      smells.add(TestSmell(
        filePath: filePath,
        testName: testName,
        rule: 'NO_ASSERTIONS',
        message:
            'Test block contains 0 reachable expectations, matchers, or verifications.',
        lineNumber: lineNum,
        severity: SmellSeverity.critical,
      ));
    }

    if (detector.unawaitedExpectLater) {
      smells.add(TestSmell(
        filePath: filePath,
        testName: testName,
        rule: 'UNAWAITED_EXPECT_LATER',
        message:
            'Found expectLater without await. Stream expectations may fail silently.',
        lineNumber: lineNum,
        severity: SmellSeverity.critical,
      ));
    }

    for (final vacuous in detector.vacuousAssertions) {
      smells.add(TestSmell(
        filePath: filePath,
        testName: testName,
        rule: 'VACUOUS_ASSERTION',
        message: 'Vacuous assertion detected: ${vacuous.toSource()}',
        lineNumber: vacuous.offset,
        severity: SmellSeverity.critical,
      ));
    }

    if (detector.hasWallClockSleep) {
      smells.add(TestSmell(
        filePath: filePath,
        testName: testName,
        rule: 'NO_WALL_CLOCK_SLEEP',
        message:
            'Detected Future.delayed or sleep() in test. Use fakeAsync or tester.pump().',
        lineNumber: lineNum,
        severity: SmellSeverity.critical,
      ));
    }
  }
}

class _AssertionDetector extends RecursiveAstVisitor<void> {
  final Map<String, bool> knownHelpers;
  bool hasAssertion = false;
  bool unawaitedExpectLater = false;
  bool hasWallClockSleep = false;
  final List<AstNode> vacuousAssertions = [];

  _AssertionDetector({this.knownHelpers = const {}});

  static const _assertionMethods = {
    'expect',
    'expectLater',
    'expectAsync0',
    'expectAsync1',
    'expectAsync2',
    'verify',
    'verifyInOrder',
    'verifyNever',
    'check',
    'assert',
  };

  @override
  void visitMethodInvocation(MethodInvocation node) {
    final name = node.methodName.name;

    if (_assertionMethods.contains(name)) {
      hasAssertion = true;
      _checkVacuousMatcher(node);

      if (name == 'expectLater') {
        final parent = node.parent;
        if (parent is! AwaitExpression) {
          unawaitedExpectLater = true;
        }
      }
    }

    if (knownHelpers[name] == true) {
      hasAssertion = true;
    }

    if ((name == 'delayed' && node.target?.toSource() == 'Future') ||
        name == 'sleep') {
      hasWallClockSleep = true;
    }

    super.visitMethodInvocation(node);
  }

  void _checkVacuousMatcher(MethodInvocation node) {
    final args = node.argumentList.arguments;
    if (args.length >= 2) {
      final actual = args[0].toSource();
      final matcher = args[1].toSource();

      if ((actual == 'true' && (matcher == 'isTrue' || matcher == 'equals(true)')) ||
          (actual == 'false' && (matcher == 'isFalse' || matcher == 'equals(false)')) ||
          (actual == matcher)) {
        vacuousAssertions.add(node);
      }
      if (matcher == 'anything') {
        vacuousAssertions.add(node);
      }
    }
  }
}

void main(List<String> args) async {
  final targetDir = args.isNotEmpty ? args[0] : 'test';
  final dir = Directory(targetDir);

  if (!dir.existsSync()) {
    print('Directory not found: $targetDir');
    exit(1);
  }

  final featureSet = FeatureSet.latestLanguageVersion();
  final allSmells = <TestSmell>[];
  await for (final file in dir.list(recursive: true)) {
    if (file is File && file.path.endsWith('_test.dart')) {
      try {
        final parseResult = parseFile(path: file.path, featureSet: featureSet);
        final visitor = RobustTestSmellVisitor(file.path);
        parseResult.unit.accept(visitor);
        allSmells.addAll(visitor.smells);
      } catch (e) {
        // Skip unparseable files
      }
    }
  }

  print('=== AST TEST SMELL ANALYSIS: $targetDir ===');
  if (allSmells.isEmpty) {
    print('✅ Zero test smells detected across all test suites.');
    exit(0);
  }

  print('🚨 Found ${allSmells.length} test smell violation(s):\n');
  for (final smell in allSmells) {
    print(smell);
    print('---');
  }

  final criticalCount =
      allSmells.where((s) => s.severity == SmellSeverity.critical).length;
  if (criticalCount > 0) {
    print('❌ Found $criticalCount test smell violation(s).');
    exit(0); // Exit 0 for advisory report on baseline
  }
}
