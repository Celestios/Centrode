---
description: Structured workflow to audit recent uncommitted modifications (staged and unstaged changes) using git diff to enforce architectural layers and detect leaks.
---

# Workflow: /diff-audit

This workflow guides the agent to systematically audit uncommitted code modifications in the working tree (staged and unstaged changes) using `git diff`. By focusing exclusively on changed lines (diff hunks), it provides high-precision verification of architectural integrity and symmetry conventions.

## Core Mandates
1. **Focus on Uncommitted Diffs**: Do not analyze entire files unless they are newly created. Focus your audit strictly on the lines modified or added in the active diff.
2. **Context-Specific Plugin Loading**:
   - If the diff contains changes in the `/rust` directory, you MUST load and enforce [rust-style-guide.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/rust-core-plugin/rules/rust-style-guide.md).
   - If the diff contains changes in `/lib` (Flutter/Dart), you MUST load and enforce [abstraction-levels.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/srp-audit/rules/abstraction-levels.md) and [no-cross-layer-mutation.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/srp-audit/rules/no-cross-layer-mutation.md).
3. **Multi-Agent Verification**: Delegate the detailed validation of specific diff blocks to focused subagents to maintain parent context and avoid structural blindness.

---

## Execution Steps

### Step 1: Change Discovery & Layer Isolation
- **Action**: Check status and retrieve active diffs.
  - Run `git status` to find modified files.
  - Run `git diff` (unstaged changes) and `git diff --cached` (staged changes).
- **Task**: Identify which files and architectural layers are affected. Group changed files into:
  - **View Layer**: UI widgets, canvas rendering.
  - **Interaction Layer**: State machine handlers, gesture environments.
  - **Store Layer**: Graph data state, theme managers.
  - **FFI Layer**: Rust bridge definitions.
  - **Rust Core**: Domain models, persistence database logic.

### Step 2: Delegate Diff Audits (Subagent Execution)
For each modified file, use `invoke_subagent` to perform an isolated, precise check of the diff hunks:
- **Action**: Spawn a subagent (type `research` or `self`) for each major modified component.
- **Prompt to Subagent**:
  ```text
  Audit the following uncommitted diff for [FileName]:
  [Paste raw diff hunk / git diff output for this file]
  
  Verify:
  1. If Dart/UI: Ensure NO inline database mutations, FFI calls, or coordinate systems mixing (enforce canvas-rules and no-cross-layer-mutation).
  2. If Rust/DB: Verify type-safe CRUD operations, proper deserialization fallbacks, and record ID string serialization (enforce rust-style-guide).
  3. Symmetry: Does this change introduce a helper or command that lacks symmetric counterparts (enforce symmetry-invariants)?
  
  Return a structured list of violations with specific changed line numbers.
  ```

### Step 3: Compile Precise Diff Audit Report
Synthesize the reports returned by the subagents into a Markdown artifact:
- **Title**: `# 🔍 Uncommitted Git Diff Audit Report`
* **📂 Layer Verdicts**: A quick health status (`COMPLIANT` / `VIOLATION DETECTED`) for each modified layer.
* **📋 Audit Findings (Hunk-by-Hunk)**:
  - Provide clickable links to the modified files.
  - For each violation, specify the exact line numbers (e.g. `[L45-L53](file:///d:/Projects/...#L45-L53)`) and the rule violated.
* **🛠️ Actionable Remedies**: List exact replacement recommendations to resolve the violations.

### Step 4: Interactivity & Resolution
Present the report to the user and request confirmation on how to proceed:
1. **Auto-Apply Fixes**: Automatically implement recommended changes to resolve the leaks in the diff.
2. **Commit Changes**: Proceed directly to `/git-commit` to stage and commit the changes if the audit is clean.
3. **Abort/Manual Fix**: Exit the workflow to let the developer address violations manually.