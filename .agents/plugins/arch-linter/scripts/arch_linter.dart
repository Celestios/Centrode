import 'dart:convert';
import 'dart:io';

String cachePath = '.agents/plugins/arch-linter/dart-architecture-cache.json';
bool isRustMode = false;

void main(List<String> args) async {
  final hasDart = args.contains('--dart');
  final hasRust = args.contains('--rust');

  if (!hasDart && !hasRust) {
    print('Error: Explicit mode flag required. Please specify either --dart or --rust.');
    print('Example: dart cache_manager.dart scan --rust');
    exit(1);
  }

  if (hasDart && hasRust) {
    print('Error: Cannot specify both --dart and --rust flags.');
    exit(1);
  }

  isRustMode = hasRust;
  cachePath = isRustMode
      ? '.agents/plugins/arch-linter/rust-architecture-cache.json'
      : '.agents/plugins/arch-linter/dart-architecture-cache.json';

  final cleanArgs = args.where((arg) => arg != '--dart' && arg != '--rust').toList();

  if (cleanArgs.isEmpty) {
    printUsage();
    exit(1);
  }

  final command = cleanArgs[0];
  final cmdArgs = cleanArgs.skip(1).toList();

  switch (command) {
    case 'scan':
      await handleScan(cmdArgs);
      break;
    case 'check':
      await handleCheck(cmdArgs);
      break;
    case 'update':
      await handleUpdate(cmdArgs);
      break;
    case 'update_bulk':
      await handleUpdateBulk(cmdArgs);
      break;
    case 'query':
      await handleQuery(cmdArgs);
      break;
    case 'query_method':
      await handleQueryMethod(cmdArgs);
      break;
    case 'dependents':
      await handleDependents(cmdArgs);
      break;
    case 'trace_path':
      await handleTracePath(cmdArgs);
      break;
    case 'query_metrics':
      await handleQueryMetrics(cmdArgs);
      break;
    case 'assert_naming':
      await handleAssertNaming(cmdArgs);
      break;
    case 'assert_tests':
      await handleAssertTests(cmdArgs);
      break;
    default:
      print('Unknown command: $command');
      printUsage();
      exit(1);
  }
}

void printUsage() {
  print('Usage:');
  print('  dart cache_manager.dart <command> [--dart | --rust] [arguments]');
  print('\nCommands:');
  print('  scan [directory_path (default: lib for --dart, rust/src for --rust)]');
  print('  update <file_path> <status> [violations_separated_by_pipe] [role] [pattern]');
  print('  update_bulk <json_file_path>');
  print('  check [directory_path (default: lib for --dart, rust/src for --rust)]');
  print('  query [filter_key=value ...]');
  print('  query_method [name=val] [return_type=val] [pattern=regex]');
  print('  dependents <file_path>');
  print('  trace_path <source_file> <target_file>');
  print('  query_metrics [api_count>=val] [size>=val] [missing_tests=true|false]');
  print('  assert_naming');
  print('  assert_tests');
  print('\nStatuses: COMPLIANT, VIOLATION_DETECTED, PENDING_AUDIT');
}

// Loads the cache file, creating it if it doesn't exist.
Map<String, dynamic> loadCache() {
  final file = File(cachePath);
  if (!file.existsSync()) {
    // Create parent directories if they don't exist
    file.parent.createSync(recursive: true);
    final layers = isRustMode ? {
      "rust/src/bridge": {
        "tier": 1,
        "responsibility": "FFI boundary, entry points for Flutter interactions, mapping events and data types.",
        "exclusions": "MUST NOT house persistence engine commands or low-level domain mutations directly."
      },
      "rust/src/persistence": {
        "tier": 2,
        "responsibility": "Database and persistence engine, transactions, and SurrealDB client interactions.",
        "exclusions": "MUST NOT depend on or import FFI bridge packages/modules."
      },
      "rust/src/domain": {
        "tier": 3,
        "responsibility": "Core domain logic, structures, and business rules.",
        "exclusions": "MUST NOT import or depend on persistence engine or FFI bridge modules."
      }
    } : {
      "lib/features/graph/ui": {
        "tier": 1,
        "responsibility": "Renders visual UI components, canvas viewports, and overlays for user interaction.",
        "exclusions": "MUST NOT house domain state mutation logic, direct database/FFI calls, or low-level mathematical coordinate calculations."
      },
      "lib/features/graph/engine": {
        "tier": 2,
        "responsibility": "Manages user interaction state (dragging, panning, zooming), processes canvas gestures, and drives the gesture Finite State Machine (FSM).",
        "exclusions": "MUST NOT paint UI widgets directly or interact directly with the database or storage controllers."
      },
      "lib/features/graph/presentation": {
        "tier": 2,
        "responsibility": "Manages UI-specific transient presentation state, view projections, layout strategies, viewport calculations, and theme mappings.",
        "exclusions": "MUST NOT directly mutate database structures or issue raw FFI commands."
      },
      "lib/features/graph/store": {
        "tier": 3,
        "responsibility": "Coordinates in-memory lookup cache, spatial queries, FFI synchronization, and local reactive state updates.",
        "exclusions": "MUST NOT import, listen to, or depend on UI presentation controllers, style managers, or theme controllers."
      },
      "lib/features/graph/models": {
        "tier": 3,
        "responsibility": "Defines UI domain models wrapping core Rust models, providing serialization/deserialization across the FFI boundary.",
        "exclusions": "MUST NOT import or depend on presentation-tier configuration parameters or metrics."
      },
      "lib/infrastructure": {
        "tier": 3,
        "responsibility": "Handles low-level platform infrastructure concerns (logger isolates, uncaught asynchronous telemetry reporting).",
        "exclusions": "MUST NOT import or depend on domain business logic or presentation-tier state."
      }
    };
    final initial = {
      'last_audit_commit': '',
      'last_audit_time': '',
      'layers': layers,
      'components': {}
    };
    final encoder = JsonEncoder.withIndent('  ');
    file.writeAsStringSync(encoder.convert(initial) + '\n');
    return initial;
  }

  try {
    final content = file.readAsStringSync();
    return jsonDecode(content) as Map<String, dynamic>;
  } catch (e) {
    print('Error reading cache file, resetting to empty. Error: $e');
    return {
      'last_audit_commit': '',
      'last_audit_time': '',
      'layers': {},
      'components': {}
    };
  }
}

