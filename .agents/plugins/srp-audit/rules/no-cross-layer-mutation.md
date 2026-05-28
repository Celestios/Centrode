---
activation: always_on
---

# Rule: Zero Cross-Layer Mutation

You MUST NOT mutate domain state or dispatch data storage operations directly from View or UI components.

- UI components (like `GraphCanvas` or buttons) MUST NOT contain inline callback logic that mutates the database or saves templates.
- Any action that modifies persistent state MUST be wrapped in a Command Object (Command Pattern) or delegated strictly to the appropriate controller (e.g., via a `CommandRegistry` or an `InteractionContext`).
- If you find code that violates this (e.g., `GraphCanvas` calling a save function directly to the database), you must flag it as an architectural leak and refactor it into the Interaction or Command layer.
