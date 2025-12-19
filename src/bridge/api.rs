use crate::persistence::db::Database;
use crate::persistence::repo::Repository;
use crate::domain::nodes::NodeInput;
use crate::domain::relations::RelationInput;
use crate::domain::nodes::NodeOutput;
use crate::format::packager; // Import the packager

// [NEW] Event Enum for the UI
#[derive(Debug, Clone)]
pub enum GraphEvent {
    NodeUpdated(NodeOutput),
    NodeDeleted(String),
    RelationUpdated,
    SnapshotLoaded,
}

// 1. App Initialization
pub async fn init_app(storage_path: String) -> anyhow::Result<()> {
    Database::connect(&storage_path).await?;
    Ok(())
}

// 2. Node Operations
pub async fn create_node(id: String, input: NodeInput) -> anyhow::Result<String> {
    Repository::create_node(id, input).await
}

pub async fn get_node(table: String, id: String) -> anyhow::Result<Option<NodeOutput>> {
    Repository::get_node(table, id).await
}

// 3. Relation Operations
pub async fn create_relation(input: RelationInput) -> anyhow::Result<String> {
    Repository::create_relation(input).await
}

// 4. Graph Snapshot
pub async fn get_graph_snapshot() -> anyhow::Result<(Vec<NodeOutput>, Vec<crate::domain::relations::IRelation>, Option<crate::domain::config::MapConfig>)> {
    Repository::get_graph_snapshot().await
}

pub async fn start_graph_stream() -> anyhow::Result<()> {
    // Placeholder: Implement live queries or broadcast channel
    Ok(())
}

// 5. File Operations
pub async fn save_map_to_file(file_path: String, attachment_dir: String) -> anyhow::Result<()> {
    // 1. Fetch current state from RocksDB
    // This runs efficiently in the async runtime
    let (nodes, relations, metadata) = Repository::get_graph_snapshot().await?;

    // 2. Offload the blocking Zip/IO operations to a thread
    // Prevents freezing the UI during large saves
    tokio::task::spawn_blocking(move || {
        packager::save_project_to_celi(&file_path, &attachment_dir, nodes, relations, metadata)
    }).await??;

    Ok(())
}