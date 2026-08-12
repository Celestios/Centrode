---
trigger: always_on
description: Rules enforcing strict 3-tier layering, concern isolation, and cross-layer mutation boundaries.
---

## Architectural Bounds

Full tier definitions, responsibilities, folder mappings, and boundary enforcement rules are in [abstraction-levels.md](.agents/plugins/code-health/rules/abstraction-levels.md).

Quick reference:
- **Tier 1 (Presentation & Interface)**: `lib/features/graph/ui/` — rendering and layout only
- **Tier 2 (Interaction & Controllers)**: `lib/features/graph/presentation/`, `lib/features/graph/engine/` — transient state and coordination
- **Tier 3 (Core Domain & Storage)**: `lib/features/graph/store/`, `lib/features/graph/models/`, `rust/src/domain/`, `rust/src/persistence/` — business logic and persistence

Tier 3 MUST NEVER import Tier 1 or Tier 2. Tier 2 MUST NOT import Tier 1. UI widgets (Tier 1) must never make direct database queries or writes; they must emit events or commands to Tier 2 coordinators.
