# Future Plans: Passive-Reactive Architecture

## 1. Behavioral Node Propagation
As discussed in the Dr. Aris consultancy report, behavioral nodes (e.g., `InterNode` with `inhibiting` or `active` features) will follow a **Passive-Reactive** model.

### Key Principles
*   **Rust-Level Execution:** All propagation logic (e.g., $A \to B \to C$) resides strictly in the Rust core.
*   **Data-Driven:** Nodes do not possess agency. They store metadata (e.g., timestamps, states) that the core logic interprets.
*   **Stateless Triggering:** The app layer handles secondary effects (like notifications) by observing timestamps or state changes saved in the database.

### Implementation Requirements
*   **Atomicity:** Use SurrealDB transactions to ensure the entire propagation chain is written as a single Unit of Work.
*   **Idempotency:** Propagation logic must be safe to re-run. Updates should be idempotent to prevent "Double Inhibition" or state drift during retries.
*   **Causality Tracking:** Store the ID of the "Triggering Node" within the affected node's metadata to prevent feedback loops and provide an audit trail.

## 2. Terminology Guardrails
To maintain the "Meta-Node" philosophy without developer confusion:
*   **Graph Tier:** Use the term **Node** (e.g., `INode`, `TaskNode`, `InterNode`).
*   **Content Tier:** Use the terms **ContentBlock** and **InlineElement**.
