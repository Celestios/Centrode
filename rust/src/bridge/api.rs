use crate::bridge::stream::{self, GraphEvent};
use crate::domain::analysis::GraphAnalysis;
use crate::domain::base_models::{IsTable, MapData, Record, RecordStrings};
use crate::domain::nodes::{INode, InterNode, Nodes, TaskNode};
use crate::domain::relations::IRelation;
use crate::domain::theme::{Theme, ThemeFields};
use crate::format::packager;
use crate::frb_generated::StreamSink;
use crate::persistence::db::Database;
use crate::persistence::history::HistoryManager;
use crate::persistence::history::HistoryRecord;
use crate::persistence::repo::Repository;
use crate::telemetry::{connect_log_stream, init_telemetry, LogState};
use std::collections::BTreeMap;
use std::sync::Mutex;
use surrealdb::types::{RecordId, SurrealValue, Value};
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
        let db = Database::connect(&storage_path, name).await?;
        Ok(Self {
            repo: Repository::new(db),
            tasks: Mutex::new(Vec::new()),
        })
    }

    async fn broadcast_boundaries(&self) {
        match GraphAnalysis::calculate_global_bounds(self.repo.db()).await {
            Ok(bounds) => {
                info!("FFI: Broadcasting bounds: {:?}", bounds);
                stream::publish_event(GraphEvent::BoundaryUpdated(bounds));
            }
            Err(e) => {
                error!("FFI: Failed to calculate global bounds: {}", e);
            }
        }
    }

    pub async fn create_node(&self, input: Nodes) -> anyhow::Result<()> {
        debug!("FFI: create_node called with input: {:?}", input);
        match self.repo.create_node(input).await {
            Result::Ok(()) => {
                info!("FFI: Successfully committed node to database");
                self.broadcast_boundaries().await;
                Ok(())
            }
            Err(e) => {
                error!("FFI: Database rejection during node creation: {}", e);
                Err(e)
            }
        }
    }

    pub async fn get_node(&self, table: String, key: String) -> anyhow::Result<Option<Nodes>> {
        debug!("Fetching node: {}/{}", &table, &key);
        self.repo.get_node(table, key).await
    }

    pub async fn update_node(&self, input: Nodes) -> anyhow::Result<()> {
        self.repo.update_node(input).await.map_err(|e| {
            error!("FFI: Repository failed to update node {}", e);
            e
        })?;
        Ok(())
    }

    pub async fn delete_node_entry(&self, table: String, key: String) -> anyhow::Result<()> {
        debug!("Deleting node: {}/{}", table, key);
        match self.repo.delete_node(table.clone(), key.clone()).await {
            Ok(()) => {
                info!("Node {} deleted successfully", key.clone());
                self.broadcast_boundaries().await;
                Ok(())
            }
            Err(e) => {
                error!("Failed to delete node {}/{}: {}", table, key, e);
                Err(e)
            }
        }
    }

    pub async fn create_relation(&self, input: IRelation) -> anyhow::Result<()> {
        debug!(
            "FFI: create_relation called: {} -> {}",
            input.in_, input.out
        );
        match self.repo.create_relation(input).await {
            Ok(()) => {
                info!("FFI: Relation created successfully");
                Ok(())
            }
            Err(e) => {
                error!("FFI: Failed to create relation: {}", e);
                Err(e)
            }
        }
    }

    pub async fn delete_relation(&self, table: String, key: String) -> anyhow::Result<()> {
        debug!("Deleting relation: {}", key);
        match self.repo.delete_relation(table, key.clone()).await {
            Ok(()) => {
                info!("Relation deleted successfully");
                Ok(())
            }
            Err(e) => {
                error!("Failed to delete relation {}: {}", key, e);
                Err(e)
            }
        }
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

    pub async fn get_graph_snapshot(
        &self,
    ) -> anyhow::Result<(
        Vec<INode>,
        Vec<TaskNode>,
        Vec<InterNode>,
        Vec<IRelation>,
        MapData,
    )> {
        let res = self.repo.get_graph_snapshot().await?;
        Ok(res)
    }

    pub async fn save_map_to_file(
        &self,
        file_path: String,
        attachment_dir: String,
    ) -> anyhow::Result<()> {
        let (inodes, task_nodes, inter_nodes, relations, metadata) =
            self.repo.get_graph_snapshot().await?;

        let mut content: BTreeMap<String, Vec<Value>> = BTreeMap::new();

        content.insert(
            INode::LABEL.into(),
            inodes.into_iter().map(|n| n.into_value()).collect(),
        );
        content.insert(
            TaskNode::LABEL.into(),
            task_nodes.into_iter().map(|n| n.into_value()).collect(),
        );
        content.insert(
            InterNode::LABEL.into(),
            inter_nodes.into_iter().map(|n| n.into_value()).collect(),
        );
        content.insert(
            IRelation::LABEL.into(),
            relations.into_iter().map(|r| r.into_value()).collect(),
        );

        tokio::task::spawn_blocking(move || {
            packager::save_project_to_celi(&file_path, &attachment_dir, content, metadata)
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

        let inodes: Vec<INode> = content
            .remove(INode::LABEL)
            .unwrap_or_default()
            .iter()
            .map(|v| INode::from_value(v.clone()).unwrap())
            .collect();

        let tasknodes: Vec<TaskNode> = content
            .remove(TaskNode::LABEL)
            .unwrap_or_default()
            .iter()
            .map(|v| TaskNode::from_value(v.clone()).unwrap())
            .collect();
        let internodes: Vec<InterNode> = content
            .remove(InterNode::LABEL)
            .unwrap_or_default()
            .iter()
            .map(|v| InterNode::from_value(v.clone()).unwrap())
            .collect();
        let irelations: Vec<IRelation> = content
            .remove(IRelation::LABEL)
            .unwrap_or_default()
            .iter()
            .map(|v| IRelation::from_value(v.clone()).unwrap())
            .collect();

        self.repo
            .set_graph_snapshot(inodes, tasknodes, internodes, irelations, metadata)
            .await?;

        Ok(())
    }

    pub async fn get_all_themes(&self) -> anyhow::Result<Vec<Theme>> {
        tracing::debug!("FFI: get_all_themes called");
        let theme_records: Vec<Value> = self.repo.db().select(Theme::LABEL).await?;
        let themes: Vec<Theme> = theme_records
            .into_iter()
            .filter_map(|val| {
                let record = Record::from_record_value(val)?;
                let (key, fields) = record.to_type::<ThemeFields>()?;
                Some(Theme { key, fields })
            })
            .collect();
        Ok(themes)
    }

    pub async fn get_theme(&self, key: String) -> anyhow::Result<Option<Theme>> {
        tracing::debug!("FFI: get_theme called with key: {}", key);

        let record_id = RecordId::new(Theme::LABEL, key.clone());
        let fields: Option<ThemeFields> = self.repo.db().select(record_id).await?;

        Ok(fields.map(|f| Theme { key, fields: f }))
    }

    pub async fn set_active_theme_id(&self, theme_id: String) -> anyhow::Result<()> {
        tracing::debug!("FFI: set_active_theme_id called with id: {}", theme_id);

        let record_id = RecordId::new(MapData::LABEL, MapData::KEY);
        self.repo
            .db()
            .query("UPDATE $record SET active_theme_id = $theme_id")
            .bind(("record", record_id))
            .bind(("theme_id", theme_id))
            .await?;
        Ok(())
    }

    pub async fn get_active_theme_id(&self) -> anyhow::Result<Option<String>> {
        tracing::debug!("FFI: get_active_theme_id called");
        let mut res = self
            .repo
            .db()
            .query("SELECT VALUE active_theme_id FROM $record")
            .bind(("record", RecordId::new(MapData::LABEL, MapData::KEY)))
            .await?;
        let result: Option<String> = res.take(0)?;
        Ok(result)
    }

    pub async fn set_active_theme(&self, theme_key: String) -> anyhow::Result<()> {
        tracing::debug!("FFI: set_active_theme_id called with id: {}", theme_key);
        let _: Option<Theme> = self.repo.db().update((MapData::LABEL, theme_key)).await?;
        Ok(())
    }

    pub async fn create_theme(&self, key: String, fields: ThemeFields) -> anyhow::Result<()> {
        tracing::debug!("FFI: create_theme called");

        let record_id = RecordId::new(Theme::LABEL, key);
        self.repo
            .db()
            .query("CREATE $record_id CONTENT $fields")
            .bind(("record_id", record_id))
            .bind(("fields", fields))
            .await?;

        Ok(())
    }

    pub async fn update_theme(&self, theme: Theme) -> anyhow::Result<()> {
        tracing::debug!("FFI: update_theme called");

        let record_id = RecordId::new(Theme::LABEL, theme.key);
        let fields = theme.fields;
        self.repo
            .db()
            .query("UPDATE $record_id MERGE $fields")
            .bind(("record_id", record_id))
            .bind(("fields", fields))
            .await?;

        Ok(())
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
        tracing::debug!("FFI: undo called");
        let history_manager = HistoryManager::new(self.repo.db(), 100);
        history_manager.undo().await
    }

    pub async fn redo(&self) -> anyhow::Result<Option<HistoryRecord>> {
        tracing::debug!("FFI: redo called");
        let history_manager = HistoryManager::new(self.repo.db(), 100);
        history_manager.redo().await
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
