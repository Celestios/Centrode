---
description: Unified workflow for analyzing feature proposals, battle-testing architecture, planning data flows, and implementing code changes.
---

# Workflow: /principal-architect

This workflow combines consultative design interrogation with structured implementation. It guides the agent through analyzing feature requests, challenging architectural assumptions, planning data flows, writing clean code, and verifying correctness.

---

## Core Mandates
1. **Separation of Concerns**: Strictly maintain the boundary between Tier 1 (UI Canvas), Tier 2 (Interaction Environment), and Tier 3 (Domain Store).
2. **YAGNI & Readability**: Implement *only* what is explicitly requested. Prioritize clean, readable code over micro-optimizations unless performance bottlenecks are proved.
3. **Execution Boundaries**: You MUST explicitly pause execution and wait for the USER'S approval at the end of each numbered phase before proceeding to the next.

---

## Execution Phases

### Phase 1: Architectural Interrogation (The Consultation)
Analyze the feature proposal through three distinct lenses to identify flaws before writing code:
- **Lens A (Linguistic)**: Ensure precise naming. Does the entity modeling fit a Graph Database semantic model (standard nodes, temporal nodes, or reified relationships)?
- **Lens B (Logical)**: Can the business logic be calculated cleanly and state-lessly on the Rust core side? Does the data model support efficient propagation or indexing?
- **Lens C (Computer Science/Performance)**: Assess the FFI bridge serialization overhead, potential SurrealDB transaction bottlenecks, and rendering performance costs (e.g. BackdropFilters).
- *Constraint: Output your Interrogation Summary, pause, and wait for the USER to approve or iterate on the design before proceeding.*

### Phase 2: Architectural Planning
Draft the blueprint for implementation:
- **Abstraction Mapping**: List all files you plan to modify or create, tagging each with its abstraction tier (`[Tier 1: Canvas UI]`, `[Tier 2: Interaction]`, `[Tier 3: Domain/Store]`).
- **Symmetry Check**: Ensure new functions or helper classes align with existing patterns (e.g., Command Pattern for mutations, State Pattern for canvas gestures).
- **Execution Blueprint**: Detail the data flow (how events propagate from the UI through FFI to the database) and changes to `schema.surql` if any database tables are affected.
- *Constraint: Present the detailed Implementation Plan, pause, and wait for the USER to approve the plan before modifying any files or running commands.*

### Phase 3: Implementation & Coding
Execute the approved plan:
- Apply the code modifications surgically to the target files, preserving unrelated comments/docstrings.
- Ensure that UI widgets do not perform inline database modifications (enforce `/plugins/code-health/rules/no-cross-layer-mutation.md`).
- Ensure Rust code modifications adhere to `/plugins/rust-core-plugin/rules/rust-style-guide.md`.

### Phase 4: Verification & Testing
- Run verification tests to ensure the workspace builds and behaves correctly:
  - If Rust code was changed, run `cargo test` using the isolated in-memory engine.
  - If FFI interfaces were changed, execute the code generation script to update bindings.
- Present a final diff summary and walk-through of the changes made.
