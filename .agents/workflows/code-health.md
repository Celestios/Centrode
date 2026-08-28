---
description: Multi-agent deep audit of the entire codebase for SOLID principles, design pattern fitness, DRY compliance, complexity hotspots, and architectural boundary enforcement using arch-mcp.
---

# Workflow: /code-health

This workflow transforms the agent into a **Principal Code Health Auditor**. It performs a comprehensive, multi-agent analysis of the codebase across the 8 dimensions defined in [code-audit-checklist.md](.agents/plugins/code-health/rules/code-audit-checklist.md), mediated by [design-tensions-reference.md](.agents/plugins/code-health/rules/design-tensions-reference.md) and [symmetrical-design](.agents/skills/design/symmetrical-design/SKILL.md).

It leverages arch-mcp for graph discovery and the [dimension-auditor](.agents/plugins/code-health/skills/dimension-auditor/SKILL.md), [architecture-auditor](.agents/plugins/code-health/skills/architecture-auditor/SKILL.md), and [symmetry-checker](.agents/plugins/code-health/skills/symmetry-checker/SKILL.md) skills for parallel cognitive auditing.

---

## Core Mandates

1. **Audit-First Discovery**: Run `audit()` to scan for automated layer/tier violations and gather files for the audit queue.
2. **Deep Semantic AI Scanning**: The CLI cache tools are only for indexing and filtering. Subagents **MUST** use the `view_file` tool to read the complete source code of every file in the audit queue.
3. **Multi-Dimensional Analysis**: Files are evaluated across all 8 dimensions in [code-audit-checklist.md](.agents/plugins/code-health/rules/code-audit-checklist.md).
4. **Dynamic Subagent Allocation**: Batch target files and spawn dimension-clustered subagents strictly according to the allocation algorithm in [dimension-auditor](.agents/plugins/code-health/skills/dimension-auditor/SKILL.md).
5. **Context-Aware Auditing**: Surrounding context (enclosing class, parent classes, annotations, imports, sister methods) must be inspected alongside modified/target lines.
6. **Actionable Output**: Every finding must adhere to the standardized schema in [code-health-report-template.md](.agents/plugins/code-health/rules/code-health-report-template.md). Do NOT propose remediation code during the audit phase.

---

## Execution Steps

### Step 1: Calibration

Read the project's own configuration to understand project-specific baselines:
1. **`analysis_options.yaml`**: Disabled lint rules and analyzer settings.
2. **`AGENTS.md`**: Architectural patterns and intentional deviations.
3. **`.arch/config.json`**: Defined layers, tiers, and dependency constraints.
4. **`pubspec.yaml`** / **`Cargo.toml`**: Language and framework constraints.

**Output**: A Calibration Baseline (5–10 bullets) capturing the project's own standards.

### Step 2: Refresh Graph & Automated Assertions

Use arch-mcp tools:
- Run automated compliance scan via `audit()` to detect tier/layer/dependency violations.
- Build the **Audit Queue** from:
  - Files with `VIOLATION_DETECTED` or `PENDING_AUDIT` status.
  - Complexity hotspots identified via `lookup`/`context` (public API counts $\ge 15$, file lines $> 500$).

### Step 3: Dead Code Discovery

Use arch-mcp's `impact` tool to identify public symbols with zero upstream callers:
- **High confidence**: 0 upstream callers AND not referenced in tests AND not a `main()` entry point.
- **Medium confidence**: 0 upstream callers but public API.
- **Low confidence**: Graph-based detection only.

Add dead code candidates to the Audit Queue for subagent semantic confirmation.

### Step 4: Knowledge Graph Analysis

Incorporate arch-mcp insights into the audit queue:
- **God Nodes**: High-centrality files with high blast radius.
- **Surprising Connections**: Cross-community edges indicating hidden coupling.
- **Community Structure**: Cohesion assessment across feature directories.

### Step 5: Test Coverage Cross-Reference

For each Tier 2/3 file in the Audit Queue, verify associated test files:
- Dart: `lib/.../foo.dart` $\rightarrow$ `test/.../foo_test.dart`
- Rust: `rust/src/.../foo.rs` $\rightarrow$ `rust/tests/.../foo.rs` or `#[test]` modules.

Tag each file with `has_test`. Untested files with high change frequency or high centrality are flagged as **Untested Hotspots**.

### Step 6: Contextual Enrichment

For each file in the Audit Queue, gather context from the arch-mcp database:
- Use `lookup` and `context` to retrieve file layer, tier, purity, and dependencies.
- Use `compile_context` on high-risk files to assess blast radius.
- Load the language-specific and architectural references:
  - [code-audit-checklist.md](.agents/plugins/code-health/rules/code-audit-checklist.md)
  - [design-tensions-reference.md](.agents/plugins/code-health/rules/design-tensions-reference.md)
  - [abstraction-levels.md](.agents/plugins/code-health/rules/abstraction-levels.md)
  - [symmetrical-design](.agents/skills/design/symmetrical-design/SKILL.md)
  - [dart-coding](.agents/skills/coding/dart-coding/SKILL.md) (for Dart) or [rust-coding](.agents/skills/coding/rust-coding/SKILL.md) & [rust-style-guide.md](.agents/plugins/rust-core-plugin/rules/rust-style-guide.md) (for Rust).

### Step 7: Multi-Agent Deep Audit (Delegated Verification)

Apply the dispatch protocol from [dimension-auditor](.agents/plugins/code-health/skills/dimension-auditor/SKILL.md):
1. **Group Files**: Group files in scope by feature/directory relevance without small remainder batches (< 8 files).
2. **Spawn Subagents**: Dynamically allocate subagents per batch based on file count as defined in `dimension-auditor`.
3. **Construct Custom Prompts**: Populate the subagent prompt template from `dimension-auditor` with `{CONTRAST_RULES}` and `{RULES & REFERENCES}`.
4. **Subagent Execution**: Subagents evaluate dimensions in contrast using `view_file` and return standardized JSON arrays matching the audit schema.

### Step 8: Synthesize & Report

1. Collect and deduplicate JSON findings from all subagents.
2. Compile the consolidated markdown report adhering to [code-health-report-template.md](.agents/plugins/code-health/rules/code-health-report-template.md).
3. Present the completed Code Health Report to the user with prioritized next steps for remediation in `/implementer` or `/bug-fixer`.health/rules/abstraction-levels.md) for full enforcement rules.
