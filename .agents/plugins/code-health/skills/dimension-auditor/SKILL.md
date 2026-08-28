---
name: dimension-auditor
description: Dynamic subagent batching, dimension clustering, and subagent prompt generation for code health audits.
---

# Dimension Auditor & Subagent Dispatch Protocol

This skill governs how the Master Agent calculates audit scope, groups files into smart batches, determines subagent counts per batch, and constructs custom prompts for parallel cognitive auditing.

---

## 1. Scope & Smart Batching

1. **Group Files by Relevance**: Group target files (`N_total`) by feature area or directory proximity (e.g. `lib/features/graph/ui/`, `lib/features/graph/store/`, `rust/src/domain/`).
2. **No Small Remainder Batches**: Never create a separate batch for a small leftover group (< 8 files). Intelligently absorb remainder files into existing batches, even if a batch slightly exceeds 20 files.

### Batching Allocation Examples:
* **`N_total = 12` files** $\implies$ 1 batch of 12 files
* **`N_total = 25` files** $\implies$ 1 batch of 25 files (or 2 batches of ~12–13 files if completely unrelated feature areas)
* **`N_total = 45` files** $\implies$ 2 batches of ~22–23 files
* **`N_total = 65` files** $\implies$ 3 batches of ~21–22 files *(absorbs remainder files across 3 batches instead of creating a 4th tiny batch)*

---

## 2. Dynamic Subagent Allocation per Batch

For each batch, spawn subagent clusters in parallel based on its file count (`F_batch`):

### 🔹 1 to 8 files $\implies$ 2 Subagents
1. **Architecture & SOLID**: Tier Boundaries + SOLID + Pattern Fitness
2. **Cohesion & Quality**: DRY + Structural Symmetry + Complexity + Test Coverage

### 🔹 9 to 15 files $\implies$ 3 Subagents
1. **Architecture & Class Design**: Tier Boundaries + SOLID
2. **Cohesion & Symmetry**: DRY + Structural Symmetry
3. **Robustness & Verification**: Complexity + Error/Async Safety + Test Coverage

### 🔹 16+ files $\implies$ 4 Subagents
1. **Macro Architecture & Boundaries**: Tier Isolation + FFI Boundaries + DIP
2. **Micro Class Design & Patterns**: SOLID Principles + Design Pattern Fitness
3. **Cohesion, Symmetry & DRY**: DRY Duplication + Structural Symmetry
4. **Robustness, Complexity & Tests**: Complexity/Bloat + Error Safety + Test Coverage

---

## 3. Subagent Prompt Construction Protocol

The Master Agent constructs each subagent prompt dynamically using this structure:

```markdown
You are a specialized Code Health Auditor. Perform a cognitive audit of the assigned files against the assigned dimension cluster.

ASSIGNED DIMENSION CLUSTER: {CLUSTER_NAME}
Principles to analyze in contrast: {CONTRAST_RULES}

TARGET FILES:
{FILE_PATH_LIST}

RULES & REFERENCES:
- file://.agents/plugins/code-health/rules/code-audit-checklist.md
- file://.agents/plugins/code-health/rules/design-tensions-reference.md
- file://.agents/plugins/code-health/rules/abstraction-levels.md
- file://.agents/skills/design/symmetrical-design/SKILL.md
- file://{LANGUAGE_SPECIFIC_RULES}

MASTER AGENT CUSTOM INSTRUCTIONS & SPECIFICATIONS:
{CUSTOM_MASTER_NOTES_AND_CONTEXT_FILLED_ENTIRELY_BY_MASTER_AGENT}

INSTRUCTIONS:
1. Use `view_file` to inspect the full source code of every assigned file.
2. Read the referenced rule documents (`code-audit-checklist.md`, `design-tensions-reference.md`, `abstraction-levels.md`, and `symmetrical-design/SKILL.md`).
3. Evaluate assigned dimensions in contrast — analyze how principles trade off against each other using Symmetry as the mediating meta-principle.
4. DO NOT propose remedies, fixes, or refactored code. Report ONLY what is broken.
5. Output a JSON array of findings only.

OUTPUT FORMAT:
[
  {
    "file": "relative/path/to/file.dart",
    "line_range": "L10-L25",
    "symbol": "ClassName.methodName",
    "principle": "Violated Principle Name",
    "tension": "e.g. SRP vs Cohesion (if applicable)",
    "severity": "Critical | Warning | Info",
    "confidence": "High | Medium | Low",
    "finding": "Description of the broken contract or violation",
    "what_would_confirm": "Additional check needed if confidence is Medium/Low"
  }
]
```

---

## 4. Synthesis & Handoff

1. Collect JSON array findings from all subagents across all batches.
2. Deduplicate findings and compile the consolidated Code Health Report using `.agents/plugins/code-health/rules/code-health-report-template.md`.
3. Hand off the clean findings list directly to chat or downstream fix workflows (`/implementer` or `/bug-fixer`).
