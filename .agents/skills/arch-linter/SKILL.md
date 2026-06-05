---
name: arch-linter
description: Run compliance checks, enforce layer boundaries, name patterns, and test coverage for Dart, Rust, Go, Python, TypeScript, and C++.
---

# Skill: Architecture Linter (arch-linter)

Use this skill to configure, audit, query, and enforce architectural guidelines using the generalized, self-contained `arch-linter` tool.

---

## 1. Directory Structure

The plugin is designed to be completely self-contained. All binaries, scripts, rules, and configuration templates live inside the plugin directory:

```
<plugin-dir>/
├── plugin.json
├── config/
│   ├── project_config.json      # Layer definitions, tiers, exclusions, and linter settings
│   ├── languages_config.json    # Language parser rules (regex, keywords, test patterns)
│   └── design_patterns.json     # Definitions for creational, structural, and behavioral patterns
├── scripts/
│   ├── arch_linter.dart         # Dart source code of the linter
│   └── arch_linter.exe          # Compiled standalone Windows executable
├── skills/
│   └── arch-linter/
│       └── SKILL.md             # This instruction manual
└── rules/
    └── architecture-cache.md    # Architecture rules and compliance guidance
```

---

## 2. Configuration Files

Before running commands, verify/edit the configuration files in the `config/` directory:

### A. Project Configuration (`project_config.json`)
Defines the structure of your specific project, layer tiers, naming conventions, and test coverage requirements.
- **`cache_dir`**: Specifies where the JSON linter cache files are read/written (set to `<plugin-dir>` or target relative cache path to keep it local).
- **`exclusions`**: Lists global and language-specific file exclusions (e.g., node_modules, generated code like `*.g.dart`).
- **`layers`**: Defines directory paths, their layer **Tier** (1 = UI/Client, 2 = Controller/Logic, 3 = Domain/Persistence), responsibilities, and import constraints.
- **`naming_rules`**: Regular expressions matching file/class names for different directories.
- **`test_assertions`**: Minimum tier requirements for tests (e.g., Tier 2 and Tier 3 components must have tests).

### B. Language Configuration (`languages_config.json`)
Defines how different languages are parsed. Supports `dart`, `rust`, `go`, `python`, `typescript`, and `cpp` out of the box.
- **`extensions`**: List of file extensions to scan.
- **`default_dir`**: The root directory to scan by default.
- **`class_pattern`**: Regex to match and capture class/struct/trait/union names.
- **`method_pattern`**: Regex to capture methods/functions.
- **`import_pattern`**: Regex to capture imported packages or paths.
- **`test_file_suffix`** / **`test_inline_keywords`**: Patterns to identify corresponding test suites.
- **`ffi_keywords`**: Indicators of low-level FFI boundaries.

### C. Design Patterns (`design_patterns.json`)
Defines structural pattern blueprints (e.g., Strategy, Factory, Command, Adapter, Facade) for auditing architecture symmetry.

---

## 3. How to Run

You can execute the linter using either the raw Dart script or the pre-compiled standalone binary (useful in environments without the Dart SDK).

### Execution Commands
- **Using the Standalone Binary (Windows)**:
  From the workspace root:
  ```powershell
  <plugin-dir>/scripts/arch_linter.exe <command> --lang=<language> [arguments]
  ```
  Or from inside the plugin directory itself:
  ```powershell
  scripts/arch_linter.exe <command> --lang=<language> [arguments]
  ```
- **Using the Dart SDK**:
  From the workspace root:
  ```powershell
  dart <plugin-dir>/scripts/arch_linter.dart <command> --lang=<language> [arguments]
  ```
  *(Note: You can use `--dart` or `--rust` as shorthands for `--lang=dart` or `--lang=rust` respectively).*

---

## 4. Command Reference

*(Note: Replace `<plugin-dir>` with the relative path to the plugin folder, e.g., `.Archive/arch-linter` or `.agents/plugins/arch-linter`).*

### 1. `check` (Audit Project Compliance)
Scans the directories defined in configurations, parses file imports/FFI/stray methods, and validates layer-boundary compliance.
```powershell
# Scan and verify Dart files
<plugin-dir>/scripts/arch_linter.exe check --dart

# Scan and verify Rust files
<plugin-dir>/scripts/arch_linter.exe check --rust
```
- **Exit Code `0`**: All files are compliant.
- **Exit Code `1`**: Violations or pending audits detected.

### 2. `update` (Mark a Component Compliant/Audited)
Manually updates the cached status of a file. Use this after auditing a modified file.
```powershell
<plugin-dir>/scripts/arch_linter.exe update <file_path> COMPLIANT --dart
```

### 3. `query` (Search Cached Components)
Finds components matching specific metadata.
```powershell
# List all Tier 3 Dart files
<plugin-dir>/scripts/arch_linter.exe query tier=3 --dart

# Find files utilizing the "Strategy" pattern
<plugin-dir>/scripts/arch_linter.exe query pattern=Strategy --dart
```

### 4. `query_method` (Search Public API Methods)
Searches for specific methods or API surfaces across the codebase to identify design symmetry or duplication.
```powershell
# Find files containing method names matching "load"
<plugin-dir>/scripts/arch_linter.exe query_method name=load --dart
```

### 5. `dependents` (Audit Blast Radius)
Lists all files that import the specified target file.
```powershell
<plugin-dir>/scripts/arch_linter.exe dependents lib/features/graph/models/graph_node.dart --dart
```

### 6. `trace_path` (Find Dependency Paths)
Traces the shortest import path from source to target. Helpful for identifying why a tier leak occurs.
```powershell
<plugin-dir>/scripts/arch_linter.exe trace_path lib/features/graph/ui/canvas.dart lib/features/graph/store/graph_store.dart --dart
```

### 7. `assert_naming` (Enforce Class/File Suffixes)
Asserts that all scanned files adhere to naming conventions specified in `project_config.json`.
```powershell
<plugin-dir>/scripts/arch_linter.exe assert_naming --dart
```

### 8. `assert_tests` (Enforce Test Coverage)
Asserts that components in Tier 2 and above have corresponding tests (inline tests for Rust, separate test files for other languages).
```powershell
<plugin-dir>/scripts/arch_linter.exe assert_tests --dart
```

---

## 5. Integrating with Git & CI/CD

To automate boundary compliance checks, include the assertions in pre-commit hooks or CI/CD scripts:

```powershell
# Validate naming rules
<plugin-dir>/scripts/arch_linter.exe assert_naming --dart
<plugin-dir>/scripts/arch_linter.exe assert_naming --rust

# Validate test coverage
<plugin-dir>/scripts/arch_linter.exe assert_tests --dart
<plugin-dir>/scripts/arch_linter.exe assert_tests --rust

# Check overall boundary compliance
<plugin-dir>/scripts/arch_linter.exe check --dart
<plugin-dir>/scripts/arch_linter.exe check --rust
```
