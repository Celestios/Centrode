# Mycelium Project Constitution (Consolidated)

This document synthesizes the historical architectural decisions and technical specifications from the original constitution files. It represents the foundational logic of the Mycelium knowledge graph.

## 1. Data Integrity & Validation
- **Strict Deserialization**: Every node fetched from the database must be strictly deserialized into its corresponding Rust struct.
- **Repair Protocol**: If a core node lacks required fields, it is either flagged for repair or downgraded to a `CustomNode` to preserve data integrity.
- **View Compliance**: Special views (Kanban/Timeline) have strict "Opt-In" protocols. A `CustomNode` must define specific fields (e.g., `status`, `effective_date`) to appear in these views.

## 2. Structural Patterns
- **Hybrid Labeled Property Graph**:
  - **Simple Relations**: Lightweight pointers (SurrealDB `RELATE`) for standard verbs (O(1) traversal).
  - **Intermediate Nodes (InterNode)**: Reified connections for complex state or metadata. Use when the connection itself must be targetable by other edges.
- **Metadata Segregation**: Administrative data (map name,作者) lives in separate document tables (e.g., `map_metadata`) rather than graph nodes to prevent graph algorithm pollution.

## 3. Storage & Persistence
- **.celi Format**: A compressed archive containing the SurrealDB database snapshot (`db/`) and external binary attachments (`data/`).
- **SurrealDB Optimization**: Tables use `SCHEMAFULL` definitions to ensure zero-overhead parsing and utilize specialized indexes (e.g., array indexes for tags).
- **Embedded Operation**: The system is designed for offline-first local operation with no HTTP/Network stack overhead.

## 4. Bridge & Telemetry
- **FFI Communication**: Direct binding via Flutter Rust Bridge (FRB). Rust logic is treated as native Dart functions.
- **Live Query Streams**: SurrealDB Live Queries are bridged directly to Dart `Stream` objects for reactive UI updates.
- **Centralized Telemetry**: All Rust telemetry (via `tracing`) is captured in a pre-stream buffer and flushed to the Dart `LogManager` once the FFI stream is established.
- **Panic Boundary**: The `ffi_guard!` macro prevents Rust panics from crossing the C boundary and causing process death.
