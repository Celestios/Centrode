use crate::bridge::stream::{self, GraphEvent};
use crate::domain::base_models::{IsTable, RecordStrings, ViewportState};
use crate::domain::nodes::Nodes;
use crate::domain::snapshot::GraphSnapshot;
use crate::domain::tags::Tag;
use crate::domain::templates::Template;

use crate::domain::patches::{EntityPatch, SymmetricEntityPatch};
use crate::domain::relations::IRelation;
use crate::domain::theme::{Theme, ThemeFields};
use crate::format::packager;
use crate::frb_generated::StreamSink;
use crate::persistence::db::Database;
use crate::persistence::history::HistoryRecord;
use crate::persistence::repo::Repository;
use crate::telemetry::{connect_log_stream, init_telemetry, LogState};
use directories::ProjectDirs;
use std::collections::BTreeMap;
use std::path::PathBuf;
use std::sync::Mutex;
use surrealdb::types::{SurrealValue, Value};
use tokio::task::JoinHandle;
use tracing::{debug, error, info};

// ============================================================================
// Telemetry FFI Endpoints
// ============================================================================

pub async fn setup_logger() -> anyhow::Result<()> {
    init_telemetry();
    tracing::debug!("FFI: setup_logger completed");
    Ok(())
}

pub async fn create_log_stream(sink: StreamSink<LogState>) -> anyhow::Result<()> {
    tracing::debug!("FFI: create_log_stream called");

    connect_log_stream();

    let receiver = crate::telemetry::subscribe_to_logs();

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
                Err(e) => {
                    // Logs tokio_stream::wrappers::errors::BroadcastStreamRecvError::Lagged
                    tracing::warn!("FFI: Log stream overflow. Dropped messages: {}", e);
                    continue;
                }
            }
        }
    });

    Ok(())
}

pub struct AppHandle {
    pub repo: Repository,
    tasks: Mutex<Vec<JoinHandle<()>>>,
}

impl AppHandle {
    pub async fn new(storage_path: String, name: String) -> anyhow::Result<Self> {
        let path = if storage_path.is_empty() {
            ProjectDirs::from("com", "mycelium", "mycelium")
                .map(|pd| pd.data_local_dir().join("data.db"))
                .unwrap_or_else(|| PathBuf::from("mycelium.db"))
        } else {
            PathBuf::from(&storage_path)
        };

        let db =
            Database::connect(path.to_str().unwrap_or(&storage_path), name, None, None).await?;
        Ok(Self::with_repository(Repository::new(db)))
    }

    pub fn with_repository(repo: Repository) -> Self {
        Self {
            repo,
            tasks: Mutex::new(Vec::new()),
        }
    }

    async fn broadcast_boundaries(&self) {
        match self.repo.calculate_global_bounds().await {
            Ok(bounds) => {
                info!("FFI: Broadcasting bounds: {:?}", bounds);
                stream::publish_event(GraphEvent::BoundaryUpdated(bounds));
            }
            Err(e) => {
                error!("FFI: Failed to calculate global bounds: {}", e);
            }
        }
    }

    async fn rebuild_node_cache(&self) {
        self.repo.clear_node_cache();
        let _ = self.repo.get_graph_snapshot().await;
    }

    pub async fn create_node(&self, input: Nodes) -> anyhow::Result<()> {
        debug!("FFI: create_node called with input: {:?}", input);
        self.repo.create_node(input.clone()).await?;

        let (table, key) = input.table_and_key();
        self.repo
            .record_patch_history(
                RecordStrings {
                    table: table.to_string(),
                    key: key.to_string(),
                },
                EntityPatch::CreateNode(input.clone(), vec![]),
                EntityPatch::DeleteNode(input, vec![]),
            )
            .await?;

        self.broadcast_boundaries().await;
        Ok(())
    }

    pub async fn get_node(&self, table: String, key: String) -> anyhow::Result<Option<Nodes>> {
        debug!("Fetching node: {}/{}", &table, &key);
        self.repo.get_node(table, key).await
    }

