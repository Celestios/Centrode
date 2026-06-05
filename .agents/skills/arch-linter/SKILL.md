---
name: arch-linter
description: Run compliance checks, enforce layer boundaries, name patterns, and test coverage for Dart, Rust, Go, Python, TypeScript, and C++.
---

# Skill: Architecture Linter (arch-linter)

This skill instructs on how to customize linter configurations and execute commands using the generalized `arch-linter` tool.

---

## 1. Customizing Configurations

The linter is driven by JSON configuration files located in the `config/` directory of the tool:

### A. Project Configuration (`project_config.json`)
Defines the layer hierarchy, naming schemas, test policies, and exclusions:
* **`cache_dir`**: The directory path where the JSON architecture cache for each language is stored.
* **`exclusions`**: Global and language-specific directory exclusion patterns (e.g. `node_modules`, `build`, generated code).
* **`layers`**: Defines directory paths, their Tier levels (e.g., Tier 1 UI, Tier 2 Logic, Tier 3 Domain), and their import constraints.
* **`naming_rules`**: Suffixes and naming patterns expected for files and classes in specific folders.
* **`test_assertions`**: Rules declaring which tiers require test coverage.

### B. Language Configuration (`languages_config.json`)
Configures AST-like parsers using regex patterns:
* **`extensions`**: Array of target file extensions (e.g. `[".dart"]`, `[".rs"]`).
* **`default_dir`**: The default scanning root.
* **`class_pattern`**: Regular expression to identify classes, mixins, structures, or traits.
* **`method_pattern`**: Regular expression to match public/private method names.
* **`import_pattern`**: Regular expression to capture imports.
* **`test_file_suffix`**: File naming rule for associated tests.

### C. Design Patterns (`design_patterns.json`)
Provides pattern blueprints (e.g., Strategy, Facade, Command, State) to match code layouts.

---

## 2. Command Reference

Execute the script via the Dart SDK (or pre-compiled binary):
```powershell
dart arch_linter.dart <command> --lang=<language> [arguments]
```
*(Note: Shorthands like `--dart` or `--rust` can be used instead of `--lang=dart` or `--lang=rust`).*

### 1. `check` (Verify Compliance)
Checks the project source code against layer boundary constraints and registers pending audits.
```powershell
dart arch_linter.dart check --dart
```

### 2. `update` (Audit Status Update)
Updates cache metadata status for a specific file.
```powershell
dart arch_linter.dart update <file_path> <COMPLIANT|VIOLATION_DETECTED|PENDING_AUDIT> [violations] [role] [pattern] --dart
```

### 3. `query` (Search Cache)
Queries the cache for components matching metadata key-value filters.
```powershell
dart arch_linter.dart query tier=3 --dart
```

### 4. `query_method` (Search Methods)
Searches for specific method declarations across all parsed files.
```powershell
dart arch_linter.dart query_method name=load --dart
```

### 5. `dependents` (Find Dependents)
Lists all files that import the target file.
```powershell
dart arch_linter.dart dependents <file_path> --dart
```

### 6. `trace_path` (Find Dependency Paths)
Traces the import path chain from a source file to a target file.
```powershell
dart arch_linter.dart trace_path <source_path> <target_path> --dart
```

### 7. `assert_naming` (Check Naming Rules)
Validates that file and class names follow the configured suffix patterns.
```powershell
dart arch_linter.dart assert_naming --dart
```

### 8. `assert_tests` (Check Test Coverage)
Verifies that components in relevant tiers have matching tests.
```powershell
dart arch_linter.dart assert_tests --dart
```
