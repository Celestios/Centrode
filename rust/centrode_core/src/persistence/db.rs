use super::schema;
use surrealdb::engine::local::{Db, SurrealKv};
use surrealdb::Surreal;

pub struct Database;

impl Database {
    /// Connects to the embedded SurrealDB (SurrealKV) and initializes the schema.
    /// Returns the database instance directly (No global state).
    pub async fn connect(
        path: &str,
        name: String,
        namespace: Option<&str>,
        database: Option<&str>,
    ) -> anyhow::Result<Surreal<Db>> {
        tracing::info!("DB: Initializing SurrealKV at path: {}", path);

        // Initialize SurrealKV (file-based)
        let db = Surreal::new::<SurrealKv>(path).await.map_err(|e| {
            tracing::error!("DB: Failed to initialize SurrealKV: {}", e);
            e
        })?;

        let ns = namespace.unwrap_or("centrode");
        let db_name = database.unwrap_or("core");

        // Select Namespace/Database
        db.use_ns(ns).use_db(db_name).await.map_err(|e| {
            tracing::error!(
                "DB: Failed to select namespace '{}' and db '{}': {}",
                ns,
                db_name,
                e
            );
            e
        })?;

        tracing::info!("DB: Namespace '{}', database '{}' selected.", ns, db_name);

        // Initialize Schema
        schema::Schema::init(&db).await.map_err(|e| {
            tracing::error!("DB: Schema initialization failed: {}", e);
            e
        })?;

        // Seed default data
        schema::Seeder::seed_default_data(&db, name).await.map_err(|e| {
            tracing::error!("DB: Default data seeding failed: {}", e);
            e
        })?;

        tracing::info!("DB: Connection, schema initialization, and seeding complete.");
        Ok(db)
    }
}
