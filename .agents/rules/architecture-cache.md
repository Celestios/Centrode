## Architecture Cache & Linter

This project maintains a rich architectural cache at `.agents/plugins/arch-linter/architecture-cache.json` containing pre-computed metadata for all files in the project.

Rules:
- **Architectural Context & Queries**: When modifying or analyzing files, look up the file in the cache or query it using the `arch-linter` skill to check its `tier` (Tier 1: UI, Tier 2: Gestures/Controllers, Tier 3: Domain/Store), its design `pattern`, public APIs, and FFI boundaries.
- **Dependency Boundary Alignment**: Before adding imports to any file, check the `tier` of the target file. You MUST NOT import components from a higher-level layer (e.g., Tier 3 Domain/Store must never import Tier 1 UI or Tier 2 Presentation/Controllers).
- **Test File Tracing**: Use the `test_file` and `has_tests` keys to immediately locate and update/create tests associated with the source code file you are modifying.
- **Compliance Scan**: After making any code changes in a session, run the compliance validation check to ensure you did not introduce any tier leaks or naming violations:
  ```powershell
  dart .agents/plugins/arch-linter/scripts/cache_manager.dart check
  ```
- **Architectural Assertions**: Make sure to check naming conventions and test coverage requirements before completing tasks:
  ```powershell
  dart .agents/plugins/arch-linter/scripts/cache_manager.dart assert_naming
  dart .agents/plugins/arch-linter/scripts/cache_manager.dart assert_tests
  ```
- **Boundary with graphify**: Use the architecture cache/linter for checking layer boundary compliance, class metrics, naming rules, test coverage, and code health auditing (SRP, DRY, SOLID, Symmetry). Do NOT use it for general system comprehension, pathfinding, or conceptual flow tracing; use `graphify` for those tasks.

