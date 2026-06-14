---
description: Multi-agent deep audit of the entire codebase for SOLID principles, design pattern fitness, DRY compliance, complexity hotspots, and architectural boundary enforcement using graphify arch.
---

# Workflow: /code-health

This workflow transforms the agent into a **Principal Code Health Auditor**. It performs a comprehensive, multi-agent analysis of the entire codebase across multiple software engineering dimensions — not just SRP, but the full spectrum of SOLID principles, DRY compliance, design pattern fitness, complexity hotspots, and naming/test coverage assertions.

It leverages [graphify arch](file:///d:/Projects/Open/flutter/code/mycelium/.agents/rules/graphify.md) for fast metadata queries, layer/tier enforcement, and dependency analysis, and the [architecture-auditor](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/code-health/skills/architecture-auditor/SKILL.md) / [symmetry-checker](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/code-health/skills/symmetry-checker/SKILL.md) skills for deep structural reasoning.

---

## Core Mandates

1. **Graph-First Discovery**: Always start with `graphify arch audit` to scan for layer/tier violations and refresh metadata. Use the graph to identify files for the audit queue.
2. **Deep Semantic AI Scanning**: The CLI cache tools are only for indexing and filtering. You and your subagents **MUST** use the `view_file` tool to read the complete source code of every file in the audit queue. The audit is a semantic, cognitive code review, not a metrics check.
3. **Multi-Dimensional Analysis**: Each file must be evaluated across all applicable dimensions using the AI-Powered Code Scanning Guidelines defined in this workflow.
4. **Multi-Agent Delegation**: Batch files into groups of 3–5 and spawn a subagent per group to audit them in parallel. Instruct them explicitly to use their file reading tools and perform cognitive analysis on the code.
5. **Context-Aware Auditing**: When auditing pending files, do not inspect changes in complete isolation. The audit must be fully informed by the surrounding context of the modified/added lines, including the enclosing class, parent classes, annotations, imports, and sister methods.
6. **Context-Specific Rule Loading**: Enforce targeted rules based on the codebase language:
   - For `/rust` components, enforce [rust-style-guide.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/rust-core-plugin/rules/rust-style-guide.md).
   - For `/lib` (Flutter/Dart) components, enforce [abstraction-levels.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/code-health/rules/abstraction-levels.md), [no-cross-layer-mutation.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/code-health/rules/no-cross-layer-mutation.md), and [symmetry-invariants.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/code-health/rules/symmetry-invariants.md).
7. **Actionable Output**: Every finding must include a severity level, the principle violated, clickable file links with line ranges, and a concrete remediation suggestion.
8. **Ontology-First Understanding**: Before any audit, read `graphify-out/arch/config.json` to understand the project's architectural ontology — its defined layers, tiers, assignment rules, dependency constraints, and propagation handlers. This config is the ground truth for what the project considers valid architecture. If a piece of code doesn't fit the current ontology (e.g., a legitimate pattern that has no layer assignment, or a dependency rule that blocks a valid use case), **do not force-fit or ignore it** — flag it as an ontology gap and propose updating `config.json` with the user's approval. The ontology evolves with the codebase.

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
- Search for duplicated logic across files in the same directory using `graphify query` with method or class names.
- Flag files that re-implement helpers already available in sibling classes or utility modules.

### 🔹 Design Pattern Fitness
- Cross-reference the cached `pattern` field against the actual class structure:
  - **Strategy Pattern**: Does it define a common interface with interchangeable implementations?
  - **Facade Pattern**: Does it simplify a complex subsystem or just pass through?
  - **Command Pattern**: Are mutations wrapped in undoable command objects?
  - **FSM State**: Does each state class handle only its own transitions?
- Flag mismatches where a class is labeled as one pattern but structurally behaves as another.

### 🔹 Complexity & Bloat
- Use `graphify arch query-file --path <file>` to check public API counts and file sizes.
- Flag God Objects: classes with both high API count AND high line count.

### 🔹 Layer Boundary Enforcement
- Run `graphify arch audit` to detect tier/layer violations.
- Run `graphify arch analyze` to verify naming conventions and config consistency.
- Run `graphify arch query-file` to verify test coverage and metadata for Tier 2/3 components.

### 🔹 Symmetry & Cohesion
- Verify that symmetric groups of classes (e.g., all mutation modules, all FSM states) follow identical structural blueprints.
- Flag orphaned helpers or asymmetric command definitions.

---

## Execution Steps

### Step 1: Refresh Graph & Automated Assertions
Run the following commands to establish the baseline:
```powershell
# Refresh the knowledge graph (re-extract changed files, rebuild communities)
graphify update .

# Understand the project ontology before auditing
# Read graphify-out/arch/config.json to learn the defined layers, tiers, rules, and handlers

# Run automated compliance scan (detects layer/tier/dependency violations)
graphify arch audit

# Validate naming conventions and config consistency
graphify arch analyze

# Identify files with violations or pending audits
graphify arch set-status --query VIOLATION_DETECTED
graphify arch set-status --query PENDING_AUDIT
```
Collect the outputs and build the **Audit Queue** from:
- Files with `VIOLATION_DETECTED` or `PENDING_AUDIT` status from the audit.
- Files flagged by `analyze` for naming or config issues.
- Complexity hotspots identified via `graphify arch query-file` (check public API counts and file sizes).

### Step 2: Graphify Knowledge Graph Analysis
After refreshing the graph, read `graphify-out/GRAPH_REPORT.md` to incorporate graphify's own analysis into the audit:
- **God Nodes**: High-centrality files that many other files depend on — these are architectural linchpins. Flag any god node in the Audit Queue for deep review (high blast radius if changed).
- **Surprising Connections**: Cross-community edges that indicate unexpected coupling between unrelated modules. These often reveal hidden dependencies or premature abstractions.
- **Community Structure**: Review community labels for cohesion issues — if files from the same feature are scattered across different communities, the code may lack physical cohesion.
- **Suggested Questions**: Use these as additional audit angles, especially questions that cross community boundaries.

Merge graphify's findings into the Audit Queue alongside the arch audit results.

### Step 3: Contextual Enrichment
For each file in the Audit Queue, gather its context from the graph:
- Use `graphify arch query-file --path <file>` to retrieve its layer, tier, purity, architectural role, and dependencies.
- Use `graphify arch compile-context --node <file> --direction upstream` on high-risk files to assess blast radius.
- Use `graphify query "<concept>"` if you suspect a transitive layer leak.
- Read the [abstraction-levels.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/code-health/rules/abstraction-levels.md), [no-cross-layer-mutation.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/code-health/rules/no-cross-layer-mutation.md), and [symmetry-invariants.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/code-health/rules/symmetry-invariants.md) rules files to load the enforcement criteria.

### Step 4: Multi-Agent Deep Audit (Delegated Verification)
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
   5. **DRY**: Is there structural or algorithmic duplication across sibling files? Use `graphify query` to cross-reference but read the code to verify.
  6. **Pattern Fitness**: Does the actual class structure match its designated design pattern? Check if strategies/commands are clean.
  7. **Symmetry**: Do sibling classes in the same directory follow the same structural blueprint?
  8. **Complexity**: Check line counts (>500) and API counts (>15) as indicators of bloat.

  Enforce:
  - Zero-Trust Checklist from architecture-auditor skill.
  - Symmetry rules from symmetry-checker skill.
  - [rust-style-guide.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/rust-core-plugin/rules/rust-style-guide.md) for Rust core components.
  - [abstraction-levels.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/code-health/rules/abstraction-levels.md), [no-cross-layer-mutation.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/code-health/rules/no-cross-layer-mutation.md), and [symmetry-invariants.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/code-health/rules/symmetry-invariants.md) for Flutter/Dart components.

  For each finding, report:
  - File path (clickable link)
  - Principle violated (e.g., SRP, DRY, Open/Closed, Layer Leak, Cross-Layer Mutation)
  - Severity: 🔴 Critical / 🟡 Warning / 🔵 Info
  - Line range if applicable
  - Concrete remediation suggestion
  ```


### Step 5: Synthesize & Report
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
| Layer Boundaries (`graphify arch audit`) | ✅/❌ | ... |
| Naming Conventions (`graphify arch analyze`) | ✅/❌ | ... |
| Config Consistency (`graphify arch analyze`) | ✅/❌ | ... |

## Graphify Knowledge Graph Insights
- **God Nodes**: [list files with highest centrality and their risk profile]
- **Surprising Connections**: [cross-community couplings that indicate architectural drift]
- **Community Cohesion Issues**: [features scattered across unrelated communities]
- **Suggested Investigation**: [graphify's suggested questions applied as audit angles]

## Complexity Hotspots
[Table of files with high API count or line count]

## Deep Audit Findings
[Grouped by principle, with file links and remediation suggestions]

## Recommended Actions
[Prioritized list of refactoring tasks]
```

### Step 6: Status Update & Finalization
For each audited file, update its status in the graph to reflect the audit result.

> [!IMPORTANT]
> A file is compliant and can be marked as `COMPLIANT` ONLY if it has been thoroughly analyzed by a separate cognitive/auditor agent (such as the `architecture-auditor` or `symmetry-checker` subagent) for various architectural principles. Do NOT mark changed files as `COMPLIANT` without a proper multi-agent audit as described in Step 3.

- **If Compliant across all dimensions**:
  ```powershell
  graphify arch set-status --path <file_path> --status COMPLIANT
  ```
- **If Violations Detected**:
  ```powershell
  graphify arch set-status --path <file_path> --status VIOLATION_DETECTED
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
