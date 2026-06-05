import 'dart:convert';
import 'dart:io';

String cachePath = '';
String lang = '';
Map<String, dynamic> langConfig = {};
Map<String, dynamic> designPatterns = {};
Map<String, dynamic> projectConfig = {};

// Hardcoded fallback configuration in case external JSONs are not found or fail to load.
const String fallbackLangConfig = '''
{
  "dart": {
    "extensions": [".dart"],
    "default_dir": "lib",
    "class_pattern": "^(?:(?:abstract|base|interface|final|sealed)\\\\s+)?(?:class|mixin|enum|extension)\\\\s+([a-zA-Z0-9_]+)",
    "method_pattern": "^\\\\s*(?:[a-zA-Z0-9<>_?]+)\\\\s+([a-z][a-zA-Z0-9_]*)\\\\s*\\\\(",
    "import_pattern": "import\\\\s+['\\\\\\"]([^'\\\\\\"]+)['\\\\\\\"];",
    "test_file_suffix": "_test.dart",
    "test_folder_mapping": {
      "from": "lib/",
      "to": "test/"
    },
    "ffi_keywords": ["rustLib", "api.", "frb_generated"]
  },
  "rust": {
    "extensions": [".rs"],
    "default_dir": "rust/src",
    "class_pattern": "^(?:pub\\\\s+)?(?:struct|enum|trait|union)\\\\s+([a-zA-Z0-9_]+)",
    "method_pattern": "^\\\\s*(?:pub\\\\s+)?(?:async\\\\s+)?fn\\\\s+([a-z0-9_]+)\\\\s*\\\\(",
    "import_pattern": "use\\\\s+(crate::[a-zA-Z0-9_:]+(?:\\\\s*::\\\\s*\\\\{[^}]*\\\\})?)\\\\s*;",
    "test_inline_keywords": ["#[cfg(test)]", "#[test]"],
    "test_file_suffix": "_test.rs",
    "test_folder_mapping": {
      "from": "src/",
      "to": "tests/"
    },
    "ffi_keywords": ["extern \\"C\\"", "no_mangle"]
  },
  "go": {
    "extensions": [".go"],
    "default_dir": ".",
    "class_pattern": "^type\\\\s+([a-zA-Z0-9_]+)\\\\s+(?:struct|interface)",
    "method_pattern": "^func\\\\s+(?:\\\\([^\\\\)]+\\\\)\\\\s+)?([a-zA-Z0-9_]+)\\\\s*\\\\(",
    "import_pattern": "import\\\\s+(?:['\\\\\\\"]([^'\\\\\\\"])['\\\\\\\"]|\\\\(([^\\\\)]+)\\\\))",
    "test_file_suffix": "_test.go",
    "ffi_keywords": ["import \\"C\\"", "C."]
  },
  "python": {
    "extensions": [".py"],
    "default_dir": ".",
    "class_pattern": "^class\\\\s+([a-zA-Z0-9_]+)",
    "method_pattern": "^\\\\s*def\\\\s+([a-zA-Z0-9_]+)\\\\s*\\\\(",
    "import_pattern": "(?:import\\\\s+([a-zA-Z0-9_\\\\.,\\\\s]+)|from\\\\s+([a-zA-Z0-9_\\\\.]+)\\\\s+import)",
    "test_file_prefix": "test_",
    "ffi_keywords": ["ctypes", "c_dll", "c_void_p"]
  },
  "typescript": {
    "extensions": [".ts", ".tsx"],
    "default_dir": "src",
    "class_pattern": "^(?:export\\\\s+)?(?:class|interface|type|enum)\\\\s+([a-zA-Z0-9_]+)",
    "method_pattern": "^\\\\s*(?:public|private|protected|async)?\\\\s*([a-zA-Z0-9_]+)\\\\s*\\\\([^\\\\)]*\\\\)\\\\s*(?::|{)",
    "import_pattern": "import\\s+.*?from\\s+['\\\"]([^'\\\"]+)['\\\"]",
    "test_file_suffix": ".test.ts",
    "ffi_keywords": ["Napi", "node-addon-api"]
  },
  "cpp": {
    "extensions": [".cpp", ".h", ".hpp", ".cc"],
    "default_dir": "src",
    "class_pattern": "^(?:class|struct)\\\\s+([a-zA-Z0-9_]+)",
    "method_pattern": "^\\\\s*(?:[a-zA-Z0-9_::<>]+\\\\s+)+([a-zA-Z0-9_]+)\\\\s*\\\\(",
    "import_pattern": "#include\\\\s+[\\\"<]([^>\\\\n]+)[\\\">]",
    "test_file_suffix": "_test.cpp",
    "ffi_keywords": ["extern \\"C\\""]
  }
}
''';

