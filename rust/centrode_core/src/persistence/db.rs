use super::schema::{Schema, Seeder};
use anyhow::Result;
use std::sync::LazyLock;
use surrealdb::engine::local::{Db, SurrealKv};
use surrealdb::Surreal;
use tokio::sync::Mutex;

pub struct EngineManager {
    root_db: Option<Surreal<Db>>,
    storage_path: Option<String>,
}

static ENGINE: LazyLock<Mutex<EngineManager>> = LazyLock::new(|| {
    Mutex::new(EngineManager {
        root_db: None,
        storage_path: None,
    })
});

impl EngineManager {
    /// Initializes the root SurrealKV engine instance.
    pub async fn init(storage_path: &str) -> Result<()> {
        let mut guard = ENGINE.lock().await;
        if guard.root_db.is_none() {
            tracing::info!("DB: Initializing root SurrealKV engine at {}", storage_path);
            let db = Surreal::new::<SurrealKv>(storage_path).await?;
            guard.root_db = Some(db);
            guard.storage_path = Some(storage_path.to_string());
        }
        Ok(())
    }

    /// Acquires a session-scoped client for a given map.
    pub async fn open_map_db(map_id: &str, map_name: &str) -> Result<Surreal<Db>> {
        let root = {
            let guard = ENGINE.lock().await;
            guard
                .root_db
                .clone()
                .ok_or_else(|| anyhow::anyhow!("EngineManager not initialized"))?
        };

        let session_db = root.clone();
        let db_name = if map_id.starts_with("map_") {
            map_id.to_string()
        } else {
            format!("map_{}", map_id)
        };

        session_db.use_ns("centrode").use_db(&db_name).await?;

        // Initialize schema and seed default data if newly created
        Schema::init(&session_db).await?;
        Seeder::seed_default_data(&session_db, map_name.to_string()).await?;

        Ok(session_db)
    }

    /// Drops the database for a deleted map.
    pub async fn delete_map_db(map_id: &str) -> Result<()> {
        let root = {
            let guard = ENGINE.lock().await;
            guard
                .root_db
                .clone()
                .ok_or_else(|| anyhow::anyhow!("EngineManager not initialized"))?
        };
        let db_name = if map_id.starts_with("map_") {
            map_id.to_string()
        } else {
            format!("map_{}", map_id)
        };
        root.query(format!("REMOVE DATABASE {};", db_name)).await?;
        Ok(())
    }

    /// Drops all engine handles, releasing OS file locks.
    pub async fn shutdown() -> Result<()> {
        let mut guard = ENGINE.lock().await;
        guard.root_db = None;
        tracing::info!("DB: Root SurrealKV engine shut down, locks released.");
        Ok(())
    }

    pub fn is_initialized() -> bool {
        ENGINE.try_lock().map(|g| g.root_db.is_some()).unwrap_or(false)
    }
}

pub struct Database;

impl Database {
    /// Connects to the embedded SurrealDB (SurrealKV) and initializes the schema.
    /// Returns the database instance directly (No global state).
    pub async fn connect(
        path: &str,
        name: String,
        namespace: Option<&str>,
        database: Option<&str>,
    ) -> Result<Surreal<Db>> {
        tracing::info!("DB: Initializing SurrealKV at path: {}", path);

        let db = Surreal::new::<SurrealKv>(path).await?;
        let ns = namespace.unwrap_or("centrode");
        let db_name = database.unwrap_or("core");

        db.use_ns(ns).use_db(db_name).await?;
        Schema::init(&db).await?;
        Seeder::seed_default_data(&db, name).await?;

        Ok(db)
    }
}
