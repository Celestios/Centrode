# Mycelium Project General Context

This file serves as the permanent context for the Mycelium project, maintaining current development priorities and the foundational architectural "Lenses" discovered during reconnaissance.

## 1. Current Development Priorities
- **Rigorous Logging over Error Handling**: We prioritize detailed logging over complex error recovery.
  - **Dart**: Use `LogManager` (centralized in `lib/core/logging/log_manager.dart`).
  - **Rust**: Use `tracing` macros (`info!`, `warn!`, `error!`, `trace!`) which route logs through the FFI sink to the central `LogManager`.
- **Pre-Deployment Focus**: The project is not yet at a deployment or production state.
  - **Ignore Migration/Versioning**: Do not spend effort on database migrations or semantic versioning of APIs yet.
  - **No Tests**: Automated testing is not a priority for now; focus on feature development and architectural integrity.

## 2. The Linguistic Lens (Semantics & Ontology)
- **Hybrid Labeled Property Graph (LPG)**: Blends formal Ontology with user-driven Folksonomy.
- **Node Fragments**: `INode` (standard), `TaskNode` (temporal), `InterNode` (Reified Relationships).
- **Directional Edges**: Mapping SurrealDB `in`/`out` pointers.

## 3. The Logical Lens (Set Theory & Data Structures)
- **Spatial Hash Grid**: Constant time complexity for rendering loops.
- **ViewState Pattern**: Strict separation between Mathematical Domain Truth and Volatile View State.

## 4. The Computer Science Lens (Architecture & Patterns)
- **FFI Resilience**: Process crash prevention using `ffi_guard!` and session-based resurrection logic.
- **Finite State Machine (FSM)**: Used in `InteractionController` to bypass standard Flutter event ambiguity.
- **Command Pattern & Write-Behind**: Optimistic execution with mathematical rollback.
- **Actor Pattern Logging**: Isolate-based batching and pre-stream buffering in Rust.
- **Offline-First Packaging**: MessagePack serialization in `.celi` archives.

## 5. Key Developer Philosophies
- "The central logger is the first port of call for debugging."
- "Performance Trumps Framework Idioms."
- "The Database is the Final Arbiter of Truth."
- "Assume Asynchrony Will Fail."
