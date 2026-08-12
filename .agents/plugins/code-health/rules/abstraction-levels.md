---
activation: always_on
---

# Rule: Abstraction Levels & Architectural Bounds

You MUST adhere to strict abstraction levels. Code must never leak between these layer tiers.

## 3-Tier Architecture

### Tier 1: Presentation & Interface (Lowest)
- **Folders**: `lib/features/graph/ui/`
- **Responsibility**: Rendering, drawing, canvas paints, toolbar overlays, view presentation, FFI bridge mapping, input event translation.
- **Restriction**: MUST NOT contain domain state mutation logic, direct database/persistence commands, or core business calculations. UI widgets are strictly forbidden from performing inline database writes or queries — they must emit commands or events to Tier 2 coordinators.

### Tier 2: Interaction, Processing & Controllers
- **Folders**: `lib/features/graph/presentation/`, `lib/features/graph/engine/`
- **Responsibility**: View controllers, gesture interceptors, FSM state machines, FFI event dispatching, state coordination, command patterns, orchestration.
- **Restriction**: MUST NOT paint UI widgets directly or perform raw database modifications.

### Tier 3: Core Domain, Services & Storage (Highest)
- **Folders**: `lib/features/graph/store/`, `lib/features/graph/models/`, `rust/src/domain/`, `rust/src/persistence/`
- **Responsibility**: SurrealDB database schemas, Rust core structs, file format models, FFI bridge serialization, business logic, transactions, core entity validation.
- **Restriction**: MUST NOT depend on or import UI presentation packages, styling managers, or external delivery channels. Dependency inversion must be strictly respected.

## Boundary Enforcement

A higher tier MUST NOT import or depend on a lower tier (Tier 3 cannot depend on Tier 1/2; Tier 2 cannot depend on Tier 1).

When modifying code:
1. Identify the tier of the file you are editing.
2. Ensure you do not add dependencies to components belonging to lower-tier layers.
3. Keep logic clean and focused on the single responsibility of that tier.
4. Any action that modifies persistent state from Tier 1 MUST be wrapped in a Command Object (Command Pattern) or delegated strictly to Tier 2.
