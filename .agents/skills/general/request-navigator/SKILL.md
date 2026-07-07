---
name: request-navigator
description: Activate this starting skill at the beginning of every task to analyze incoming user requests, classify them, handle iteration vs pivots, and route to the correct workflow.
---

# Skill: Request Navigator

This skill is the central dispatcher and router for every message in the Mycelium workspace. 

## Global Compliance

At the start of any task, you MUST read and enforce all instructions within [global.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/rules/global.md) and [AGENTS.md](file:///d:/Projects/Open/flutter/code/mycelium/AGENTS.md).

## Request Classification & Routing


Upon receiving a message from the user, evaluate the message and classify it into one of the following interaction patterns:

### Case A: Initial Task Request
- **Criteria**: The user initiates a new task, feature request, bug fix, or workspace command at the start of a session or after completing a previous task.
- **Action**: Follow the **Dispatching Protocol** below to route the user's request to the appropriate workflow.

### Case B: Iterative Update / Follow-up to Current Task
- **Criteria**: The user provides additional details, answers an interrogation question, gives feedback on a plan, or approves a draft.
- **Action**: **Completely bypass the Dispatching Protocol.** Refer directly to the steps of the currently active workflow (e.g., `/designer` or `/implementer` or `/bug-fixer`) to determine the next action based on the user's input.

### Case C: Complete Task Pivot / Context Switch
- **Criteria**: The user completely changes their request mid-stream to something unrelated before the current task is completed or committed.
- **Action**:
  1. Recognize that the current task is being abandoned.
  2. Determine the necessary clean-up procedure: guess what files need to be reverted/deleted, check `git status`, or ask the user how to clean up the workspace (e.g., stashing changes, discarding local branch modifications).
  3. Execute the clean-up.
  4. Once clean-up is done, treat the new request as a fresh **Case A (Initial Task Request)** and route it accordingly.

### Case D: General One-off Inquiry
- **Criteria**: The user asks an explanatory, informational, or investigatory question (e.g., "where is the FFI configuration?", "explain how node rendering is handled") without requesting code modifications.
- **Action**: **Do NOT launch any workflow.** Directly research the codebase and answer the user's question concisely.

### Case E: Explicit Cancellation or Reversion
- **Criteria**: The user explicitly requests to cancel, abort, or revert all current changes in the workspace, without starting a new task.
- **Action**:
  1. Confirm the clean-up scope with the user or determine the appropriate reset command (e.g., discarding modified files).
  2. Revert the workspace to the clean baseline.
  3. Confirm the workspace is clean and await the next request.


---

## Dispatching Protocol (For Case A)

If the request is classified as **Case A (Initial Task Request)**, route the task to exactly ONE of the following core workflows:

1. **/brain-stormer** (Feature & UX Ideation)
   - *Scope*: Concept design, comparing ideas, zero-input project analysis.
   - *Target*: [.agents/workflows/brain-stormer.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/workflows/brain-stormer.md)

2. **/designer** (Architecture & Visual Design)
   - *Scope*: Custom paints, spring motion parameters, database schema changes, FFI boundary interfaces, architecture blueprints.
   - *Target*: [.agents/workflows/designer.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/workflows/designer.md)

3. **/implementer** (Coding & Refactoring)
   - *Scope*: Writing new logic, implementing approved plan blueprints, standard code refactoring.
   - *Target*: [.agents/workflows/implementer.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/workflows/implementer.md)

4. **/bug-fixer** (Diagnose & Debug)
   - *Scope*: Investigating crashes, fixing styling bugs, solving exceptions.
   - *Target*: [.agents/workflows/bug-fixer.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/workflows/bug-fixer.md)

5. **/code-health** (Quality Auditing)
   - *Scope*: SOLID review, DRY analysis, design symmetry compliance checks.
   - *Target*: [.agents/workflows/code-health.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/workflows/code-health.md)

6. **/git-commit** (Git Staging & Releases)
   - *Scope*: Commit drafting, version bumps, release tags.
   - *Target*: [.agents/workflows/git-commit.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/workflows/git-commit.md)

7. **/tester** (Testing & Test Coverage)
   - *Scope*: Designing mocks, writing unit/widget/integration/Cargo tests, and increasing code coverage.
   - *Target*: [.agents/workflows/tester.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/workflows/tester.md)

8. **/perf-profiler** (Performance & Tuning)
   - *Scope*: Profiling canvas rendering frames, analyzing repaint boundaries, tuning gesture processing lag, and optimizing database query transactions.
   - *Target*: [.agents/workflows/perf-profiler.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/workflows/perf-profiler.md)

9. **/documenter** (Documentation & Specifications)
   - *Scope*: Drafting API specs, system documentation, README files, and updating architecture logs.
   - *Target*: [.agents/workflows/documenter.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/workflows/documenter.md)



---

## Action Items

1. State clearly to the user which Case you have identified.
2. If launching a workflow, state which workflow is selected and follow its steps.