// Saves the cache file with pretty printing.
void saveCache(Map<String, dynamic> cache) {
  final file = File(cachePath);
  final encoder = JsonEncoder.withIndent('  ');
  file.writeAsStringSync(encoder.convert(cache) + '\n');
}

// Helper to compute a file's hash using git hash-object, with modified-time fallback.
Future<String> getFileHash(String filePath) async {
  try {
    final result = await Process.run('git', ['hash-object', filePath]);
    if (result.exitCode == 0) {
      return result.stdout.toString().trim();
    }
  } catch (_) {}

  // Fallback: compound key of modified timestamp and file size
  final file = File(filePath);
  final stat = file.statSync();
  return '${stat.modified.millisecondsSinceEpoch}_${stat.size}';
}

Future<void> handleScan(List<String> args) async {
  final defaultDir = isRustMode ? 'rust/src' : 'lib';
  final targetDir = args.isNotEmpty ? args[0] : defaultDir;
  final dir = Directory(targetDir);

  if (!dir.existsSync()) {
    print('Target directory does not exist: $targetDir');
    exit(1);
  }

  final cache = loadCache();
  final components = cache['components'] as Map<String, dynamic>;
  final layersMap = cache['layers'] != null ? Map<String, dynamic>.from(cache['layers'] as Map) : <String, dynamic>{};
  bool cacheChanged = false;

  final pendingAudit = <String>[];
  final violationDetected = <String>[];
  final compliant = <String>[];

  final extension = isRustMode ? '.rs' : '.dart';

  final files = dir
      .listSync(recursive: true)
      .where((entity) {
        if (entity is! File || !entity.path.endsWith(extension)) return false;
        final path = entity.path.replaceAll('\\', '/');
        if (isRustMode) {
          return !path.contains('/frb_generated.rs') && !path.contains('/target/');
        } else {
          return !path.contains('/src/rust/');
        }
      })
      .map((entity) => entity.path.replaceAll('\\', '/'))
      .toList();

  for (final filePath in files) {
    final file = File(filePath);
    final currentHash = await getFileHash(filePath);
    Map<String, dynamic> cachedEntry;

    if (components[filePath] == null) {
      cachedEntry = {
        'class': '',
        'architectural_role': '',
        'sha256': currentHash,
        'status': 'PENDING_AUDIT',
        'violations': []
      };
      components[filePath] = cachedEntry;
      pendingAudit.add(filePath);
      cacheChanged = true;
    } else {
      cachedEntry = components[filePath] as Map<String, dynamic>;
      final cachedHash = cachedEntry['sha256'] as String?;
      final cachedStatus = cachedEntry['status'] as String?;

      if (cachedHash != currentHash) {
        cachedEntry['sha256'] = currentHash;
        cachedEntry['status'] = 'PENDING_AUDIT';
        cachedEntry['violations'] = [];
        pendingAudit.add(filePath);
        cacheChanged = true;
      } else {
        if (cachedStatus == 'COMPLIANT') {
          compliant.add(filePath);
        } else if (cachedStatus == 'VIOLATION_DETECTED') {
          violationDetected.add(filePath);
        } else {
          pendingAudit.add(filePath);
        }
      }
    }

    final tier = getTierForFile(filePath, layersMap);
    if (cachedEntry['tier'] != tier) {
      cachedEntry['tier'] = tier;
      cacheChanged = true;
    }

    final content = file.existsSync() ? file.readAsStringSync() : '';
    final cleanContent = stripComments(content);
    final parsedImports = isRustMode ? parseRustImports(cleanContent) : parseImports(cleanContent);
    final resolvedImports = isRustMode ? parsedImports : parsedImports.map((imp) => resolveImport(filePath, imp)).toList();
    
    final oldImports = List<String>.from(cachedEntry['imports'] as List? ?? []);
    if (oldImports.length != resolvedImports.length || !oldImports.every(resolvedImports.contains)) {
      cachedEntry['imports'] = resolvedImports;
      cacheChanged = true;
    }

    final String testFile;
    final bool hasTests;
    if (isRustMode) {
      hasTests = rustFileHasTests(filePath, content);
      testFile = hasTests ? 'inline or integration test' : '';
    } else {
      testFile = getTestFilePath(filePath);
      hasTests = testFile.isNotEmpty;
    }

    if (cachedEntry['test_file'] != testFile) {
      cachedEntry['test_file'] = testFile;
      cachedEntry['has_tests'] = hasTests;
      cacheChanged = true;
    }

    final isFfi = isRustMode ? filePath.contains('/bridge/') : detectsRustFFI(content, resolvedImports);
    if (cachedEntry['is_ffi_bridge'] != isFfi) {
      cachedEntry['is_ffi_bridge'] = isFfi;
      cacheChanged = true;
    }

    if (cachedEntry['pattern'] == null || cachedEntry['pattern'] == '') {
      final pattern = detectPattern(filePath, cachedEntry['class'] as String? ?? '');
      cachedEntry['pattern'] = pattern;
      cacheChanged = true;
    }

    final publicApis = isRustMode ? parseRustPublicApis(file) : parsePublicApis(file);
    final oldApis = List<String>.from(cachedEntry['public_apis'] as List? ?? []);
    if (oldApis.length != publicApis.length || !oldApis.every(publicApis.contains)) {
      cachedEntry['public_apis'] = publicApis;
      cacheChanged = true;
    }

    if (cachedEntry['class'] == null || cachedEntry['class'] == '') {
      cachedEntry['class'] = isRustMode ? parseRustClassNames(file) : parseClassName(file);
      cacheChanged = true;
    }
  }

  // Second pass: audit boundary violations once all files' tiers are established
  for (final filePath in files) {
    final cachedEntry = components[filePath] as Map<String, dynamic>;
    final fileTier = cachedEntry['tier'] as int? ?? 3;
    final resolvedImports = List<String>.from(cachedEntry['imports'] as List? ?? []);

    final violations = checkBoundaryViolations(filePath, fileTier, resolvedImports, components, layersMap);
    final oldBoundaryViolations = List<String>.from(cachedEntry['boundary_violations'] as List? ?? []);

    if (oldBoundaryViolations.length != violations.length || !oldBoundaryViolations.every(violations.contains)) {
      cachedEntry['boundary_violations'] = violations;
      cacheChanged = true;
    }

    final existingViolations = List<String>.from(cachedEntry['violations'] as List? ?? []);
    final nonLeakViolations = existingViolations.where((v) => !v.startsWith('Layer leak:')).toList();
    final newViolations = [...nonLeakViolations, ...violations];

    // Sort to compare
    newViolations.sort();
    existingViolations.sort();

    final bool violationsChanged = newViolations.length != existingViolations.length || 
        !newViolations.every(existingViolations.contains);

    if (violationsChanged) {
      cachedEntry['violations'] = newViolations;
      cacheChanged = true;

      if (newViolations.isEmpty && cachedEntry['status'] == 'VIOLATION_DETECTED') {
        cachedEntry['status'] = 'COMPLIANT';
      } else if (newViolations.isNotEmpty) {
        cachedEntry['status'] = 'VIOLATION_DETECTED';
      }
    }

    final finalStatus = cachedEntry['status'] as String? ?? 'PENDING_AUDIT';
    if (finalStatus == 'VIOLATION_DETECTED') {
      compliant.remove(filePath);
      pendingAudit.remove(filePath);
      if (!violationDetected.contains(filePath)) {
        violationDetected.add(filePath);
      }
    } else if (finalStatus == 'COMPLIANT') {
      if (!compliant.contains(filePath)) {
        compliant.add(filePath);
      }
      pendingAudit.remove(filePath);
      violationDetected.remove(filePath);
    } else {
      if (!pendingAudit.contains(filePath)) {
        pendingAudit.add(filePath);
      }
      compliant.remove(filePath);
      violationDetected.remove(filePath);
    }
  }

  // Check for deleted files that are still in the cache
  final Set<String> currentFilesSet = files.toSet();
  final keysToRemove = <String>[];
  components.forEach((key, _) {
    // Only check files that belong to the target scan directory
    if (key.startsWith(targetDir) && !currentFilesSet.contains(key)) {
      keysToRemove.add(key);
    }
  });

  if (keysToRemove.isNotEmpty) {
    for (final key in keysToRemove) {
      components.remove(key);
    }
    cacheChanged = true;
  }

  if (cacheChanged) {
    saveCache(cache);
  }

  // Print results to stdout in a clean, structured format for the agent to parse
  print('\n=== SRP AUDIT CACHE SCAN RESULTS ===');
  print('Total Files Scanned: ${files.length}');
  print('Bypassed (Compliant): ${compliant.length}');
  print('Queue - Pending Audit: ${pendingAudit.length}');
  print('Queue - Violation Detected: ${violationDetected.length}');
  
  if (pendingAudit.isNotEmpty) {
    print('\n[AUDIT_REQUIRED - PENDING]');
    for (final file in pendingAudit) {
      print('  $file');
    }
  }

  if (violationDetected.isNotEmpty) {
    print('\n[AUDIT_REQUIRED - VIOLATION]');
    for (final file in violationDetected) {
      final entry = components[file] as Map<String, dynamic>;
      final list = entry['violations'] as List? ?? [];
      print('  $file - Violations: $list');
    }
  }
}

