---
description: Guided workflow to implement approved designs, write clean code, and verify changes via tests.
---

# Workflow: /implementer

This workflow is used when executing code changes, feature implementations, and refactoring tasks. It delegates language-specific styles to programming skills and governs tests and builds.

## Execution Steps

### Step 1: Target Identification & Plan Review
- Review the approved design blueprint or task description.
- **Short/Raw Requests Gate**: If the user provides a short, raw feature or refactor request instead of an approved design blueprint, you MUST implicitly refer back to the [/designer](file:///d:/Projects/Open/flutter/code/mycelium/.agents/workflows/designer.md) workflow first to design the architecture, context, and plans before writing any code.
- Identify all target files to create or modify.


### Step 2: Implement Code Changes
- Determine the languages involved:
  - For Dart/Flutter changes: View and activate the [dart-coding](file:///d:/Projects/Open/flutter/code/mycelium/.agents/skills/coding/dart-coding/SKILL.md) skill.
  - For Rust core changes: View and activate the [rust-coding](file:///d:/Projects/Open/flutter/code/mycelium/.agents/skills/coding/rust-coding/SKILL.md) skill.
- Ensure all code conforms strictly to [solid-principles](file:///d:/Projects/Open/flutter/code/mycelium/.agents/rules/solid-principles.md) (SRP, OCP, LSP, ISP, DIP, DRY), respects the [architectural-bounds](file:///d:/Projects/Open/flutter/code/mycelium/.agents/rules/architectural-bounds.md) (layer boundaries), and aligns with [symmetrical-design](file:///d:/Projects/Open/flutter/code/mycelium/.agents/skills/design/symmetrical-design/SKILL.md) guidelines.


- Apply code changes surgically. Keep changes focused and clean, preserving unrelated comments/docstrings.
- **Rule**: Follow style guidelines (layer boundaries, no UI database calls, no manual schema changes, no custom error fallbacks) from line one.


### Step 3: Code Generation & Binding Rebuilds
- If any models, annotated classes, domain structures, or FFI bridge endpoints changed, run the code generators:
  ```bash
  flutter pub run build_runner build --delete-conflicting-outputs
  ```
- Ensure that the build finishes with zero errors.

### Step 4: Verification & Test Execution
- Do NOT automatically run test suites. Prompt the user for permission first if you wish to verify changes:
  - For Dart/Flutter changes, ask to run: `flutter test`
  - For Rust core changes, ask to run: `cd rust && cargo test`
- If the user approves, execute the command and fix any compilation or test failures. If not, skip and proceed to Step 5.


### Step 5: Walkthrough & Completion
- Present a final diff summary and walk-through of the changes made.
