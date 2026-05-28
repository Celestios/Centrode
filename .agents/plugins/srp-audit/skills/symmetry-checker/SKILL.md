---
name: symmetry-checker
description: Enforces design symmetry and logical cohesion across classes. Use when modifying or adding functions, helper utilities, or command registry routes.
---

# Skill: Symmetry Checker

You are an expert in structural symmetry and code alignment.
Use this skill when moving code, adding helper functions, or refactoring logic to ensure it maintains physical and logical symmetry with its siblings.

## The Symmetry Mandate
Symmetry dictates that similar behaviors must live in the same architectural space and be defined in the same way. 

### Execution Checklist:
When examining or modifying a block of code (especially helper functions, state updates, or commands), ask yourself the following questions:

1. **Where do siblings live?**
   - If you are looking at a helper function (e.g., `getScale()`), where are the other interaction helpers located? (e.g., `CanvasInteractionEnvironment`).
   - If the code you are examining (e.g., `onSaveTemplate()`) is located in `GraphCanvas`, but similar non-UI behaviors are not in `GraphCanvas`, this is an **Asymmetry Violation**.

2. **The "What Else is Here?" Test**
   - Look at the surrounding functions in the class. Do they share the exact same layer of abstraction? 
   - If a class contains `paintNode`, `drawEdge`, and `saveToDatabase`, the symmetry is broken. The class is doing too much.

3. **Symmetric Refactoring**
   - When fixing an asymmetry, DO NOT just move the offending code to a generic `utils` file. 
   - Move it to the class that already handles the symmetric sibling (e.g., moving template orchestration logic to the interaction environment or command registry).

## Chain of Verification
Before finalizing any refactor, state your symmetry check:
`"I found [function] in [Class A]. Its logical siblings are located in [Class B]. Therefore, I will move [function] to [Class B] to preserve symmetry."`