Future<void> handleUpdate(List<String> args) async {
  if (args.length < 2) {
    print('Error: Missing arguments for update command.');
    printUsage();
    exit(1);
  }

  final filePath = args[0].replaceAll('\\', '/');
  final status = args[1].toUpperCase();
  
  if (status != 'COMPLIANT' && status != 'VIOLATION_DETECTED' && status != 'PENDING_AUDIT') {
    print('Error: Invalid status: $status. Must be COMPLIANT, VIOLATION_DETECTED, or PENDING_AUDIT.');
    exit(1);
  }

  final file = File(filePath);
  if (!file.existsSync()) {
    print('Error: File does not exist: $filePath');
    exit(1);
  }

  final cache = loadCache();
  final components = cache['components'] as Map<String, dynamic>;
  final cachedEntry = components[filePath] as Map<String, dynamic>? ?? {};

  final currentHash = await getFileHash(filePath);

  // Extract violations list if provided
  final violationsList = <String>[];
  if (args.length > 2 && args[2].isNotEmpty) {
    violationsList.addAll(args[2].split('|').map((v) => v.trim()).where((v) => v.isNotEmpty));
  }

  // Extract responsibility if provided
  if (args.length > 3 && args[3].isNotEmpty) {
    cachedEntry['architectural_role'] = args[3].trim();
  }

  // Extract pattern if provided
  if (args.length > 4 && args[4].isNotEmpty) {
    cachedEntry['pattern'] = args[4].trim();
  }

  // Update entry
  cachedEntry['sha256'] = currentHash;
  cachedEntry['status'] = status;
  cachedEntry['violations'] = violationsList;

  // Try to find the class name dynamically if not already populated
  if (cachedEntry['class'] == null || cachedEntry['class'] == '') {
    cachedEntry['class'] = parseClassName(file);
  }

  components[filePath] = cachedEntry;

  // Update global commit meta
  try {
    final gitCommitResult = await Process.run('git', ['rev-parse', 'HEAD']);
    if (gitCommitResult.exitCode == 0) {
      cache['last_audit_commit'] = gitCommitResult.stdout.toString().trim();
    }
  } catch (_) {}

  cache['last_audit_time'] = DateTime.now().toUtc().toIso8601String();

  saveCache(cache);
  print('Successfully updated cache for $filePath to $status.');
}

String parseClassName(File file) {
  final names = <String>[];
  try {
    final content = file.readAsStringSync();
    final clean = stripComments(content);
    final lines = clean.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      final match = RegExp(r'^(?:(?:abstract|base|interface|final|sealed)\s+)?(?:class|mixin|enum|extension)\s+([a-zA-Z0-9_]+)').firstMatch(trimmed);
      if (match != null) {
        final name = match.group(1);
        if (name != null && !names.contains(name)) {
          names.add(name);
        }
      }
    }
  } catch (_) {}
  return names.join(', ');
}

