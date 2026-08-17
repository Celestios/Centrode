## Test Architecture & Quality Rules

These rules govern all unit, widget, integration, and backend tests in Centrode.

1. **NO RAW MOCKS FOR DOMAIN ENGINES.** Never create `class MockGraphApi extends Mock` or `MockInteractionContext`. Use `InMemoryGraphApi`, `FakeInteractionContext`, and `TestGraphBuilder`.
2. **COPY-ON-WRITE & REAL TRANSACTION SEMANTICS.** In-memory test doubles must emulate the exact transaction rollback and cascading deletion behaviors of native Rust SurrealDB.
3. **HERMETIC & VIRTUAL-TIME GESTURES.** Canvas gesture and interaction tests must never use `Future.delayed` or `sleep()`. Use `GestureTestHarness` with explicit virtual timestamps and deterministic frame stepping.
4. **ZERO TEST SMELLS.** Every test must contain at least one valid, non-vacuous assertion or verification. Unawaited `expectLater` and `expect(true, isTrue)` are strictly prohibited.
5. **DUAL-RUN CONTRACT PARITY.** Any changes to `GraphApi` or persistence APIs must be verified by `graph_api_contract_suite.dart` against both `InMemoryGraphApi` and native Rust in-memory SurrealDB (`Surreal::new::<Mem>(())`).
