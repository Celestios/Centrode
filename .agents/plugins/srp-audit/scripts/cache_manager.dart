import 'dart:convert';
import 'dart:io';

const String cachePath = '.agents/plugins/srp-audit/architecture-cache.json';

void main(List<String> args) async {
  if (args.isEmpty) {
    printUsage();
    exit(1);
  }

  final command = args[0];

  switch (command) {
    case 'scan':
      await handleScan(args.skip(1).toList());
      break;
    case 'update':
      await handleUpdate(args.skip(1).toList());
      break;
    default:
      print('Unknown command: $command');
      printUsage();
      exit(1);
  }
}

void printUsage() {
  print('Usage:');
  print('  dart cache_manager.dart scan [directory_path (default: lib)]');
  print('  dart cache_manager.dart update <file_path> <status> [violations_separated_by_pipe]');
  print('\nStatuses: COMPLIANT, VIOLATION_DETECTED, PENDING_AUDIT');
}

// Loads the cache file, creating it if it doesn't exist.
Map<String, dynamic> loadCache() {
  final file = File(cachePath);
  if (!file.existsSync()) {
    // Create parent directories if they don't exist
    file.parent.createSync(recursive: true);
    final initial = {
      'last_audit_commit': '',
      'last_audit_time': '',
      'layers': {},
      'components': {}
    };
    file.writeAsStringSync(jsonEncode(initial));
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
  file.writeAsStringSync(encoder.convert(cache));
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
  final targetDir = args.isNotEmpty ? args[0] : 'lib';
  final dir = Directory(targetDir);

  if (!dir.existsSync()) {
    print('Target directory does not exist: $targetDir');
    exit(1);
  }

  final cache = loadCache();
  final components = cache['components'] as Map<String, dynamic>;
  bool cacheChanged = false;

  final pendingAudit = <String>[];
  final violationDetected = <String>[];
  final compliant = <String>[];

  // Recursively find all .dart files
  final files = dir
      .listSync(recursive: true)
      .where((entity) => entity is File && entity.path.endsWith('.dart'))
      .map((entity) => entity.path.replaceAll('\\', '/')) // Normalize paths to forward slashes
      .toList();

  for (final filePath in files) {
    final currentHash = await getFileHash(filePath);
    final cachedEntry = components[filePath] as Map<String, dynamic>?;

    if (cachedEntry == null) {
      // New file discovered
      components[filePath] = {
        'class': '',
        'srp_responsibility': '',
        'sha256': currentHash,
        'status': 'PENDING_AUDIT',
        'violations': []
      };
      pendingAudit.add(filePath);
      cacheChanged = true;
    } else {
      final cachedHash = cachedEntry['sha256'] as String?;
      final cachedStatus = cachedEntry['status'] as String?;

      if (cachedHash != currentHash) {
        // File modified -> Invalidate status to PENDING_AUDIT
        cachedEntry['sha256'] = currentHash;
        cachedEntry['status'] = 'PENDING_AUDIT';
        cachedEntry['violations'] = [];
        pendingAudit.add(filePath);
        cacheChanged = true;
      } else {
        // Hash matches -> Keep status
        if (cachedStatus == 'COMPLIANT') {
          compliant.add(filePath);
        } else if (cachedStatus == 'VIOLATION_DETECTED') {
          violationDetected.add(filePath);
        } else {
          pendingAudit.add(filePath);
        }
      }
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
      print('  $file');
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
  try {
    final lines = file.readAsLinesSync();
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('class ')) {
        final parts = trimmed.split(' ');
        if (parts.length > 1) {
          return parts[1].replaceAll('{', '').trim();
        }
      }
    }
  } catch (_) {}
  return '';
}
