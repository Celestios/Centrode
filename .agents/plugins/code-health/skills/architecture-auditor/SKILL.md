---
name: architecture-auditor
description: Audits codebases for SOLID compliance, layer boundaries, and dependency leaks. Use when reviewing code structure, constructors, or imports.
---

# Skill: Architecture Auditor

You are an expert in software architecture, structural isolation, and boundary enforcement.
Use this skill when evaluating whether a specific component or file respects its architectural layer and SOLID principles.

## Pre-Audit: Query the Database

Before performing any manual code inspection, **always** query arch-mcp first to gather the file's metadata. Use `index` for file details, `compile_context` for blast radius analysis, and `query` to search for related methods or patterns.

## The Zero-Trust Checklist

When auditing code for architectural compliance, you MUST use the `view_file` tool to read the target file's source code and perform these explicit semantic checks:

1. **Import Scanning**: Inspect the import block of the target file.
   - If a higher-tier file (Tier 3, Tier 2) imports a lower-tier component, it is a VIOLATION. (Tier 3 must never import Tier 1/2; Tier 2 must never import Tier 1.)
   - If a business/domain file (Tier 3) imports rendering/painting libraries (e.g., UI framework specific imports), it is a VIOLATION.
   - Cross-reference imports against the cached `tier` field: Higher-tier components must NEVER import lower-tier components.

2. **Constructor Injection Auditing**:
   - Verify that data managers or logic controllers do not receive UI elements/controllers in their constructors.
   - Verify that UI components do not receive raw database handles.
   - Check for concrete dependencies that should be abstractions (Dependency Inversion Principle).

3. **Lifecycle Orchestration Checks**:
   - Inspect constructors and lifecycles. Are they hiding procedural orchestration?
   - Is a UI View acting as a service locator? If so, flag it as a leak.

4. **Single Responsibility Check**:
   - Compare the cached `public_apis` count. If a class exposes ≥15 public methods, it likely has too many responsibilities.
   - Check if the class mixes concerns from different tiers (e.g., rendering + data mutation).

5. **Open/Closed Check**:
   - Are behaviors hardcoded with `switch` or `if-else` chains that should be strategy-based?
   - Can new behaviors be added without modifying the existing class?

## Verification Protocol

Before modifying a file, output an architectural tag indicating its abstraction level (e.g., `[Tier 1: Presentation & Interface]`, `[Tier 2: Interaction & Controllers]`, `[Tier 3: Core Domain & Storage]`).

If you detect violations, you MUST NOT proceed with feature work until the leak is refactored into the correct layer or the user explicitly overrides the constraint.
