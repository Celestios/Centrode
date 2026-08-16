# Infrastructure Module

> Last verified: 2026-08-16
> Tier: 3 (Domain & Storage)

---

## Overview

The infrastructure module provides cross-cutting concerns: telemetry, logging, and error handling.

---

## Structure

```
lib/infrastructure/telemetry/
├── log_manager.dart         # Singleton log manager
├── log_models.dart          # Log entry data models
├── disk_writer.dart         # Async disk log writer
└── error_handler.dart       # Global error handler
```

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
