---
name: arch-linter
description: Query component metadata, method signatures, dependents/blast-radius, shortest import paths, and assert layering, naming compliance, and test coverage.
---

# Skill: Architecture Linter (arch-linter)

Use this skill when you need to inspect class structures, find public methods, trace dependency lines, calculate the blast radius of proposed changes, verify layer bounds, or run compliance checks. This tool is completely offline, runs instantly, and is highly useful for a wide range of coding and refactoring tasks.

## Core Capabilities & Commands

The underlying tool is a Dart script located at [cache_manager.dart](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/arch-linter/scripts/cache_manager.dart). All commands require specifying either the `--dart` or `--rust` mode flag.

### 1. File & Component Queries (`query`)
Filters components by tier, pattern name, audit status, test presence, FFI boundaries, or directory.
```powershell
dart .agents/plugins/arch-linter/scripts/cache_manager.dart query [--dart | --rust] [tier=1|2|3] [pattern=name] [status=COMPLIANT|VIOLATION_DETECTED|PENDING_AUDIT] [has_tests=true|false] [is_ffi=true|false] [dir=folder]
```
*Example (Find untested Tier 3 Rust components):*
```powershell
dart .agents/plugins/arch-linter/scripts/cache_manager.dart query --rust tier=3 has_tests=false
```

### 2. Method-Level Search (`query_method`)
Locates public class/struct methods by name, return type, or regular expression pattern.
```powershell
dart .agents/plugins/arch-linter/scripts/cache_manager.dart query_method [--dart | --rust] [name=query] [return_type=query] [pattern=regex]
```
*Example (Search for all methods converting elements to Rust format in Dart files):*
```powershell
dart .agents/plugins/arch-linter/scripts/cache_manager.dart query_method --dart name=torust
```

### 3. Blast Radius Discovery (`dependents`)
Finds all components that directly import and depend on the target file. Run this before making changes to estimate their impact.
```powershell
dart .agents/plugins/arch-linter/scripts/cache_manager.dart dependents [--dart | --rust] <file_path>
```

### 4. BFS Import Pathfinder (`trace_path`)
Runs a Breadth-First Search (BFS) over resolved imports to print the exact import sequence connecting a source file to a target file.
```powershell
dart .agents/plugins/arch-linter/scripts/cache_manager.dart trace_path [--dart | --rust] <source_file> <target_file>
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
dart .agents/plugins/arch-linter/scripts/cache_manager.dart query_metrics --dart api_count_gte=15
```

---

## Compliance & Verification Commands

### 6. Architectural Layers Audit (`check`)
Check all files against layer boundaries. Exits with code `0` on success, or code `1` if boundary violations or pending audits exist.
```powershell
dart .agents/plugins/arch-linter/scripts/cache_manager.dart check [--dart | --rust]
```

### 7. Cache Refresh (`scan`)
Recursively scan the directory and regenerate the architecture cache metadata.
```powershell
dart .agents/plugins/arch-linter/scripts/cache_manager.dart scan [--dart | --rust]
```

### 8. Bulk Cache Updates (`update_bulk`)
Updates the compliance status, architectural role, design pattern, and violation details of multiple files simultaneously using a temporary JSON file.
```powershell
dart .agents/plugins/arch-linter/scripts/cache_manager.dart update_bulk [--dart | --rust] <json_file_path>
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
dart .agents/plugins/arch-linter/scripts/cache_manager.dart assert_naming [--dart | --rust]
```

### 10. Test Coverage Assertion (`assert_tests`)
Asserts that all Tier 2 and Tier 3 components have test coverage.
```powershell
dart .agents/plugins/arch-linter/scripts/cache_manager.dart assert_tests [--dart | --rust]
```

---

## AI-Powered Code Scanning Guidelines (Semantic Auditing)

While CLI tools and cache queries are excellent for metadata-level discovery, they are blind to the semantic quality of code. As an AI Auditor, your core strength is **semantic scanning**. For every file in the audit queue, you must read the actual code (using `view_file` or receiving it from the parent) and evaluate it against these cognitive criteria:

