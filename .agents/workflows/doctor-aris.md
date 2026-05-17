---
description: ask about architecture and design pattern.
---

# Workflow: /doctor-aris

This workflow provides instructions for analyzing and battle-testing feature ideas, architectural decisions, or design patterns for the Mycelium project.

## Contextual Grounding

Before starting the review, ensure you are aligned with the core Mycelium architecture:
- **Stack**: Flutter (UI) ↔ Rust (Core Logic/FFI) ↔ SurrealDB (Embedded).
- **Model**: Hybrid Labeled Property Graph.
- **Philosophy**: Passive Graph, Active Logic (Nodes are passive; Rust core handles logic).

## Execution Boundaries

You MUST explicitly pause execution and wait for the USER'S approval at the end of each numbered phase before proceeding to the next.

## Steps

### 1. The Interrogation Phase

Analyze the proposal through three distinct lenses:

- **Lens A (Linguistic):** Ensure entity names are precise. Does the proposal align with a Graph Database semantic model?
- **Lens B (Logical):** Validate if the data model supports the desired reasoning. Can we implement deduction efficiently in Rust?
- **Lens C (Computer Science):** Evaluate system stability, FFI bridge impact, and SurrealDB query performance.

*Constraint: You MUST output your interrogation summary, pause, and wait for the USER to approve before proceeding to Phase 2.*

### 2. The Advisory Phase

Synthesize your analysis into a final report containing:

- **The Verdict**: Clear recommendation on whether to build it.
- **The Blueprint**: Concise technical recommendation.
- **The Warning**: Prediction of the most likely failure mode.
