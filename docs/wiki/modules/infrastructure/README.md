# Infrastructure Module

---

## Overview

The infrastructure module provides cross-cutting concerns: app bootstrap orchestration, lifecycle management (daemon & custodian), telemetry, logging, and error handling.

---

## Structure

```
lib/infrastructure/
├── bootstrap/
│   └── app_bootstrap.dart     # AppBootstrap — phased boot coordinator (FRB init,
│                             #   window manager, themes, splash); AppContext container
├── lifecycle/
│   ├── custodian_manager.dart # CustodianLifecycleCoordinator — window close interception,
│                             #   detached daemon spawn on shutdown, teardown callbacks
│   └── daemon_gateway.dart    # DaemonGateway (singleton) — implements MapStorageGateway
│                             #   via the Rust DaemonHandle FFI
└── telemetry/
    ├── log_manager.dart         # Singleton log manager
    ├── log_models.dart          # Log entry data models
    ├── disk_writer.dart         # Async disk log writer
    └── error_handler.dart       # Global error handler
```

---

## Bootstrap

`AppBootstrap` (`bootstrap/app_bootstrap.dart`) coordinates phased startup: FRB initialization, engine init handshake ([yield daemon → init_core_engine](../../ffi/README.md)), window manager setup, theme loading, and splash transitions. The resulting `AppContext` carries initialized services to the widget tree.

---

## Lifecycle

- **`DaemonGateway`** — singleton bridge to the Rust [DaemonHandle](../../ffi/README.md). Implements `MapStorageGateway` so the workspace can list, create, rename, duplicate, delete, and touch maps without touching FFI details.
- **`CustodianLifecycleCoordinator`** — intercepts window close events; on shutdown it may detach a background custodian daemon process before tearing down the engine, and runs registered teardown callbacks.

---

## Logging

### Dart Side

`LogManager` is a singleton that:
- Initializes the `package:logging` hierarchy
- Writes logs to disk via `DiskWriter`
- Bridges Rust telemetry logs into Dart logging

Usage:
```dart
final _log = Logger('ClassName');
_log.info('Something happened');
_log.severe('Error occurred', error, stackTrace);
```

### Rust Side

Rust uses the `tracing` crate:
```rust
use tracing::{info, debug, warn, error};
info!("Node created: {}", node_id);
```

Logs are bridged to Flutter via `TelemetryLayer` → FFI stream → `LogManager`.

---

## Telemetry Stream

The telemetry flow:
1. Rust `tracing` subscriber captures log events
2. `TelemetryLayer` forwards events to a `broadcast` channel
3. FFI `create_log_stream()` subscribes and streams to Dart
4. Dart `LogManager` receives and processes log entries

---

## Error Handler

`ErrorHandler` catches unhandled exceptions and routes them to the telemetry system. It does not suppress errors — it ensures they are visible and logged.