    pub async fn update_node(&self, input: Nodes) -> anyhow::Result<()> {
        let (table, key) = input.table_and_key();
        if let Some(old) = self
            .repo
            .get_node(table.to_string(), key.to_string())
            .await?
        {
            self.repo.update_node(input.clone()).await.map_err(|e| {
                error!("FFI: Repository failed to update node {}", e);
                e
            })?;

            self.repo
                .record_patch_history(
                    RecordStrings {
                        table: table.to_string(),
                        key: key.to_string(),
                    },
                    EntityPatch::CreateNode(input.clone(), vec![]),
                    EntityPatch::CreateNode(old, vec![]),
                )
                .await?;
        } else {
            self.repo.update_node(input).await.map_err(|e| {
                error!("FFI: Repository failed to update node {}", e);
                e
            })?;
        }
        Ok(())
    }

    pub async fn apply_entity_mutation(
        &self,
        mutation: SymmetricEntityPatch,
    ) -> anyhow::Result<()> {
        if self
            .repo
            .apply_patch_check_position(&mutation.id, &mutation.forward)
            .await?
        {
            self.broadcast_boundaries().await;
        }
        self.repo.apply_cache_patch(&mutation.id, &mutation.forward);
        self.repo
            .record_patch_history(mutation.id, mutation.forward, mutation.reverse)
            .await?;
        Ok(())
    }

    pub async fn delete_node_entry(&self, table: String, key: String) -> anyhow::Result<()> {
        debug!("Deleting node: {}/{}", table, key);
        if let Some(node) = self.repo.get_node(table.clone(), key.clone()).await? {
            let connected_relations = self.repo.get_connected_relations(&key).await?;

            self.repo.delete_node(table.clone(), key.clone()).await?;

            self.repo
                .record_patch_history(
                    RecordStrings {
                        table: table.clone(),
                        key: key.clone(),
                    },
                    EntityPatch::DeleteNode(node.clone(), connected_relations.clone()),
                    EntityPatch::CreateNode(node, connected_relations),
                )
                .await?;

            self.broadcast_boundaries().await;
            Ok(())
        } else {
            Err(anyhow::anyhow!("Node not found for deletion"))
        }
    }

    pub async fn create_relation(&self, input: IRelation) -> anyhow::Result<()> {
        debug!(
            "FFI: create_relation called: {} -> {}",
            input.in_, input.out
        );
        self.repo.create_relation(input.clone()).await?;

        self.repo
            .record_patch_history(
                RecordStrings {
                    table: IRelation::LABEL.to_string(),
                    key: input.key.clone(),
                },
                EntityPatch::CreateRelation(input.clone()),
                EntityPatch::DeleteRelation(input),
            )
            .await?;

        Ok(())
    }

    pub async fn delete_relation(&self, table: String, key: String) -> anyhow::Result<()> {
        debug!("Deleting relation: {}", key);
        let rel = self.repo.get_relation(table.clone(), key.clone()).await?;

        self.repo
            .delete_relation(table.clone(), key.clone())
            .await?;

        self.repo
            .record_patch_history(
                RecordStrings {
                    table: table.clone(),
                    key: key.clone(),
                },
                EntityPatch::DeleteRelation(rel.clone()),
                EntityPatch::CreateRelation(rel),
            )
            .await?;

        Ok(())
    }

    pub async fn update_relation(&self, input: IRelation) -> anyhow::Result<()> {
        debug!("FFI: update_relation called for {} with patch", input.key);

        self.repo
            .update_relation("IRelation".to_string(), input.key.clone(), input.fields)
            .await
            .map_err(|e| {
                error!(
                    "FFI: Repository failed to patch relation {}: {}",
                    input.key, e
                );
                e
            })?;
        info!("FFI: Relation {} patched successfully", input.key);
        Ok(())
    }

    pub async fn reroute_relation(
        &self,
        record: RecordStrings,
        from: RecordStrings,
        to: RecordStrings,
    ) -> anyhow::Result<()> {
        debug!(
            "Rerouting relation {} to: {} -> {}",
            record.to_str(),
            from.to_str(),
            to.to_str()
        );
        let id = record.to_str();
        match self.repo.reroute_relation(record, from, to).await {
            Ok(rerouted_id) => {
                info!("Relation {} rerouted successfully", id);
                Ok(rerouted_id)
            }
            Err(e) => {
                error!("Failed to reroute relation {}: {}", id, e);
                Err(e)
            }
        }
    }

