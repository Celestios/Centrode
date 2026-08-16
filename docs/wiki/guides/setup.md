# Development Setup

> Last verified: 2026-08-16

---

## Prerequisites

1. **Flutter SDK** (Channel Stable, version matches `pubspec.yaml` SDK constraints)
2. **Rust Toolchain** (via [rustup](https://rustup.rs/))
3. **LLVM** (required by `flutter_rust_bridge_codegen` for binding generation)
4. **Visual Studio** (Windows) or **Xcode** (macOS) — for native builds

---

## First Build

```bash
# 1. Clone and install Flutter packages
git clone <repo-url>
cd centrode
flutter pub get

# 2. Generate FRB bindings (Rust → Dart)
flutter_rust_bridge_codegen generate

# 3. Generate Dart code (freezed, json_serializable, centrode_codegen)
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Run the app
flutter run -d windows    # or linux, macos
```

---

## Subsequent Builds

After pulling changes:

```bash
flutter pub get
flutter run -d windows
```

If models changed, re-run code generation:

```bash
flutter_rust_bridge_codegen generate
flutter pub run build_runner build --delete-conflicting-outputs
```

---

## Version Synchronization

Keep versions aligned across `pubspec.yaml` and `rust/Cargo.toml`:

```bash
dart scripts/sync_version.dart 0.6.0
```

---

## Running Tests

### Dart Tests
```bash
flutter test
```

### Rust Tests
```bash
cd rust && cargo test
```

### Integration Tests
```bash
flutter test integration_test
```

See [Running Tests guide](running-tests.md) for details.

---

## IDE Setup

### VS Code
- Install Flutter and Rust extensions
- Open `centrode/` as workspace root
- Use `flutter run` from the Debug panel

### IntelliJ / Android Studio
- Install Flutter and Dart plugins
- Open `pubspec.yaml` as project

---

## Project Structure Quick Reference

```
centrode/
├── lib/                    # Flutter frontend
├── rust/                   # Rust backend
├── packages/               # Internal Dart packages
├── shaders/                # GLSL shaders
├── assets/                 # Themes, images
├── scripts/                # Utility scripts
├── test/                   # Dart tests
├── integration_test/       # Integration tests
└── docs/                   # Documentation
```

---

## Troubleshooting & Native Setup

### LLVM / `LIBCLANG_PATH` Error on Windows
If `flutter_rust_bridge_codegen generate` fails with `Cannot find libclang`:
1. Install LLVM via winget: `winget install LLVM.LLVM`
2. Set `LIBCLANG_PATH` in PowerShell (or System Environment Variables):
   ```pwsh
   $env:LIBCLANG_PATH = "C:\Program Files\LLVM\bin"
   ```

### SurrealDB Lock Contention (`database is locked`)
If the app terminates abruptly during development and a map database remains locked:
1. Ensure all background `centrode` or `cargo` processes are terminated.
2. If using file-backed storage in `maps/`, delete transient lock files or remove the development database clone.

### Stale Native Bindings / Clean Rebuild
If type mismatches occur across FFI after switching Git branches:
```bash
# Clean Rust build cache
cd rust && cargo clean && cd ..

# Regenerate all bindings & models
flutter_rust_bridge_codegen generate
flutter pub run build_runner build --delete-conflicting-outputs
```

