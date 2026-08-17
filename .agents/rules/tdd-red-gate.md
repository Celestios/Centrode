## Autonomous TDD & Runtime Red Gate Rules

These rules enforce strict Test-Driven Development (TDD) across all coding and bug-fixing agents.

1. **TEST-FIRST ENFORCEMENT.** Never create or modify production code in `lib/` or `rust/src/` before a failing test exists in `test/` or `rust/tests/`.
2. **THE RUNTIME RED CHECKPOINT.** You must run `dart run scripts/quality/tdd_red_gate_validator.dart <test_file>` and confirm `RED_GATE_PASSED` before touching production files.
3. **NEVER WEAKEN ASSERTIONS.** If a test fails, you are strictly prohibited from changing expected values to match buggy code. Fix the production code.
4. **STACK TRACE ORIGIN CLASSIFICATION.** If the Red Gate returns `RED_GATE_SETUP_ERROR` (broken test harness, missing `Directionality`, uninitialized mock), fix the test setup first. Do not start implementing production code on a broken test harness.
5. **ZERO SURVIVING MUTANTS.** Every bug fix must include a test that fails when the original bug is re-introduced.
