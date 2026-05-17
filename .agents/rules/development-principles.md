# Rule: Development Principles

- You MUST prioritize rigorous logging over complex error handling and recovery. Use the centralized logging system in the UI and structured tracing macros in the Rust core.
- You MUST NOT focus on database migrations, semantic versioning, or automated tests until explicitly instructed (Pre-Deployment Focus).
- You MUST strictly deserialize every node fetched from the database into its corresponding domain model. Fallbacks or repairs MUST be enforced if fields are missing.
- You MUST NOT mix administrative metadata (e.g., map name, author) with graph nodes. They must reside in separate document tables.
- You MUST NOT use floats for any UI-related canvas variables. Use discrete values. Only the Rust side is permitted to use float types for advanced computations.
