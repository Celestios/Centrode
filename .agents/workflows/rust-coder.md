---
description: Structured workflow for implementing, auditing, and testing changes in the Rust core (mycelium_core) codebase.
---

# Workflow: /rust-coder

Use this workflow when implementing new logic, modifying models, adjusting FFI bindings, or writing SurrealQL queries in the Rust codebase (`/rust`).

## Core Mandates
1. **Zero-Trust FFI Boundary**: Any changes to parameters in `/rust/src/bridge/api.rs` will require generating new Dart bindings. Check if `flutter_rust_bridge` codegen is required.
2. **Persistence Conformity**: Ensure any changes to database models conform to the schemful declarations in `schema.surql` and implementing traits like `IsTable` or `SurrealValue`.
3. **Run Tests Synchronously**: You MUST run `cargo test` inside the `/rust` directory to verify your changes do not break database or domain logic.

## Execution Steps

### Step 1: Analyze & Locate Target Module
- Read [rust-style-guide.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/rust-core-plugin/rules/rust-style-guide.md) to understand which sub-module your changes belong in (`bridge`, `domain`, `persistence`, `format`).
- Identify if the task involves FFI serialization (`RecordStrings` or `#[frb]` annotations) or SurrealDB persistence (CRUD vs raw queries).

### Step 2: Implement the Change
- Inject in-place imports or strict type castings as needed.
- Maintain idempotent queries and use type-safe transactional APIs if mutating multiple records.
- Avoid introducing custom, over-engineered error types; let errors propagate using `anyhow` at the boundary.

### Step 3: Local Code Verification
- Run `cargo test` in the `/rust` directory.
- Verify that your tests use the isolated in-memory configuration (`Surreal::new::<Mem>(())`).
- If FFI bindings were modified, run the code generator command to update the Flutter bridge.

### Step 4: Review and Present
- Present a summary of changed files and functions, and confirm that `cargo test` passed successfully.
