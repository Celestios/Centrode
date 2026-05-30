---
description: Structured workflow for automatically analyzing the project and brainstorming new feature and design ideas.
---

# Workflow: /feature-ideator

This workflow directs the agent to perform an automated, zero-input inspection of the current workspace and generate high-fidelity, context-aware feature and design concepts based on existing application capabilities, spatial UI plugin rules, and architectural boundaries.

---

## Core Mandates

1. **Zero-Input Project Contextualization**: Do not ask the user for context or scope. Proactively scan the directories (e.g., `lib/`, `rust/src/`, schemas, themes) to understand what components exist and where features can be enhanced.
2. **Constraint & Style Alignment**: Ideas must align strictly with:
   - [smart-glass.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/spatial-ui/rules/smart-glass.md) (Glassmorphism 2.0 aesthetics).
   - [motion-performance.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/spatial-ui/rules/motion-performance.md) (Repaint boundary conventions and spring physics).
   - [abstraction-levels.md](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/srp-audit/rules/abstraction-levels.md) (3-tier architecture: Canvas UI, Interaction, Domain Store).
3. **Idea Triad**: Generate exactly 3 distinct, creative feature or UX improvements ranging in complexity and focus (e.g., one visual polish, one structural tool, one interactive system).
4. **SRP, Symmetry, & Performance Safeguards**: For each concept, explicitly identify potential Single Responsibility Principle (SRP) boundary crossings, design symmetry alignment, and performance hotspots (BackdropFilter limits, FFI bandwidth, and SurrealDB query complexity).
5. **Actionable Roadmap**: End with a structured comparison matrix and direct action items, making it seamless for the user to choose an idea and transition directly to development.

---

## Execution Steps

### Step 1: Automated Workspace & Rules Audit
- Scan the directory structure and recent files (e.g. graph layout, database schema, undo/redo state, toolbars) to build a mental map of what is currently built.
- Check active plugins, workflows, and rules to understand aesthetic and architectural expectations.
- Identify 3 areas ripe for innovation or refinement (e.g., canvas navigation, node attributes, command palette extensions, visual transitions).

### Step 2: Ideation & Concept Generation
Brainstorm 3 concrete, premium feature ideas. For each idea, detail:
- **Concept Name**: Creative and descriptive name.
- **Problem Solved & Value**: Why this adds immediate value to the user experience.
- **Visual Design & Motion Dynamics**:
  - HSL colors, glassmorphic layout, backdrop filter rules.
  - Spring-based animations, micro-interactions, responsive canvas feedback.
- **Architectural Footprint**:
  - `[Tier 1: Canvas UI]`: Widgets, custom paints, and layout changes.
  - `[Tier 2: Interaction]`: Gesture listeners, command patterns, FFI bridge events.
  - `[Tier 3: Domain/Store]`: Database tables, queries, Rust core data structures.
- **SRP & Symmetry Cautions**:
  - Analyze SRP compliance using [architecture-auditor](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/srp-audit/skills/architecture-auditor/SKILL.md) guidelines.
  - Define symmetry patterns (e.g. aligning undo commands, matching widget controller lifetimes) using [symmetry-checker](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/srp-audit/skills/symmetry-checker/SKILL.md) guidelines.
- **Performance & Bottleneck Analysis**:
  - Evaluate potential FFI bridge serialization overhead or database transaction blocks.
  - Identify rendering bottlenecks (e.g. BackdropFilters or repaint limits) and mitigation strategies.

### Step 3: Comparison & Choice Matrix
Summarize the 3 concepts in a clear, scannable Markdown table:
- **Dimensions**: UX Impact, Implementation Complexity, Performance Impact (Repaint/FFI overhead), and Core Tier Involvement.
- Present a final prompt inviting the user to select one of the ideas (or combine them) to immediately initiate the `/principal-architect` or `/ui-designer` workflow for implementation.