    pub async fn get_graph_snapshot(&self) -> anyhow::Result<GraphSnapshot> {
        let res = self.repo.get_graph_snapshot().await?;
        Ok(res)
    }

    pub async fn save_map_to_file(
        &self,
        file_path: String,
        attachment_dir: String,
    ) -> anyhow::Result<()> {
        let snapshot = self.repo.get_graph_snapshot().await?;

        let mut content: BTreeMap<String, Vec<Value>> = BTreeMap::new();

        for node in snapshot.nodes {
            let label = node.table_and_key().0.to_string();
            content.entry(label).or_default().push(node.into_value());
        }

        content.insert(
            IRelation::LABEL.into(),
            snapshot
                .relations
                .into_iter()
                .map(|r| r.into_value())
                .collect(),
        );

        tokio::task::spawn_blocking(move || {
            packager::save_project_to_celi(&file_path, &attachment_dir, content, snapshot.metadata)
        })
        .await??;

        Ok(())
    }

    pub async fn load_map_from_file(
        &self,
        file_path: String,
        attachment_dir: String,
    ) -> anyhow::Result<()> {
        let (mut content, metadata) = tokio::task::spawn_blocking(move || {
            packager::load_project_from_celi(&file_path, &attachment_dir)
        })
        .await??;

        let mut nodes = Vec::new();
        for &table in Nodes::TABLES {
            if let Some(list) = content.remove(table) {
                for val in list {
                    match Nodes::from_struct_value(table, val) {
                        Ok(node) => nodes.push(node),
                        Err(e) => tracing::error!(
                            "Failed to deserialize node from table {}: {:?}",
                            table,
                            e
                        ),
                    }
                }
            }
        }

        let irelations: Vec<IRelation> = content
            .remove(IRelation::LABEL)
            .unwrap_or_default()
            .iter()
            .map(|v| IRelation::from_value(v.clone()).unwrap())
            .collect();

        self.repo
            .set_graph_snapshot(GraphSnapshot {
                nodes,
                relations: irelations,
                metadata,
            })
            .await?;

        Ok(())
    }

    pub async fn get_all_themes(&self) -> anyhow::Result<Vec<Theme>> {
        self.repo.get_all_themes().await
    }

    pub async fn get_theme(&self, key: String) -> anyhow::Result<Option<Theme>> {
        self.repo.get_theme(key).await
    }

    pub async fn set_active_theme_id(&self, theme_id: String) -> anyhow::Result<()> {
        self.repo.set_active_theme_id(theme_id).await
    }

    pub async fn update_viewport_state(&self, state: ViewportState) -> anyhow::Result<()> {
        self.repo.update_viewport_state(state).await
    }

    pub async fn get_active_theme_id(&self) -> anyhow::Result<Option<String>> {
        self.repo.get_active_theme_id().await
    }

    pub async fn set_active_theme(&self, theme_key: String) -> anyhow::Result<()> {
        self.repo.set_active_theme(theme_key).await
    }

    pub async fn create_theme(&self, key: String, fields: ThemeFields) -> anyhow::Result<()> {
        self.repo.create_theme(key, fields).await
    }

    pub async fn update_theme(&self, theme: Theme) -> anyhow::Result<()> {
        self.repo.update_theme(theme).await
    }

