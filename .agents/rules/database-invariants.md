# Rule: Database Invariants

- You MUST use `#[derive(SurrealValue)]` from the `surrealdb` crate instead of `serde` for all domain models (`INode`, `TaskNode`, `MapData`, `Coordinates`, etc.).
- You MUST prioritize type-safe methods (`.select(...)`, `.create(...)`, `.update(...)`, `.delete(...)`) over raw string-based SurrealQL queries (`.query(...)`) unless strictly necessary.
- You MUST always use parameterized queries with `.bind()` when raw queries are unavoidable.
- You MUST separate Identity and Content: Do NOT save top-level wrapper structs (`INode`, `TaskNode`); save their `Fields` variants explicitly using `.content(node.fields)`.
- You MUST implement the `IsTable` trait for all top-level database models to ensure strongly typed `LABEL` constants and unified `RecordId` generation.
- You MUST store relation IDs (`in`, `out`) as raw Strings and use helper methods (`get_in_id()`, `get_out_id()`) to safely parse them into typed `RecordId` objects.
- You MUST use type-safe transactions (`db.begin()`, `tx.commit()`) for operations requiring atomicity.
- You MUST manually unpack nested wrapper domains when querying via `db.query()`: extract `id` as `key`, use `from_value(v)` for `fields`.
