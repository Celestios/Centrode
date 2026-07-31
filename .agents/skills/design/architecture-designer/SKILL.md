---
name: architecture-designer
description: Activate this skill when defining design patterns, structuring software abstractions, mapping class hierarchies, and detailing command/FSM state machines.
---

# Skill: Architecture Designer

Use this skill when designing technical layouts, database schemas, command patterns, or FFI bindings in the Centrode workspace.

## Core Directives

### 1. Abstraction Mapping

Detail all components and files to be created or modified, tagging each with its architectural tier:

- `[Tier 1: Canvas UI]` - Presentation widgets, paints, overlays.
- `[Tier 2: Interaction/Presentation]` - Controllers, command handlers, gesture engines.
- `[Tier 3: Domain/Store]` - Rust domain structs, SurrealQL schema models, persistence modules.

### 2. Design Symmetry Check

Verify that the proposed architecture aligns with existing workspace patterns:

- Use the **Command Pattern** for state mutations (for undo/redo support).
- Use the **State Pattern** for interactive UI gestures (canvas panning, zoom, node resizing).
- Ensure class names, folder paths, and file operations match sibling features.

### 3. Execution Blueprint

Draft the event propagation flow:

- Detail how inputs or UI gestures propagate from Tier 1 to Tier 2.
- Define FFI calls, bridge models, and serialization methods to Tier 3.
- Map out the exact database schema additions or mutations and specify SurrealQL query transactions.
