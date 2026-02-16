use crate::persistence::db::Database;
use crate::persistence::repo::Repository;
use crate::domain::nodes::{NodeInput, NodeOutput};
use crate::domain::relations::RelationInput;
use crate::format::packager;
use crate::telemetry::{LogState, connect_log_stream};
use crate::frb_generated::StreamSink;
use serde_json;
use tracing::{info, debug, error};

// ============================================================================
// Telemetry FFI Endpoints
// ============================================================================

/// Initialization endpoint for the telemetry layer.
/// Called by Dart during app startup to initialize the tracing subscriber.
pub async fn setup_logger() -> anyhow::Result<()> {
    crate::telemetry::init_telemetry();
    Ok(())
}

/// Stream connection endpoint for FFI.
/// Dart calls this after the DiskWriterIsolate is ready.
/// Flushes the pre-stream buffer and starts streaming logs.
pub async fn create_log_stream(sink: StreamSink<LogState>) -> anyhow::Result<()> {
    // Connect the stream and flush buffer
    connect_log_stream();
    
    // Subscribe to the broadcast channel
    let mut receiver = crate::telemetry::subscribe_to_logs();
    
    // Spawn a task to forward logs to the sink
    tokio::spawn(async move {
        use tokio_stream::StreamExt;
        let stream = tokio_stream::wrappers::BroadcastStream::new(receiver);
        tokio::pin!(stream);
        
        while let Some(result) = stream.next().await {
            match result {
                Ok(log_state) => {
                    if sink.add(log_state).is_err() {
                        break; // Sink closed
                    }
                }
                Err(_) => continue, // Skip lagged messages
            }
        }
    });
    
    Ok(())
}

// [NEW] Event Enum for the UI (Keep public for FFI)
#[derive(Debug, Clone)]
pub enum GraphEvent {
    NodeUpdated(NodeOutput),
    NodeDeleted(String),
    RelationUpdated,
    SnapshotLoaded,
}

// [NEW] The Opaque App Handle
// This struct holds the entire state of the running backend.
pub struct AppHandle {
    pub repo: Repository,
}

impl AppHandle {
    // 1. App Initialization (The Constructor)
    pub async fn new(storage_path: String) -> anyhow::Result<Self> {
        debug!("Initializing AppHandle with storage path: {}", storage_path);
        let db = Database::connect(&storage_path).await?;
        let repo = Repository::new(db);
        info!("AppHandle initialized successfully");
        Ok(Self { repo })
    }

    // 2. Node Operations
    // Note: usage of &self eliminates the need for Mutex locking
    pub async fn create_node(&self, input: NodeInput) -> anyhow::Result<String> {
        debug!("Received FFI request to create node: {:?}", input);
        match self.repo.create_node(input).await {
            Ok(id) => {
                info!("Successfully committed node to database: {}", id);
                Ok(id)
            },
            Err(e) => {
                error!("Database rejection during node creation: {}", e);
                Err(e)
            }
        }
    }

    pub async fn get_node(&self, table: String, id: String) -> anyhow::Result<Option<NodeOutput>> {
        debug!("Fetching node: {}/{}", table, id);
        self.repo.get_node(table, id).await
    }

    pub async fn patch_node_properties(&self, table: String, id: String, json_patch: String) -> anyhow::Result<()> {
        debug!("Patching node {}/{} with: {}", table, id, json_patch);
        let patch: serde_json::Value = serde_json::from_str(&json_patch)?;
        self.repo.patch_node(table.clone(), id.clone(), patch).await?;
        info!("Node {}/{} patched successfully", table, id);
        Ok(())
    }

    pub async fn delete_node_entry(&self, table: String, id: String) -> anyhow::Result<String> {
        debug!("Deleting node: {}/{}", table, id);
        match self.repo.delete_node(table.clone(), id.clone()).await {
            Ok(deleted_id) => {
                info!("Node {} deleted successfully", deleted_id);
                Ok(deleted_id)
            },
            Err(e) => {
                error!("Failed to delete node {}/{}: {}", table, id, e);
                Err(e)
            }
        }
    }

