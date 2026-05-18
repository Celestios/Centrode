---
description: Structured workflow to audit recent modifications (staged, unstaged, or branch comparison) using git diff to enforce architectural layers, detect bugs, and ensure style compliance.
---

# Workflow: /diff-audit

This workflow guides the agent to systematically audit code changes within the workspace using `git diff`. It ensures that modified files align with the project's architectural guidelines (e.g., Separation of Concerns, Single-Responsibility Principle, FFI safety boundaries), remain free of common bug patterns, and comply with the project's formatting, style, and testing expectations.

---

## Customizable Variables

When starting this workflow, the agent must check and allow the user to tweak the following configuration variables:

| Variable | Default Value | Description |
| :--- | :--- | :--- |
| `diff_target` | `working_tree` | The target for git diff: `working_tree` (staged + unstaged), `staged` (`--cached`), or a branch/commit name (e.g., `main`, `origin/main`). |
| `audit_level` | `thorough` | Depth of analysis: `thorough` (line-by-line logic & architectural analysis), `standard` (code quality, styling, and general checks), or `fast` (quick sanity check on changed files). |
| `focus_areas` | `all` | Core aspects to prioritize: `all`, `architecture` (separation of concerns, layer leaking), `bugs` (edge cases, async errors), `performance` (unnecessary rebuilds, heavy FFI), or `style` (naming, formatting, docs). |

---

## Steps

### 1. Change Discovery & Context Ingestion
- **Task**: Identify all modified files and retrieve the diff contents.
- **Action**:
  - Run `git status` to identify modified, staged, and untracked files.
  - Run the appropriate `git diff` command based on the chosen `diff_target` (e.g., `git diff` for unstaged, `git diff --cached` for staged, or `git diff <branch>` for branch comparison).
  - Categorize the changed files into architectural layers:
    - **Flutter UI / Presentation**: `lib/features/.../presentation/` or `ui/`
    - **Flutter State Engine / Store**: `lib/features/.../store/` or `engine/`
    - **Rust FFI Bridge**: `rust/src/...` or FFI definitions.
    - **Database & Persistence**: `rust/src/persistence/...` or `schema.surql`.
- **Output**: Present a high-level summary listing all changed files, grouped by layer, and list the active configuration variables.

### 2. Line-Level Code Quality & Bug Audit
- **Task**: Perform a surgical line-by-line inspection of the diff hunks for logical errors, edge cases, and typical bugs.
- **Action**:
  - Check for missing error handling and robust try-catch blocks in asynchronous Flutter calls or FFI interactions.
  - Check for incomplete implementation structures, placeholder code, or leftovers (e.g., debug print statements, leftover draft comments).
  - Verify range, boundary, and null safety conditions in modified logical/math structures (e.g., coordinate adjustments, gesture hit-tests).
  - Verify that async/await flows do not suffer from race conditions or unhandled future completions.

### 3. Architectural Boundary & SRP Audit
- **Task**: Enforce the separation of concern boundaries between layers.
- **Action**:
  - **Presentation Layer Boundaries**: Ensure no widgets contain raw domain state mutations, heavy file/DB I/O, or coordinate-system calculations.
  - **State Store Boundaries**: Ensure state controllers do not touch rendering primitives, paint context, or widgets.
  - **FFI Layer Safeguards**: Check that the FFI boundary handles serialization/deserialization safely, checks for Rust panic-safety, and manages memory boundaries without leaks.
  - **Persistence Schema Alignment**: Verify that schema updates (e.g., `schema.surql`) perfectly align with Dart representation models.

### 4. Audit Report Generation
- **Task**: Compile the findings into a clear, visually beautiful Markdown report.
- **Format Requirements**:
  - **Title**: `# 🔍 Git Diff Audit Report`
  - **Summary Block**: Display active parameters (`diff_target`, `audit_level`, `focus_areas`) and a brief high-level verdict.
  - **📂 Layer Compliance Breakdown**: Give a quick rating/status (e.g. `Excellent`, `Warning`, `Leaks Detected`) for each modified architectural layer.
  - **📋 Detailed Findings (File-by-File)**:
    - For each audited file, create a sub-heading with a clickable file link (e.g., `[view_state.dart](file:///d:/Projects/Open/flutter/code/mycelium/lib/features/graph/presentation/view_state.dart)`).
    - Group findings by severity:
      - `[CRITICAL]` - Logic bugs, crash vectors, FFI safety breaches.
      - `[WARNING]` - Architectural leaks (SRP violations), missing error handlers, potential memory leaks.
      - `[SUGGESTION]` - Refactoring improvements, readability enhancements, better async patterns.
      - `[INFO]` - Structural improvements, clean design highlights.
    - For each finding, list the specific line numbers with clickable line ranges (e.g. `[L45-L53](file:///d:/Projects/...#L45-L53)`).
  - **🛠️ Recommended Remedies**: List highly specific, actionable code recommendations to address the warnings or critical findings.

### 5. Interactive Action & Remediation
- **Task**: Allow the user to act on the audit report.
- **Action**:
  - Display the generated report and present the user with a set of interactive choices:
    1. **Auto-Apply Remedies**: Have the agent automatically implement the suggested improvements for the audited files.
    2. **Generate Tests**: Automatically draft unit or widget tests to verify the correctness of the modified logic.
    3. **Tweak Parameters**: Adjust variables (e.g., focus on `bugs` only, or compare against another target branch) and rerun the audit.
    4. **Approve & Commit**: Confirm that the diff is perfect, and transition directly to the `/git-commit` workflow to commit the changes.
    5. **Abort**: Finish the workflow.
  - **PAUSE** execution and wait for the USER'S choice or custom feedback.