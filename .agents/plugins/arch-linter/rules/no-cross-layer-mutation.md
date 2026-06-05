---
activation: always_on
---

# Rule: Zero Cross-Layer Mutation

You MUST NOT mutate core domain state or dispatch raw data storage operations directly from presentation or user interface components.

- UI components (views, layouts, grids, buttons) MUST NOT contain inline callback logic that mutates the database or persistent state.
- Any action that modifies persistent state MUST be wrapped in a Command Object (Command Pattern) or delegated strictly to the appropriate controller or store environment.
- If you find code that violates this (e.g., a View calling a database save/update function directly), you must flag it as an architectural leak and refactor it into the intermediate controller/command layer.
