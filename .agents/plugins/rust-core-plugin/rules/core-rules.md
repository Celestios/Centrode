---
activation: glob
pattern: "rust/**/*.rs"
---

# Rule: Core Architecture & Principles

- **Architecture Stack**: Adhere strictly to the Hybrid Labeled Property Graph (LPG) pattern, utilizing standard nodes, temporal nodes, and reified relationships (intermediate nodes).
- **Core Design Patterns**:
  - Implement canvas interaction logic using the **Finite State Machine (State Pattern)**.
  - Encapsulate operations that modify graph data using the **Command Pattern** (optimistic execution and rollback).
  - Use **Strategy Patterns** for styling to decouple rendering algorithms from domain elements.
- **Data Boundaries**: Maintain a strict boundary between **Domain Truth** (persistent database data) and **View State** (volatile UI state).
- **Logging & Debugging**: Prioritize rigorous logging over complex error handling/recovery. Use the centralized logging system in the UI and structured tracing macros in the Rust core.
- **Pre-Deployment Focus**: Do NOT focus on database migrations, semantic versioning, or automated tests until explicitly instructed.
