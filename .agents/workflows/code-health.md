---
description: Multi-agent deep audit of the entire codebase for SOLID principles, design pattern fitness, DRY compliance, complexity hotspots, and architectural boundary enforcement using arch-mcp.
---

# Workflow: /code-health

This workflow transforms the agent into a **Principal Code Health Auditor**. It performs a comprehensive, multi-agent analysis of the entire codebase across multiple software engineering dimensions — not just SRP, but the full spectrum of SOLID principles, DRY compliance, design pattern fitness, complexity hotspots, and naming/test coverage assertions.

It leverages arch-mcp for fast metadata queries, layer/tier enforcement, and dependency analysis, and the [dimension-auditor](.agents/plugins/code-health/skills/dimension-auditor/SKILL.md), [architecture-auditor](.agents/plugins/code-health/skills/architecture-auditor/SKILL.md), and [symmetry-checker](.agents/plugins/code-health/skills/symmetry-checker/SKILL.md) skills for deep structural reasoning.

---

## Core Mandates

1. **Audit-First Discovery**: Always start with `audit()` to scan for layer/tier violations. Use `index` to query the arch-mcp database and identify files for the audit queue.
2. **Deep Semantic AI Scanning**: The CLI cache tools are only for indexing and filtering. You and your subagents **MUST** use the `view_file` tool to read the complete source code of every file in the audit queue. The audit is a semantic, cognitive code review, not a metrics check.
3. **Multi-Dimensional Analysis**: Each file must be evaluated across all applicable dimensions using the AI-Powered Code Scanning Guidelines defined in this workflow.
4. **Dynamic Subagent Allocation**: Group files in scope (`N_total`) by feature area/relevance without small remainder batches (< 8 files). Spawn 2, 3, or 4 dimension-clustered subagents per batch as defined in the [dimension-auditor](.agents/plugins/code-health/skills/dimension-auditor/SKILL.md) skill.
5. **Context-Aware Auditing**: When auditing pending files, do not inspect changes in complete isolation. The audit must be fully informed by the surrounding context of the modified/added lines, including the enclosing class, parent classes, annotations, imports, and sister methods.
6. **Context-Specific Rule Loading**: Enforce targeted rules based on the codebase language:
   - For `/rust` components, enforce [rust-style-guide.md](.agents/plugins/rust-core-plugin/rules/rust-style-guide.md).
   - For `/lib` (Flutter/Dart) components, enforce [abstraction-levels.md](.agents/plugins/code-health/rules/abstraction-levels.md) (includes cross-layer mutation boundaries) and the [symmetrical-design](.agents/skills/design/symmetrical-design/SKILL.md) skill.
7. **Actionable Output**: Every finding must include a severity level, the principle violated, clickable file links, and a concise violation description. Do NOT propose remediation fixes during the audit phase.

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
- Search for duplicated logic across files in the same directory using arch-mcp's `query` tool with method or class names.
- Flag files that re-implement helpers already available in sibling classes or utility modules.

### 🔹 Design Pattern Fitness
- Cross-reference the cached `pattern` field against the actual class structure:
  - **Strategy Pattern**: Does it define a common interface with interchangeable implementations?
  - **Facade Pattern**: Does it simplify a complex subsystem or just pass through?
  - **Command Pattern**: Are mutations wrapped in undoable command objects?
  - **FSM State**: Does each state class handle only its own transitions?
- Flag mismatches where a class is labeled as one pattern but structurally behaves as another.

### 🔹 Complexity & Bloat
- Use arch-mcp's `index` tool to check public API counts and file sizes.
- Flag God Objects: classes with both high API count AND high line count.

### 🔹 Layer Boundary Enforcement
- Run `audit()` to detect tier/layer violations.
- Run `analyze()` to verify naming conventions and config consistency.
- Use arch-mcp's `index` tool to verify test coverage and metadata for Tier 2/3 components.

### 🔹 Symmetry & Cohesion
- Verify that symmetric groups of classes (e.g., all mutation modules, all FSM states) follow identical structural blueprints.
- Flag orphaned helpers or asymmetric command definitions.

