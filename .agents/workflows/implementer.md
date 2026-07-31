---
description: Guided workflow to implement approved designs, write clean code, and verify changes via tests.
---

# Workflow: /implementer

This workflow is used when executing code changes, feature implementations, and refactoring tasks. It delegates language-specific styles to programming skills and governs tests and builds.

## Execution Steps

### Step 1: Complexity Assessment & Execution Mode

Assess whether the task is **simple** or **complex**. Simple means few files, single subsystem, no cross-tier work. Complex means multi-file, cross-tier, multi-language, or deep dependency chains.

Present the assessment and ask the user:
1. **Execution mode**: "Should I implement this **inline** or **delegate to subagents**?" (Don't delegate simple tasks.)
2. **Commit strategy** (complex tasks only): "Should I commit after each subtask, or a single commit at the end?"

Record the user's choices. These govern all subsequent steps.

---

### Step 2: Branch Management (complex tasks with commits)

If the user chose commit-per-subtask strategy:
- Check the current branch via `git branch --show-current`.
- If already on a feature branch (not `main`/`master`/`develop`), use it.
- If on `main`/`master`/`develop`, create and checkout a new branch named per git conventions (`<type>/<scope>-<kebab-desc>`).

Simple tasks skip this step — no branch management needed.

---

### Step 3: Implementer Plan

Write a concise plan to `.hermes/plans/implementer_<scope>_<timestamp>.md`. This is a task-tracking file, not a design document — keep it short and to the point.

**Requirements:**
- List the source artifacts consumed from the designer
- Break work into hierarchical subtasks with numbered notation (1, 1.1, 1.1.1)
- Depth depends on complexity: 2 levels by default, up to 4–5 for complex tasks
- Each subtask should note affected files, tier, and any dependencies
- Note if code generation or tests are needed post-implementation

Write only what is useful for tracking execution. Skip verbose explanations.

Present the plan to the user for approval before proceeding.

---

### Step 4: Implement Code Changes

- Determine the languages involved:
  - For Dart/Flutter changes: View and activate the [dart-coding](.agents/skills/coding/dart-coding/SKILL.md) skill.
  - For Rust core changes: View and activate the [rust-coding](.agents/skills/coding/rust-coding/SKILL.md) skill.
- Ensure all code conforms strictly to [solid-principles](.agents/rules/solid-principles.md) (SRP, OCP, LSP, ISP, DIP, DRY), respects the [architectural-bounds](.agents/rules/architectural-bounds.md) (layer boundaries), and aligns with [symmetrical-design](.agents/skills/design/symmetrical-design/SKILL.md) guidelines.
- Apply code changes surgically. Keep changes focused and clean, preserving unrelated comments/docstrings.
- **Rule**: Follow style guidelines (layer boundaries, no UI database calls, no manual schema changes, no custom error fallbacks) from line one.
- **Subagent mode**: If delegated, each subagent receives its own subtask scope from the plan. The orchestrator merges results and resolves conflicts.
- **Inline mode**: Execute subtasks sequentially per the plan order, respecting dependency chains.
- **Commit-per-subtask mode**: After each subtask completes, stage and commit with a conventional commit message scoped to that subtask (`<type>(<scope>): <desc>`). If on a feature branch, push is NOT automatic — leave that to the user.

---

### Step 5: Code Generation & Binding Rebuilds

- If any models, annotated classes, domain structures, or FFI bridge endpoints changed, run the code generators:
  ```bash
  flutter pub run build_runner build --delete-conflicting-outputs
  ```
- Ensure that the build finishes with zero errors.

---

### Step 6: Verification & Test Execution

- Do NOT automatically run test suites. Prompt the user for permission first if you wish to verify changes:
  - For Dart/Flutter changes, ask to run: `flutter test`
  - For Rust core changes, ask to run: `cd rust && cargo test`
- If the user approves, execute the command and fix any compilation or test failures. If not, skip and proceed to Step 7.

---

### Step 7: Artifact Completion Marking

On successful implementation, mark all designer artifacts that were consumed during this task as complete. This includes architecture context reports and any design handover documents, plus the implementer plan file from Step 3.

For each artifact, re-output the document with a status block as the first lines:

```
> ## ✅ STATUS: COMPLETE
> Marked complete by `/implementer` on <YYYY-MM-DD>.
```

If an artifact was only partially implemented, use:

```
> ## ⚠️ STATUS: PARTIAL
> Implemented: [X]. Remaining: [Y].
> Marked partial by `/implementer` on <YYYY-MM-DD>.
```

This prevents future agents from re-executing completed work.

---

### Step 8: Walkthrough & Completion

- Present a final diff summary and walk-through of the changes made.
- If commit-per-subtask was chosen, list all commits made during this session.

---

## Short/Raw Requests Gate

When the user provides a short, raw request without a designer handover:

- **Simple** (few files, single subsystem, trivial logic): Implement directly. No designer step needed.
- **Complex** (cross-tier, new feature, schema changes, multiple files): Refer back to the [/designer](.agents/workflows/designer.md) workflow first, then resume this workflow with those artifacts.
