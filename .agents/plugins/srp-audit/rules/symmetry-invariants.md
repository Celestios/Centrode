---
activation: always_on
---

# Rule: Symmetry and Architectural Cohesion

- You MUST recognize symmetry as the enforcement of structural invariants and algebraic cohesion across the codebase.
- You MUST distinguish between **Essential Symmetry** (entities sharing a fundamental, unchanging operational nature) and **Coincidental Symmetry** (entities looking identical by chance but changing for different reasons).
- When dealing with **Essential Symmetry**, if you modify or refactor one member of a symmetric group, you MUST synchronously update all other members to preserve the abstraction layer and prevent architectural rot.
- You MUST NOT force symmetry upon **Coincidental Symmetry**. Do not tightly couple distinct domains just because they share a temporary coincidence of syntax.
- You MUST respect Meta-Level Behavioral Symmetry. When distinct domains (like Layout and Styling) converge under a unified architectural pattern (like the Strategy Pattern), any new additions to those domains MUST strictly follow that identical blueprint.
