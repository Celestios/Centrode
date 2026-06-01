---
description: Combined workflow to identify relevant files for a task and then implement code based on expert programmer's analysis using those files.
---

# Workflow: /implement-with-expert

This workflow combines file identification and expert-based implementation. First, it identifies relevant files for the task described in the expert analysis. Then, it implements code based on the expert's analysis, verifying correctness and correcting misunderstandings using evidence from the project.

## Core Mandate

When executing this workflow, adhere to the following principles:
1. **Expert Guidance**: Treat the expert's analysis as the primary source of truth for the task.
2. **File Precision**: Identify only the absolutely relevant files for the task to focus the implementation context.
3. **Verification**: Verify that the expert's proposed implementation is correct and fits the project's context within the relevant files.
4. **Correction**: If a misunderstanding is detected, explain why and provide evidence (code snippets) from the project to support the correction.
5. **Implementation**: Apply the code as usual (either the expert's version or a corrected version) following the project's conventions.
6. **Precision**: Only output the necessary code changes or explanations; avoid unnecessary verbosity.

## Steps

### 1. Expert Analysis Review
- **Task**: Understand the expert's analysis, including the task description, explanation, and proposed implementation.
- **Action**:
    - Read the expert's analysis carefully.
    - Extract the task description, the explanation, and the proposed code implementation.
    - If the analysis is unclear, ask for clarification.

### 2. Identify Relevant Files
- **Task**: Identify the absolutely relevant files for the task described in the expert analysis.
- **Action**:
    - Use the task description from the expert analysis to break it down into keywords or concepts.
    - Use glob patterns to find files by name or path that match the keywords.
    - Use grep to search for relevant content within files if the task involves specific functionality.
    - Invoke the explore agent with a prompt to search for files by keyword or content, using an appropriate thoroughness level (quick, medium, or very thorough).
    - Filter out irrelevant files (e.g., build artifacts, generated files, dependencies).
    - For each candidate file, read its content (or a portion) to check for direct involvement in the task.
    - Consider the file's role and location (e.g., if the task is about UI, prioritize files in lib/presentation or lib/features/*/ui).
    - Exclude files that are only tangentially related (e.g., utility files used by many modules unless the task is about that utility).
    - Aim for a minimal set of files that would need to be changed to accomplish the task.
    - If uncertain, lean towards excluding the file to avoid excessive output.
    - Output the list of relevant file paths (relative to project root) for reference in subsequent steps.

### 3. Contextual Verification
- **Task**: Verify the expert's proposed implementation in the context of the relevant files and the project.
- **Action**:
    - Focus on the relevant files identified in the previous step.
    - Check the project's coding conventions, patterns, and existing code in those files.
    - Determine if the expert's implementation:
        - Matches the project's style and conventions.
        - Correctly addresses the task.
        - Fits within the existing architecture without causing conflicts.
    - If the implementation is correct, proceed to implementation.
    - If there is a misunderstanding, proceed to the next step.

### 4. Misunderstanding Handling (if applicable)
- **Task**: Identify and explain any misunderstanding in the expert's implementation, providing evidence from the project.
- **Action**:
    - Clearly state what the misunderstanding is.
    - Provide code snippets from the relevant files (or project) that demonstrate the correct pattern or convention.
    - Explain why the expert's implementation is incorrect or incomplete based on the project's context.
    - Suggest a corrected implementation that aligns with the project.

### 5. Implementation
- **Task**: Apply the code (either the expert's version or the corrected version) to the project.
- **Action**:
    - Write the necessary code changes to the relevant files.
    - Ensure the code follows the project's conventions and style.
    - Do not include any additional text or explanation in the code changes.

### 6. Output
- **Task**: Output the result of the workflow.
- **Action**:
    - If the expert's implementation was applied correctly, output a confirmation that the code has been applied.
    - If a misunderstanding was found and corrected, output the explanation and evidence (code snippets) that led to the correction, followed by the applied code changes.
    - The output should be concise and focused on the code changes or the correction evidence.

## Constraints
- Do not apply any code changes without verification unless the expert's analysis is clear and correct.
- When providing evidence for a misunderstanding, use actual code snippets from the project (not just references to files).
- Keep the output minimal: only the necessary code changes or the correction evidence and code changes.