---
name: symmetry-checker
description: Enforces design symmetry, DRY compliance, and logical cohesion across classes. Use when modifying or adding functions, helper utilities, or command registry routes.
---

# Skill: Symmetry Checker

You are an expert in structural symmetry, DRY enforcement, and code alignment.
Use this skill when moving code, adding helper functions, or refactoring logic to ensure it maintains physical and logical symmetry with its siblings and does not introduce duplication.

## Pre-Check: Query the Linter Cache

Before performing any manual symmetry analysis, use the arch-linter to find sibling classes and check for duplicated methods:
```powershell
# Find all classes in the same directory
dart scripts/arch_linter.dart query --lang=<lang> dir=<directory>

# Search for a method name across the entire codebase to detect duplication
dart scripts/arch_linter.dart query_method --lang=<lang> name=<method_name>

# Check if the same pattern is used consistently across siblings
dart scripts/arch_linter.dart query --lang=<lang> pattern=<pattern_name>
```

## The Symmetry Mandate

Symmetry dictates that similar behaviors must live in the same architectural space and be defined in the same way.

### Execution Checklist:
When examining or modifying a block of code (especially helper functions, state updates, or commands), you MUST use the `view_file` tool to read the source code of both your target file and its logical sibling files, and ask yourself the following questions:

1. **Where do siblings live?**
   - If you are looking at a helper function, where are the other similar helpers located? Are they clustered symmetrically?
   - If the code you are examining is located in a UI component, but similar non-UI behaviors are not, this is an **Asymmetry Violation**.

2. **The "What Else is Here?" Test**
   - Look at the surrounding functions in the class. Do they share the exact same layer of abstraction?
   - If a class contains UI-painting logic and database-access logic, the symmetry is broken. The class is doing too much.

3. **The DRY Cross-Reference**
   - Use `query_method` to search for methods with similar names across the codebase.
   - If two classes in different directories implement the same helper logic, extract it into a shared utility or inherit from a common base.

4. **Symmetric Refactoring**
   - When fixing an asymmetry, DO NOT just move the offending code to a generic `utils` file.
   - Move it to the class that already handles the symmetric sibling to preserve organizational balance.

5. **Pattern Consistency Check**
   - Use `query pattern=<pattern>` to find all classes tagged with the same design pattern.
   - Verify they all follow the same structural blueprint (same method signatures, same lifecycle hooks, same extension points).

## Chain of Verification

Before finalizing any refactor, state your symmetry check:
`"I found [function] in [Class A]. Its logical siblings are located in [Class B]. Therefore, I will move [function] to [Class B] to preserve symmetry."`
