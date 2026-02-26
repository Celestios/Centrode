use crate::bridge::stream::{self, GraphEvent};
use crate::domain::analysis::GraphAnalysis;
use crate::domain::base_models::{Content, MapConfig};
use crate::domain::nodes::{NodeInput, NodeOutput};
use crate::domain::relations::RelationInput;
use crate::format::packager;
use crate::frb_generated::StreamSink;
use crate::persistence::db::Database;
use crate::persistence::repo::Repository;
use crate::telemetry::{connect_log_stream, LogState};
use serde_json;
use tracing::{debug, error, info};

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
    let receiver = crate::telemetry::subscribe_to_logs();

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

// ============================================================================
// Content Serialization FFI Endpoints
// ============================================================================

/// Serialize Content to binary for FFI transport.
/// Used by Flutter to prepare content for efficient transfer.
pub fn serialize_content(content: Content) -> anyhow::Result<Vec<u8>> {
    bincode::serialize(&content).map_err(|e| anyhow::anyhow!("Failed to serialize content: {}", e))
}

/// Deserialize Content from binary FFI payload.
/// Used by Flutter to decode content received from Rust.
pub fn deserialize_content(bytes: Vec<u8>) -> anyhow::Result<Option<Content>> {
    let content: Content = bincode::deserialize(&bytes)
        .map_err(|e| anyhow::anyhow!("Failed to deserialize content: {}", e))?;
    Ok(Some(content))
}

/// Create a simple Content from plain text.
/// Convenience function for creating paragraph content.
pub fn create_content_from_text(text: String) -> Content {
    Content::from_plain_text(text)
}

