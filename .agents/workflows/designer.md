---
description: Structured workflow to design UI/UX, database schemas, and application architecture patterns.
---

# Workflow: /designer
This workflow coordinates detailed visual UI designs, motion mapping, database schemas, and software architectures. It is a highly context-aware, iterative workflow designed to produce multiple tailored artifacts (context reports and design specifications) based on the user's progressive descriptions, prior to writing any source code.

---

## Core Mandates

1. **Deep Context Gathering**: Start by researching target files, database models, and existing interfaces. Understand the codebase layout before proposing any architectural changes.
2. **Context Report Artifacts**: Before drafting designs, write one or more **Architecture Context Reports** (`architecture_context_<aspect>.md`) describing the current system's structures, schemas, and FFI setups relevant to the task.
3. **No Code Execution**: Focus strictly on styling rules, schema models, API interfaces, and layouts. Do NOT write or modify any project code files during this workflow.
4. **Design-Only Output**: This workflow produces **design artifacts only** — context reports, visual specifications, interaction mappings, and architectural layouts. It does NOT produce implementation plans, task lists, or code roadmaps. The `/implementer` workflow is responsible for creating the implementation plan and task decomposition.
5. **Iterative & Plural Designs**: Design the features component-by-component. Generate **multiple specific design artifacts** as the user provides progressive specifications and design iterations.
6. **Hard Gates**: Stop and wait for the user's explicit confirmation at the end of each design iteration and context report phase before proceeding.

---

## Artifact Naming Convention

- `architecture_context_<aspect>.md` — Context reports describing current system state
- `design_<subsystem>.md` — Design specifications for a specific subsystem (UI, schema, interaction, etc.)
- Do NOT use filenames containing `implementation_plan`, `task_list`, `roadmap`, or similar — those belong to the implementer.

---

## Execution Phases

### Phase 1: Context Discovery & Baseline Reports
- Deeply inspect the codebase to understand the current architecture surrounding the task.
- Generate one or more **Architecture Context Reports** as brain artifacts outlining:
  - Affected modules, file dependencies, and structural boundaries.
  - Existing database tables, indexes, and queries.
  - Parity constraints and design symmetry models.
- *Constraint: Present the Architecture Context Reports, then pause and wait for the USER's validation before proceeding.*

---

### Phase 2: Iterative Design & Plural Design Artifacts
- Engage in an iterative loop as the user describes features and requirements progressively.
- For each distinct component, tier, or subsystem, create or refine specialized design artifacts. These artifacts describe **what** to build and **how** it should look/behave — not the step-by-step implementation sequence.
- Align designs with the respective architectural guidelines:
  - **Visual & UI mockups**: Adhere to [ui-designer](file:///d:/Projects/Open/flutter/code/mycelium/.agents/skills/design/ui-designer/SKILL.md) guidelines (HSL colors, glassmorphic depths, spring physics).
  - **FFI & Logic structures**: Adhere to [architecture-designer](file:///d:/Projects/Open/flutter/code/mycelium/.agents/skills/design/architecture-designer/SKILL.md) guidelines (Command patterns, state patterns).
  - **Architectural boundaries**: Adhere to [architectural-bounds](file:///d:/Projects/Open/flutter/code/mycelium/.agents/rules/architectural-bounds.md) guidelines (3-tier isolation, no cross-layer database mutations from the UI).
  - **Design symmetry**: Adhere to [symmetrical-design](file:///d:/Projects/Open/flutter/code/mycelium/.agents/skills/design/symmetrical-design/SKILL.md) guidelines (symmetrical commands, file structures, lifecycles).
  - **Persistence schemas**: Model SurrealDB tables, fields, transaction queries, and trait representations (no manual edits to `schema.surql`) according to [persistence-schemas](file:///d:/Projects/Open/flutter/code/mycelium/.agents/skills/design/persistence-schemas/SKILL.md).
  - **Gesture & Interaction FSM**: Map gesture recognizers, event bubbling hierarchies, and state machine transitions using [gesture-interaction-fsm](file:///d:/Projects/Open/flutter/code/mycelium/.agents/skills/design/gesture-interaction-fsm/SKILL.md).
  - **Package & Package Format (.celi)**: Model data zip compression archives, directory hierarchies, and file-system serialization structures using [package-format-celi](file:///d:/Projects/Open/flutter/code/mycelium/.agents/skills/design/package-format-celi/SKILL.md).
  - **Physics & Layout Simulation**: Define force-directed canvas node math, link forces, and boundary restrictions using [physics-layout-simulation](file:///d:/Projects/Open/flutter/code/mycelium/.agents/skills/design/physics-layout-simulation/SKILL.md).
  - **Telemetry & Diagnostics**: Define structured warning/error logs, metrics hooks, and tracing schemas using [telemetry-diagnostics](file:///d:/Projects/Open/flutter/code/mycelium/.agents/skills/design/telemetry-diagnostics/SKILL.md).

- *Constraint: Present the newly generated or modified design artifacts, then pause and wait for the USER's feedback. Repeat this phase for every iteration.*

---

### Phase 3: Final Alignment & Handover Gate
- Summarize all context reports and finalized design artifacts created during this workflow.
- **Handover Output**: Explicitly package and list all created design artifacts and context reports. These documents are the primary output of this workflow and MUST be handed over directly to the `/implementer` stage.
- Present the list of target codebase files to be modified (identified during context discovery).
- **HARD GATE**: Request final confirmation from the user. Do NOT transition to the `/implementer` workflow until the user explicitly approves the entire set of design artifacts and output documents.