    // 3. Relation Operations
    pub async fn create_relation(&self, input: RelationInput) -> anyhow::Result<String> {
        debug!("Creating relation: {:?} -> {:?}", input.from, input.to);
        match self.repo.create_relation(input).await {
            Ok(id) => {
                info!("Relation created successfully: {}", id);
                Ok(id)
            },
            Err(e) => {
                error!("Failed to create relation: {}", e);
                Err(e)
            }
        }
    }

    pub async fn delete_relation(&self, id: String) -> anyhow::Result<String> {
        debug!("Deleting relation: {}", id);
        match self.repo.delete_relation(id.clone()).await {
            Ok(deleted_id) => {
                info!("Relation {} deleted successfully", deleted_id);
                Ok(deleted_id)
            },
            Err(e) => {
                error!("Failed to delete relation {}: {}", id, e);
                Err(e)
            }
        }
    }

    pub async fn patch_relation(&self, id: String, json_patch: String) -> anyhow::Result<()> {
        debug!("Patching relation {} with: {}", id, json_patch);
        let patch: serde_json::Value = serde_json::from_str(&json_patch)?;
        self.repo.update_relation_properties(id.clone(), patch).await?;
        info!("Relation {} patched successfully", id);
        Ok(())
    }

    pub async fn reroute_relation(&self, id: String, new_from: String, new_to: String) -> anyhow::Result<String> {
        debug!("Rerouting relation {} to: {} -> {}", id, new_from, new_to);
        match self.repo.reroute_relation(id.clone(), new_from, new_to).await {
            Ok(rerouted_id) => {
                info!("Relation {} rerouted successfully", rerouted_id);
                Ok(rerouted_id)
            },
            Err(e) => {
                error!("Failed to reroute relation {}: {}", id, e);
                Err(e)
            }
        }
    }

    // 4. Graph Snapshot
    pub async fn get_graph_snapshot(&self) -> anyhow::Result<(Vec<NodeOutput>, Vec<crate::domain::relations::IRelation>, Option<crate::domain::config::MapConfig>)> {
        debug!("Fetching graph snapshot");
        let result = self.repo.get_graph_snapshot().await;
        if let Ok((nodes, relations, _config)) = &result {
            info!("Graph snapshot loaded: {} nodes, {} relations", nodes.len(), relations.len());
        }
        result
    }

    pub async fn start_graph_stream(&self) -> anyhow::Result<()> {
        debug!("Starting graph stream (placeholder)");
        // Placeholder: Implement live queries or broadcast channel
        Ok(())
    }

    // 5. File Operations
    pub async fn save_map_to_file(&self, file_path: String, attachment_dir: String) -> anyhow::Result<()> {
        info!("Saving map to file: {}", file_path);
        // 1. Fetch current state from SurrealDB
        let (nodes, relations, metadata) = self.repo.get_graph_snapshot().await?;

        // 2. Clone for logging after the closure
        let file_path_clone = file_path.clone();
        
        // 3. Offload packaging to blocking thread
        tokio::task::spawn_blocking(move || {
            packager::save_project_to_celi(&file_path, &attachment_dir, nodes, relations, metadata)
        }).await??;

        info!("Map saved successfully to {}", file_path_clone);
        Ok(())
    }

    // NEW: Load Map
    pub async fn load_map_from_file(&self, file_path: String, attachment_dir: String) -> anyhow::Result<()> {
        info!("Loading map from file: {}", file_path);

        // 1. Offload File I/O & Deserialization (Cold -> RAM)
        // This stops the UI from freezing during unzip
        let (nodes, relations, metadata) = tokio::task::spawn_blocking(move || {
            packager::load_project_from_celi(&file_path, &attachment_dir)
        }).await??;

        debug!("Loaded {} nodes and {} relations from file", nodes.len(), relations.len());

        // 2. Persistence Layer: RAM -> DB
        // The Repo now handles the sorting, so the API is clean.
        self.repo.import_dynamic_graph(nodes, relations, metadata).await?;

        info!("Map loaded and imported successfully");
        Ok(())
    }
}
