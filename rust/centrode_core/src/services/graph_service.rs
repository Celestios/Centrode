use crate::bridge::stream::GraphEvent;
use crate::frb_generated::StreamSink;
use crate::layout_engine::config::LayoutConfig;
use crate::layout_engine::engine::LayoutEngine;
use crate::repo::Repository;
use crate::relation_engine::config::RelationEngineConfig;
use centrode_daemon::EngineManager;
use std::path::{Path, PathBuf};
pub use std::sync::Mutex;
use tokio::sync::broadcast;
use tokio::task::JoinHandle;
use tokio_stream::StreamExt;

pub use crate::domain::styles::{NodeLayout, NodeStyle, RelationLayout, RelationStyle};
pub use crate::relation_engine::engine::RelationEngine;

pub mod history;
pub mod layout;
pub mod metadata;
pub mod node;
pub mod relation;

pub struct GraphService {
    pub repo: Repository,
    pub relation_engine: std::sync::Arc<Mutex<RelationEngine>>,
    pub layout_engine: std::sync::Arc<Mutex<LayoutEngine>>,
    pub event_tx: broadcast::Sender<GraphEvent>,
    tasks: Mutex<Vec<JoinHandle<()>>>,
    pub layout_task: Mutex<Option<JoinHandle<()>>>,
}

impl GraphService {
    pub async fn new(storage_path: String, name: String) -> anyhow::Result<Self> {
        let db = if EngineManager::is_initialized() {
            let map_id = Path::new(&storage_path)
                .file_stem()
                .and_then(|s| s.to_str())
                .unwrap_or(&storage_path);
            EngineManager::open_map_db(map_id, &name).await?
        } else {
            let path = if storage_path.is_empty() {
                directories::ProjectDirs::from("com", "centrode", "centrode")
                    .map(|pd| pd.data_local_dir().join("data.db"))
                    .unwrap_or_else(|| PathBuf::from("centrode.db"))
            } else {
                PathBuf::from(&storage_path)
            };
            EngineManager::connect(path.to_str().unwrap_or(&storage_path), name, None, None).await?
        };

        Ok(Self::with_repository(Repository::new(db)))
    }

    pub async fn open(map_id: &str, name: &str) -> anyhow::Result<Self> {
        let db = EngineManager::open_map_db(map_id, name).await?;
        Ok(Self::with_repository(Repository::new(db)))
    }

    pub fn with_repository(repo: Repository) -> Self {
        let relation_engine = std::sync::Arc::new(Mutex::new(RelationEngine::new(
            RelationEngineConfig::default(),
        )));
        let layout_engine = std::sync::Arc::new(Mutex::new(LayoutEngine::new(
            LayoutConfig::default(),
        )));
        let (event_tx, _) = broadcast::channel(1024);
        Self {
            repo,
            relation_engine,
            layout_engine,
            event_tx,
            tasks: Mutex::new(Vec::new()),
            layout_task: Mutex::new(None),
        }
    }

    #[inline]
    pub fn publish_event(&self, event: GraphEvent) {
        let _ = self.event_tx.send(event);
    }

    pub async fn create_graph_stream(&self, sink: StreamSink<GraphEvent>) -> anyhow::Result<()> {
        tracing::debug!("FFI: create_graph_stream called");
        let receiver = self.event_tx.subscribe();

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

        match self.tasks.lock() {
            Ok(mut tasks) => tasks.push(task),
            Err(poisoned) => poisoned.into_inner().push(task),
        }

        Ok(())
    }

    pub fn close(&self) -> anyhow::Result<()> {
        tracing::info!("Closing AppHandle, aborting background tasks...");
        if let Ok(mut handle) = self.layout_task.lock() {
            if let Some(t) = handle.take() {
                t.abort();
            }
        }
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
        if let Ok(mut handle) = self.layout_task.lock() {
            if let Some(t) = handle.take() {
                t.abort();
            }
        }
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
