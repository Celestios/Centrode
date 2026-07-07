---
description: Guided workflow to design mocks, write unit/widget/integration/Cargo tests, and increase code coverage.
---

# Workflow: /tester

This workflow guides the design, implementation, and execution of unit, widget, integration, and backend tests in the Mycelium workspace.

## Execution Steps

### Step 1: Target Analysis & Test Scope
- Locate the source components that require testing.
- Determine the scope: unit testing (state logic, FFI parsing), widget testing (UI canvas behaviors), integration testing (canvas gestures to DB), or Rust unit/integration tests.
- Identify existing sibling tests to maintain structural and styling symmetry.

### Step 2: Enforce Coding Standards
- Based on the language of the component:
  - For Dart/Flutter tests: View and activate the [dart-coding](file:///d:/Projects/Open/flutter/code/mycelium/.agents/skills/dart-coding/SKILL.md) skill.
  - For Rust backend tests: View and activate the [rust-coding](file:///d:/Projects/Open/flutter/code/mycelium/.agents/skills/rust-coding/SKILL.md) skill.

### Step 3: Mocking & Setup Design
- Design mock dependencies and test data.
- Ensure that Rust persistence tests use an isolated in-memory DB configuration (`Surreal::new::<Mem>(())`).
- Avoid introducing flaky timers or dynamic external network requests.

### Step 4: Implement Test Suites
- Write the tests, following the naming and file location conventions:
  - Dart unit/widget: `test/features/<feature_name>/`
  - Dart integration: `integration_test/`
  - Rust tests: either inline `#[cfg(test)]` modules or inside `rust/tests/`.
- Ensure all test classes and mocks compile cleanly.

### Step 5: Verification & Run Approval
- Do NOT run test commands automatically. Ask the user if they would like you to execute the tests:
  - Dart: `flutter test`
  - Rust: `cd rust && cargo test`
- If the user approves, run the tests and address any failures. If they decline, proceed.

### Step 6: Presentation
- Summarize the written test scenarios, assertions, and mocked paths.
