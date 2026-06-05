---
trigger: always_on
description: Rules for using the architecture cache and linter.
---

## Architecture Cache & Linter

This project maintains rich architectural caches at `.agents/plugins/arch-linter/dart-architecture-cache.json` and `.agents/plugins/arch-linter/rust-architecture-cache.json` containing pre-computed metadata for all files in the project.

Rules:
- **Strictly No Cache Updates or Compliance Runs**: You must NEVER attempt to run linter checks (`check`) or update cache metadata (using `update` or by editing cache JSON files directly). Cache maintenance is strictly handled externally and is NOT the agent's job.
- **Architectural Context & Queries**: When modifying or analyzing files, look up the file in the cache or query it using the `arch-linter` skill to check its `tier`, its design `pattern`, public APIs, and FFI boundaries. Always declare the mode via `--dart` or `--rust` flag.
- **Dependency Boundary Alignment**: Before adding imports to any file, check the `tier` of the target file. You MUST NOT import components from a higher-level layer (e.g., Tier 3 Domain/Store must never import Tier 1 UI or Tier 2 Presentation/Controllers).
- **Test File Tracing**: Use the `test_file` and `has_tests` keys to immediately locate and update/create tests associated with the source code file you are modifying.
- **Boundary with graphify**: Use the architecture cache/linter for checking layer boundary compliance, class metrics, naming rules, test coverage, and code health auditing (SRP, DRY, SOLID, Symmetry). Do NOT use it for general system comprehension, pathfinding, or conceptual flow tracing; use `graphify` for those tasks.