Future<void> handleCheck(List<String> args) async {
  final defaultDir = isRustMode ? 'rust/src' : 'lib';
  final targetDir = args.isNotEmpty ? args[0] : defaultDir;
  final dir = Directory(targetDir);

  if (!dir.existsSync()) {
    print('Target directory does not exist: $targetDir');
    exit(1);
  }

  // Pre-run scan to update all hashes, rich metadata, and boundary violations
  await handleScan([targetDir]);

  final cache = loadCache();
  final components = cache['components'] as Map<String, dynamic>;
  final pendingAudit = <String>[];
  final violationDetected = <String>[];

  final extension = isRustMode ? '.rs' : '.dart';

  final files = dir
      .listSync(recursive: true)
      .where((entity) {
        if (entity is! File || !entity.path.endsWith(extension)) return false;
        final path = entity.path.replaceAll('\\', '/');
        if (isRustMode) {
          return !path.contains('/frb_generated.rs') && !path.contains('/target/');
        } else {
          return !path.contains('/src/rust/');
        }
      })
      .map((entity) => entity.path.replaceAll('\\', '/'))
      .toList();

  for (final filePath in files) {
    final cachedEntry = components[filePath] as Map<String, dynamic>?;

    if (cachedEntry == null) {
      pendingAudit.add(filePath);
    } else {
      final cachedStatus = cachedEntry['status'] as String?;
      if (cachedStatus == 'VIOLATION_DETECTED') {
        violationDetected.add(filePath);
      } else if (cachedStatus != 'COMPLIANT') {
        pendingAudit.add(filePath);
      }
    }
  }

  print('\n=== SRP AUDIT COMPLIANCE CHECK ===');
  print('Total Files Checked: ${files.length}');
  print('Pending Audit Queue: ${pendingAudit.length}');
  print('Violation Queue: ${violationDetected.length}');

  if (violationDetected.isNotEmpty) {
    print('\n❌ VIOLATIONS DETECTED:');
    for (final file in violationDetected) {
      final entry = components[file] as Map<String, dynamic>;
      print('  $file - Violations: ${entry['violations']}');
    }
  }

  if (pendingAudit.isNotEmpty) {
    print('\n⚠️ PENDING AUDITS (needs to be audited or has modified hashes):');
    for (final file in pendingAudit) {
      print('  $file');
    }
  }

  if (violationDetected.isNotEmpty || pendingAudit.isNotEmpty) {
    print('\n❌ Compliance check failed. Please resolve violations or run the /arch-linter workflow.');
    exit(1);
  }

  print('\n✅ All files are COMPLIANT.');
  exit(0);
}

int getTierForFile(String filePath, Map<String, dynamic> layers) {
  for (final layerPath in layers.keys) {
    if (filePath.startsWith(layerPath)) {
      final layerMeta = layers[layerPath] as Map<String, dynamic>?;
      if (layerMeta != null && layerMeta['tier'] != null) {
        return layerMeta['tier'] as int;
      }
    }
  }
  if (isRustMode) {
    if (filePath.contains('/bridge/')) return 1;
    if (filePath.contains('/persistence/')) return 2;
    if (filePath.contains('/domain/')) return 3;
    if (filePath.contains('/format/') || filePath.contains('/telemetry.rs')) return 3;
    return 3;
  }
  if (filePath.contains('/ui/')) return 1;
  if (filePath.contains('/engine/') || filePath.contains('/presentation/')) return 2;
  if (filePath.contains('/store/') || filePath.contains('/models/') || filePath.contains('/infrastructure/')) return 3;
  return 3;
}

List<String> parseImports(String content) {
  final imports = <String>[];
  final importRegex = RegExp(r"import\s+['\']([^'\']+)['\'];");
  final matches = importRegex.allMatches(content);
  for (final match in matches) {
    final imp = match.group(1);
    if (imp != null) {
      imports.add(imp);
    }
  }
  return imports;
}

String resolveImport(String currentFilePath, String importUri) {
  if (importUri.startsWith('package:mycelium/')) {
    return importUri.replaceFirst('package:mycelium/', 'lib/');
  }
  if (importUri.startsWith('dart:') || importUri.startsWith('package:')) {
    return importUri;
  }
  final currentDirSegments = currentFilePath.split('/');
  currentDirSegments.removeLast();
  
  final importSegments = importUri.split('/');
  for (final seg in importSegments) {
    if (seg == '.') {
      continue;
    } else if (seg == '..') {
      if (currentDirSegments.isNotEmpty) {
        currentDirSegments.removeLast();
      }
    } else {
      currentDirSegments.add(seg);
    }
  }
  return currentDirSegments.join('/');
}

List<String> checkBoundaryViolations(String filePath, int fileTier, List<String> resolvedImports, Map<String, dynamic> components, Map<String, dynamic> layers) {
  final violations = <String>[];
  if (!isRustMode && filePath == 'lib/main.dart') {
    return violations;
  }
  for (final imp in resolvedImports) {
    if (!isRustMode && (imp.startsWith('package:') || imp.startsWith('dart:'))) {
      continue;
    }
    if (isRustMode && !imp.startsWith('rust/src/')) {
      continue;
    }
    final importedEntry = components[imp] as Map<String, dynamic>?;
    int? importedTier;
    if (importedEntry != null) {
      importedTier = importedEntry['tier'] as int?;
    } else {
      importedTier = getTierForFile(imp, layers);
    }
    
    if (importedTier != null && importedTier < fileTier) {
      violations.add('Layer leak: Tier $fileTier component imports Tier $importedTier component ($imp)');
    }
  }
  return violations;
}

String getTestFilePath(String filePath) {
  if (filePath.startsWith('lib/')) {
    final testPath = filePath.replaceFirst('lib/', 'test/').replaceFirst('.dart', '_test.dart');
    if (File(testPath).existsSync()) {
      return testPath;
    }
  }
  return '';
}

