---
trigger: always_on
description: Rules enforcing strict 3-tier layering, concern isolation, and cross-layer mutation boundaries.
---

## Architectural Bounds

This project enforces strict decoupling and layer boundaries across UI, interaction, and database tiers.

Rules:
- **3-Tier Isolation**:
  - **Tier 1 (UI Canvas)**: Rendering, drawing, canvas paints, toolbar overlays, and view presentation.
  - **Tier 2 (Presentation & Interaction)**: View controllers, gesture interceptors, FSM state machines, and FFI event dispatching.
  - **Tier 3 (Domain & Persistence)**: SurrealDB database schemas, Rust core structs, file format models, FFI bridge serialization.
- **Import Restrictions**: Lower tiers must NEVER import or depend on higher tiers (Tier 3 cannot depend on Tier 1/2; Tier 2 cannot depend on Tier 1).
- **Mutation Boundaries**: UI widgets (Tier 1) are strictly forbidden from performing inline database writes or queries. They must emit commands or events to Tier 2 coordinators.
