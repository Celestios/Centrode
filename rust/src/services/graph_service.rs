use crate::bridge::stream::{self, GraphEvent};
use crate::frb_generated::StreamSink;
use crate::persistence::db::Database;
use crate::persistence::repo::Repository;
use crate::relation_engine::config::RelationEngineConfig;
use crate::telemetry::{connect_log_stream, init_telemetry, subscribe_to_logs, LogState};
use directories::ProjectDirs;
use std::path::PathBuf;
pub use std::sync::Mutex;
use tokio::task::JoinHandle;
use tokio_stream::StreamExt;

pub use crate::domain::styles::{NodeLayout, NodeStyle, RelationLayout, RelationStyle};
pub use crate::relation_engine::engine::RelationEngine;

pub mod history;
pub mod metadata;
pub mod node;
pub mod relation;

pub struct GraphService {
    pub repo: Repository,
    pub relation_engine: std::sync::Arc<Mutex<RelationEngine>>,
    tasks: Mutex<Vec<JoinHandle<()>>>,
}

impl GraphService {
    pub async fn new(storage_path: String, name: String) -> anyhow::Result<Self> {
        let path = if storage_path.is_empty() {
            ProjectDirs::from("com", "centrode", "centrode")
                .map(|pd| pd.data_local_dir().join("data.db"))
                .unwrap_or_else(|| PathBuf::from("centrode.db"))
        } else {
            PathBuf::from(&storage_path)
        };

        let db =
            Database::connect(path.to_str().unwrap_or(&storage_path), name, None, None).await?;
        Ok(Self::with_repository(Repository::new(db)))
    }

    pub fn with_repository(repo: Repository) -> Self {
        let relation_engine = std::sync::Arc::new(Mutex::new(RelationEngine::new(
            RelationEngineConfig::default(),
        )));
        Self {
            repo,
            relation_engine,
            tasks: Mutex::new(Vec::new()),
        }
    }

    pub async fn create_graph_stream(&self, sink: StreamSink<GraphEvent>) -> anyhow::Result<()> {
        tracing::debug!("FFI: create_graph_stream called");
        let receiver = stream::subscribe_to_graph();

        let task = tokio::spawn(async move {
            let stream = tokio_stream::wrappers::BroadcastStream::new(receiver);
            tokio::pin!(stream);

            while let Some(result) = stream.next().await {
                match result {
                    Ok(event) => {
                        if sink.add(event).is_err() {
                            break;
                        }
                    }
                    Err(e) => {
                        tracing::warn!("FFI: Graph stream overflow. Dropped events: {}", e);
                        continue;
                    }
                }
            }
        });

        self.tasks.lock().unwrap().push(task);

        Ok(())
    }

    pub fn close(&self) -> anyhow::Result<()> {
        tracing::info!("Closing AppHandle, aborting background tasks...");
        match self.tasks.lock() {
            Ok(mut tasks) => {
                for task in tasks.drain(..) {
                    task.abort();
                }
            }
            Err(poisoned) => {
                let mut tasks = poisoned.into_inner();
                tracing::warn!("Mutex poisoned while closing; aborting tasks anyway.");
                for task in tasks.drain(..) {
                    task.abort();
                }
            }
        }
        Ok(())
    }
}

impl Drop for GraphService {
    fn drop(&mut self) {
        tracing::info!("Dropping AppHandle, aborting background tasks...");
        match self.tasks.lock() {
            Ok(mut tasks) => {
                for task in tasks.drain(..) {
                    task.abort();
                }
            }
            Err(_) => {
                tracing::error!(
                    "Mutex poisoned while dropping AppHandle; background tasks not aborted."
                );
            }
        }
    }
}

// ============================================================================
// Telemetry FFI Endpoints (standalone, no AppHandle)
// ============================================================================

pub async fn setup_logger() -> anyhow::Result<()> {
    init_telemetry();
    tracing::debug!("FFI: setup_logger completed");
    Ok(())
}

pub async fn create_log_stream(sink: StreamSink<LogState>) -> anyhow::Result<()> {
    tracing::debug!("FFI: create_log_stream called");

    connect_log_stream();

    let receiver = subscribe_to_logs();

    tokio::spawn(async move {
        let stream = tokio_stream::wrappers::BroadcastStream::new(receiver);
        tokio::pin!(stream);

        while let Some(result) = stream.next().await {
            match result {
                Ok(log_state) => {
                    if sink.add(log_state).is_err() {
                        break;
                    }
                }
                Err(e) => {
                    tracing::warn!("FFI: Log stream overflow. Dropped messages: {}", e);
                    continue;
                }
            }
        }
    });

    Ok(())
}
