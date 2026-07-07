---
description: Guided workflow to brainstorm new workspace features, UI designs, refactorings, and architectural patterns.
---

# Workflow: /brain-stormer

This workflow guides features, design patterns, refactoring pathways, and architectural brainstorming in the Mycelium workspace. It functions as a decision tree to classify the brainstorming target, consult with specialists, and align on a conceptual direction.

---

## Core Mandates

1. **Maximize Creativity**: Emphasize giving highly creative, out-of-the-box ideas, patterns, and architectural options.
2. **Warn, Do Not Filter**: Do NOT enforce constraints or filter out any ideas or design patterns because they clash with existing workspace conventions. Propose them anyway, but output a clear warning highlighting where they diverge from conventions. The *only* filtering factor is the set of explicit constraints specified by the user in the request.
3. **Iterative Discussion**: Support an active dialogue, answering any user questions about the proposed options and iterating on the details.
4. **Hard Gate**: Once the user has selected options for all aspects of the brainstorm, write the chosen options to the `chosen_options.md` artifact and stop to obtain final confirmation before initiating the `/designer` workflow.

---

## Execution Phases

### Phase 1: Classify Brainstorming Target & Identify Constraints
Evaluate the user's inquiry and classify it into one of the following brainstorming branches:

#### Branch A: New Feature Proposal
- *Focus*: Introducing entirely new capabilities, UI modules, or interactive components.
- *Specialized Skill*: View and activate [feature-ideator](file:///d:/Projects/Open/flutter/code/mycelium/.agents/skills/design/feature-ideator/SKILL.md).

#### Branch B: Design Pattern Selection
- *Focus*: Determining structural patterns for a feature (e.g., Strategy, Command, FSM state machine).
- *Specialized Skill*: View and activate [ui-designer](file:///d:/Projects/Open/flutter/code/mycelium/.agents/skills/design/ui-designer/SKILL.md) and [architecture-designer](file:///d:/Projects/Open/flutter/code/mycelium/.agents/skills/design/architecture-designer/SKILL.md).

#### Branch C: Refactoring & Architectural Ideas
- *Focus*: Restructuring existing code, improving SOLID compliance, fixing DRY duplicates, or changing abstraction levels.
- *Specialized Skill*: View and load [architecture-auditor](file:///d:/Projects/Open/flutter/code/mycelium/.agents/plugins/code-health/skills/architecture-auditor/SKILL.md).

*Note: Incorporate ONLY the explicit constraints provided by the user in their request.*


---

### Phase 2: Design Concept Generation
- Generate highly creative, distinct options/paths.

- If any option diverges from standard conventions (e.g., `AGENTS.md` rules, layer decoupling, or schema patterns), label it clearly with a **Convention Warning** rather than discarding it.
- Detail the layout parameters, FFI structures, and database traits for each option.
- Propose options to the user and request feedback.

---

### Phase 3: Designer Subagent Consultation (Optional)
- For complex architectural choices or gesture systems, you may spawn a subagent of type `self` to adopt the `/designer` workflow persona to review and improve the options before presentation.

---

### Phase 4: Discussion & Iteration Loop
- Engage in an active, iterative dialogue with the user.
- Answer their questions about the options (e.g., complexity, visual limits, performance trade-offs, extension points).
- Iterate and refine the options based on user feedback.
- Continue this discussion loop as long as aspects of the choices remain open.

---

### Phase 5: Chosen Options Artifact & Gate
- Once the user has finalized their choice for all aspects of the feature/architecture:
  1. Create a `chosen_options.md` artifact in the brain artifacts directory summarizing the selected choices, features, and target architectures.
  2. Present the summary to the user.
  3. **HARD GATE**: Request final confirmation to proceed to `/designer`. Do NOT launch the `/designer` workflow until the user approves this final summary.
