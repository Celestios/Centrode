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

    /// Obtains the root database handle.
    pub async fn root_db() -> Result<Surreal<Db>> {
        let guard = ENGINE.lock().await;
        guard
            .root_db
            .clone()
            .ok_or_else(|| anyhow::anyhow!("EngineManager not initialized"))
    }

    /// Obtains the configured storage path.
    pub async fn storage_path() -> Result<String> {
        let guard = ENGINE.lock().await;
        guard
            .storage_path
            .clone()
            .ok_or_else(|| anyhow::anyhow!("EngineManager not initialized"))
    }

    /// Obtains a client scoped to the system database: `centrode:system`.
    pub async fn system_db() -> Result<Surreal<Db>> {
        let db = Self::root_db().await?;
        db.use_ns("centrode").use_db("system").await?;
        Ok(db)
    }

    /// Obtains a client scoped to a specific map database: `centrode:map_<id>`.
    pub async fn map_db(map_id: &str) -> Result<Surreal<Db>> {
        let db = Self::root_db().await?;
        let db_name = if map_id.starts_with("map_") {
            map_id.to_string()
        } else {
            format!("map_{}", map_id)
        };
        db.use_ns("centrode").use_db(&db_name).await?;
        Ok(db)
    }

    /// Acquires a session-scoped client for a given map and ensures schema is initialized.
    pub async fn open_map_db(map_id: &str, map_name: &str) -> Result<Surreal<Db>> {
        let session_db = Self::map_db(map_id).await?;
        crate::schema::Schema::init(&session_db).await?;
        crate::schema::Seeder::seed_default_data(&session_db, map_name.to_string()).await?;
        Ok(session_db)
    }

    /// Connects to embedded SurrealDB (SurrealKV) directly.
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
        crate::schema::Schema::init(&db).await?;
        crate::schema::Seeder::seed_default_data(&db, name).await?;
        Ok(db)
    }

    /// Drops the database for a deleted map.
    pub async fn delete_map_db(map_id: &str) -> Result<()> {
        let root = Self::root_db().await?;
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
        guard.storage_path = None;
        tracing::info!("DB: Root SurrealKV engine shut down, locks released.");
        Ok(())
    }

    pub fn is_initialized() -> bool {
        ENGINE.try_lock().map(|g| g.root_db.is_some()).unwrap_or(false)
    }
}
