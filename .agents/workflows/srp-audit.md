---
description: Orchestrates a differential multi-agent architectural audit utilizing the Architecture Auditor and Symmetry Checker skills from the SRP Audit Plugin, using a local JSON cache to skip unmodified files.
---

# Workflow: /srp-audit

This workflow transforms the agent into an **Architectural Orchestrator**. To keep audits fast and context-efficient as the project grows, this workflow implements a **differential caching pipeline** managed by an automated helper script (`cache_manager.dart`). 

You will only audit files that have changed since the last check, using the cached architectural metadata as a baseline.

---

## Core Mandates
1. **Cache-First Auditing**: Always execute the `cache_manager.dart scan` command before starting. Do not manually recalculate file hashes.
2. **Precision Audits**: Focus deep line-audits only on files outputted in the `[AUDIT_REQUIRED - PENDING]` and `[AUDIT_REQUIRED - VIOLATION]` blocks.
3. **Multi-Agent Verification**: Delegate the detailed validation of queued files to isolated subagents to preserve context.
4. **Automated Cache Updates**: Run the `cache_manager.dart update` command immediately after auditing each file to ensure the cache stays completely in sync.

---

## Execution Steps

### Step 1: Scan & Scope Detection
- **Action**: Run the scan helper script:
  ```powershell
  dart .agents/plugins/srp-audit/scripts/cache_manager.dart scan
  ```
- **Task**: Inspect the stdout of the script. Identify:
  - Files under `[AUDIT_REQUIRED - PENDING]` (Modified or new files whose status has been reset to `PENDING_AUDIT`).
  - Files under `[AUDIT_REQUIRED - VIOLATION]` (Files previously marked with violations).
  - These files compose your **Audit Queue**.

### Step 2: Architecture & Symmetry Analysis (Planner Agent)
- **Task**: For the queued files, identify their expected tier based on the cache's layer mappings:
  - `.agents/plugins/srp-audit/rules/abstraction-levels.md`
  - `.agents/plugins/srp-audit/rules/no-cross-layer-mutation.md`
  - `.agents/plugins/srp-audit/rules/symmetry-invariants.md`
- **Evaluation**: Plan the verification check (e.g., matching imports and constructor injection constraints).

### Step 3: Deep Dive (Delegated Verification)
- **Action**: For each file in the queue, use `invoke_subagent` to spawn a subagent.
- **Prompt to Subagent**:
  ```text
  Audit [FilePath] against the SRP Audit rules:
  1. Enforce the Zero-Trust Checklist in .agents/plugins/srp-audit/skills/architecture-auditor/SKILL.md.
  2. Enforce the Symmetry rules in .agents/plugins/srp-audit/skills/symmetry-checker/SKILL.md.
  
  Report back with:
  - Class Name and Tier.
  - 1-sentence Single Responsibility description.
  - Verification Status (COMPLIANT or VIOLATION_DETECTED).
  - Specific line ranges of any violations.
  ```

### Step 4: Update Cache & Final Report
- **Action**: For each file that was audited in Step 3, run the update helper command to save the results in the cache:
  - **If Compliant**:
    ```powershell
    dart .agents/plugins/srp-audit/scripts/cache_manager.dart update <file_path> COMPLIANT
    ```
  - **If Violations Detected** (separate multiple violation descriptions with `|`):
    ```powershell
    dart .agents/plugins/srp-audit/scripts/cache_manager.dart update <file_path> VIOLATION_DETECTED "First violation description | Second violation"
    ```
- **Task**: Compile the final audit report, listing the audited files (and their status), and bypassed files.
