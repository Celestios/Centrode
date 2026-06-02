---
description: Combined workflow to identify relevant files for a task and then implement code based on expert programmer's analysis using those files.
---

# Workflow: /implement-with-expert

This workflow is **iterative** and operates in two distinct turns:

1. **Turn 1 — File Discovery**: The user provides only a task description. The agent identifies and outputs the absolutely relevant files for that task. No implementation occurs yet.
2. **Turn 2+ — Expert Implementation**: The user pastes the expert's analysis (explanation + proposed code). The agent verifies the expert's guidance against the identified files, corrects any misunderstandings, and applies the implementation.

This split allows the user to copy the relevant file list as context when consulting an external expert (e.g., a senior developer or AI with deep knowledge), then feed the expert's response back to drive the actual implementation.

## Core Mandate

When executing this workflow, adhere to the following principles:
1. **Iterative Flow**: Never skip the file-discovery turn. If the user's first message contains both a task and expert guidance, still perform discovery first, then immediately proceed to implementation in the same response.
2. **Expert Guidance**: In Turn 2+, treat the expert's analysis as the primary source of truth for the task.
3. **File Precision**: Identify only the absolutely relevant files for the task to focus the implementation context.
4. **Verification**: Verify that the expert's proposed implementation is correct and fits the project's context within the relevant files.
5. **Correction**: If a misunderstanding is detected, explain why and provide evidence (code snippets) from the project to support the correction.
6. **Implementation**: Apply the code as usual (either the expert's version or a corrected version) following the project's conventions.
7. **Precision**: Only output the necessary code changes or explanations; avoid unnecessary verbosity.

## Steps

### TURN 1 — Task Only (File Discovery)

Triggered when: the user provides a task description **without** expert guidance.

#### Step 1. Parse the Task
- Read the task description carefully.
- Break it down into keywords, concepts, and affected areas (e.g., feature name, layer, data type).

#### Step 2. Identify Relevant Files
- Use glob patterns to find files by name or path that match the keywords.
- Use grep to search for relevant content within files if the task involves specific functionality.
- Invoke the research subagent when a broader codebase survey is needed.
- Filter out irrelevant files (e.g., build artifacts, generated files, third-party dependencies).
- For each candidate file, read its content (or a relevant portion) to confirm direct involvement in the task.
- Consider the file's role and location (e.g., if the task is about UI, prioritize files in `lib/presentation` or `lib/features/*/ui`).
- Exclude files that are only tangentially related unless the task is specifically about that utility.
- Aim for a **minimal set** of files that would need to be changed to accomplish the task.
- If uncertain, lean towards excluding the file to avoid excessive output.

#### Step 3. Output — Relevant Files
Present the results clearly so the user can copy them when consulting an expert:

```
## Relevant Files for: <task summary>

- `path/to/file_a.dart` — <one-line reason>
- `path/to/file_b.dart` — <one-line reason>
- ...

**Next step**: Share these files (and their contents) with your expert.
Paste the expert's analysis back here to proceed with implementation.
```

> **Stop here.** Do not implement anything until the expert's analysis is provided in Turn 2.

---

### TURN 2+ — Expert Guidance Provided (Verification & Implementation)

Triggered when: the user pastes an expert's analysis (explanation + proposed code).

#### Step 4. Expert Analysis Review
- Read the expert's analysis carefully.
- Extract the task description, the explanation, and the proposed code implementation.
- If the analysis is ambiguous or incomplete, ask for clarification before proceeding.

#### Step 5. Contextual Verification
- Focus on the relevant files identified in Turn 1 (or re-identify them if context was lost).
- Check the project's coding conventions, patterns, and existing code in those files.
- Determine if the expert's implementation:
  - Matches the project's style and conventions.
  - Correctly addresses the task.
  - Fits within the existing architecture without causing conflicts.
- If the implementation is correct, proceed to Step 7.
- If there is a misunderstanding, proceed to Step 6.

#### Step 6. Misunderstanding Handling (if applicable)
- Clearly state what the misunderstanding is.
- Provide code snippets from the relevant files that demonstrate the correct pattern or convention.
- Explain why the expert's implementation is incorrect or incomplete based on the project's context.
- Propose a corrected implementation that aligns with the project.

#### Step 7. Implementation
- Apply the code (either the expert's version or the corrected version) to the relevant files.
- Ensure the code follows the project's conventions and style.
- Do not include unnecessary commentary in the code changes themselves.

#### Step 8. Output — Result
- If the expert's implementation was applied as-is, output a concise confirmation with a summary of what changed.
- If a misunderstanding was found and corrected, output:
  1. The explanation and evidence (code snippets) that led to the correction.
  2. A summary of the applied changes.
- Keep the output minimal and focused.

---

## Constraints
- **Turn 1 must always end with file output and a stop** — never implement without expert input.
- Do not apply any code changes without verification unless the expert's analysis is unambiguous and clearly correct.
- When providing evidence for a misunderstanding, use actual code snippets from the project (not just file references).
- Keep the output minimal: only the necessary code changes or the correction evidence and code changes.
- If the workflow is invoked mid-conversation and files have already been identified in a prior turn, skip Step 2 and proceed directly to Step 4.