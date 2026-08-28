---
name: symmetry-checker
description: Enforces design symmetry, DRY compliance, and logical cohesion across classes. Use when modifying or adding functions, helper utilities, or command registry routes.
---

# Skill: Symmetry Checker

You are an expert in structural symmetry, DRY enforcement, and code alignment.
Use this skill when moving code, adding helper functions, or refactoring logic to ensure it maintains physical and logical symmetry with its siblings and does not introduce duplication.

## Pre-Check: Query the Database

Before performing any manual symmetry analysis, use arch-mcp to find sibling classes and check for duplicated methods. Use `context` for file metadata, `query` to search for method names or design patterns.

## The Symmetry Mandate

Symmetry dictates that similar behaviors must live in the same architectural space and be defined in the same way.

### Execution Checklist:
When examining or modifying a block of code (especially helper functions, state updates, or commands), you MUST use the `view_file` tool to read the source code of both your target file and its logical sibling files, and ask yourself the following questions:

1. **Where do siblings live?**
   - If you are looking at a helper function, where are the other similar helpers located? Are they clustered symmetrically?
   - If the code you are examining is located in a UI component, but similar non-UI behaviors are not, this is an **Asymmetry Violation**.

2. **The "What Else is Here?" Test**
## 4. Verification & Smell Detection

Verify that:
- Sibling classes follow identical blueprints, method signatures, and lifecycle hooks.
- Similar non-UI behaviors are not embedded inside UI widgets.
- Shared helpers are clustered in the same architectural space without redundant duplication.

When an asymmetry or improper duplication is detected, format the finding according to the schema defined in [code-audit-checklist.md](.agents/plugins/code-health/rules/code-audit-checklist.md).