### 🔹 Test Coverage Cross-Reference
- For each Tier 2/3 source file in the Audit Queue, check if a corresponding test file exists.
- Dart pattern: `lib/features/graph/store/foo.dart` → `test/features/graph/store/foo_test.dart`
- Rust pattern: `rust/src/domain/foo.rs` → `rust/tests/core_tests/foo.rs` or `#[test]` in `rust/src/foo.rs`
- Use arch-mcp's `query` tool to find associated test files for the module.
- Cross-reference with git churn data: files with high change frequency but no corresponding test are **untested hotspots** (highest remediation priority).

---

## Execution Steps

### Step 1: Calibration

Before applying any rules, read the project's own configuration to understand what "correct" means **here** — not in generic best-practice land. This prevents false positives from auditing against standards the project explicitly opts out of.

Read and note:
1. **`analysis_options.yaml`**: Disabled lint rules, custom analyzer settings, excluded files. Any rule the project intentionally turns off is NOT a finding.
2. **`AGENTS.md`**: Documented architectural patterns, coding conventions, and intentional deviations. These override generic SOLID/DDD advice.
3. **`.arch/config.json`**: The project's own ontology — defined layers, tiers, dependency constraints, and propagation handlers. This is the authoritative source for layer boundary rules. If a piece of code doesn't fit the current ontology, **do not force-fit or ignore it** — flag it as an **Ontology Gap** and propose updating `config.json` with the user's approval.
4. **`pubspec.yaml`** / **`Cargo.toml`**: Language versions, framework constraints, and dependency choices that may affect what patterns are viable.

**Output**: A Calibration Baseline (5–10 bullets) capturing the project's own standards. This baseline is what you audit *against*.

> [!TIP]
> Skip this step only if you are re-running an audit within the same session and the calibration baseline is already in your context.

### Step 2: Refresh Graph & Automated Assertions

Use arch-mcp tools to:
- Run automated compliance scan (detects layer/tier/dependency violations)
- Validate naming conventions and config consistency

Collect the outputs and build the **Audit Queue** from:
- Files with `VIOLATION_DETECTED` or `PENDING_AUDIT` status from the audit.
- Files flagged by `analyze` for naming or config issues.
- Complexity hotspots identified via arch-mcp's `index` tool (check public API counts and file sizes).

### Step 3: Dead Code Discovery

Use arch-mcp's `impact` tool to identify public symbols with zero callers. If upstream callers = 0, this is a dead code candidate.

Evaluation criteria for dead code candidates:
- **High confidence**: zero upstream callers AND not referenced in any test file AND not a `main()` entry point
- **Medium confidence**: zero upstream callers but is a public API (may be consumed by external packages)
- **Low confidence**: graph-based detection only (symbol exists but caller edges are incomplete)

Tag dead code candidates with confidence tier and add to the Audit Queue for subagent verification. The subagent must read the code to confirm the symbol is truly unreachable (graph may miss dynamic invocations, reflection, or string-based lookups).

### Step 4: Knowledge Graph Analysis

After running initial scans, use arch-mcp's `report` tool to incorporate its analysis into the audit:
- **God Nodes**: High-centrality files that many other files depend on — these are architectural linchpins. Flag any god node in the Audit Queue for deep review (high blast radius if changed).
- **Surprising Connections**: Cross-community edges that indicate unexpected coupling between unrelated modules. These often reveal hidden dependencies or premature abstractions.
- **Community Structure**: Review community labels for cohesion issues — if files from the same feature are scattered across different communities, the code may lack physical cohesion.
- **Suggested Questions**: Use these as additional audit angles, especially questions that cross community boundaries.

Merge arch-mcp's findings into the Audit Queue alongside the audit results.

### Step 5: Test Coverage Cross-Reference

For each Tier 2/3 file in the Audit Queue, run a heuristic test-coverage check:

```powershell
# Find test files associated with source modules via arch-mcp
query(text="<module_or_feature_name>")

# For Dart: check for corresponding test file
# lib/features/graph/store/foo.dart → test/features/graph/store/foo_test.dart

# For Rust: check for #[test] annotations or test crate references
# rust/src/domain/foo.rs → rust/tests/core_tests/foo.rs
```

