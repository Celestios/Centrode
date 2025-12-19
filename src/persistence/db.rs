use surrealdb::engine::local::{Db, RocksDb};
use surrealdb::Surreal;
use lazy_static::lazy_static;
use std::sync::Arc;
use tokio::sync::Mutex;
use std::path::Path;
use std::fs;
use anyhow::Context;
use super::schema;

// Global Singleton for the Database
lazy_static! {
    pub static ref DB: Arc<Mutex<Option<Surreal<Db>>>> = Arc::new(Mutex::new(None));
}

pub struct Database;

impl Database {
    pub async fn connect(path: &str) -> anyhow::Result<()> {
        // 1. Force directory creation to ensure visibility and permissions
        let db_path = Path::new(path);
        if !db_path.exists() {
            fs::create_dir_all(db_path)
                .with_context(|| format!("Failed to create database directory at: {:?}", db_path))?;
        }

        // Log the absolute path for verification (Boss needs to know where data lives)
        let abs_path = fs::canonicalize(db_path)?;
        println!(" [Database] Initializing RocksDB at: {:?}", abs_path);

        // 2. Initialize RocksDB
        let db = Surreal::new::<RocksDb>(path).await?;

        db.use_ns("mycelium").use_db("core").await?;
        schema::Schema::init().await?;

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