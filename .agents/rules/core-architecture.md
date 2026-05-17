# Rule: Core Architecture

- You MUST adhere to the Hybrid Labeled Property Graph (LPG) pattern, utilizing standard nodes, temporal nodes, and reified relationships (intermediate nodes).
- You MUST implement interaction logic using the **Finite State Machine (State Pattern)** to manage canvas interactions and prevent complex conditional logic in UI widgets.
- You MUST encapsulate operations that modify graph data using the **Command Pattern** to support optimistic execution and mathematical rollback.
- You MUST use **Strategy Patterns** for styling to decouple rendering algorithms from domain elements.
- You MUST maintain a strict boundary between **Domain Truth** (persistent data) and **View State** (volatile UI state).
- You MUST utilize **Spatial Indexing** to achieve constant time complexity for rendering and hit-testing in the infinite canvas.
- You MUST implement **Passive-Reactive** behavioral node propagation entirely within the core logic layer, ensuring it is data-driven and stateless.
- You MUST execute all propagation logic as atomic, idempotent operations using database transactions.