bool detectsRustFFI(String content, List<String> resolvedImports) {
  if (resolvedImports.any((imp) => imp.contains('src/rust/'))) {
    return true;
  }
  return content.contains('rustLib') || content.contains('api.') || content.contains('frb_generated');
}

String detectPattern(String filePath, String className) {
  final lowerPath = filePath.toLowerCase();
  final lowerClass = className.toLowerCase();
  if (isRustMode) {
    if (lowerPath.contains('/bridge/')) return 'FFI Bridge';
    if (lowerPath.contains('/persistence/')) return 'Persistence Engine';
    if (lowerPath.contains('/domain/')) return 'Domain Logic';
    if (lowerClass.contains('state')) return 'FSM State';
    if (lowerClass.contains('command')) return 'Command Pattern';
    if (lowerClass.contains('strategy')) return 'Strategy Pattern';
    if (lowerClass.contains('facade')) return 'Facade Pattern';
    if (lowerClass.contains('error')) return 'Error Type';
    if (lowerClass.contains('helper') || lowerClass.contains('utils')) return 'Utility/Helper';
    return 'Rust Module';
  }
  if (lowerPath.contains('/ui/')) return 'UI Component';
  if (lowerPath.contains('/models/')) return 'Data Model';
  if (lowerClass.endsWith('controller') || lowerClass.endsWith('manager')) return 'Controller/Manager';
  if (lowerClass.endsWith('state')) return 'FSM State';
  if (lowerClass.endsWith('command')) return 'Command Pattern';
  if (lowerClass.endsWith('strategy')) return 'Strategy Pattern';
  if (lowerClass.endsWith('facade')) return 'Facade Pattern';
  if (lowerClass.contains('mutation')) return 'Mutation Helper';
  if (lowerClass.contains('store')) return 'Data Store';
  if (lowerClass.contains('utils') || lowerClass.contains('helper')) return 'Utility/Helper';
  return 'Component';
}

List<String> parsePublicApis(File file) {
  final apis = <String>[];
  try {
    final content = file.readAsStringSync();
    final clean = stripComments(content);
    final lines = clean.split('\n');
    final methodRegex = RegExp(r'^\s+(?:[a-zA-Z0-9<>_?]+)\s+([a-z][a-zA-Z0-9_]*)\s*\(');
    for (final line in lines) {
      final trimmed = line.trim();
      final match = methodRegex.firstMatch(line);
      if (match != null) {
        final methodName = match.group(1);
        if (methodName != null && methodName != 'if' && methodName != 'for' && methodName != 'switch' && methodName != 'while' && methodName != 'catch') {
          final decl = trimmed.split('{').first.trim();
          if (!apis.contains(decl)) {
            apis.add(decl);
          }
        }
      }
    }
  } catch (_) {}
  return apis;
}

Future<void> handleQueryMethod(List<String> args) async {
  if (args.isEmpty) {
    print('Usage:');
    print('  dart cache_manager.dart query_method [filter_key=value ...]');
    print('\nAvailable filters:');
    print('  name=<method_name>');
    print('  return_type=<type>');
    print('  pattern=<regex>');
    exit(0);
  }

  final filters = <String, String>{};
  for (final arg in args) {
    final parts = arg.split('=');
    if (parts.length == 2) {
      filters[parts[0].trim().toLowerCase()] = parts[1].trim().toLowerCase();
    }
  }

  final cache = loadCache();
  final components = cache['components'] as Map<String, dynamic>;
  final matches = <String, List<String>>{};

  components.forEach((filePath, data) {
    final apis = List<String>.from(data['public_apis'] as List? ?? []);
    final matchedApis = <String>[];

    for (final api in apis) {
      bool isMatch = true;
      final parsed = parseMethodSignature(api);

      if (filters.containsKey('name')) {
        final nameVal = filters['name']!;
        final methodName = ((parsed != null ? parsed['name'] : api) ?? '').toLowerCase();
        if (!methodName.contains(nameVal)) {
          isMatch = false;
        }
      }

      if (filters.containsKey('return_type')) {
        final retVal = filters['return_type']!;
        final retType = ((parsed != null ? parsed['return_type'] : '') ?? '').toLowerCase();
        if (!retType.contains(retVal)) {
          isMatch = false;
        }
      }

      if (filters.containsKey('pattern')) {
        try {
          final regex = RegExp(filters['pattern']!, caseSensitive: false);
          if (!regex.hasMatch(api)) {
            isMatch = false;
          }
        } catch (_) {
          isMatch = false;
        }
      }

      if (isMatch) {
        matchedApis.add(api);
      }
    }

    if (matchedApis.isNotEmpty) {
      matches[filePath] = matchedApis;
    }
  });

  print('\n=== CACHE METHOD QUERY RESULTS (Found matches in ${matches.length} components) ===');
  matches.forEach((filePath, apisList) {
    print('\n$filePath:');
    for (final api in apisList) {
      print('  - $api');
    }
  });
}

Map<String, String>? parseMethodSignature(String signature) {
  final match = RegExp(r'^([a-zA-Z0-9<>_?]+(?:\s+[a-zA-Z0-9<>_?]+)*)\s+([a-zA-Z0-9_]+)\s*\(').firstMatch(signature);
  if (match != null) {
    return {
      'return_type': match.group(1)!.trim(),
      'name': match.group(2)!.trim()
    };
  }
  return null;
}

Future<void> handleDependents(List<String> args) async {
  if (args.isEmpty) {
    print('Usage: dart cache_manager.dart dependents <file_path>');
    exit(1);
  }

  final targetFile = args[0].replaceAll('\\', '/');
  final cache = loadCache();
  final components = cache['components'] as Map<String, dynamic>;
  final dependentsList = <String>[];

  components.forEach((filePath, data) {
    final imports = List<String>.from(data['imports'] as List? ?? []);
    if (imports.contains(targetFile)) {
      dependentsList.add(filePath);
    }
  });

  print('\n=== DEPENDENTS OF $targetFile (Found ${dependentsList.length} dependents) ===');
  for (final dep in dependentsList) {
    print('  - $dep');
  }
}

