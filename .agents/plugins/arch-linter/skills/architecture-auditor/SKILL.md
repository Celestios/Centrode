---
name: architecture-auditor
description: Audits codebases for SOLID compliance, layer boundaries, and dependency leaks. Use when reviewing code structure, constructors, or imports.
---

# Skill: Architecture Auditor

You are an expert in software architecture, structural isolation, and boundary enforcement.
Use this skill when evaluating whether a specific component or file respects its architectural layer and SOLID principles.

## Pre-Audit: Query the Linter Cache

Before performing any manual code inspection, **always** query the [arch-linter](file:///d:/Projects/Open/flutter/code/mycelium/.agents/skills/arch-linter/SKILL.md) cache first to gather the file's metadata:
```powershell
# Get the file's tier, pattern, FFI status, and test coverage
dart .agents/plugins/arch-linter/scripts/cache_manager.dart query dir=<directory>

# Check who depends on this file (blast radius)
dart .agents/plugins/arch-linter/scripts/cache_manager.dart dependents <file_path>

# Check the file's public API surface
dart .agents/plugins/arch-linter/scripts/cache_manager.dart query_method name=<search>
```

## The Zero-Trust Checklist

When auditing code for architectural compliance, you MUST use the `view_file` tool to read the file's source code and perform these explicit semantic checks:

1. **Import Scanning**: Inspect the `import` block of the target file.
   - If a presentation/UI file imports database drivers or backend logic, it is a VIOLATION.
   - If a business/domain file imports rendering/painting libraries (e.g., `flutter/material.dart` for anything other than basic types), it is a VIOLATION.
   - Cross-reference imports against the cached `tier` field: Tier 3 must NEVER import Tier 1 or Tier 2.

2. **Constructor Injection Auditing**:
   - Verify that data managers do not receive UI components (like ThemeControllers) in their constructors.
   - Verify that UI components do not receive raw database handles.
   - Check for concrete dependencies that should be abstractions (Dependency Inversion Principle).

3. **Lifecycle Orchestration Checks**:
   - Inspect constructors, `initState`, and `dispose`. Are they hiding procedural orchestration?
   - Is a UI View acting as a service locator? If so, flag it as a leak.

4. **Single Responsibility Check**:
   - Compare the cached `public_apis` count. If a class exposes ≥15 public methods, it likely has too many responsibilities.
   - Check if the class mixes concerns from different tiers (e.g., rendering + data mutation).

5. **Open/Closed Check**:
   - Are behaviors hardcoded with `switch` or `if-else` chains that should be strategy-based?
   - Can new behaviors be added without modifying the existing class?

## Verification Protocol
Before modifying a file, output an architectural tag indicating its abstraction level (e.g., `[Tier 1: Canvas]`, `[Tier 2: Interaction]`, `[Tier 3: Domain]`).

If you detect violations, you MUST NOT proceed with feature work until the leak is refactored into the correct layer or the user explicitly overrides the constraint.
