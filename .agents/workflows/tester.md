---
description: Guided workflow to design behavioral specifications, write hermetic contract/FSM tests, run mutation testing, and enforce agentic quality gates.
---

# Workflow: /tester

This workflow guides the design, authoring, and verification of unit, contract, FSM, and backend tests across the bilingual Centrode workspace (Dart/Flutter + Rust/SurrealDB).

---

## Testing Principles & Constraints

1. **CSIV Topology & Boundary Enforcement:** The Test Spec Agent must never modify production source code (`lib/`, `rust/src/`). It authors tests based strictly on behavioral specifications and public API contracts.
2. **Anti-Mocking by Default:** NEVER create raw mock objects (e.g. `MockGraphApi`, `MockInteractionContext`). Use:
   - `InMemoryGraphApi` (`lib/features/graph/store/in_memory_graph_api.dart`) for graph storage/streaming.
   - `FakeInteractionContext` & `GestureTestHarness` (`test/helpers/gesture_test_harness.dart`) for canvas gesture tests.
   - `Surreal::new::<Mem>(())` for Rust backend persistence.
3. **No Wall-Clock Delays:** Never use `Future.delayed()` or `sleep()`. Use `fakeAsync` or `GestureTestHarness.advanceTime()`.
4. **Non-Vacuous Assertions:** Every test must contain meaningful state or property assertions. `expect(true, isTrue)` and unawaited `expectLater` are strictly forbidden.

---

## Execution Steps

### Step 1: Target Contract Analysis & Specification
- Identify the target subsystem (Domain logic, Graph FSM, Persistence, FFI Bridge, Layout Engine).
- Formulate behavioral invariants, boundary cases, and contract properties (Arrange-Act-Assert).

### Step 2: Language & Architectural Skills
- For Dart/Flutter tests: View and activate [.agents/rules/test-architecture.md](.agents/rules/test-architecture.md) and [.agents/skills/coding/dart-coding/SKILL.md](.agents/skills/coding/dart-coding/SKILL.md).
- For Rust backend tests: View and activate [.agents/skills/coding/rust-coding/SKILL.md](.agents/skills/coding/rust-coding/SKILL.md).

### Step 3: Test Harness & Double Selection
- **Persistence / Store:** Use `InMemoryGraphApi` or run `graph_api_contract_suite.dart`.
- **Canvas / Gestures:** Use `GestureTestHarness` to step through discrete pointer events with virtual timestamps.
- **FFI Boundary:** Design round-trip serialization tests against `proptest` generators or golden JSON vectors.
- **Rust Backend:** Use `TestContext` with in-memory SurrealDB (`Surreal::new::<Mem>(())`).

### Step 4: Implement Test Suites
Write hermetic tests in the canonical directories:
- Dart unit/contract/widget: `test/features/<feature>/`, `test/shared/contract_suites/`, `test/bug_fix/`
- Dart integration: `integration_test/`
- Rust backend: `rust/tests/` or inline `#[cfg(test)]` modules

### Step 5: Autonomous Verification & Quality Gates
Execute automated validation scripts:
1. **AST Smell Gate:**
   ```bash
   dart run scripts/quality/dart_test_smell_visitor.dart
   ```
2. **Runtime Red Gate (for new feature/bug stubs):**
   ```bash
   dart run scripts/quality/tdd_red_gate_validator.dart <test_file_path>
   ```
3. **Test Suite Execution:**
   - Dart: `flutter test <test_file_path>`
   - Rust: `cd rust && cargo test`
4. **Diff-Scoped Mutation Gate:**
   ```bash
   cd rust && cargo mutants --in-diff "git diff origin/main...HEAD"
   ```

### Step 6: Presentation
- Summarize tested contract invariants, state transitions, and mutation survival results.