Tag each file in the Audit Queue with a `has_test` boolean. Files with `has_test: false` AND high git churn (or high centrality from Step 4) are flagged as **Untested Hotspots** — these get elevated priority in the final report.

### Step 6: Contextual Enrichment

For each file in the Audit Queue, gather its context from the arch-mcp database:
- Use arch-mcp's `index` tool to retrieve a file's layer, tier, purity, architectural role, and dependencies.
- Use `compile_context` on high-risk files to assess blast radius.
- Use `query` if you suspect a transitive layer leak.
- Load the language-specific coding standards to audit against:
   - For Dart files, view and load [dart-coding](.agents/skills/coding/dart-coding/SKILL.md) skill rules.
   - For Rust files, view and load [rust-coding](.agents/skills/coding/rust-coding/SKILL.md) skill rules.
- Read rule files: [abstraction-levels.md](.agents/plugins/code-health/rules/abstraction-levels.md) (includes cross-layer mutation boundaries) and the [symmetrical-design](.agents/skills/design/symmetrical-design/SKILL.md) skill.


### Step 7: Multi-Agent Deep Audit (Delegated Verification)

Apply the dynamic batching and subagent allocation rules from the [dimension-auditor](.agents/plugins/code-health/skills/dimension-auditor/SKILL.md) skill:
1. **Group Files Intelligently**: Group files in scope (`N_total`) by feature/directory relevance, avoiding small remainder batches (< 8 files) by absorbing remainder files across batches.
2. **Determine Subagents per Batch**: Spawn 2, 3, or 4 subagents per batch based on file count (`F_batch`):
   - `1 <= F_batch <= 8` $\implies$ 2 Subagents
   - `9 <= F_batch <= 15` $\implies$ 3 Subagents
   - `F_batch >= 16` $\implies$ 4 Subagents
3. **Construct Custom Subagent Prompts**: Populate the subagent prompt template from `dimension-auditor`, adding custom Master Agent context and domain notes for each batch.
4. **Audit Rules**: Subagents evaluate dimensions in contrast using `view_file` and output ultra-compact JSON arrays without proposing remediation fixes.

### Step 8: Synthesize & Report

Compile all subagent results into a single **Code Health Report** using the template from [code-health-report-template.md](.agents/plugins/code-health/rules/code-health-report-template.md).

### Step 9: Status Update & Finalization

For each audited file, update its status in the graph to reflect the audit result.

> [!IMPORTANT]
> A file is compliant and can be marked as `COMPLIANT` ONLY if it has been thoroughly analyzed by a separate cognitive/auditor agent (such as the `dimension-auditor`, `architecture-auditor`, or `symmetry-checker` subagent) for various architectural principles. Do NOT mark changed files as `COMPLIANT` without a proper multi-agent audit as described in Step 7.

- **If Compliant across all dimensions**:
  ```powershell
  set_fields(target="<file_path>", update="status:COMPLIANT")
  ```
- **If Violations Detected**:
  ```powershell
  set_fields(target="<file_path>", update="status:VIOLATION")
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

The project enforces a strict **3-Tier Hierarchy**. Full tier definitions, responsibilities, and dependency rules are in [abstraction-levels.md](.agents/plugins/code-health/rules/abstraction-levels.md). The authoritative source for layer assignments is `.arch/config.json`.

Quick reference:
- **Tier 1 (Presentation & Interface)**: `lib/features/graph/ui` — rendering and layout only. LOWEST tier.
- **Tier 2 (Interaction & Controllers)**: `lib/features/graph/presentation`, `lib/features/graph/engine` — transient state and coordination
- **Tier 3 (Core Domain & Storage)**: `lib/features/graph/store`, `lib/features/graph/models` — business logic and persistence. HIGHEST tier.

Tier 3 MUST NEVER import Tier 1 or Tier 2. Tier 2 MUST NOT import Tier 1. See [abstraction-levels.md](.agents/plugins/code-health/rules/abstraction-levels.md) for full enforcement rules.
