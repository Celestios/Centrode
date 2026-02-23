use super::schema;
use surrealdb::engine::local::{Db, SurrealKv};
use surrealdb::Surreal;

pub struct Database;

impl Database {
    /// Connects to the embedded SurrealDB (SurrealKV) and initializes the schema.
    /// Returns the database instance directly (No global state).
    pub async fn connect(path: &str) -> anyhow::Result<Surreal<Db>> {
        // Initialize SurrealKV (file-based)
        let db = Surreal::new::<SurrealKv>(path).await?;

        // Select Namespace/Database
        db.use_ns("mycelium").use_db("core").await?;

        // Initialize Schema
        schema::Schema::init(&db).await?;

        Ok(db)
    }
}
