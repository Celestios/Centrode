---
activation: always_on
---

# Rule: Abstraction Levels

You MUST adhere to strict abstraction levels. Code must never leak between these layer tiers. The specific folders, extensions, and responsibilities for each tier are defined in `graphify-out/arch/config.json`.

## General Architecture Tiers

### Tier 1: Presentation & Interface (e.g., UI, FFI Bridge, API Endpoints)
- **Responsibility**: Handles user interaction, external calls, FFI mapping, rendering UI components, and input event translation.
- **Restriction**: MUST NOT contain domain state mutation logic, direct database/persistence commands, or core business calculations.

### Tier 2: Interaction, Processing & Controllers (e.g., State Managers, Orchestrators)
- **Responsibility**: Coordinates workflows, handles gestures, commands, queries, and acts as the intermediate translation layer between Tier 1 and Tier 3.
- **Restriction**: MUST NOT paint UI widgets directly or perform raw database modifications.

### Tier 3: Core Domain, Services & Storage (e.g., Entities, Repositories, Database Models)
- **Responsibility**: Manages persistent application truth, business logic, transactions, and core entity validation.
- **Restriction**: MUST NOT depend on or import UI presentation packages, styling managers, or external delivery channels. Dependency inversion must be strictly respected.

## Boundary Enforcement

The Architectural Linter automatically enforces these boundaries based on the tiers defined in `graphify-out/arch/config.json`. A higher tier (e.g., Tier 3) MUST NOT import or depend on a lower tier (e.g., Tier 1 or Tier 2).

When modifying code:
1. Identify the tier of the file you are editing.
2. Ensure you do not add dependencies to components belonging to lower-tier layers.
3. Keep logic clean and focused on the single responsibility of that tier.
