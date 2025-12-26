use surrealdb::engine::local::{Db, RocksDb};
use surrealdb::Surreal;
use super::schema;

pub struct Database;

impl Database {
    /// Connects to the embedded RocksDB and initializes the schema.
    /// Returns the database instance directly (No global state).
    pub async fn connect(path: &str) -> anyhow::Result<Surreal<Db>> {
        // Initialize RocksDB (file-based)
        let db = Surreal::new::<RocksDb>(path).await?;
        
        // Select Namespace/Database
        db.use_ns("mycelium").use_db("core").await?;

        // Initialize Schema
        schema::Schema::init(&db).await?;

        Ok(db)
    }
}
