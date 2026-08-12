---
name: feature-ideator
description: Activate this skill when brainstorming new features, generating user experience flows, analyzing project capabilities, or comparing functional paths.
---

# Skill: Feature Ideator

Use this skill when brainstorming, proposing, or refining new features and design ideas for the Centrode workspace.

## Core Directives

### 1. Zero-Input Context Scanning

Do not ask the user for context or scope initially. Proactively scan:

- UI components in `lib/features/graph/ui/`
- Database schema and persistence files in `rust/src/`
- Rules and styles in `.agents/rules/` and plugins.

### 2. Design Concept Proposals

Develop distinct concept proposals. Each concept must cover:

- **Concept Name**: Creative and descriptive.
- **Problem & Value**: Why this adds immediate value.
- **Aesthetic & Motion Plan**: HSL palettes, glassmorphism parameters, spring properties, and interaction behaviors.
- **Architectural Footprint**:
  - `[Tier 1: Presentation & Interface]`: Custom paints, layout updates, interactive nodes. LOWEST tier.
  - `[Tier 2: Interaction & Controllers]`: Gesture bindings, Command patterns, FFI events.
  - `[Tier 3: Core Domain & Storage]`: SurrealDB schema additions, Rust core data structures. HIGHEST tier.

### 3. Verification & Cautions

- Identify potential Single Responsibility Principle (SRP) crossings.
- Define design symmetry patterns (e.g. alignment of commands or FSM states).
- Analyze performance bottlenecks (BackdropFilter repaint boundaries, serialization overhead).

### 4. Comparison & Choice Matrix

Create a Markdown table comparing the proposed concepts:

- **Dimensions**: UX Impact, Implementation Complexity, Performance Impact, and Tiers Involved.