    pub async fn create_graph_stream(&self, sink: StreamSink<GraphEvent>) -> anyhow::Result<()> {
        tracing::debug!("FFI: create_graph_stream called");
        let receiver = stream::subscribe_to_graph();

        let task = tokio::spawn(async move {
            use tokio_stream::StreamExt;
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

    pub fn close(self) -> anyhow::Result<()> {
        tracing::info!("Closing AppHandle, aborting background tasks...");
        match self.tasks.lock() {
            Ok(mut tasks) => {
                for task in tasks.drain(..) {
                    task.abort();
                }
            }
            Err(poisoned) => {
                // The mutex is poisoned, but we can still get the data inside.
                let mut tasks = poisoned.into_inner();
                tracing::warn!("Mutex poisoned while closing; aborting tasks anyway.");
                for task in tasks.drain(..) {
                    task.abort();
                }
            }
        }
        Ok(())
    }

    async fn apply_history_record_patch(
        &self,
        record: &HistoryRecord,
        is_forward: bool,
    ) -> anyhow::Result<()> {
        if record.action_type == "entity_patch" {
            let payload = SymmetricEntityPatch::from_value(record.payload.clone())?;
            let patch = if is_forward {
                &payload.forward
            } else {
                &payload.reverse
            };
            if self
                .repo
                .apply_patch_check_position(&payload.id, patch)
                .await?
            {
                self.broadcast_boundaries().await;
            }
        }
        Ok(())
    }

    pub async fn undo(&self) -> anyhow::Result<Option<HistoryRecord>> {
        tracing::debug!("FFI: undo called");
        let record = self.repo.undo_event().await?;
        if let Some(ref rec) = record {
            self.apply_history_record_patch(rec, false).await?;
        }
        self.rebuild_node_cache().await;
        Ok(record)
    }

    pub async fn redo(&self) -> anyhow::Result<Option<HistoryRecord>> {
        tracing::debug!("FFI: redo called");
        let record = self.repo.redo_event().await?;
        if let Some(ref rec) = record {
            self.apply_history_record_patch(rec, true).await?;
        }
        self.rebuild_node_cache().await;
        Ok(record)
    }

    pub async fn undo_count(&self) -> anyhow::Result<u32> {
        self.repo.undo_count().await
    }

    pub async fn redo_count(&self) -> anyhow::Result<u32> {
        self.repo.redo_count().await
    }

    pub async fn create_tag(&self, tag: Tag) -> anyhow::Result<()> {
        self.repo.create_tag(tag).await
    }

    pub async fn update_tag(&self, tag: Tag) -> anyhow::Result<()> {
        self.repo.update_tag(tag).await
    }

    pub async fn get_tag(&self, key: String) -> anyhow::Result<Option<Tag>> {
        self.repo.get_tag(key).await
    }

    pub async fn get_all_tags(&self) -> anyhow::Result<Vec<Tag>> {
        self.repo.get_all_tags().await
    }

    pub async fn delete_tag(&self, key: String) -> anyhow::Result<()> {
        self.repo.delete_tag(key).await
    }

    // --- Template FFI Endpoints ---

    pub async fn save_template_from_selection(
        &self,
        name: String,
        node_keys: Vec<RecordStrings>,
        relation_keys: Vec<RecordStrings>,
    ) -> anyhow::Result<()> {
        self.repo
            .save_template_from_selection(name, node_keys, relation_keys)
            .await
    }

    pub async fn instantiate_template(
        &self,
        key: String,
        target_x: f64,
        target_y: f64,
    ) -> anyhow::Result<()> {
        self.repo
            .instantiate_template(key, target_x, target_y)
            .await?;
        stream::publish_event(GraphEvent::SnapshotLoaded);
        Ok(())
    }

    pub async fn get_all_templates(&self) -> anyhow::Result<Vec<Template>> {
        self.repo.get_all_templates().await
    }

    pub async fn delete_template(&self, key: String) -> anyhow::Result<()> {
        self.repo.delete_template(key).await
    }

    pub async fn query_search(&self, query: String) -> anyhow::Result<Vec<Nodes>> {
        self.repo.query_search(query).await
    }

    pub async fn compute_relations(
        &self,
        config: crate::domain::relation_engine::config::RelationEngineConfig,
        relation_ids: Option<Vec<String>>,
    ) -> anyhow::Result<Vec<crate::domain::relation_engine::computed::ComputedRelation>> {
        let nodes = self.repo.get_cached_nodes();
        let snapshot = self.repo.get_graph_snapshot().await?;
        let edges: Vec<crate::domain::relation_engine::input::InputEdge> = snapshot
            .relations
            .iter()
            .map(crate::domain::relation_engine::input::InputEdge::from_domain)
            .collect();

        let result = crate::domain::relation_engine::engine::RelationEngine::compute_relations(
            &nodes,
            &edges,
            &config,
            relation_ids.as_deref(),
        );
        Ok(result)
    }

    pub fn update_node_cache_positions(
        &self,
        positions: Vec<(String, f64, f64, f64, f64)>,
    ) {
        for (id, x, y, w, h) in positions {
            self.repo.update_node_cache(
                crate::domain::relation_engine::input::InputNode {
                    id,
                    x,
                    y,
                    width: w,
                    height: h,
                },
            );
        }
    }
}

impl Drop for AppHandle {
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
