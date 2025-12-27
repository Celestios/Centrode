# Project Structure

```
mycelium/
├── .gitignore
├── .metadata
├── analysis_options.yaml
├── flutter_rust_bridge.yaml
├── pubspec.yaml
├── integration_test/
│   └── simple_test.dart
├── lib/
│   ├── main.dart
│   └── src/
│       └── rust/
│           ├── frb_generated.dart
│           ├── frb_generated.io.dart
│           ├── frb_generated.web.dart
│           └── api/
│               └── simple.dart
├── rust/
│   ├── .gitignore
│   ├── Cargo.lock
│   ├── cargo.toml
│   ├── project_tree.md
│   ├── .vscode/
│   ├── src/
│   │   ├── bridge.rs
│   │   ├── domain.rs
│   │   ├── format.rs
│   │   ├── lib.rs
│   │   ├── persistence.rs
│   │   ├── bridge/
│   │   │   └── api.rs
│   │   ├── domain/
│   │   │   ├── config.rs
│   │   │   ├── nodes.rs
│   │   │   └── relations.rs
│   │   ├── format/
│   │   │   └── packager.rs
│   │   ├── persistence/
│   │   │   ├── db.rs
│   │   │   ├── repo.rs
│   │   │   ├── schema.rs
│   │   │   └── templates.rs
│   │   └── plugin_system/
│   │       └── runner.rs
│   └── tests/
│       └── flow_tests.rs
├── test/
└── test_driver/
    └── integration_test.dart
```