/// Extract plain text from Content.
/// Used for search indexing and fallback rendering.
pub fn content_to_plain_text(content: Content) -> String {
    content.to_plain_text()
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

    // Helper to calculate and broadcast boundaries
    async fn broadcast_boundaries(&self) {
        if let Ok(bounds) = GraphAnalysis::calculate_global_bounds(self.repo.db()).await {
            stream::publish_event(GraphEvent::BoundaryUpdated(bounds));
        }
    }

    // 2. Node Operations
    // Note: usage of &self eliminates the need for Mutex locking
    pub async fn create_node(&self, input: NodeInput) -> anyhow::Result<String> {
        debug!("FFI: create_node called with input: {:?}", input);
        match self.repo.create_node(input).await {
            Ok(id) => {
                info!("FFI: Successfully committed node to database: {}", id);
                self.broadcast_boundaries().await; // Trigger on creation - requires FRB regeneration
                Ok(id)
            }
            Err(e) => {
                error!("FFI: Database rejection during node creation: {}", e);
                Err(e)
            }
        }
    }

    pub async fn get_node(&self, table: String, id: String) -> anyhow::Result<Option<NodeOutput>> {
        debug!("Fetching node: {}/{}", table, id);
        self.repo.get_node(table, id).await
    }

    pub async fn patch_node_properties(
        &self,
        table: String,
        id: String,
        json_patch: String,
    ) -> anyhow::Result<()> {
        debug!(
            "FFI: patch_node_properties called for {}/{} with patch: {}",
            table, id, json_patch
        );
        let patch: serde_json::Value = serde_json::from_str(&json_patch).map_err(|e| {
            error!("FFI: Failed to parse JSON patch: {}", e);
            e
        })?;

        self.repo
            .patch_node(table.clone(), id.clone(), patch)
            .await
            .map_err(|e| {
                error!(
                    "FFI: Repository failed to patch node {}/{}: {}",
                    table, id, e
                );
                e
            })?;

        // If position was patched, recalculate bounds
        if json_patch.contains("position") {
            self.broadcast_boundaries().await;
        }

        info!("FFI: Node {}/{} patched successfully", table, id);
        Ok(())
    }

    pub async fn delete_node_entry(&self, table: String, id: String) -> anyhow::Result<String> {
        debug!("Deleting node: {}/{}", table, id);
        match self.repo.delete_node(table.clone(), id.clone()).await {
            Ok(deleted_id) => {
                info!("Node {} deleted successfully", deleted_id);
                self.broadcast_boundaries().await; // Trigger recalculation after deletion
                Ok(deleted_id)
            }
            Err(e) => {
                error!("Failed to delete node {}/{}: {}", table, id, e);
                Err(e)
            }
        }
    }

    // 3. Relation Operations
    pub async fn create_relation(&self, input: RelationInput) -> anyhow::Result<String> {
        debug!(
            "FFI: create_relation called: {:?} -> {:?}",
            input.from, input.to
        );
        match self.repo.create_relation(input).await {
            Ok(id) => {
                info!("FFI: Relation created successfully: {}", id);
                Ok(id)
            }
            Err(e) => {
                error!("FFI: Failed to create relation: {}", e);
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
            }
            Err(e) => {
                error!("Failed to delete relation {}: {}", id, e);
                Err(e)
            }
        }
    }

    pub async fn patch_relation(&self, id: String, json_patch: String) -> anyhow::Result<()> {
        debug!(
            "FFI: patch_relation called for {} with patch: {}",
            id, json_patch
        );
        let patch: serde_json::Value = serde_json::from_str(&json_patch).map_err(|e| {
            error!("FFI: Failed to parse JSON patch for relation {}: {}", id, e);
            e
        })?;

        self.repo
            .update_relation_properties(id.clone(), patch)
            .await
            .map_err(|e| {
                error!("FFI: Repository failed to patch relation {}: {}", id, e);
                e
            })?;
        info!("FFI: Relation {} patched successfully", id);
        Ok(())
    }

    pub async fn reroute_relation(
        &self,
        id: String,
        new_from: String,
        new_to: String,
    ) -> anyhow::Result<String> {
        debug!("Rerouting relation {} to: {} -> {}", id, new_from, new_to);
        match self
            .repo
            .reroute_relation(id.clone(), new_from, new_to)
            .await
        {
            Ok(rerouted_id) => {
                info!("Relation {} rerouted successfully", rerouted_id);
                Ok(rerouted_id)
            }
            Err(e) => {
                error!("Failed to reroute relation {}: {}", id, e);
                Err(e)
            }
        }
    }

    // 4. Graph Snapshot
    pub async fn get_graph_snapshot(
        &self,
    ) -> anyhow::Result<(
        Vec<NodeOutput>,
        Vec<crate::domain::relations::IRelation>,
        Option<MapConfig>,
    )> {
        debug!("Fetching graph snapshot");
        let result = self.repo.get_graph_snapshot().await;
        if let Ok((nodes, relations, _config)) = &result {
            info!(
                "Graph snapshot loaded: {} nodes, {} relations",
                nodes.len(),
                relations.len()
            );
        }
        result
    }

    // 5. File Operations
    pub async fn save_map_to_file(
        &self,
        file_path: String,
        attachment_dir: String,
    ) -> anyhow::Result<()> {
        info!("Saving map to file: {}", file_path);
        // 1. Fetch current state from SurrealDB
        let (nodes, relations, metadata) = self.repo.get_graph_snapshot().await?;

        // 2. Clone for logging after the closure
        let file_path_clone = file_path.clone();

        // 3. Offload packaging to blocking thread
        tokio::task::spawn_blocking(move || {
            packager::save_project_to_celi(&file_path, &attachment_dir, nodes, relations, metadata)
        })
        .await??;

        info!("Map saved successfully to {}", file_path_clone);
        Ok(())
    }

    // NEW: Load Map
    pub async fn load_map_from_file(
        &self,
        file_path: String,
        attachment_dir: String,
    ) -> anyhow::Result<()> {
        info!("Loading map from file: {}", file_path);

        // 1. Offload File I/O & Deserialization (Cold -> RAM)
        // This stops the UI from freezing during unzip
        let (nodes, relations, metadata) = tokio::task::spawn_blocking(move || {
            packager::load_project_from_celi(&file_path, &attachment_dir)
        })
        .await??;

        debug!(
            "Loaded {} nodes and {} relations from file",
            nodes.len(),
            relations.len()
        );

        // 2. Persistence Layer: RAM -> DB
        // The Repo now handles the sorting, so the API is clean.
        self.repo
            .import_dynamic_graph(nodes, relations, metadata)
            .await?;

        info!("Map loaded and imported successfully");
        Ok(())
    }

    // 6. Content Operations (Binary Serialization)
    /// Patch node content using raw UTF-8 bytes from Dart.
    /// The content_bytes parameter is raw UTF-8 text, not bincode-serialized.
    /// The Content struct is constructed in Rust where its schema is authoritative.
    pub async fn patch_node_content(
        &self,
        table: String,
        id: String,
        content_bytes: Vec<u8>,
    ) -> anyhow::Result<()> {
        debug!(
            "FFI: patch_node_content called for {}/{} ({} bytes)",
            table,
            id,
            content_bytes.len()
        );

        // FIX: Interpret the incoming bytes as a raw string rather than a
        // bincode-serialized struct to resolve the "unexpected end of file"
        let text = String::from_utf8(content_bytes)
            .map_err(|e| anyhow::anyhow!("Invalid UTF-8 content: {}", e))?;

        // Construct the Content struct in Rust where its schema is authoritative
        let content = Content::from_plain_text(text);

        debug!(
            "FFI: Constructed content for {}/{}: {:?}",
            table, id, content
        );

        // Create the patch with native content object
        let patch = serde_json::json!({
            "content": content
        });

        self.repo
            .patch_node(table.clone(), id.clone(), patch)
            .await
            .map_err(|e| {
                error!(
                    "FFI: Repository failed to patch content for {}/{}: {}",
                    table, id, e
                );
                e
            })?;
        info!("FFI: Node content {}/{} patched successfully", table, id);
        Ok(())
    }

    // 7. Theme Operations
    pub async fn get_all_themes(&self) -> anyhow::Result<Vec<crate::domain::base_models::Theme>> {
        let mut res = self.repo.db().query("SELECT * FROM theme").await?;
        let themes: Vec<crate::domain::base_models::Theme> = res.take(0)?;
        Ok(themes)
    }

    pub async fn get_active_theme_id(&self) -> anyhow::Result<Option<String>> {
        let mut res = self
            .repo
            .db()
            .query("SELECT active_theme_id FROM map_metadata LIMIT 1")
            .await?;
        let result: Option<serde_json::Value> = res.take(0)?;
        if let Some(val) = result {
            if let Some(id_val) = val.get("active_theme_id") {
                if let Some(id_str) = id_val.as_str() {
                    // SurrealDB record IDs look like "theme:id"
                    return Ok(Some(id_str.replace("theme:", "")));
                }
            }
        }
        Ok(None)
    }

    pub async fn set_active_theme_id(&self, theme_id: String) -> anyhow::Result<()> {
        let theme_record = format!("theme:{}", theme_id);
        self.repo
            .db()
            .query("UPDATE map_metadata SET active_theme_id = $theme_id")
            .bind(("theme_id", theme_record))
            .await?;
        Ok(())
    }

    pub async fn upsert_theme(
        &self,
        theme: crate::domain::base_models::Theme,
    ) -> anyhow::Result<String> {
        let mut res = if let Some(id) = theme.id.clone() {
            let theme_record = format!("theme:{}", id);
            self.repo
                .db()
                .query("UPDATE $id MERGE $theme")
                .bind(("id", theme_record))
                .bind(("theme", theme))
                .await?
        } else {
            self.repo
                .db()
                .query("CREATE theme CONTENT $theme")
                .bind(("theme", theme))
                .await?
        };

        let result: Option<crate::domain::base_models::Theme> = res.take(0)?;
        result
            .and_then(|t| t.id)
            .ok_or_else(|| anyhow::anyhow!("Failed to upsert theme"))
    }

    // 7. Graph Stream Connection
    /// Creates a stream connection for graph events.
    /// This enables Flutter to receive async updates about node changes.
    pub async fn create_graph_stream(&self, sink: StreamSink<GraphEvent>) -> anyhow::Result<()> {
        let receiver = stream::subscribe_to_graph();

        tokio::spawn(async move {
            use tokio_stream::StreamExt;
            let stream = tokio_stream::wrappers::BroadcastStream::new(receiver);
            tokio::pin!(stream);

            while let Some(result) = stream.next().await {
                match result {
                    Ok(event) => {
                        if sink.add(event).is_err() {
                            break; // Flutter disconnected
                        }
                    }
                    Err(_) => continue, // Skip lagged messages
                }
            }
        });

        Ok(())
    }
}
