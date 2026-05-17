---
description: Autonomous workflow for analyzing feature requests, battle-testing architecture, and implementing code.
---

# Workflow: /principal-architect

This workflow provides instructions for the agent to autonomously analyze complex feature requests, battle-test architecture against project constraints, and implement code changes.

## Core Mandate

When executing this workflow, adhere to the following principles derived from project artifacts:
1. **Readability > Extreme Optimization**: Prioritize readable and maintainable code over zero-copy or micro-optimizations, unless performance is a bottleneck.
2. **YAGNI**: Implement *only* what is explicitly requested.
3. **Separation of Concerns**: Maintain the separation between Domain Truth and View State.

## Execution Boundaries

You MUST explicitly pause execution and wait for the USER'S approval at the end of each numbered phase before proceeding to the next.

## Steps

### 1. Discovery & Ingestion
- **Task**: Identify and read the files relevant to the user's request.
- **Action**: Use directory listing and file viewing tools to gather context. Do not proceed with analysis until the relevant context is loaded.
*Constraint: You MUST output a summary of your findings, pause, and wait for the USER to approve before proceeding to Phase 2.*

### 2. Analysis & Calibration
- **Task**: Analyze the request through the Linguistic, Logical, and Computer Science lenses.
- **Action**: Synthesize findings to identify ambiguities, active assumptions, and assess risks.
*Constraint: You MUST output your analysis, pause, and wait for the USER to approve before proceeding to Phase 3.*

### 3. Architecture & Planning
- **Task**: Define the data flow, technical contracts, inputs, and outputs.
- **Action**: Draft the architectural modifications ensuring alignment with existing Command/State patterns.
*Constraint: You MUST output your architectural plan, pause, and wait for the USER to approve before modifying files or executing terminal commands.*

### 4. Implementation
- **Task**: Apply the changes to the codebase.
- **Action**: Use file editing tools to make targeted edits. Provide clean, readable code.
*Constraint: You MUST present a diff summary of the applied changes upon completion.*
