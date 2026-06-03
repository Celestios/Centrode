---
description: Targeted multi-agent audit of uncommitted git diffs for SOLID violations, design pattern regressions, layer leaks, and symmetry breaks using the arch-linter skill.
---

# Workflow: /diff-audit

This workflow audits **only the uncommitted changes** (staged and unstaged) for architectural compliance, SOLID violations, and design pattern regressions. It is the fast, focused counterpart to `/code-health` — where `/code-health` scans the whole codebase, `/diff-audit` surgically inspects only what you are about to commit.

It leverages the [arch-linter](file:///d:/Projects/Open/flutter/code/mycelium/.agents/skills/arch-linter/SKILL.md) skill to enrich each changed file with cached metadata (tier, pattern, dependents, APIs) before delegating deep analysis to subagents.

---

## Core Mandates
1. **Context-Aware Diff Auditing**: Do not analyze diff hunks in complete isolation. You and your subagents **MUST** use the `view_file` tool to inspect the surrounding context of the modified lines (such as the enclosing class, parent classes, annotations, imports, and sister methods). While findings are reported against the changed lines, the evaluation must be fully informed by the file's structure.
2. **Deep Semantic AI Scanning**: Do not rely on git diff hunks alone. Use `view_file` to read the target files around the changes, and apply the AI-Powered Code Scanning Guidelines (Semantic Auditing) defined in the [arch-linter](file:///d:/Projects/Open/flutter/code/mycelium/.agents/skills/arch-linter/SKILL.md) skill.
3. **Linter-Enriched Context**: Before auditing any changed file, query the arch-linter cache for its tier, pattern, public APIs, and blast radius. This context dramatically improves audit precision.
4. **Context-Specific Rule Loading**:
   - If the diff contains changes in the `/rust` directory, enforce [rust-style-guide.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/rust-core-plugin/rules/rust-style-guide.md).
   - If the diff contains changes in `/lib` (Flutter/Dart), enforce [abstraction-levels.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/arch-linter/rules/abstraction-levels.md), [no-cross-layer-mutation.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/arch-linter/rules/no-cross-layer-mutation.md), and [symmetry-invariants.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/arch-linter/rules/symmetry-invariants.md).
5. **Multi-Agent Verification**: Delegate detailed validation of diff blocks to focused subagents to prevent context pollution and structural blindness. Instruct subagents to read the code surrounding the diffs using `view_file`.

---

## Execution Steps

### Step 1: Change Discovery & Linter Enrichment
- **Action**: Discover what changed and enrich with cached metadata.
  ```powershell
  # Discover changed files
  git status
  git diff --name-only
  git diff --cached --name-only

  # Refresh the architecture cache
  dart .agents/plugins/arch-linter/scripts/cache_manager.dart scan

  # For each changed Dart file, query its architectural context:
  dart .agents/plugins/arch-linter/scripts/cache_manager.dart query dir=<changed_file_directory>

  # Check blast radius for high-risk changes:
  dart .agents/plugins/arch-linter/scripts/cache_manager.dart dependents <changed_file_path>
  ```
- **Task**: Group changed files by architectural layer:
  - **Tier 1 (View Layer)**: UI widgets, canvas rendering.
  - **Tier 2 (Interaction Layer)**: State machine handlers, gesture environments, presentation strategies.
  - **Tier 3 (Store Layer)**: Graph data state, mutation modules, models.
  - **FFI / Rust Core**: Bridge definitions, domain models, persistence logic.

### Step 2: Delegate Diff Audits (Subagent Execution)
For each changed file (or batch of 2–3 related files), spawn a subagent with enriched context:

- **Prompt to Subagent**:
  ```text
  You are an Architectural Diff Auditor. Audit the following uncommitted diff.

  CRITICAL: You MUST use the `view_file` tool to inspect the surrounding
  context of the modified lines (the class declaration, imports, sibling
  methods, annotations, and overall structure). Do NOT audit the diff hunk
  blindly in isolation. Your primary value is your cognitive AI scanning
  capability. Use the "AI-Powered Code Scanning Guidelines (Semantic Auditing)"
  defined in the arch-linter skill.

  File: [FilePath]
  Tier: [tier from cache]
  Pattern: [pattern from cache]
  Public APIs: [api count]
  Dependents (blast radius): [list from dependents command]

  Diff:
  [Paste raw diff hunk / git diff output for this file]

  Evaluate the changes and their surrounding context against:
  1. **Layer Boundaries**: Do the new imports or calls introduce a tier violation? (Tier 3 must NOT import Tier 1 or Tier 2)
  2. **SRP**: Do the changes add a second responsibility to this class or mix abstraction levels?
  3. **Open/Closed**: Do the changes modify existing behavior that should have been extended via a strategy or callback instead (e.g. hardcoded switches)?
  4. **LSP & ISP**: Do subclasses honor parent contracts without throwing UnimplementedError? Are they forced to implement fat interfaces?
  5. **DRY**: Do the changes duplicate logic that already exists in a sibling class? (Use `query_method` to check, but read code to verify)
  6. **Symmetry**: If a new method or helper was added, do its siblings in the same directory follow the same structural blueprint?
  7. **Cross-Layer Mutation**: Does a UI component directly mutate domain state without going through the Command/Controller layer?
  8. **Pattern Fitness**: If the class is labeled as a specific design pattern, do the changes maintain that pattern's structural contract?

  For each finding, report:
  - Principle violated (e.g., SRP, DRY, Layer Leak)
  - Severity: 🔴 Critical / 🟡 Warning / 🔵 Info
  - Exact changed line numbers (e.g., L45-L53)
  - Concrete fix suggestion
  ```


### Step 3: Compile Diff Audit Report
Synthesize the subagent reports into a Markdown artifact:

```markdown
# 🔍 Diff Audit Report

## Summary
- Files Changed: X
- Files Audited: Y
- Findings: Z (🔴 Critical: N, 🟡 Warning: N, 🔵 Info: N)

## Layer Verdicts
| Layer | Status | Files |
|-------|--------|-------|
| Tier 1 (UI) | ✅/❌ | ... |
| Tier 2 (Interaction) | ✅/❌ | ... |
| Tier 3 (Domain) | ✅/❌ | ... |
| Rust Core | ✅/❌ | ... |

## Findings (Hunk-by-Hunk)
### [file_path](file:///absolute/path)
- 🔴 **SRP** [L45-L53]: Added database logic to a UI widget. 
  → Move to `GraphPropertyMutations`.
- 🟡 **DRY** [L120]: `getScale()` duplicates logic in 
  `CanvasInteractionEnvironment.getScale()`.
  → Reuse existing helper.

## Actionable Remedies
[Prioritized list of exact changes to make]
```

### Step 4: Resolution
Present the report to the user and offer:
1. **Auto-Apply Fixes**: Implement the recommended changes directly.
2. **Commit Clean**: Proceed to `/git-commit` if the audit is clean.
3. **Manual Fix**: Exit to let the developer address violations.