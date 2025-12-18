use surrealdb::engine::local::{Db, RocksDb};
use surrealdb::Surreal;
use lazy_static::lazy_static;
use std::sync::Arc;
use tokio::sync::Mutex;

// Global Singleton for the Database
lazy_static! {
    pub static ref DB: Arc<Mutex<Option<Surreal<Db>>>> = Arc::new(Mutex::new(None));
}

pub struct Database;

impl Database {
    pub async fn connect(path: &str) -> anyhow::Result<()> {
        // Initialize RocksDB (file-based)
        let db = Surreal::new::<RocksDb>(path).await?;
        
        // Select Namespace/Database
        db.use_ns("mycelium").use_db("core").await?;

        // Store in Global Static
        let mut global_db = DB.lock().await;
        *global_db = Some(db);
        
        Ok(())
    }

    pub async fn get() -> anyhow::Result<Surreal<Db>> {
        let global_db = DB.lock().await;
        match &*global_db {
            Some(db) => Ok(db.clone()),
            None => Err(anyhow::anyhow!("Database not initialized. Call init_app first.")),
        }
    }
}