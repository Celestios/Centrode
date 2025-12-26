use crate::persistence::db::Database;
use crate::persistence::repo::Repository;
use crate::domain::nodes::{NodeInput, NodeOutput};
use crate::domain::relations::RelationInput;
use crate::format::packager;
use serde_json;

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
        let db = Database::connect(&storage_path).await?;
        let repo = Repository::new(db);
        Ok(Self { repo })
    }

    // 2. Node Operations
    // Note: usage of &self eliminates the need for Mutex locking
    pub async fn create_node(&self, input: NodeInput) -> anyhow::Result<String> {
        self.repo.create_node(input).await
    }

    pub async fn get_node(&self, table: String, id: String) -> anyhow::Result<Option<NodeOutput>> {
        self.repo.get_node(table, id).await
    }

    pub async fn patch_node_properties(&self, table: String, id: String, json_patch: String) -> anyhow::Result<()> {
        let patch: serde_json::Value = serde_json::from_str(&json_patch)?;
        self.repo.patch_node(table, id, patch).await?;
        Ok(())
    }

    pub async fn delete_node_entry(&self, table: String, id: String) -> anyhow::Result<String> {
        self.repo.delete_node(table, id).await
    }

    // 3. Relation Operations
    pub async fn create_relation(&self, input: RelationInput) -> anyhow::Result<String> {
        self.repo.create_relation(input).await
    }

    pub async fn delete_relation(&self, id: String) -> anyhow::Result<String> {
        self.repo.delete_relation(id).await
    }

    pub async fn patch_relation(&self, id: String, json_patch: String) -> anyhow::Result<()> {
        let patch: serde_json::Value = serde_json::from_str(&json_patch)?;
        self.repo.update_relation_properties(id, patch).await?;
        Ok(())
    }

    pub async fn reroute_relation(&self, id: String, new_from: String, new_to: String) -> anyhow::Result<String> {
        self.repo.reroute_relation(id, new_from, new_to).await
    }

    // 4. Graph Snapshot
    pub async fn get_graph_snapshot(&self) -> anyhow::Result<(Vec<NodeOutput>, Vec<crate::domain::relations::IRelation>, Option<crate::domain::config::MapConfig>)> {
        self.repo.get_graph_snapshot().await
    }

    pub async fn start_graph_stream(&self) -> anyhow::Result<()> {
        // Placeholder: Implement live queries or broadcast channel
        Ok(())
    }

    // 5. File Operations
    pub async fn save_map_to_file(&self, file_path: String, attachment_dir: String) -> anyhow::Result<()> {
        // 1. Fetch current state from RocksDB
        let (nodes, relations, metadata) = self.repo.get_graph_snapshot().await?;

        // 2. Offload packaging to blocking thread
        tokio::task::spawn_blocking(move || {
            packager::save_project_to_celi(&file_path, &attachment_dir, nodes, relations, metadata)
        }).await??;

        Ok(())
    }
}