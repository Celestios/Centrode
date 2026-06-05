---
name: arch-linter
description: Query component metadata, method signatures, dependents/blast-radius, shortest import paths, and assert layering, naming compliance, and test coverage.
---

# Skill: Architecture Linter (arch-linter)

Use this skill when you need to inspect class structures, find public methods, trace dependency lines, calculate the blast radius of proposed changes, verify layer bounds, or run compliance checks. This tool is completely offline, runs instantly, and is highly useful for a wide range of coding and refactoring tasks.

## Core Capabilities & Commands

The underlying tool is a Dart script located at [arch_linter.dart](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/arch-linter/scripts/arch_linter.dart). All commands require specifying either the `--dart` or `--rust` mode flag.

### 1. File & Component Queries (`query`)
Filters components by tier, pattern name, audit status, test presence, FFI boundaries, or directory.
```powershell
dart .agents/plugins/arch-linter/scripts/arch_linter.dart query [--dart | --rust] [tier=1|2|3] [pattern=name] [status=COMPLIANT|VIOLATION_DETECTED|PENDING_AUDIT] [has_tests=true|false] [is_ffi=true|false] [dir=folder]
```
*Example (Find untested Tier 3 Rust components):*
```powershell
dart .agents/plugins/arch-linter/scripts/arch_linter.dart query --rust tier=3 has_tests=false
```

### 2. Method-Level Search (`query_method`)
Locates public class/struct methods by name, return type, or regular expression pattern.
```powershell
dart .agents/plugins/arch-linter/scripts/arch_linter.dart query_method [--dart | --rust] [name=query] [return_type=query] [pattern=regex]
```
*Example (Search for all methods converting elements to Rust format in Dart files):*
```powershell
dart .agents/plugins/arch-linter/scripts/arch_linter.dart query_method --dart name=torust
```

### 3. Blast Radius Discovery (`dependents`)
Finds all components that directly import and depend on the target file. Run this before making changes to estimate their impact.
```powershell
dart .agents/plugins/arch-linter/scripts/arch_linter.dart dependents [--dart | --rust] <file_path>
```

### 4. BFS Import Pathfinder (`trace_path`)
Runs a Breadth-First Search (BFS) over resolved imports to print the exact import sequence connecting a source file to a target file.
```powershell
dart .agents/plugins/arch-linter/scripts/arch_linter.dart trace_path [--dart | --rust] <source_file> <target_file>
```

### 5. Codebase Metrics & Complexity (`query_metrics`)
Filter classes based on line count, public API counts, or missing tests.
> [!NOTE]
> To prevent shell redirection errors in Windows environments, use shell-safe operators like `_gte=` or `=` instead of `>=`.
*   `api_count_gte=val` (or `api_count=val`)
*   `size_gte=val` (or `size=val`)
*   `missing_tests=true|false`

*Example (Locate highly complex components with at least 15 public methods):*
```powershell
dart .agents/plugins/arch-linter/scripts/arch_linter.dart query_metrics --dart api_count_gte=15
```

---

## Compliance & Verification Commands

### 6. Architectural Layers Audit (`check`)
Scans the directories, updates the architecture cache metadata, and asserts layer boundaries. Exits with code `0` on success, or code `1` (failing the shell execution) if boundary violations or pending audits exist.
```powershell
dart .agents/plugins/arch-linter/scripts/arch_linter.dart check [--dart | --rust]
```

### 8. Bulk Cache Updates (`update_bulk`)
Updates the compliance status, architectural role, design pattern, and violation details of multiple files simultaneously using a temporary JSON file.
```powershell
dart .agents/plugins/arch-linter/scripts/arch_linter.dart update_bulk [--dart | --rust] <json_file_path>
```
The JSON file should have the following schema:
```json
{
  "rust/src/bridge/api.rs": {
    "status": "VIOLATION_DETECTED",
    "violations": [
      "SRP: Transaction Orchestration Leak",
      "SRP: Serialization & Data Mapping Leak"
    ],
    "architectural_role": "FFI Bridge API Gateway",
    "pattern": "FFI Bridge"
  },
  "rust/src/bridge/stream.rs": {
    "status": "COMPLIANT",
    "violations": [],
    "architectural_role": "FFI Outbound Event Emitter",
    "pattern": "FFI Bridge"
  }
}
```

### 9. Naming Compliance Assertion (`assert_naming`)
Verifies naming conventions for strategies, FSM states, and store modules (for `--dart`), or snake_case format rules (for `--rust`).
```powershell
dart .agents/plugins/arch-linter/scripts/arch_linter.dart assert_naming [--dart | --rust]
```

### 10. Test Coverage Assertion (`assert_tests`)
Asserts that all Tier 2 and Tier 3 components have test coverage.
```powershell
dart .agents/plugins/arch-linter/scripts/arch_linter.dart assert_tests [--dart | --rust]
```

