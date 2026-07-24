---
name: persistence-schemas
description: Activate this skill when designing database schemas, writing SurrealQL transactions, modeling table fields, or structuring persistence trait implementations.
---

# Skill: Persistence Schemas

Use this skill when designing or implementing SurrealDB database schemas, table models, transaction queries, and traits.

## Guidelines

- **Table Modeling**: Ensure database tables, fields, and indexes are defined cleanly on Rust domain structures.
- **Traits Representation**: Implement appropriate domain traits like `SurrealTable` or `SurrealValue`.
- **No Manual Schema Edits**: Never manually edit [schema.surql](file:///d:/Projects/Open/flutter/code/mycelium/rust/src/persistence/schema.surql). Always modify domain structures and run the schema generator.
- **Transactional Queries**: Propose and implement safe SurrealQL transactions when mutating multiple related records.