Future<void> handleTracePath(List<String> args) async {
  if (args.length < 2) {
    print('Usage: dart cache_manager.dart trace_path <source_file> <target_file>');
    exit(1);
  }

  final source = args[0].replaceAll('\\', '/');
  final target = args[1].replaceAll('\\', '/');

  final cache = loadCache();
  final components = cache['components'] as Map<String, dynamic>;

  if (!components.containsKey(source)) {
    print('Error: Source file not found in cache: $source');
    exit(1);
  }
  if (!components.containsKey(target)) {
    print('Error: Target file not found in cache: $target');
    exit(1);
  }

  final path = traceImportPath(source, target, components);

  if (path == null) {
    print('\nNo import path connects $source to $target.');
  } else {
    print('\n=== IMPORT PATH: $source -> $target ===');
    for (int i = 0; i < path.length; i++) {
      final file = path[i];
      final entry = components[file] as Map<String, dynamic>?;
      final tierStr = entry != null ? ' (Tier ${entry['tier']})' : '';
      print('  [$i] $file$tierStr');
    }
  }
}

List<String>? traceImportPath(String source, String target, Map<String, dynamic> components) {
  final queue = <List<String>>[[source]];
  final visited = <String>{source};
  while (queue.isNotEmpty) {
    final path = queue.removeAt(0);
    final current = path.last;
    if (current == target) return path;
    final entry = components[current] as Map<String, dynamic>?;
    if (entry != null && entry['imports'] != null) {
      final imports = List<String>.from(entry['imports'] as List);
      for (final imp in imports) {
        if (!visited.contains(imp)) {
          visited.add(imp);
          queue.add([...path, imp]);
        }
      }
    }
  }
  return null;
}

Future<void> handleQueryMetrics(List<String> args) async {
  if (args.isEmpty) {
    print('Usage:');
    print('  dart cache_manager.dart query_metrics [filter_key>=value ...]');
    print('\nAvailable filters (shell-safe alternatives in brackets):');
    print('  api_count>=<val>  (or api_count_gte=<val>)');
    print('  size>=<val>       (or size_gte=<val>)');
    print('  missing_tests=true|false');
    exit(0);
  }

  int? apiCountMin;
  int? sizeMin;
  bool? missingTests;

  for (final arg in args) {
    if (arg.startsWith('api_count>=')) {
      apiCountMin = int.tryParse(arg.substring(11));
    } else if (arg.startsWith('api_count_gte=')) {
      apiCountMin = int.tryParse(arg.substring(14));
    } else if (arg.startsWith('api_count=')) {
      apiCountMin = int.tryParse(arg.substring(10));
    } else if (arg.startsWith('size>=')) {
      sizeMin = int.tryParse(arg.substring(6));
    } else if (arg.startsWith('size_gte=')) {
      sizeMin = int.tryParse(arg.substring(9));
    } else if (arg.startsWith('size=')) {
      sizeMin = int.tryParse(arg.substring(5));
    } else if (arg.startsWith('missing_tests=')) {
      missingTests = arg.substring(14).toLowerCase() == 'true';
    }
  }

  final cache = loadCache();
  final components = cache['components'] as Map<String, dynamic>;
  final results = <String, Map<String, dynamic>>{};

  components.forEach((filePath, data) {
    bool matches = true;
    final apisCount = (data['public_apis'] as List? ?? []).length;
    final size = getLineCount(filePath);
    final isMissingTests = data['has_tests'] == false;

    if (apiCountMin != null && apisCount < apiCountMin!) {
      matches = false;
    }
    if (sizeMin != null && size < sizeMin!) {
      matches = false;
    }
    if (missingTests != null && isMissingTests != missingTests!) {
      matches = false;
    }

    if (matches) {
      results[filePath] = {
        ...data as Map<String, dynamic>,
        'computed_size': size,
        'computed_api_count': apisCount
      };
    }
  });

  print('\n=== CACHE METRICS RESULTS (Found ${results.length} matches) ===');
  results.forEach((filePath, data) {
    print('\n$filePath:');
    print('  Class:      ${data['class']}');
    print('  Line Count: ${data['computed_size']} lines');
    print('  API Count:  ${data['computed_api_count']} public APIs');
    print('  Pattern:    ${data['pattern']}');
    print('  Status:     ${data['status']}');
    print('  Has Tests:  ${data['has_tests']}');
  });
}

int getLineCount(String filePath) {
  try {
    final file = File(filePath);
    if (file.existsSync()) {
      return file.readAsLinesSync().length;
    }
  } catch (_) {}
  return 0;
}

Future<void> handleAssertNaming(List<String> args) async {
  final cache = loadCache();
  final components = cache['components'] as Map<String, dynamic>;
  final violations = <String>[];

  components.forEach((filePath, data) {
    final className = data['class'] as String? ?? '';
    if (className.isEmpty) return;

    final path = filePath.toLowerCase();
    final name = className.toLowerCase();

    if (isRustMode) {
      final fileName = filePath.split('/').last;
      if (!RegExp(r'^[a-z0-9_]+\.rs$').hasMatch(fileName)) {
        violations.add('Naming Violation: Rust source file names must be snake_case. Found: $filePath');
      }
      return;
    }

    // 1. Strategies directory naming rule
    if (path.contains('/strategies/')) {
      if (!filePath.endsWith('_strategy.dart') || !name.endsWith('strategy')) {
        violations.add('Naming Violation: File under strategies/ folder must suffix with _strategy.dart and contain class ending in Strategy. Found: $filePath -> Class: $className');
      }
    }

    // 2. States directory naming rule
    if (path.contains('/states/')) {
      if (!name.endsWith('state') && 
          !name.endsWith('idle') && 
          !name.endsWith('dragging') && 
          !name.endsWith('drawing') && 
          !name.endsWith('resizing') && 
          !name.endsWith('selecting') &&
          !name.endsWith('active')) {
        violations.add('Naming Violation: File under states/ folder must contain State or active state FSM suffix (e.g. Idle, Resizing, Dragging). Found: $filePath -> Class: $className');
      }
    }

    // 3. Store modules directory naming rule
    if (path.contains('/store/modules/')) {
      if (!name.endsWith('mutations') && 
          !name.endsWith('store') && 
          !name.endsWith('spatial') && 
          !name.endsWith('engine') && 
          !name.endsWith('facade') &&
          !name.endsWith('index')) {
        violations.add('Naming Violation: File under store/modules/ folder must suffix with Mutations, Store, Spatial, Engine, Facade, or Index. Found: $filePath -> Class: $className');
      }
    }
  });

  print('\n=== SRP ARCHITECTURE NAMING CONVENTIONS ASSERTION ===');
  if (violations.isNotEmpty) {
    print('❌ Naming assertions failed with ${violations.length} violations:');
    for (final v in violations) {
      print('  - $v');
    }
    exit(1);
  }

  print('✅ All class and file names are compliant with directory patterns.');
  exit(0);
}

