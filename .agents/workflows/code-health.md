---
description: Multi-agent deep audit of the entire codebase for SOLID principles, design pattern fitness, DRY compliance, complexity hotspots, and architectural boundary enforcement using the arch-linter skill.
---

# Workflow: /code-health

This workflow transforms the agent into a **Principal Code Health Auditor**. It performs a comprehensive, multi-agent analysis of the entire codebase across multiple software engineering dimensions — not just SRP, but the full spectrum of SOLID principles, DRY compliance, design pattern fitness, complexity hotspots, and naming/test coverage assertions.

It leverages the [arch-linter](file:///d:/Projects/Open/flutter/code/mycelium/.agents/skills/arch-linter/SKILL.md) skill for fast cached metadata queries and the [architecture-auditor](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/arch-linter/skills/architecture-auditor/SKILL.md) / [symmetry-checker](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/arch-linter/skills/symmetry-checker/SKILL.md) skills for deep structural reasoning.

---

## Core Mandates

1. **Cache-First Discovery**: Always start with `cache_manager.dart scan` to refresh metadata. Use cached tiers, imports, public APIs, and patterns to identify files for the audit queue.
2. **Deep Semantic AI Scanning**: The CLI cache tools are only for indexing and filtering. You and your subagents **MUST** use the `view_file` tool to read the complete source code of every file in the audit queue. The audit is a semantic, cognitive code review, not a metrics check.
3. **Multi-Dimensional Analysis**: Each file must be evaluated across all applicable dimensions using the AI-Powered Code Scanning Guidelines defined in the [arch-linter](file:///d:/Projects/Open/flutter/code/mycelium/.agents/skills/arch-linter/SKILL.md) skill.
4. **Multi-Agent Delegation**: Batch files into groups of 3–5 and spawn a subagent per group to audit them in parallel. Instruct them explicitly to use their file reading tools and perform cognitive analysis on the code.
5. **Actionable Output**: Every finding must include a severity level, the principle violated, clickable file links with line ranges, and a concrete remediation suggestion.

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
Run the following commands to establish the baseline:
```powershell
# Refresh all cached metadata
dart .agents/plugins/arch-linter/scripts/cache_manager.dart scan

# Run automated compliance checks
dart .agents/plugins/arch-linter/scripts/cache_manager.dart check
dart .agents/plugins/arch-linter/scripts/cache_manager.dart assert_naming
dart .agents/plugins/arch-linter/scripts/cache_manager.dart assert_tests

# Identify complexity hotspots
dart .agents/plugins/arch-linter/scripts/cache_manager.dart query_metrics api_count_gte=15
dart .agents/plugins/arch-linter/scripts/cache_manager.dart query_metrics size_gte=500
```
Collect the outputs and build the **Audit Queue** from:
- Files in `[AUDIT_REQUIRED - PENDING]` and `[AUDIT_REQUIRED - VIOLATION]` from the scan.
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
  defined in the arch-linter skill.

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

  For each finding, report:
  - File path (clickable link)
  - Principle violated (e.g., SRP, DRY, Open/Closed)
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
For each audited file, update the cache to reflect the new status:
- **If Compliant across all dimensions**:
  ```powershell
  dart .agents/plugins/arch-linter/scripts/cache_manager.dart update <file_path> COMPLIANT "" "<responsibility>" "<pattern>"
  ```
- **If Violations Detected** (separate multiple descriptions with `|`):
  ```powershell
  dart .agents/plugins/arch-linter/scripts/cache_manager.dart update <file_path> VIOLATION_DETECTED "SRP: too many responsibilities | DRY: duplicated logic in sibling" "<responsibility>" "<pattern>"
  ```
