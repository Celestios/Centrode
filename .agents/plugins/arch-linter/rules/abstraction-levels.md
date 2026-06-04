---
activation: always_on
---

# Rule: Abstraction Levels

You MUST adhere to strict abstraction levels. Code must never leak between these layers:

### Dart (Flutter) Codebase Tiers
1. **Tier 1: High-Level UI / View (e.g., GraphCanvas)**
   - **Responsibility**: Rendering UI components, layout orchestrations, and visual user feedback.
   - **Restriction**: MUST NOT contain domain state mutation logic, direct database/FFI calls, or low-level mathematical coordinate calculations.
   - **Interaction**: Delegates actions to Interaction Controllers or Environments.

2. **Tier 2: Interaction Environment (e.g., CanvasInteractionEnvironment)**
   - **Responsibility**: Managing the state of user interactions (panning, selecting, zooming), processing gestures, and housing helper functions (e.g., `getScale()`).
   - **Restriction**: MUST NOT paint UI widgets or directly touch database storage. Acts as the intermediate bridge.

3. **Tier 3: Domain / Store (e.g., GraphDataController)**
   - **Responsibility**: Managing persistent application truth, database interactions, and graph nodes.
   - **Restriction**: MUST NOT listen to or depend on UI concerns (e.g., Theme Controllers, UI state). Dependency inversion is forbidden here.

### Rust (Core) Codebase Tiers
1. **Tier 1: FFI Bridge / External Gateway (e.g., `rust/src/bridge`)**
   - **Responsibility**: FFI entry points, real-time event streams, log streams, type mapping/serialization for bridge transactions.
   - **Restriction**: MUST NOT house persistence engine commands or core domain rules directly.

2. **Tier 2: Persistence Engine (e.g., `rust/src/persistence`)**
   - **Responsibility**: Database repository abstractions, connection setups, transaction handlers, SurrealDB query executions, and history tracking.
   - **Restriction**: MUST NOT depend on or import FFI bridge packages/modules.

3. **Tier 3: Domain Core / Shared Utilities (e.g., `rust/src/domain`, `rust/src/format`, `rust/src/telemetry`)**
   - **Responsibility**: Core entities (nodes, relations, tags), database schemas, traits, serializing, formatting, and logging telemetry.
   - **Restriction**: MUST NOT import or depend on persistence engine or FFI bridge modules.

When modifying code, explicitly state which abstraction layer the file belongs to, and ensure your additions do not pull responsibilities from other tiers.