Future<void> handleAssertTests(List<String> args) async {
  final cache = loadCache();
  final components = cache['components'] as Map<String, dynamic>;
  final violations = <String>[];

  components.forEach((filePath, data) {
    final tier = data['tier'] as int? ?? 3;
    final hasTests = data['has_tests'] as bool? ?? false;
    final testFile = data['test_file'] as String? ?? '';

    if (isRustMode) {
      if (tier >= 2) {
        if (!hasTests) {
          violations.add('Test Coverage Violation: Tier $tier Rust component does not have inline or integration tests. Found: $filePath');
        }
      }
      return;
    }

    // Check test coverage for Tier 2 and Tier 3 files
    if (tier >= 2) {
      if (filePath.contains('lib/main.dart') || filePath.contains('/shared/')) {
        return;
      }
      if (!hasTests || testFile.isEmpty) {
        violations.add('Test Coverage Violation: Tier $tier component does not have an associated test file. Found: $filePath (Expected test file: ${filePath.replaceFirst("lib/", "test/").replaceFirst(".dart", "_test.dart")})');
      }
    }
  });

  print('\n=== SRP ARCHITECTURE TEST COVERAGE ASSERTION ===');
  if (violations.isNotEmpty) {
    print('❌ Test coverage assertions failed with ${violations.length} violations:');
    for (final v in violations) {
      print('  - $v');
    }
    exit(1);
  }

  print('✅ All Tier 2 and Tier 3 components have test coverage.');
  exit(0);
}

Future<void> handleQuery(List<String> args) async {
  if (args.isEmpty) {
    print('Usage:');
    print('  dart cache_manager.dart query [filter_key=value ...]');
    print('\nAvailable filters:');
    print('  tier=<1|2|3>');
    print('  pattern=<PatternName>');
    print('  status=<COMPLIANT|PENDING_AUDIT|VIOLATION_DETECTED>');
    print('  has_tests=<true|false>');
    print('  is_ffi=<true|false>');
    print('  dir=<directory_path>');
    exit(0);
  }

  final filters = <String, String>{};
  for (final arg in args) {
    final parts = arg.split('=');
    if (parts.length == 2) {
      filters[parts[0].trim().toLowerCase()] = parts[1].trim().toLowerCase();
    }
  }

  final cache = loadCache();
  final components = cache['components'] as Map<String, dynamic>;
  final results = <String, Map<String, dynamic>>{};

  components.forEach((filePath, data) {
    bool matches = true;

    // Filter by Directory
    if (filters.containsKey('dir')) {
      final dirVal = filters['dir']!;
      if (!filePath.toLowerCase().contains(dirVal)) {
        matches = false;
      }
    }

    // Filter by Tier
    if (filters.containsKey('tier')) {
      final tierVal = int.tryParse(filters['tier']!);
      if (data['tier'] != tierVal) {
        matches = false;
      }
    }

    // Filter by Pattern
    if (filters.containsKey('pattern')) {
      final patternVal = filters['pattern']!;
      final compPattern = (data['pattern'] as String? ?? '').toLowerCase();
      if (!compPattern.contains(patternVal)) {
        matches = false;
      }
    }

    // Filter by Status
    if (filters.containsKey('status')) {
      final statusVal = filters['status']!;
      if ((data['status'] as String? ?? '').toLowerCase() != statusVal) {
        matches = false;
      }
    }

    // Filter by Has Tests
    if (filters.containsKey('has_tests')) {
      final hasTestsVal = filters['has_tests'] == 'true';
      if (data['has_tests'] != hasTestsVal) {
        matches = false;
      }
    }

    // Filter by FFI
    if (filters.containsKey('is_ffi')) {
      final isFfiVal = filters['is_ffi'] == 'true';
      if (data['is_ffi_bridge'] != isFfiVal) {
        matches = false;
      }
    }

    if (matches) {
      results[filePath] = data as Map<String, dynamic>;
    }
  });

  print('\n=== CACHE QUERY RESULTS (Found ${results.length} matches) ===');
  results.forEach((filePath, data) {
    print('\n$filePath:');
    print('  Class(es): ${data['class']}');
    print('  Tier:      ${data['tier']}');
    print('  Pattern:   ${data['pattern']}');
    print('  Status:    ${data['status']}');
    if (data['architectural_role'] != null && data['architectural_role'].toString().isNotEmpty) {
      print('  Arch Role: ${data['architectural_role']}');
    }
    if (data['violations'] != null && data['violations'].toString() != '[]') {
      print('  Violations: ${data['violations']}');
    }
    print('  Has Tests: ${data['has_tests']} (${data['test_file']})');
    print('  FFI Bridge: ${data['is_ffi_bridge']}');
  });
}

String stripComments(String content) {
  final blockCommentRegex = RegExp(r'/\*[\s\S]*?\*/');
  final lineCommentRegex = RegExp(r'//.*');
  var result = content.replaceAll(blockCommentRegex, '');
  result = result.replaceAll(lineCommentRegex, '');
  return result;
}

String resolveRustImport(String importUri) {
  if (!importUri.startsWith('crate::')) {
    return importUri;
  }
  
  final parts = importUri.replaceFirst('crate::', '').split('::');
  for (int i = parts.length; i > 0; i--) {
    final subPath = parts.sublist(0, i).join('/');
    final file1 = 'rust/src/$subPath.rs';
    final file2 = 'rust/src/$subPath/mod.rs';
    if (File(file1).existsSync()) {
      return file1;
    }
    if (File(file2).existsSync()) {
      return file2;
    }
  }
  return 'rust/src/${parts[0]}.rs';
}