void main(List<String> args) async {
  // Load Configurations
  await loadConfigurations();

  final supportedLanguages = langConfig.keys.toList();

  // Parse Language Argument
  String? detectedLang;
  for (final arg in args) {
    if (arg.startsWith('--lang=')) {
      detectedLang = arg.substring(7).toLowerCase();
    } else if (arg == '--dart') {
      detectedLang = 'dart';
    } else if (arg == '--rust') {
      detectedLang = 'rust';
    }
  }

  if (detectedLang == null) {
    for (final l in supportedLanguages) {
      if (args.contains(l)) {
        detectedLang = l;
        break;
      }
    }
  }

  if (detectedLang == null || !supportedLanguages.contains(detectedLang)) {
    print('Error: Language specification required or language unsupported.');
    print('Please specify either --lang=<lang> or use aliases like --dart / --rust.');
    print('Supported languages: ${supportedLanguages.join(", ")}');
    exit(1);
  }

  lang = detectedLang;
  langConfig = langConfig[lang] as Map<String, dynamic>;

  // Set Cache Path
  final customCacheDir = projectConfig['cache_dir'] as String?;
  cachePath = customCacheDir != null
      ? '$customCacheDir/$lang-architecture-cache.json'
      : '$lang-architecture-cache.json';

  // Filter out language flags from arguments
  final cleanArgs = args.where((arg) {
    if (arg.startsWith('--lang=')) return false;
    if (arg == '--dart' || arg == '--rust') return false;
    if (supportedLanguages.contains(arg)) return false;
    return true;
  }).toList();

  if (cleanArgs.isEmpty) {
    printUsage();
    exit(1);
  }

  final command = cleanArgs[0];
  final cmdArgs = cleanArgs.skip(1).toList();

  switch (command) {
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

Future<void> loadConfigurations() async {
  try {
    langConfig = jsonDecode(fallbackLangConfig) as Map<String, dynamic>;
  } catch (_) {}

  try {
    final scriptDir = File(Platform.script.toFilePath()).parent;
    final configDir = Directory('${scriptDir.parent.path}/config');

    if (configDir.existsSync()) {
      final configDoc = File('${configDir.path}/languages_config.json');
      if (configDoc.existsSync()) {
        try {
          langConfig = jsonDecode(configDoc.readAsStringSync()) as Map<String, dynamic>;
        } catch (e) {
          print('Warning: Failed to parse languages_config.json, falling back to default. Error: $e');
        }
      }

      final patternsDoc = File('${configDir.path}/design_patterns.json');
      if (patternsDoc.existsSync()) {
        try {
          designPatterns = jsonDecode(patternsDoc.readAsStringSync()) as Map<String, dynamic>;
        } catch (e) {
          print('Warning: Failed to parse design_patterns.json. Error: $e');
        }
      }

      final projectDoc = File('${configDir.path}/project_config.json');
      if (projectDoc.existsSync()) {
        try {
          projectConfig = jsonDecode(projectDoc.readAsStringSync()) as Map<String, dynamic>;
        } catch (e) {
          print('Warning: Failed to parse project_config.json. Error: $e');
        }
      }
    }
  } catch (e) {
    print('Warning: Error locating configuration directory. Error: $e');
  }
}

void printUsage() {
  print('Usage:');
  print('  dart arch_linter.dart <command> --lang=<language> [arguments]');
  print('\nCommands:');
  print('  check [directory_path]');
  print('  update <file_path> <status> [violations_separated_by_pipe] [role] [pattern]');
  print('  update_bulk <json_file_path>');
  print('  query [filter_key=value ...]');
  print('  query_method [name=val] [return_type=val] [pattern=regex]');
  print('  dependents <file_path>');
  print('  trace_path <source_file> <target_file>');
  print('  query_metrics [api_count>=val] [size>=val] [missing_tests=true|false]');
  print('  assert_naming');
  print('  assert_tests');
  print('\nStatuses: COMPLIANT, VIOLATION_DETECTED, PENDING_AUDIT');
}

Map<String, dynamic> loadCache() {
  final file = File(cachePath);
  if (!file.existsSync()) {
    try {
      file.parent.createSync(recursive: true);
    } catch (e) {
      print('Warning: Failed to create cache parent directory. Error: $e');
    }
    
    // Attempt to read custom layers from project configuration
    Map<String, dynamic> layers = {};
    if (projectConfig['layers'] != null && projectConfig['layers'][lang] != null) {
      layers = Map<String, dynamic>.from(projectConfig['layers'][lang] as Map);
    } else {
      // Setup generic default layers based on selected language
      if (lang == 'rust') {
        layers = {
          "rust/src/bridge": {
            "tier": 1,
            "responsibility": "FFI boundary, entry points.",
            "exclusions": "MUST NOT house persistence engine commands directly."
          },
          "rust/src/persistence": {
            "tier": 2,
            "responsibility": "Database and persistence client interactions.",
            "exclusions": "MUST NOT depend on FFI bridge packages."
          },
          "rust/src/domain": {
            "tier": 3,
            "responsibility": "Core domain logic and business rules.",
            "exclusions": "MUST NOT import persistence engine or FFI bridge."
          }
        };
      } else if (lang == 'dart') {
        layers = {
          "lib/features/graph/ui": {
            "tier": 1,
            "responsibility": "Renders UI components.",
            "exclusions": "MUST NOT house domain state mutation logic."
          },
          "lib/features/graph/engine": {
            "tier": 2,
            "responsibility": "Manages user interaction and gestures FSM.",
            "exclusions": "MUST NOT paint UI widgets directly."
          },
          "lib/features/graph/store": {
            "tier": 3,
            "responsibility": "Coordinates in-memory cache and state updates.",
            "exclusions": "MUST NOT import or depend on UI presentation controllers."
          }
        };
      } else {
        layers = {
          "src/ui": {"tier": 1, "responsibility": "User Interface component layer.", "exclusions": ""},
          "src/logic": {"tier": 2, "responsibility": "Business logic controllers.", "exclusions": ""},
          "src/data": {"tier": 3, "responsibility": "Data sources and models.", "exclusions": ""}
        };
      }
    }

    final initial = {
      'last_audit_commit': '',
      'last_audit_time': '',
      'layers': layers,
      'components': {}
    };
    final encoder = JsonEncoder.withIndent('  ');
    try {
      file.writeAsStringSync(encoder.convert(initial) + '\n');
    } catch (e) {
      print('Warning: Failed to write initial cache file. Error: $e');
    }
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

void saveCache(Map<String, dynamic> cache) {
  try {
    final file = File(cachePath);
    final encoder = JsonEncoder.withIndent('  ');
    file.writeAsStringSync(encoder.convert(cache) + '\n');
  } catch (e) {
    print('Warning: Failed to save cache file. Error: $e');
  }
}

Future<String> getFileHash(String filePath) async {
  try {
    final result = await Process.run('git', ['hash-object', filePath]);
    if (result.exitCode == 0) {
      return result.stdout.toString().trim();
    }
  } catch (_) {}

  final file = File(filePath);
  final stat = file.statSync();
  return '${stat.modified.millisecondsSinceEpoch}_${stat.size}';
}

Future<void> handleCheck(List<String> args) async {
  final defaultDir = langConfig['default_dir'] as String? ?? '.';
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

  final extensions = List<String>.from(langConfig['extensions'] ?? []);

  final files = dir
      .listSync(recursive: true)
      .where((entity) {
        if (entity is! File) return false;
        final path = entity.path.replaceAll('\\', '/');
        
        final exclusions = projectConfig['exclusions'] ?? {};
        final globalExclusions = List<String>.from(exclusions['global'] ?? ['/.git/', '/node_modules/', '/target/']);
        final langExclusions = List<String>.from(exclusions[lang] ?? []);

        for (final exc in globalExclusions) {
          try {
            if (path.contains(exc) || RegExp(exc).hasMatch(path)) {
              return false;
            }
          } catch (_) {
            if (path.contains(exc)) return false;
          }
        }
        for (final exc in langExclusions) {
          try {
            if (path.contains(exc) || RegExp(exc).hasMatch(path)) {
              return false;
            }
          } catch (_) {
            if (path.contains(exc)) return false;
          }
        }

        return extensions.any((ext) => path.endsWith(ext));
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

    String content = '';
    try {
      if (file.existsSync()) {
        content = file.readAsStringSync();
      }
    } catch (e) {
      print('Warning: Failed to read file $filePath. Skipping. Error: $e');
      continue;
    }
    final cleanContent = stripComments(content);
    
    final parsedImports = parseImportsList(cleanContent);
    final resolvedImports = resolveImportsList(filePath, parsedImports);
    
    final oldImports = List<String>.from(cachedEntry['imports'] as List? ?? []);
    if (oldImports.length != resolvedImports.length || !oldImports.every(resolvedImports.contains)) {
      cachedEntry['imports'] = resolvedImports;
      cacheChanged = true;
    }

    final hasTests = checkHasTests(filePath, content);
    final testFile = hasTests ? (lang == 'rust' ? 'inline or integration test' : getTestFilePath(filePath)) : '';

    if (cachedEntry['test_file'] != testFile) {
      cachedEntry['test_file'] = testFile;
      cachedEntry['has_tests'] = hasTests;
      cacheChanged = true;
    }

    final isFfi = detectsFFIBridge(content, resolvedImports, filePath);
    if (cachedEntry['is_ffi_bridge'] != isFfi) {
      cachedEntry['is_ffi_bridge'] = isFfi;
      cacheChanged = true;
    }

    if (cachedEntry['pattern'] == null || cachedEntry['pattern'] == '') {
      final pattern = detectPattern(filePath, cachedEntry['class'] as String? ?? '');
      cachedEntry['pattern'] = pattern;
      cacheChanged = true;
    }

    final publicApis = parsePublicApis(file);
    final oldApis = List<String>.from(cachedEntry['public_apis'] as List? ?? []);
    if (oldApis.length != publicApis.length || !oldApis.every(publicApis.contains)) {
      cachedEntry['public_apis'] = publicApis;
      cacheChanged = true;
    }

    if (cachedEntry['class'] == null || cachedEntry['class'] == '') {
      cachedEntry['class'] = parseClassName(file);
      cacheChanged = true;
    }

    final strayFunctions = parseStrayFunctions(cleanContent);
    final oldStrays = List<String>.from(cachedEntry['stray_functions'] as List? ?? []);
    if (oldStrays.length != strayFunctions.length || !oldStrays.every(strayFunctions.contains)) {
      cachedEntry['stray_functions'] = strayFunctions;
      cacheChanged = true;
    }

    final specialObjects = parseSpecialObjects(cleanContent);
    final oldSpecials = List<String>.from(cachedEntry['special_objects'] as List? ?? []);
    if (oldSpecials.length != specialObjects.length || !oldSpecials.every(specialObjects.contains)) {
      cachedEntry['special_objects'] = specialObjects;
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

  final Set<String> currentFilesSet = files.toSet();
  final keysToRemove = <String>[];
  components.forEach((key, _) {
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

  print('\n=== SRP AUDIT COMPLIANCE CHECK ===');
  print('Language: $lang');
  print('Total Files Checked: ${files.length}');
  print('Pending Audit Queue: ${pendingAudit.length}');
  print('Violation Queue: ${violationDetected.length}');
  
  if (pendingAudit.isNotEmpty) {
    print('\n⚠️ PENDING AUDITS (needs to be audited or has modified hashes):');
    for (final file in pendingAudit) {
      print('  $file');
    }
  }

  if (violationDetected.isNotEmpty) {
    print('\n❌ VIOLATIONS DETECTED:');
    for (final file in violationDetected) {
      final entry = components[file] as Map<String, dynamic>;
      final list = entry['violations'] as List? ?? [];
      print('  $file - Violations: $list');
    }
  }

  if (violationDetected.isNotEmpty || pendingAudit.isNotEmpty) {
    print('\n❌ Compliance check failed.');
    exit(1);
  }
  print('\n✅ All files are COMPLIANT.');
  exit(0);
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
    print('Error: Invalid status: $status.');
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

  final violationsList = <String>[];
  if (args.length > 2 && args[2].isNotEmpty) {
    violationsList.addAll(args[2].split('|').map((v) => v.trim()).where((v) => v.isNotEmpty));
  }

  if (args.length > 3 && args[3].isNotEmpty) {
    cachedEntry['architectural_role'] = args[3].trim();
  }

  if (args.length > 4 && args[4].isNotEmpty) {
    cachedEntry['pattern'] = args[4].trim();
  }

  cachedEntry['sha256'] = currentHash;
  cachedEntry['status'] = status;
  cachedEntry['violations'] = violationsList;

  if (cachedEntry['class'] == null || cachedEntry['class'] == '') {
    cachedEntry['class'] = parseClassName(file);
  }

  components[filePath] = cachedEntry;

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
    final patternStr = langConfig['class_pattern'] as String?;
    if (patternStr == null) return '';

    final regex = RegExp(patternStr);
    for (final line in lines) {
      final trimmed = line.trim();
      final match = regex.firstMatch(trimmed);
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

int getTierForFile(String filePath, Map<String, dynamic> layers) {
  for (final layerPath in layers.keys) {
    if (filePath.startsWith(layerPath)) {
      final layerMeta = layers[layerPath] as Map<String, dynamic>?;
      if (layerMeta != null && layerMeta['tier'] != null) {
        return layerMeta['tier'] as int;
      }
    }
  }
  
  if (lang == 'rust') {
    if (filePath.contains('/bridge/')) return 1;
    if (filePath.contains('/persistence/')) return 2;
    if (filePath.contains('/domain/')) return 3;
    return 3;
  }
  if (lang == 'dart') {
    if (filePath.contains('/ui/')) return 1;
    if (filePath.contains('/engine/')) return 2;
    if (filePath.contains('/presentation/')) return 2;
    if (filePath.contains('/store/')) return 3;
    if (filePath.contains('/models/')) return 3;
    return 3;
  }

  if (filePath.contains('/ui/') || filePath.contains('/view/')) return 1;
  if (filePath.contains('/controller/') || filePath.contains('/logic/')) return 2;
  if (filePath.contains('/data/') || filePath.contains('/model/')) return 3;
  return 3;
}

List<String> parseImportsList(String content) {
  final imports = <String>[];
  final patternStr = langConfig['import_pattern'] as String?;
  if (patternStr == null) return imports;

  final regex = RegExp(patternStr);
  final matches = regex.allMatches(content);
  for (final match in matches) {
    for (int i = 1; i <= match.groupCount; i++) {
      final imp = match.group(i);
      if (imp != null && imp.trim().isNotEmpty) {
        imports.add(imp.trim());
      }
    }
  }
  return imports;
}

List<String> resolveImportsList(String currentFilePath, List<String> parsedImports) {
  final resolved = <String>[];
  for (final imp in parsedImports) {
    if (lang == 'dart') {
      if (imp.startsWith('package:mycelium/')) {
        resolved.add(imp.replaceFirst('package:mycelium/', 'lib/'));
      } else if (imp.startsWith('dart:') || imp.startsWith('package:')) {
        resolved.add(imp);
      } else {
        resolved.add(resolveRelativePath(currentFilePath, imp));
      }
    } else if (lang == 'rust') {
      resolved.add(resolveRustImport(imp));
    } else {
      resolved.add(imp);
    }
  }
  return resolved;
}

String resolveRelativePath(String currentFilePath, String importUri) {
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

List<String> checkBoundaryViolations(String filePath, int fileTier, List<String> resolvedImports, Map<String, dynamic> components, Map<String, dynamic> layers) {
  final violations = <String>[];
  if (lang == 'dart' && filePath == 'lib/main.dart') {
    return violations;
  }
  for (final imp in resolvedImports) {
    if (lang == 'dart' && (imp.startsWith('package:') || imp.startsWith('dart:'))) {
      continue;
    }
    if (lang == 'rust' && !imp.startsWith('rust/src/')) {
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
  final mapping = langConfig['test_folder_mapping'] as Map<String, dynamic>?;
  final suffix = langConfig['test_file_suffix'] as String? ?? '_test.dart';

  if (mapping != null) {
    final from = mapping['from'] as String;
    final to = mapping['to'] as String;
    if (filePath.startsWith(from)) {
      final ext = langConfig['extensions'][0] as String;
      final testPath = filePath.replaceFirst(from, to).replaceFirst(ext, suffix);
      if (File(testPath).existsSync()) {
        return testPath;
      }
    }
  }
  return '';
}

bool checkHasTests(String filePath, String fileContent) {
  final inlineKeywords = langConfig['test_inline_keywords'] as List<dynamic>?;
  if (inlineKeywords != null) {
    for (final kw in inlineKeywords) {
      if (fileContent.contains(kw.toString())) {
        return true;
      }
    }
  }

  if (lang == 'rust') {
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

  return getTestFilePath(filePath).isNotEmpty;
}

bool detectsFFIBridge(String content, List<String> resolvedImports, String filePath) {
  if (lang == 'rust' && filePath.contains('/bridge/')) {
    return true;
  }
  if (lang == 'dart' && resolvedImports.any((imp) => imp.contains('src/rust/'))) {
    return true;
  }

  final ffiKeywords = List<String>.from(langConfig['ffi_keywords'] ?? []);
  for (final kw in ffiKeywords) {
    if (content.contains(kw)) {
      return true;
    }
  }
  return false;
}

String detectPattern(String filePath, String className) {
  final lowerPath = filePath.toLowerCase();
  final lowerClass = className.toLowerCase();

  for (final category in designPatterns.entries) {
    final patterns = category.value as Map<String, dynamic>;
    for (final pattern in patterns.entries) {
      final info = pattern.value as Map<String, dynamic>;
      final keywords = List<String>.from(info['keywords'] ?? []);
      for (final kw in keywords) {
        if (lowerClass.contains(kw.toLowerCase()) || lowerPath.contains(kw.toLowerCase())) {
          return '${pattern.key} Pattern';
        }
      }
    }
  }

  if (lang == 'rust') {
    if (lowerPath.contains('/bridge/')) return 'FFI Bridge';
    if (lowerPath.contains('/persistence/')) return 'Persistence Engine';
    if (lowerPath.contains('/domain/')) return 'Domain Logic';
    return 'Rust Module';
  }

  if (lowerPath.contains('/ui/') || lowerPath.contains('/view/')) return 'UI Component';
  if (lowerPath.contains('/models/') || lowerPath.contains('/model/')) return 'Data Model';
  if (lowerClass.endsWith('controller') || lowerClass.endsWith('manager')) return 'Controller/Manager';
  if (lowerClass.contains('store')) return 'Data Store';
  return 'Component';
}

List<String> parsePublicApis(File file) {
  final apis = <String>[];
  try {
    final content = file.readAsStringSync();
    final clean = stripComments(content);
    final lines = clean.split('\n');
    final patternStr = langConfig['method_pattern'] as String?;
    if (patternStr == null) return apis;

    final regex = RegExp(patternStr);
    for (final line in lines) {
      final trimmed = line.trim();
      final match = regex.firstMatch(line);
      if (match != null) {
        final methodName = match.group(1);
        if (methodName != null && 
            methodName != 'if' && 
            methodName != 'for' && 
            methodName != 'switch' && 
            methodName != 'while' && 
            methodName != 'catch') {
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
    print('  dart arch_linter.dart query_method [filter_key=value ...]');
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

  print('\n=== CACHE METHOD QUERY RESULTS ===');
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
    print('Usage: dart arch_linter.dart dependents <file_path>');
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

  print('\n=== DEPENDENTS OF $targetFile ===');
  for (final dep in dependentsList) {
    print('  - $dep');
  }
}

Future<void> handleTracePath(List<String> args) async {
  if (args.length < 2) {
    print('Usage: dart arch_linter.dart trace_path <source_file> <target_file>');
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
    print('  dart arch_linter.dart query_metrics [filter_key>=value ...]');
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
    } else if (arg.startsWith('size>=')) {
      sizeMin = int.tryParse(arg.substring(6));
    } else if (arg.startsWith('size_gte=')) {
      sizeMin = int.tryParse(arg.substring(9));
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

  print('\n=== CACHE METRICS RESULTS ===');
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

  final configRules = projectConfig['naming_rules'] != null && projectConfig['naming_rules'][lang] != null
      ? List<dynamic>.from(projectConfig['naming_rules'][lang] as List)
      : <dynamic>[];

  components.forEach((filePath, data) {
    final className = data['class'] as String? ?? '';
    final path = filePath.toLowerCase();
    final name = className.toLowerCase();

    // Check generic config rules
    for (final rule in configRules) {
      final type = rule['type'] as String?;
      final message = rule['message'] as String? ?? 'Naming Violation: $filePath';

      if (type == 'file_regex') {
        final pattern = rule['pattern'] as String?;
        if (pattern != null) {
          final fileName = filePath.split('/').last;
          if (!RegExp(pattern).hasMatch(fileName)) {
            violations.add('$message (Found: $filePath)');
          }
        }
      } else if (type == 'path_contains') {
        final rulePath = (rule['path'] as String?)?.toLowerCase();
        if (rulePath != null && path.contains(rulePath)) {
          // Check file suffix if defined
          final fileSuffix = rule['file_suffix'] as String?;
          if (fileSuffix != null && !filePath.endsWith(fileSuffix)) {
            violations.add('$message (Found file: $filePath)');
          }

          // Check class suffixes if defined
          if (className.isNotEmpty) {
            final classSuffix = rule['class_suffix'] as String?;
            final classSuffixes = rule['class_suffixes'] != null 
                ? List<String>.from(rule['class_suffixes'] as List) 
                : <String>[];
            
            if (classSuffix != null && !name.endsWith(classSuffix.toLowerCase())) {
              violations.add('$message (Found class: $className in $filePath)');
            }
            if (classSuffixes.isNotEmpty) {
              final matched = classSuffixes.any((suff) => name.endsWith(suff.toLowerCase()));
              if (!matched) {
                violations.add('$message (Found class: $className in $filePath)');
              }
            }
          }
        }
      }
    }
  });

  print('\n=== SRP ARCHITECTURE NAMING CONVENTIONS ASSERTION ===');
  if (violations.isNotEmpty) {
    print('❌ Naming assertions failed:');
    for (final v in violations) {
      print('  - $v');
    }
    exit(1);
  }

  print('✅ All class and file names are compliant.');
  exit(0);
}

Future<void> handleAssertTests(List<String> args) async {
  final cache = loadCache();
  final components = cache['components'] as Map<String, dynamic>;
  final violations = <String>[];

  final testConfig = projectConfig['test_assertions'] != null && projectConfig['test_assertions'][lang] != null
      ? projectConfig['test_assertions'][lang] as Map<String, dynamic>
      : null;

  components.forEach((filePath, data) {
    final tier = data['tier'] as int? ?? 3;
    final hasTests = data['has_tests'] as bool? ?? false;

    if (testConfig != null) {
      final minTier = testConfig['min_tier'] as int? ?? 2;
      final excludePaths = testConfig['exclude_paths'] != null 
          ? List<String>.from(testConfig['exclude_paths'] as List)
          : <String>[];
      final messageTemplate = testConfig['message'] as String? ?? 'Test Coverage Violation: Tier {tier} component lacks tests.';

      if (tier >= minTier) {
        final isExcluded = excludePaths.any((exPath) => filePath.contains(exPath));
        if (!isExcluded && !hasTests) {
          final resolvedMessage = messageTemplate.replaceAll('{tier}', tier.toString());
          violations.add('$resolvedMessage Found: $filePath');
        }
      }
    } else {
      // General default fallback checks
      if (tier >= 2 && !hasTests) {
        violations.add('Test Coverage Violation: Tier $tier component does not have tests. Found: $filePath');
      }
    }
  });

  print('\n=== SRP ARCHITECTURE TEST COVERAGE ASSERTION ===');
  if (violations.isNotEmpty) {
    print('❌ Test coverage assertions failed:');
    for (final v in violations) {
      print('  - $v');
    }
    exit(1);
  }

  print('✅ All required components have test coverage.');
  exit(0);
}

Future<void> handleQuery(List<String> args) async {
  if (args.isEmpty) {
    print('Usage:');
    print('  dart arch_linter.dart query [filter_key=value ...]');
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

    if (filters.containsKey('dir')) {
      final dirVal = filters['dir']!;
      if (!filePath.toLowerCase().contains(dirVal)) {
        matches = false;
      }
    }

    if (filters.containsKey('tier')) {
      final tierVal = int.tryParse(filters['tier']!);
      if (data['tier'] != tierVal) {
        matches = false;
      }
    }

    if (filters.containsKey('pattern')) {
      final patternVal = filters['pattern']!;
      final compPattern = (data['pattern'] as String? ?? '').toLowerCase();
      if (!compPattern.contains(patternVal)) {
        matches = false;
      }
    }

    if (filters.containsKey('status')) {
      final statusVal = filters['status']!;
      if ((data['status'] as String? ?? '').toLowerCase() != statusVal) {
        matches = false;
      }
    }

    if (filters.containsKey('has_tests')) {
      final hasTestsVal = filters['has_tests'] == 'true';
      if (data['has_tests'] != hasTestsVal) {
        matches = false;
      }
    }

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

  print('\n=== CACHE QUERY RESULTS ===');
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
    if (data['stray_functions'] != null && (data['stray_functions'] as List).isNotEmpty) {
      print('  Stray Functions: ${data['stray_functions']}');
    }
    if (data['special_objects'] != null && (data['special_objects'] as List).isNotEmpty) {
      print('  Special Objects: ${data['special_objects']}');
    }
  });
}

String stripComments(String content) {
  var result = content;

  // Load custom comment patterns from languages_config.json
  final patterns = langConfig['comment_patterns'] != null 
      ? List<String>.from(langConfig['comment_patterns'] as List)
      : <String>[];

  if (patterns.isNotEmpty) {
    for (final pat in patterns) {
      try {
        result = result.replaceAll(RegExp(pat), '');
      } catch (_) {}
    }
  } else {
    // Default fallback (handles C-style and Python comments)
    result = result.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
    result = result.replaceAll(RegExp(r'//.*'), '');
    result = result.replaceAll(RegExp(r'#.*'), '');
  }

  return result;
}

List<String> parseStrayFunctions(String cleanContent) {
  final strays = <String>[];
  final patternStr = langConfig['stray_function_pattern'] as String?;
  if (patternStr == null) return strays;

  final regex = RegExp(patternStr);
  final lines = cleanContent.split('\n');
  for (final line in lines) {
    if (line.isNotEmpty && !line.startsWith(' ') && !line.startsWith('\t')) {
      final match = regex.firstMatch(line);
      if (match != null) {
        final name = match.group(1);
        if (name != null && 
            name != 'if' && 
            name != 'for' && 
            name != 'switch' && 
            name != 'while' && 
            name != 'catch') {
          strays.add(name);
        }
      }
    }
  }
  return strays;
}

List<String> parseSpecialObjects(String content) {
  final detected = <String>[];
  final patternStrings = langConfig['special_object_patterns'] as List<dynamic>?;
  if (patternStrings == null) return detected;

  for (final pat in patternStrings) {
    try {
      final regex = RegExp(pat.toString());
      final matches = regex.allMatches(content);
      for (final m in matches) {
        final matchedText = m.group(0);
        if (matchedText != null && !detected.contains(matchedText)) {
          detected.add(matchedText);
        }
      }
    } catch (_) {}
  }
  return detected;
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
      cachedEntry['class'] = parseClassName(file);
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
