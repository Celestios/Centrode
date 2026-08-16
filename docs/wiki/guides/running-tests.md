# Running Tests

> Last verified: 2026-08-16

---

## Dart Unit & Widget Tests

```bash
flutter test
```

Runs all tests in `test/` directory. Includes:
- Unit tests for models, utilities, store modules
- Widget tests for UI components
- Bug regression tests

### Specific Test Files

```bash
flutter test test/features/graph/engine/interaction_test.dart
flutter test test/features/graph/store/modules/
```

---

## Rust Tests

```bash
cd rust && cargo test
```

Runs all `#[cfg(test)]` tests in the Rust crate. Includes:
- Domain type tests
- Schema generation tests
- Repository CRUD tests
- Relation engine tests
- Layout engine tests

---

## Integration Tests

```bash
flutter test integration_test
```

Runs Flutter integration tests that exercise the full stack (Dart + Rust).

---

## Test Structure

```
test/
├── widget_test.dart
├── liquid_glass_rendering_test.dart
├── markdown_parse_test.dart
├── bug_fix/                    # Regression tests
├── features/
│   └── graph/
│       ├── engine/             # Interaction FSM tests
│       ├── models/             # Model unit tests
│       ├── presentation/       # Viewport, zoom, render tests
│       ├── store/              # Store module tests
│       └── ui/                 # Widget tests
├── shared/                     # Shared utility tests
└── widget_test/                # Widget test helpers
```

---

## Coverage

To generate coverage reports:

```bash
# Dart
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html  # requires lcov

# Rust
cd rust && cargo tarpaulin
```

---

## CI

Tests run automatically via GitHub Actions (`.github/workflows/release-to-public.yml`). The workflow:
1. Runs Dart tests
2. Runs Rust tests
3. Builds release binaries
