---
description: Structured workflow for diagnosing, explaining, and proposing fixes for bugs.
---

# Workflow: /bug-fixer

This workflow provides instructions for the agent to systematically diagnose bugs, explain their root causes, and propose solutions for user approval.

## Core Mandate

When executing this workflow, adhere to the following principles:
1. **Verify System Dynamics**: Do not guess. Make sure you understand the exact system dynamics and precisely how the problem occurs before attempting to fix it.
2. **Handle Uncertainty & Difficult Bugs**: If you are not absolutely sure about the root cause, or if the problem does not get solved easily, implement extensive temporary debugging print statements to trace variable states, control flow, and runtime values. Using print statements is a robust way to isolate issues.
3. **Debug Print Cleanup**: You must automatically identify and remove all temporary debugging print statements after the issue is successfully resolved. Do not leave debug pollution in the codebase.
4. **Clear Explanation**: Explain *why* the bug occurs, not just *that* it occurs.
5. **Impact Assessment**: Briefly mention what else might be affected by the proposed fix.
6. **Pause for Consent**: Never apply a fix without explicit confirmation of the plan.

## Steps

### 1. Investigation & Reproduction
- **Task**: Identify the scope of the bug, understand the system dynamics, and gather necessary context.
- **Action**: 
    - Search for relevant code, error messages, or logs.
    - Analyze the execution flow and state transitions leading to the reported issue.
    - **Observe Dynamics**: If you lack certainty about how the bug behaves or its exact path of execution, or if a fix does not work immediately, introduce temporary debugging print statements to trace execution paths and values. This provides robust real-time insight into the running code.
    - If possible, describe how to reproduce the issue.
*Constraint: You MUST output a summary of your investigation, including the specific files/lines involved and how you verified the execution dynamics.*

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
    - **Clean Up Debug Prints**: Completely remove all temporary debugging print statements added during the debugging process.
    - Provide a summary of the changes made.
