---
trigger: always_on
description: Rules enforcing clean coding standards, including SOLID design principles and DRY compliance.
---

## SOLID & DRY Principles

This project enforces strict clean coding standards across both Rust and Dart codebases. Adhere to these principles for all modifications:

Rules:
- **Single Responsibility (SRP)**: Each class, module, or function must have exactly one reason to change. Refactor God Objects (classes with high line counts or public API counts >= 15).
- **Open/Closed (OCP)**: Code should be open for extension but closed for modification. Prefer strategy patterns, callbacks, and polymorphism over hardcoded case switch statements or nested if/else logic for state handling.
- **Liskov Substitution (LSP)**: Interface implementations must fully satisfy base class contracts. Do not return arbitrary nulls or throw unimplemented errors for required methods.
- **Interface Segregation (ISP)**: Segment interfaces into cohesive roles. Do not force classes to implement methods they do not require.
- **Dependency Inversion (DIP)**: Always depend on abstractions (interfaces) rather than concrete implementations. Use constructor dependency injection.
- **DRY (Don't Repeat Yourself)**: Reuse helper functions and widgets. Inspect sibling packages and files before writing duplicate utility code.
