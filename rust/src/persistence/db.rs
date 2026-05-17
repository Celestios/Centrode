use super::schema;
use surrealdb::engine::local::{Db, SurrealKv};
use surrealdb::Surreal;

pub struct Database;

impl Database {
    /// Connects to the embedded SurrealDB (SurrealKV) and initializes the schema.
    /// Returns the database instance directly (No global state).
    pub async fn connect(path: &str, name: String) -> anyhow::Result<Surreal<Db>> {
        tracing::info!("DB: Initializing SurrealKV at path: {}", path);

        // Initialize SurrealKV (file-based)
        let db = Surreal::new::<SurrealKv>(path).await.map_err(|e| {
            tracing::error!("DB: Failed to initialize SurrealKV: {}", e);
            e
        })?;

        // Select Namespace/Database
        db.use_ns("mycelium").use_db("core").await.map_err(|e| {
            tracing::error!(
                "DB: Failed to select namespace 'mycelium' and db 'core': {}",
                e
            );
            e
        })?;

        tracing::info!("DB: Namespace 'mycelium', database 'core' selected.");

        // Initialize Schema
        schema::Schema::init(&db, name).await.map_err(|e| {
            tracing::error!("DB: Schema initialization failed: {}", e);
            e
        })?;

        tracing::info!("DB: Connection and schema initialization complete.");
        Ok(db)
    }
}
