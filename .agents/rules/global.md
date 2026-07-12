---
trigger: always_on
description: Global development rules — hard constraints, zero tolerance.
---

## Global Development Rules

These are absolute rules. No exceptions. No "just this once."

1. **ZERO FALLBACKS.** No fallbacks. No defensive alternatives. No graceful degradation. If the expected path fails, it fails visibly.
2. **NO BACKWARD COMPATIBILITY.** Do not preserve old interfaces, old field names, old behavior for the sake of existing consumers. Delete and replace. Update call sites. Move forward only.
3. **TESTS DO NOT JUSTIFY KEEPING CODE.** If a test suite covers something that should be removed, delete the tests too. Test coverage is not a reason to keep dead or wrong code around.
4. **NO ERROR HANDLING.** Do not wrap calls in try/catch. Do not add if-error-then-fallback logic. Do not suppress exceptions. Let it crash. The stack trace is the error handling.
5. **NO MIGRATIONS.** Do not write database migrations. Do not add schema evolution logic. Modify the schema definition and regenerate. The system is the source of truth, not a changelog.
6. **USE THE PROJECT'S LOGGING.
   - **Dart:** `final _log = Logger('ClassName');` via `package:logging`. `LogManager` singleton at `lib/infrastructure/telemetry/`.
   - **Rust:** `use tracing::{info, debug, warn, error};`. `TelemetryLayer` at `rust/src/telemetry.rs` streams to Flutter via FFI.
7. **DO NOT TRUST COMMENTS.** Comments are not documentation. They are almost always stale, misleading, or wrong. Unless a comment was written by the agent(you) in this exact session, treat it as unreliable. Read the actual code to understand what it does.

8. **CRITICAL THINKING, NOT BLIND EXECUTION.** The agent must critically evaluate every user request. Do not assume the user's request is correct, optimal, or complete. If there is ambiguity, a logical flaw, a contradictory instruction, a better approach, or a potential issue with the requested change, STOP and discuss it with the user before proceeding. Blind compliance is not helpful — thoughtful skepticism is. Always ask "is this actually the right thing?" before doing it.

9. If a request or execution step is not explicitly defined in the active workflow, output a warning to the user pinpointing exactly where the instruction was undefined, then proceed with the most logical action to fulfill the request.
