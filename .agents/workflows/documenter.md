---
description: Writing API specs, system markdown documents, and developer references.
---

# Workflow: /documenter

This workflow is used when updating, creating, or auditing markdown documentation, API specifications, READMEs, or architectural guides in the Centrode workspace.

## Execution Steps

### Step 1: Audit Target Documentation
- Identify the documentation targets that need updates (e.g. workspace setups, FFI interface manuals, SurrealDB schema notes, rules).
- Trace the current source code to ensure that the facts described in the documentation (classes, FFI parameters, database tables) are completely accurate.

### Step 2: Plan the Updates
- List all documentation files to modify or create.
- Plan the visual layout (Markdown tables, mermaid diagrams, alerts) to maximize readability.

### Step 3: Implement Documentation Changes
- Apply changes to the target documentation files.
- Ensure all file links use standard markdown syntax: `[link text](file:///absolute/path/to/file)`.
- Ensure no broken links or outdated references are left behind.

### Step 4: Presentation
- Present the updated documents or changes to the user for review.
