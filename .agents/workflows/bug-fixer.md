---
description: Structured workflow for diagnosing, explaining, and proposing fixes for bugs.
---

# Workflow: /bug-fixer

This workflow provides instructions for the agent to systematically diagnose bugs, explain their root causes, and propose solutions for user approval.

## Core Mandate

When executing this workflow, adhere to the following principles:
1. **Evidence-Based Diagnosis**: Don't guess. Use logs, code analysis, and reproduction steps to find the root cause.
2. **Clear Explanation**: Explain *why* the bug occurs, not just *that* it occurs.
3. **Impact Assessment**: Briefly mention what else might be affected by the proposed fix.
4. **Pause for Consent**: Never apply a fix without explicit confirmation of the plan.

## Steps

### 1. Investigation & Reproduction
- **Task**: Identify the scope of the bug and gather necessary context.
- **Action**: 
    - Search for relevant code, error messages, or logs.
    - Analyze the execution flow leading to the reported issue.
    - If possible, describe how to reproduce the issue.
*Constraint: You MUST output a summary of your investigation, including the specific files and lines involved.*

### 2. Root Cause Analysis (RCA)
- **Task**: Explain the "How" and "Why".
- **Action**:
    - Outline the logical or state-related failure that causes the bug.
    - Explain why the current implementation fails under the reported conditions.
    - Identify if this is a regression or a missing edge case.

### 3. Proposed Solution
- **Task**: Explain how to fix the problem.
- **Action**:
    - Describe the architectural or logic changes required.
    - Provide a high-level plan of the code modifications.
    - Mention any potential side effects or trade-offs.

### 4. User Confirmation
- **Task**: Wait for user approval.
- **Action**: 
    - Present the findings from Steps 1, 2, and 3 in a single structured report.
    - **PAUSE** and wait for the USER to provide confirmation ("Go ahead", "Fix it") or comments/suggestions on the approach.
*Constraint: Do NOT modify any project files until the user gives the green light.*

### 5. Implementation & Verification
- **Task**: Apply the fix.
- **Action**:
    - Implement the agreed-upon changes.
    - Verify that the fix addresses the root cause without introducing new issues.
    - Provide a summary of the changes made.
