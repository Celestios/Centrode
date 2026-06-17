---
description: Step-by-step bug investigation pipeline with subagent analysis, controlled test widgets, and automated execution. Always operates at maximum debugging intensity.
---

# Workflow: /bug-fixer

Active execution pipeline for diagnosing and fixing bugs. Every step is mandatory and produces a checkpoint before advancing. There is no "normal" vs "panic" mode — this workflow IS the maximum intensity debugging mode.

## Core Principles

1. **Find the problem before fixing it.** Never implement a fix without confirmed root cause.
2. **Maximum instrumentation always.** Extensive debug prints, runtime checks, and log statements across all suspected paths — every time, not just when escalated.
3. **Subagent validation.** Hypotheses are tested by independent subagents before being accepted.
4. **All errors to terminal.** No silent failures. Every investigation step prints progress and findings.
5. **Preserve test artifacts.** Test widgets are never deleted — bugs can return.
6. **Pause for consent.** Never modify project files until user approves the fix plan.

## Debug Print Rules

| Location | Created | Removed after fix? |
|---|---|---|
| Test widgets (`test/bug_fix/`) | Always | No — preserved for regression |
| Main code (upstream investigation) | When bug is upstream | Yes — after user confirms fix |

Test widget debug prints are ignored by the analyzer. Main code debug prints must be cleaned up after fix.

## Test Widget Types

- **Automatic** — agent runs `flutter run`, captures logs, kills process after timeout. No user interaction needed.
- **User-intervention** — agent builds and launches, user interacts with the widget to reproduce the issue, then reports back.

Choose the type based on whether the bug requires human interaction to trigger (e.g., gesture, specific UI state) or can be reproduced programmatically.

---

## Phase 1: Understand & Reproduce

### Step 1: Receive description

The user provides an error message, crash log, or bug description. Read it carefully. Identify keywords, error codes, related file names, and stack traces.

**Output:** Summarize what the user described — the symptom, any error messages, and initial guesses about where to look.

### Step 2: Initial code trace

Search the codebase for relevant code paths:
- Use `grep` for error messages, exception types, function names from the description
- Use `glob` to find related files
- Read the relevant code and trace the execution flow leading to the reported issue
- Identify the most likely affected components

**Output:** List of files/lines involved, the execution flow, and initial hypothesis about widget-level vs upstream.

### Step 3: Clarify (conditional)

After the initial trace, assess whether the description is sufficient to proceed:
- If the code path is clear and the description is specific → skip this step
- If the description is ambiguous, the code has many branches, or you can't determine the trigger condition → ask the user ONE targeted question about the exact situation that causes the bug

Use `compose:ask` with specific options derived from the code paths you found.

### Step 4: Path A — Test Widget Investigation

Create a test widget that isolates the suspected component:

1. Create `test/bug_fix/` directory if it doesn't exist
2. Create a test widget file that:
   - Imports and renders the suspected component in isolation
   - Injects extensive debug prints: widget lifecycle (initState, build, dispose), state changes, error callbacks, constraint values, animation values
   - Uses `debugPrint` for all instrumentation (respects Flutter's logging)
   - Wraps the component in error-catching widgets where appropriate
3. Choose widget type:
   - **Automatic** if the bug can be triggered without user interaction (e.g., on build, on timer, on data load)
   - **User-intervention** if the bug requires specific user actions (e.g., tap sequence, scroll, gesture)
4. Run the widget:
   - Automatic: execute `flutter run -d <device>` via bash, capture terminal output, kill process after 30s or when sufficient logs are captured
   - User-intervention: build and launch, instruct the user what to do, wait for their report
5. Parse the output for errors, exceptions, unexpected state values

**If errors found in the test widget:** The bug is at widget level. Proceed to Phase 2 with this evidence.

**If the test widget runs clean:** The bug is in upstream logic. Proceed to Step 5.

### Step 5: Path B — Upstream Logic Investigation

The bug is not in the widget itself but in the data flow, state management, services, or Rust backend that feeds it.

1. Add extensive debug prints to the upstream code:
   - Function entry/exit with parameter values
   - State variable values before and after mutations
   - Error conditions and catch blocks
   - Control flow branches (which path is taken)
   - Data transformation steps
2. Run the application (or the relevant test) and capture output
3. Trace the upstream logic using the debug output to find where the data diverges from expected

**Output:** The exact upstream location where the bug originates, with debug print evidence.

### Checkpoint 1

Output a structured report:
- **Files/lines involved:** exact locations
- **Reproduction steps:** how to trigger the bug
- **Error output:** exact terminal output showing the problem
- **Path taken:** widget-level (Path A) or upstream (Path B)
- **Evidence:** specific debug print output that shows the failure

Do NOT proceed to Phase 2 until Checkpoint 1 is complete and printed to terminal.
