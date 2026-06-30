---
activation: always_on
---

# Rule: Code Health Report Template

The output format for the /code-health workflow. All audit reports must follow this structure.

```markdown
# 🏥 Code Health Audit Report

## Executive Summary
- Files Scanned: X
- Files Audited (Deep): Y
- Findings: Z (🔴 Critical: N, 🟡 Warning: N, 🔵 Info: N)

## Calibration Baseline
1. [e.g., `prefer_const_constructors` disabled in analysis_options.yaml]
2. [e.g., AGENTS.md documents Tier 3 → Tier 2 import is allowed for X pattern]
3. [e.g., config.json defines 7 Dart layers, 5 Rust layers]
4. [e.g., project uses Flutter 3.x with flutter_rust_bridge]

## Automated Assertion Results
| Assertion | Status | Details |
|-----------|--------|---------|
| Layer Boundaries (`audit()`) | ✅/❌ | ... |
| Naming Conventions (`analyze()`) | ✅/❌ | ... |
| Config Consistency (`analyze()`) | ✅/❌ | ... |

## Arch-MCP Knowledge Graph Insights
- **God Nodes**: [list files with highest centrality and their risk profile]
- **Surprising Connections**: [cross-community couplings that indicate architectural drift]
- **Community Cohesion Issues**: [features scattered across unrelated communities]
- **Suggested Investigation**: [arch-mcp's suggested questions applied as audit angles]

## Complexity Hotspots
| File | Tier | Line Count | API Count | Pattern | Status |
|------|------|------------|-----------|---------|--------|
| [file link] | Tier X | N | N | ... | ✅/🟡/🔴 |

## Untested Hotspots
| File | Tier | Churn (commits/30d) | Has Test | Risk |
|------|------|---------------------|----------|------|
| [file link] | Tier 3 | 12 | ❌ | High — high churn, no tests |
| [file link] | Tier 2 | 8 | ❌ | Medium — moderate churn, no tests |

## Dead Code Candidates
| Symbol | File | Confidence | Upstream Callers | In Tests? | Recommendation |
|--------|------|------------|-----------------|-----------|----------------|
| `old_helper()` | lib/utils/old_helper.dart | High | 0 | No | Remove |
| `legacy_bridge()` | rust/src/bridge/legacy.rs | Medium | 0 | No | Verify no external consumers |
| `parse_v1()` | lib/features/graph/store/parser.dart | Low | 0 | Yes | Graph may miss dynamic calls |

## Deep Audit Findings
| File | Principle | Severity | Confidence | Finding | What Would Confirm |
|------|-----------|----------|------------|---------|-------------------|
| [file link] | SRP | 🔴 Critical | High | ... | N/A |
| [file link] | DRY | 🟡 Warning | Medium | ... | Read sibling files for duplication |
| [file link] | OCP | 🔵 Info | Low | ... | Run `query` on pattern |

## Recommended Actions
[Prioritized list of refactoring tasks, grouped by phase: Immediate / This Sprint / This Quarter]
```
