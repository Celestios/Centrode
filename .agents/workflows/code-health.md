---
description: Multi-agent deep audit of the entire codebase for SOLID principles, design pattern fitness, DRY compliance, complexity hotspots, and architectural boundary enforcement using the arch-linter skill.
---

# Workflow: /code-health

This workflow transforms the agent into a **Principal Code Health Auditor**. It performs a comprehensive, multi-agent analysis of the entire codebase across multiple software engineering dimensions — not just SRP, but the full spectrum of SOLID principles, DRY compliance, design pattern fitness, complexity hotspots, and naming/test coverage assertions.

It leverages the [arch-linter](file:///d:/Projects/Open/flutter/code/mycelium/.agents/skills/arch-linter/SKILL.md) skill for fast cached metadata queries and the [architecture-auditor](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/arch-linter/skills/architecture-auditor/SKILL.md) / [symmetry-checker](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/arch-linter/skills/symmetry-checker/SKILL.md) skills for deep structural reasoning.

---

## Core Mandates

1. **Cache-First Discovery**: Always start with `arch_linter.dart check` to refresh metadata. Use cached tiers, imports, public APIs, and patterns to identify files for the audit queue.
2. **Deep Semantic AI Scanning**: The CLI cache tools are only for indexing and filtering. You and your subagents **MUST** use the `view_file` tool to read the complete source code of every file in the audit queue. The audit is a semantic, cognitive code review, not a metrics check.
3. **Multi-Dimensional Analysis**: Each file must be evaluated across all applicable dimensions using the AI-Powered Code Scanning Guidelines defined in this workflow.
4. **Multi-Agent Delegation**: Batch files into groups of 3–5 and spawn a subagent per group to audit them in parallel. Instruct them explicitly to use their file reading tools and perform cognitive analysis on the code.
5. **Context-Aware Auditing**: When auditing pending files, do not inspect changes in complete isolation. The audit must be fully informed by the surrounding context of the modified/added lines, including the enclosing class, parent classes, annotations, imports, and sister methods.
6. **Context-Specific Rule Loading**: Enforce targeted rules based on the codebase language:
   - For `/rust` components, enforce [rust-style-guide.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/rust-core-plugin/rules/rust-style-guide.md).
   - For `/lib` (Flutter/Dart) components, enforce [abstraction-levels.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/arch-linter/rules/abstraction-levels.md), [no-cross-layer-mutation.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/arch-linter/rules/no-cross-layer-mutation.md), and [symmetry-invariants.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/arch-linter/rules/symmetry-invariants.md).
7. **Actionable Output**: Every finding must include a severity level, the principle violated, clickable file links with line ranges, and a concrete remediation suggestion.

---

## Audit Dimensions

Each component in the Audit Queue is evaluated against these principles:

### 🔹 SOLID Principles
| Principle | What to Check |
|---|---|
| **S – Single Responsibility** | Does the class have exactly one reason to change? Check `public_apis` count (flag if ≥15). Check if the class mixes UI rendering with data logic. |
| **O – Open/Closed** | Can the class be extended without modifying its source? Check if behavior is hard-coded vs. delegated to strategies/callbacks. |
| **L – Liskov Substitution** | Do subclasses honor the contract of their parent? Check abstract class implementations for missing overrides or weakened preconditions. |
| **I – Interface Segregation** | Is the class forced to implement methods it doesn't use? Check if abstract facades expose more than the consumer needs. |
| **D – Dependency Inversion** | Does the class depend on abstractions or concrete implementations? Check constructor parameters and import blocks. |

### 🔹 DRY (Don't Repeat Yourself)
- Search for duplicated logic across files in the same directory using `query_method` with regex patterns.
- Flag files that re-implement helpers already available in sibling classes or utility modules.

### 🔹 Design Pattern Fitness
- Cross-reference the cached `pattern` field against the actual class structure:
  - **Strategy Pattern**: Does it define a common interface with interchangeable implementations?
  - **Facade Pattern**: Does it simplify a complex subsystem or just pass through?
  - **Command Pattern**: Are mutations wrapped in undoable command objects?
  - **FSM State**: Does each state class handle only its own transitions?
- Flag mismatches where a class is labeled as one pattern but structurally behaves as another.

### 🔹 Complexity & Bloat
- Use `query_metrics api_count_gte=15` to find classes with too many public methods.
- Use `query_metrics size_gte=500` to find files that are too large.
- Flag God Objects: classes with both high API count AND high line count.

### 🔹 Layer Boundary Enforcement
- Run `check` to detect tier violations.
- Run `assert_naming` to verify naming conventions.
- Run `assert_tests` to verify test coverage for Tier 2/3 components.

### 🔹 Symmetry & Cohesion
- Verify that symmetric groups of classes (e.g., all mutation modules, all FSM states) follow identical structural blueprints.
- Flag orphaned helpers or asymmetric command definitions.

---

## Execution Steps

### Step 1: Refresh Cache & Automated Assertions
Run the following commands to establish the baseline (always append the required mode flag: `--dart` or `--rust`):
```powershell
# Run automated compliance check (re-scans and updates cache automatically)
dart .agents/plugins/arch-linter/scripts/arch_linter.dart check --dart
dart .agents/plugins/arch-linter/scripts/arch_linter.dart assert_naming --dart
dart .agents/plugins/arch-linter/scripts/arch_linter.dart assert_tests --dart

# Identify complexity hotspots
dart .agents/plugins/arch-linter/scripts/arch_linter.dart query_metrics api_count_gte=15 --dart
dart .agents/plugins/arch-linter/scripts/arch_linter.dart query_metrics size_gte=500 --dart
```
Collect the outputs and build the **Audit Queue** from:
- Files in `PENDING AUDITS` and `VIOLATIONS DETECTED` from the compliance check.
- Files flagged by `assert_naming` or `assert_tests`.
- Complexity hotspots from `query_metrics`.

### Step 2: Contextual Enrichment
For each file in the Audit Queue, gather its cached context:
- Use `query` to retrieve its tier, pattern, FFI status, and test coverage.
- Use `dependents` on high-risk files to assess blast radius.
- Use `trace_path` if you suspect a transitive layer leak.
- Read the [abstraction-levels.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/arch-linter/rules/abstraction-levels.md), [no-cross-layer-mutation.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/arch-linter/rules/no-cross-layer-mutation.md), and [symmetry-invariants.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/arch-linter/rules/symmetry-invariants.md) rules files to load the enforcement criteria.

### Step 3: Multi-Agent Deep Audit (Delegated Verification)
Batch the Audit Queue into groups of 3–5 files (grouped by feature area or tier when possible). For each batch, spawn a subagent:

- **Prompt to Subagent**:
  ```text
  You are a Code Health Auditor. Analyze the following files for compliance
  across ALL of the dimensions below.

  CRITICAL: You MUST use the `view_file` tool to read the full source code
  of each target file. Do NOT rely solely on the CLI cache tools. Your primary
  value is your cognitive AI scanning capability. Read the code line-by-line
  and apply the "AI-Powered Code Scanning Guidelines (Semantic Auditing)"
  defined in the /code-health workflow.

  Files to audit: [list of 3-5 file paths]

  For EACH file, evaluate and report:
  1. **SRP**: Does the class have a single, clear responsibility? Check for mixed tiers, mixed levels of abstraction, or multiple roles.
  2. **Open/Closed**: Can behavior be extended without modification? Check for hardcoded mode switchers, conditional chains, and lack of injection.
  3. **LSP & ISP**: Do subclasses honor parent contracts without throwing UnimplementedError? Are they forced to implement fat interfaces?
  4. **Dependency Inversion**: Does it depend on abstractions or concretions? Check for hardcoded class instantiations inside the code.
  5. **DRY**: Is there structural or algorithmic duplication across sibling files? Use `query_method` to cross-reference but read the code to verify.
  6. **Pattern Fitness**: Does the actual class structure match its designated design pattern? Check if strategies/commands are clean.
  7. **Symmetry**: Do sibling classes in the same directory follow the same structural blueprint?
  8. **Complexity**: Check line counts (>500) and API counts (>15) as indicators of bloat.

  Enforce:
  - Zero-Trust Checklist from architecture-auditor skill.
  - Symmetry rules from symmetry-checker skill.
  - [rust-style-guide.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/rust-core-plugin/rules/rust-style-guide.md) for Rust core components.
  - [abstraction-levels.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/arch-linter/rules/abstraction-levels.md), [no-cross-layer-mutation.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/arch-linter/rules/no-cross-layer-mutation.md), and [symmetry-invariants.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/arch-linter/rules/symmetry-invariants.md) for Flutter/Dart components.

  For each finding, report:
  - File path (clickable link)
  - Principle violated (e.g., SRP, DRY, Open/Closed, Layer Leak, Cross-Layer Mutation)
  - Severity: 🔴 Critical / 🟡 Warning / 🔵 Info
  - Line range if applicable
  - Concrete remediation suggestion
  ```


### Step 4: Synthesize & Report
Compile all subagent results into a single **Code Health Report** artifact:

```markdown
# 🏥 Code Health Audit Report

## Executive Summary
- Files Scanned: X
- Files Audited (Deep): Y
- Findings: Z (🔴 Critical: N, 🟡 Warning: N, 🔵 Info: N)

## Automated Assertion Results
| Assertion | Status | Details |
|-----------|--------|---------|
| Layer Boundaries (`check`) | ✅/❌ | ... |
| Naming Conventions (`assert_naming`) | ✅/❌ | ... |
| Test Coverage (`assert_tests`) | ✅/❌ | ... |

## Complexity Hotspots
[Table of files with high API count or line count]

## Deep Audit Findings
[Grouped by principle, with file links and remediation suggestions]

## Recommended Actions
[Prioritized list of refactoring tasks]
```

### Step 5: Cache Update & Finalization
For each audited file, update the cache to reflect the new status (appending `--dart` or `--rust` accordingly).

> [!IMPORTANT]
> A file is compliant and can be marked as `COMPLIANT` in the cache ONLY if it has been thoroughly analyzed by a separate cognitive/auditor agent (such as the `architecture-auditor` or `symmetry-checker` subagent) for various architectural principles. Do NOT mark changed files as `COMPLIANT` without a proper multi-agent audit as described in Step 3.

- **If Compliant across all dimensions**:
  ```powershell
  dart .agents/plugins/arch-linter/scripts/arch_linter.dart update <file_path> COMPLIANT "" "<responsibility>" "<pattern>" --dart
  ```
- **If Violations Detected** (separate multiple descriptions with `|`):
  ```powershell
  dart .agents/plugins/arch-linter/scripts/arch_linter.dart update <file_path> VIOLATION_DETECTED "SRP: too many responsibilities | DRY: duplicated logic in sibling" "<responsibility>" "<pattern>" --dart
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