### 1. SRP (Single Responsibility) Semantic Audit
*   **Mixed Tiers**: Does a Tier 1 widget execute Tier 3 database queries, FFI operations, or file I/O?
*   **Mixed Levels of Abstraction**: Does a method coordinate high-level interactions while also performing low-level math or byte manipulations?
*   **Heuristic**: If you can describe the class's purpose using "and" (e.g., "This class renders the nodes AND manages connection states AND saves them to db"), it violates SRP.

### 2. OCP (Open/Closed) Semantic Audit
*   **Hardcoded Mode Switchers**: Look for `switch(stateType)` or chains of `if (mode == A)` that control behavior. If adding a new mode requires modifying this class, suggest extracting it into a **Strategy** interface or polymorphic subclasses.
*   **Lack of Extension Points**: Are callback handlers, theme hooks, or behavior policies hardcoded instead of being injected or configured?

### 3. LSP & ISP (Substitution & Segregation) Semantic Audit
*   **LSP Violations**: Does an subclass implementation throw `UnimplementedError()`, `UnsupportedError()`, or return arbitrary dummy/null values for methods defined by the interface?
*   **ISP Violations**: Is a class forced to implement a "fat" interface containing methods it does not need? Suggest splitting the interface into smaller, single-method interface roles.

### 4. DIP (Dependency Inversion) Semantic Audit
*   **Hardcoded Instantiations**: Scan for `new ConcreteClass()` or `ConcreteClass(...)` inside business logic or UI code. These dependencies should be injected via constructor arguments or resolved through a service locator/provider as abstract interfaces.
*   **Concrete Import Types**: Verify that high-level modules do not import concrete implementation classes from lower layers.

### 5. Semantic DRY & Duplication Audit
*   **Structural Duplication**: Scan sibling files in the same directory. Do they contain identical helper functions, data mappings, or widget assembly patterns?
*   **Algorithmic Redundancy**: Detect if two methods calculate coordinate layouts, scale offsets, or serialize state structures using slightly different code but achieving the same goal.

### 6. Design Pattern Fitness
*   **Pattern Contradictions**: Compare class signatures to their intended pattern (e.g. Strategy, Facade, Command, State):
    *   *Strategy*: Are strategy implementations stateless? Do they expose mutable state?
    *   *Command*: Can it record undo/redo states correctly?
    *   *FSM State*: Does a state handle events outside its lifecycle?
*   **Pattern Pollution**: Is a simple logic container bloated with unnecessary boilerplate from a complex design pattern it doesn't need?

### 7. Symmetry & Physical Cohesion
*   **Blueprint Violations**: Sibling classes in directories like `/commands/` or `/states/` must follow the exact same method signature, naming, and lifecycle styles.
*   **Orphan Helpers**: Avoid adding random static functions to UI classes. Extract them to cohesive helper environments or domain managers.

---

## Architectural Layer Boundaries

The project enforces a strict **3-Tier Hierarchy**:
*   **Tier 1: Canvas UI**: [lib/features/graph/ui](file:///d:/Projects/Open/flutter/code/mycelium/lib/features/graph/ui). Handles layout and widgets. Must NOT house domain state mutations, direct database/FFI calls, or low-level coordinate mathematics.
*   **Tier 2: Presentational & FSM**: [lib/features/graph/presentation](file:///d:/Projects/Open/flutter/code/mycelium/lib/features/graph/presentation) and [lib/features/graph/engine](file:///d:/Projects/Open/flutter/code/mycelium/lib/features/graph/engine). Manages transient state, gesture tracking, and theme mapping. Must NOT paint directly or call raw FFI endpoints.
*   **Tier 3: Domain / Store**: [lib/features/graph/store](file:///d:/Projects/Open/flutter/code/mycelium/lib/features/graph/store) and [lib/features/graph/models](file:///d:/Projects/Open/flutter/code/mycelium/lib/features/graph/models). Coordinates storage, SurrealDB syncing, and FFI bridges. **Must NEVER import or listen to Tier 1 or Tier 2 components.**
