use crate::bridge::stream::{self, GraphEvent};
use crate::bridge::node_ffi::NodeFfi;
use crate::bridge::relation_ffi::RelationFfi;
use crate::bridge::history_ffi::HistoryFfi;
use crate::bridge::metadata_ffi::MetadataFfi;
use crate::domain::base_models::ViewportState;
use crate::domain::id::TypedRecordId;
use crate::domain::nodes::Nodes;
use crate::domain::snapshot::GraphSnapshot;
use crate::domain::tags::Tag;
use crate::domain::templates::Template;

use crate::domain::patches::{EntityPatch, SymmetricEntityPatch};
use crate::domain::relations::IRelation;
use crate::domain::relation_engine::config::RelationEngineConfig;
pub use crate::domain::relation_engine::engine::RelationEngine;
use crate::domain::relation_engine::input::InputNode;
use crate::domain::theme::{Theme, ThemeFields};
pub use crate::domain::styles::{NodeStyle, NodeLayout, RelationLayout, RelationStyle};
use crate::format::packager;
use crate::frb_generated::StreamSink;
use crate::persistence::db::Database;
use crate::persistence::history::HistoryRecord;
use crate::persistence::repo::Repository;
use crate::telemetry::{connect_log_stream, init_telemetry, LogState};
use directories::ProjectDirs;
use std::collections::BTreeMap;
use std::path::PathBuf;
pub use std::sync::Mutex;
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
    pub relation_engine: std::sync::Arc<Mutex<RelationEngine>>,
    tasks: Mutex<Vec<JoinHandle<()>>>,
    node_ffi: NodeFfi,
    relation_ffi: RelationFfi,
    history_ffi: HistoryFfi,
    metadata_ffi: MetadataFfi,
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
        use crate::domain::relation_engine::config::RelationEngineConfig;
        let relation_engine = std::sync::Arc::new(Mutex::new(RelationEngine::new(RelationEngineConfig::default())));
        Self {
            repo: repo.clone(),
            relation_engine: relation_engine.clone(),
            tasks: Mutex::new(Vec::new()),
            node_ffi: NodeFfi::new(repo.clone()),
            relation_ffi: RelationFfi::new(repo.clone(), relation_engine),
            history_ffi: HistoryFfi::new(repo.clone()),
            metadata_ffi: MetadataFfi::new(repo),
        }
    }



    pub async fn create_node(&self, input: Nodes) -> anyhow::Result<()> {
        self.node_ffi.create_node(input, &self.relation_engine).await
    }

    pub async fn get_node(&self, id: TypedRecordId) -> anyhow::Result<Option<Nodes>> {
        self.node_ffi.get_node(id).await
    }

    pub async fn update_node(&self, input: Nodes) -> anyhow::Result<()> {
        self.node_ffi.update_node(input).await
    }

    pub async fn apply_entity_mutation(
        &self,
        mutation: SymmetricEntityPatch,
    ) -> anyhow::Result<()> {
        self.node_ffi.apply_entity_mutation(mutation, &self.relation_engine).await
    }

    pub async fn delete_node_entry(&self, id: TypedRecordId) -> anyhow::Result<()> {
        self.node_ffi.delete_node_entry(id).await
    }

    pub async fn create_relation(&self, input: IRelation) -> anyhow::Result<()> {
        self.relation_ffi.create_relation(input).await
    }

    pub async fn delete_relation(&self, id: TypedRecordId) -> anyhow::Result<()> {
        self.relation_ffi.delete_relation(id).await
    }

    pub async fn update_relation(&self, input: IRelation) -> anyhow::Result<()> {
        self.relation_ffi.update_relation(input).await
    }

    pub async fn reroute_relation(
        &self,
        record: TypedRecordId,
        from: TypedRecordId,
        to: TypedRecordId,
    ) -> anyhow::Result<()> {
        self.relation_ffi.reroute_relation(record, from, to).await
    }

    pub async fn get_graph_snapshot(&self) -> anyhow::Result<GraphSnapshot> {
        self.metadata_ffi.get_graph_snapshot().await
    }

    pub async fn save_map_to_file(
        &self,
        file_path: String,
        attachment_dir: String,
    ) -> anyhow::Result<()> {
        self.metadata_ffi.save_map_to_file(file_path, attachment_dir).await
    }

    pub async fn load_map_from_file(
        &self,
        file_path: String,
        attachment_dir: String,
    ) -> anyhow::Result<()> {
        self.metadata_ffi.load_map_from_file(file_path, attachment_dir).await
    }

    pub async fn get_all_themes(&self) -> anyhow::Result<Vec<Theme>> {
        self.metadata_ffi.get_all_themes().await
    }

    pub async fn get_theme(&self, key: String) -> anyhow::Result<Option<Theme>> {
        self.metadata_ffi.get_theme(key).await
    }

    pub async fn set_active_theme_id(&self, theme_id: String) -> anyhow::Result<()> {
        self.metadata_ffi.set_active_theme_id(theme_id).await
    }

    pub async fn update_viewport_state(&self, state: ViewportState) -> anyhow::Result<()> {
        self.metadata_ffi.update_viewport_state(state).await
    }

    pub async fn get_active_theme_id(&self) -> anyhow::Result<Option<String>> {
        self.metadata_ffi.get_active_theme_id().await
    }

    pub async fn set_active_theme(&self, theme_key: String) -> anyhow::Result<()> {
        self.metadata_ffi.set_active_theme(theme_key).await
    }

    pub async fn create_theme(&self, key: String, fields: ThemeFields) -> anyhow::Result<()> {
        self.metadata_ffi.create_theme(key, fields).await
    }

    pub async fn update_theme(&self, theme: Theme) -> anyhow::Result<()> {
        self.metadata_ffi.update_theme(theme).await
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


    pub async fn undo(&self) -> anyhow::Result<Option<HistoryRecord>> {
        self.history_ffi.undo(self.relation_engine.clone()).await
    }

    pub async fn redo(&self) -> anyhow::Result<Option<HistoryRecord>> {
        self.history_ffi.redo(self.relation_engine.clone()).await
    }

    pub async fn undo_count(&self) -> anyhow::Result<u32> {
        self.history_ffi.undo_count().await
    }

    pub async fn redo_count(&self) -> anyhow::Result<u32> {
        self.history_ffi.redo_count().await
    }

    pub async fn create_tag(&self, tag: Tag) -> anyhow::Result<()> {
        self.metadata_ffi.create_tag(tag).await
    }

    pub async fn update_tag(&self, tag: Tag) -> anyhow::Result<()> {
        self.metadata_ffi.update_tag(tag).await
    }

    pub async fn get_tag(&self, key: String) -> anyhow::Result<Option<Tag>> {
        self.metadata_ffi.get_tag(key).await
    }

    pub async fn get_all_tags(&self) -> anyhow::Result<Vec<Tag>> {
        self.metadata_ffi.get_all_tags().await
    }

    pub async fn delete_tag(&self, key: String) -> anyhow::Result<()> {
        self.metadata_ffi.delete_tag(key).await
    }

    // --- Template FFI Endpoints ---

    pub async fn save_template_from_selection(
        &self,
        name: String,
        node_keys: Vec<TypedRecordId>,
        relation_keys: Vec<TypedRecordId>,
    ) -> anyhow::Result<()> {
        self.metadata_ffi
            .save_template_from_selection(name, node_keys, relation_keys)
            .await
    }

    pub async fn instantiate_template(
        &self,
        key: String,
        target_x: f64,
        target_y: f64,
    ) -> anyhow::Result<()> {
        self.metadata_ffi
            .instantiate_template(key, target_x, target_y)
            .await
    }

    pub async fn get_all_templates(&self) -> anyhow::Result<Vec<Template>> {
        self.metadata_ffi.get_all_templates().await
    }

    pub async fn delete_template(&self, key: String) -> anyhow::Result<()> {
        self.metadata_ffi.delete_template(key).await
    }

    pub async fn query_search(&self, query: String) -> anyhow::Result<Vec<Nodes>> {
        self.metadata_ffi.query_search(query).await
    }

    pub async fn compute_relations(
        &self,
        config: crate::domain::relation_engine::config::RelationEngineConfig,
        relation_ids: Option<Vec<TypedRecordId>>,
    ) -> anyhow::Result<Vec<crate::domain::relation_engine::computed::ComputedRelation>> {
        self.relation_ffi.compute_relations(config, relation_ids).await
    }

    pub fn update_node_cache_positions(
        &self,
        positions: Vec<(TypedRecordId, f64, f64, f64, f64)>,
    ) {
        self.node_ffi.update_node_cache_positions(positions, &self.relation_engine)
    }

    pub async fn compute_single_relation(
        &self,
        config: crate::domain::relation_engine::config::RelationEngineConfig,
        edge_id: TypedRecordId,
        from_node_id: TypedRecordId,
        to_node_id: TypedRecordId,
        from_side: Option<crate::domain::styles::PortSide>,
        to_side: Option<crate::domain::styles::PortSide>,
        routing_mode: Option<crate::domain::relation_engine::config::RoutingMode>,
        override_start_x: Option<f64>,
        override_start_y: Option<f64>,
        override_end_x: Option<f64>,
        override_end_y: Option<f64>,
    ) -> anyhow::Result<crate::domain::relation_engine::computed::ComputedRelation> {
        self.relation_ffi
            .compute_single_relation(
                config,
                edge_id,
                from_node_id,
                to_node_id,
                from_side,
                to_side,
                routing_mode,
                override_start_x,
                override_start_y,
                override_end_x,
                override_end_y,
            )
            .await
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