List<String> parseRustImports(String content) {
  final imports = <String>[];
  final regex = RegExp(r'use\s+(crate::[a-zA-Z0-9_:]+(?:\s*::\s*\{[^}]*\})?)\s*;');
  final matches = regex.allMatches(content);
  for (final match in matches) {
    var imp = match.group(1)?.replaceAll(RegExp(r'\s+'), '') ?? '';
    if (imp.isEmpty) continue;
    
    if (imp.contains('{')) {
      final parts = imp.split('{');
      final base = parts[0];
      final items = parts[1].replaceAll('}', '').split(',');
      for (final item in items) {
        if (item.trim().isNotEmpty) {
          imports.add(resolveRustImport('$base${item.trim()}'));
        }
      }
    } else {
      imports.add(resolveRustImport(imp));
    }
  }
  return imports.toSet().toList();
}

String parseRustClassNames(File file) {
  final names = <String>[];
  try {
    final content = file.readAsStringSync();
    final clean = stripComments(content);
    final lines = clean.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      final structMatch = RegExp(r'^(?:pub\s+)?(?:struct|enum|trait)\s+([a-zA-Z0-9_]+)').firstMatch(trimmed);
      if (structMatch != null) {
        final name = structMatch.group(1);
        if (name != null && !names.contains(name)) {
          names.add(name);
        }
      }
    }
  } catch (_) {}
  return names.join(', ');
}

List<String> parseRustPublicApis(File file) {
  final apis = <String>[];
  try {
    final content = file.readAsStringSync();
    final clean = stripComments(content);
    final lines = clean.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      final fnMatch = RegExp(r'^\s*pub\s+(?:async\s+)?fn\s+([a-z0-9_]+)\s*\(').firstMatch(line);
      if (fnMatch != null) {
        final decl = trimmed.split('{').first.trim();
        if (!apis.contains(decl)) {
          apis.add(decl);
        }
      }
    }
  } catch (_) {}
  return apis;
}

bool rustFileHasTests(String filePath, String fileContent) {
  if (fileContent.contains('#[cfg(test)]') || fileContent.contains('#[test]')) {
    return true;
  }
  final parts = filePath.split('/');
  if (parts.length > 2) {
    final fileName = parts.last;
    final testFileName = fileName.replaceFirst('.rs', '_test.rs');
    final integrationTestPath = 'rust/tests/$testFileName';
    if (File(integrationTestPath).existsSync()) {
      return true;
    }
    final testsDir = Directory('rust/tests');
    if (testsDir.existsSync()) {
      final list = testsDir.listSync(recursive: true);
      for (final entity in list) {
        if (entity is File && entity.path.contains(fileName.replaceFirst('.rs', ''))) {
          return true;
        }
      }
    }
  }
  return false;
}

Future<void> handleUpdateBulk(List<String> args) async {
  if (args.isEmpty) {
    print('Error: Missing JSON file path for update_bulk command.');
    printUsage();
    exit(1);
  }

  final jsonPath = args[0];
  final jsonFile = File(jsonPath);
  if (!jsonFile.existsSync()) {
    print('Error: JSON file not found at $jsonPath');
    exit(1);
  }

  final Map<String, dynamic> bulkData;
  try {
    final jsonContent = jsonFile.readAsStringSync();
    bulkData = jsonDecode(jsonContent) as Map<String, dynamic>;
  } catch (e) {
    print('Error decoding bulk JSON: $e');
    exit(1);
  }

  final cache = loadCache();
  final components = cache['components'] as Map<String, dynamic>;
  bool changed = false;

  for (final entry in bulkData.entries) {
    final filePath = entry.key.replaceAll('\\', '/');
    final data = entry.value;
    if (data is! Map<String, dynamic>) {
      print('Warning: Invalid format for $filePath, skipping.');
      continue;
    }

    final file = File(filePath);
    if (!file.existsSync()) {
      print('Warning: File does not exist: $filePath, skipping.');
      continue;
    }

    final status = (data['status'] as String? ?? '').toUpperCase();
    if (status != 'COMPLIANT' && status != 'VIOLATION_DETECTED' && status != 'PENDING_AUDIT') {
      print('Warning: Invalid status "$status" for $filePath, skipping.');
      continue;
    }

    final cachedEntry = components[filePath] as Map<String, dynamic>? ?? {};
    final currentHash = await getFileHash(filePath);

    final violationsList = <String>[];
    if (data['violations'] != null) {
      if (data['violations'] is List) {
        violationsList.addAll((data['violations'] as List).map((v) => v.toString()));
      } else if (data['violations'] is String && data['violations'].isNotEmpty) {
        violationsList.addAll(data['violations'].split('|').map((v) => v.trim()).where((v) => v.isNotEmpty));
      }
    }

    if (data['architectural_role'] != null) {
      cachedEntry['architectural_role'] = data['architectural_role'].toString().trim();
    }
    if (data['pattern'] != null) {
      cachedEntry['pattern'] = data['pattern'].toString().trim();
    }

    cachedEntry['sha256'] = currentHash;
    cachedEntry['status'] = status;
    cachedEntry['violations'] = violationsList;

    if (cachedEntry['class'] == null || cachedEntry['class'] == '') {
      cachedEntry['class'] = isRustMode ? parseRustClassNames(file) : parseClassName(file);
    }

    components[filePath] = cachedEntry;
    changed = true;
  }

  if (changed) {
    try {
      final gitCommitResult = await Process.run('git', ['rev-parse', 'HEAD']);
      if (gitCommitResult.exitCode == 0) {
        cache['last_audit_commit'] = gitCommitResult.stdout.toString().trim();
      }
    } catch (_) {}

    cache['last_audit_time'] = DateTime.now().toUtc().toIso8601String();
    saveCache(cache);
    print('Successfully bulk-updated cache.');
  } else {
    print('No components were updated.');
  }
}
