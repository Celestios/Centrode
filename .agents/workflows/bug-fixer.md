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

---

## Phase 2: Hypothesis Formation & Subagent Analysis

### Step 6: Form hypotheses

Based on the evidence from Phase 1, form 2-3 root cause hypotheses. For each:
- What code path would fail
- What state or data would be wrong
- What condition triggers the failure

**Output:** Numbered list of hypotheses with the evidence supporting each.

### Step 7: Spawn subagents (parallel)

Dispatch subagents in a SINGLE message — all run in parallel.

**IMPORTANT:** Every subagent prompt MUST include the instruction that they are **read-only** — they must NOT modify, create, or delete any files. Their sole job is to analyze code and report findings.

**Hypothesis tester subagents (one per hypothesis):**
- Use `subagent_type: "explore"` for each
- Each subagent receives ONE hypothesis and the relevant code files
- Task: independently verify or eliminate the hypothesis by reading code, tracing paths, checking edge cases
- Output per subagent: `CONFIRMED` / `ELIMINATED` / `INCONCLUSIVE` with evidence

**Blameless reviewer subagent (one):**
- Use `subagent_type: "general"` 
- Task: critically examine the suspected code from a fresh perspective
- Defend existing design assumptions — argue why the code might be correct
- Flag fragile dependencies, race conditions, null references, edge cases
- Output: findings about code quality, assumptions that might be wrong, alternative explanations

Example dispatch (3 hypotheses):
```
[Agent call 1: hypothesis 1 tester, subagent_type="explore"]
[Agent call 2: hypothesis 2 tester, subagent_type="explore"]
[Agent call 3: hypothesis 3 tester, subagent_type="explore"]
[Agent call 4: blameless reviewer, subagent_type="general"]
```

All four in one message. Wait for all to complete.

### Checkpoint 2

Output a structured report:
- **Hypothesis verdicts:** each hypothesis with CONFIRMED/ELIMINATED/INCONCLUSIVE and key evidence
- **Reviewer findings:** what the blameless reviewer found — assumptions questioned, fragile points identified
- **Confidence ranking:** ordered list of remaining hypotheses by confidence level

Do NOT proceed to Phase 3 until Checkpoint 2 is complete and printed to terminal.

---

## Phase 3: Root Cause Confirmed

### Step 8: Confirm root cause

Select the highest-confidence hypothesis that survived both subagent scrutiny (hypothesis testers confirmed, reviewer found no fatal flaws).

Explain:
- The confirmed root cause with evidence
- The "why" — not just what broke, but why the design allows this failure
- Impact scope: what else could be affected by this bug or its fix

### Checkpoint 3

Output a structured report:
- **Confirmed root cause:** exact location and mechanism
- **Causal chain:** step-by-step from trigger to failure
- **Impact assessment:** other components or features that might be affected

Do NOT proceed to Phase 4 until Checkpoint 3 is complete and printed to terminal.

---

## Phase 4: Proposed Fix (Pause for Consent)

### Step 9: Present fix plan

Describe the architectural or logic changes required to fix the root cause:
- What files need to change and how
- Any side effects or trade-offs of the proposed fix
- Whether the fix addresses the root cause or just the symptom

Present the FULL investigation report combining all three phases:
- Phase 1 evidence (trace, error output, path taken)
- Phase 2 analysis (hypothesis verdicts, reviewer findings)
- Phase 3 confirmation (root cause, causal chain, impact)

**HARD GATE:** Do NOT modify any project files until the user explicitly gives approval ("Go ahead", "Fix it", etc.).

---

## Phase 5: Implement, Verify, Confirm

### Step 10: Apply the fix

Implement the agreed-upon changes to the project files:
- For Dart/Flutter components: View and activate the [dart-coding](.agents/skills/coding/dart-coding/SKILL.md) skill.
- For Rust core/DB components: View and activate the [rust-coding](.agents/skills/coding/rust-coding/SKILL.md) skill.
- Ensure that you follow the project's coding standards, layer boundaries, and autogeneration triggers from the first line of the fix.


### Step 11: Verify the fix

Re-run the original reproduction method:
- If Path A was used: re-run the test widget and confirm the error no longer appears
- If Path B was used: re-run the application with the same conditions and confirm the bug is gone
- Check for any new errors or regressions in the output

### Step 12: Confirm and clean up

1. Confirm the fix addresses the root cause without introducing new issues
2. **Debug print cleanup:**
   - Test widget files: KEEP all debug prints (ignored by analyzer, preserved for regression)
   - Main code debug prints (from Path B upstream investigation): REMOVE after user confirms fix works
3. Ask the user explicitly: "Do you want to clean up the debug prints added to the main code?"
4. Only remove main code debug prints upon user's explicit confirmation
5. Provide a summary of all changes made

---

## Error Visibility

ALL errors, exceptions, debug prints, and investigation progress go to terminal output. The agent prints findings at every checkpoint. No silent failures — if a step produces no evidence, say so explicitly and explain why.

## Process Termination

When running test widgets or the application automatically:
- Set a 30-second timeout for automatic widgets
- Kill the process after capturing sufficient log output
- If the process hangs, kill it and report what was captured before the hang
- For user-intervention widgets, wait for the user's signal that they've completed interaction
