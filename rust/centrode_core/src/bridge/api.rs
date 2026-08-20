use crate::bridge::stream::{GraphDelta, GraphEvent};
pub use crate::domain::base_models::BoundingBox;
pub use crate::domain::base_models::ViewportState;
pub use crate::domain::id::TypedRecordId;
pub use crate::domain::nodes::{Attachment, Nodes};
pub use crate::domain::patches::SymmetricEntityPatch;
pub use crate::domain::relations::IRelation;
pub use crate::domain::snapshot::GraphSnapshot;
pub use crate::domain::styles::PortSide;
pub use crate::domain::tags::Tag;
pub use crate::domain::templates::Template;
pub use crate::domain::theme::{MapTheme, ThemeFields};
pub use crate::domain::types::{Auxiliary, DomainEntity, Relations};
pub use crate::frb_generated::StreamSink;
pub use crate::layout_engine::config::LayoutConfig;
pub use crate::layout_engine::types::{Axis, LayoutPatch};
pub use crate::persistence::history::HistoryRecord;
pub use crate::persistence::repo::Repository;
pub use crate::relation_engine::computed::ComputedRelation;
pub use crate::relation_engine::config::{RelationEngineConfig, RoutingMode};
pub use crate::telemetry::{connect_log_stream, init_telemetry, subscribe_to_logs, LogState};
pub use std::sync::Arc;
pub use tokio_stream::StreamExt;

pub use crate::domain::styles::{NodeLayout, NodeStyle, RelationLayout, RelationStyle};
pub use crate::relation_engine::engine::RelationEngine;
pub use crate::services::graph_service::GraphService;

pub struct AppHandle {
    pub service: Arc<GraphService>,
}

impl AppHandle {
    pub async fn new(storage_path: String, name: String) -> anyhow::Result<Self> {
        let service = GraphService::new(storage_path, name).await?;
        Ok(Self {
            service: Arc::new(service),
        })
    }

    pub fn with_repository(repo: Repository) -> Self {
        let service = GraphService::with_repository(repo);
        Self {
            service: Arc::new(service),
        }
    }

    pub async fn create_graph_stream(&self, sink: StreamSink<GraphEvent>) -> anyhow::Result<()> {
        self.service.create_graph_stream(sink).await
    }

    pub fn close(&self) -> anyhow::Result<()> {
        self.service.close()
    }

    // Node FFI Surface Endpoints
    pub async fn create_node(&self, input: Nodes) -> anyhow::Result<()> {
        self.service.create_node(input).await
    }

    pub async fn get_node(&self, id: TypedRecordId) -> anyhow::Result<Option<Nodes>> {
        self.service.get_node(id).await
    }

    pub async fn update_node(&self, input: Nodes) -> anyhow::Result<()> {
        self.service.update_node(input).await
    }

    pub async fn apply_entity_mutation(
        &self,
        mutation: SymmetricEntityPatch,
    ) -> anyhow::Result<()> {
        self.service.apply_entity_mutation(mutation).await
    }

    pub async fn delete_node_entry(&self, id: TypedRecordId) -> anyhow::Result<()> {
        self.service.delete_node_entry(id).await
    }

    pub fn update_node_cache_positions(&self, positions: Vec<(TypedRecordId, f64, f64, f64, f64)>) {
        self.service.update_node_cache_positions(positions);
    }

    pub async fn broadcast_boundaries(&self) {
        self.service.broadcast_boundaries().await;
    }

    // Relation FFI Surface Endpoints
    pub async fn create_relation(&self, input: IRelation) -> anyhow::Result<()> {
        self.service.create_relation(input).await
    }

    pub async fn delete_relation(&self, id: TypedRecordId) -> anyhow::Result<()> {
        self.service.delete_relation(id).await
    }

    pub async fn update_relation(&self, input: IRelation) -> anyhow::Result<()> {
        self.service.update_relation(input).await
    }

    pub async fn reroute_relation(
        &self,
        record: TypedRecordId,
        from: TypedRecordId,
        to: TypedRecordId,
    ) -> anyhow::Result<()> {
        self.service.reroute_relation(record, from, to).await
    }

    pub async fn compute_relations(
        &self,
        config: RelationEngineConfig,
        relation_ids: Option<Vec<TypedRecordId>>,
    ) -> anyhow::Result<Vec<ComputedRelation>> {
        self.service.compute_relations(config, relation_ids).await
    }

    pub async fn compute_single_relation(
        &self,
        config: RelationEngineConfig,
        edge_id: TypedRecordId,
        from_node_id: TypedRecordId,
        to_node_id: TypedRecordId,
        from_side: Option<PortSide>,
        to_side: Option<PortSide>,
        routing_mode: Option<RoutingMode>,
        override_start_x: Option<f64>,
        override_start_y: Option<f64>,
        override_end_x: Option<f64>,
        override_end_y: Option<f64>,
    ) -> anyhow::Result<ComputedRelation> {
        self.service
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

    pub async fn rebuild_node_cache(&self) {
        self.service.rebuild_node_cache().await;
    }

    // History FFI Surface Endpoints
    pub async fn undo(&self) -> anyhow::Result<Option<HistoryRecord>> {
        self.service.undo().await
    }

    pub async fn redo(&self) -> anyhow::Result<Option<HistoryRecord>> {
        self.service.redo().await
    }

    pub async fn undo_count(&self) -> anyhow::Result<u32> {
        self.service.undo_count().await
    }

    pub async fn redo_count(&self) -> anyhow::Result<u32> {
        self.service.redo_count().await
    }

    pub async fn apply_history_record_patch(
        &self,
        record: &HistoryRecord,
        is_forward: bool,
    ) -> anyhow::Result<Option<GraphDelta>> {
        self.service
            .apply_history_record_patch(record, is_forward)
            .await
    }

    // Metadata / MapTheme / Tag / Template FFI Surface Endpoints
    pub async fn get_all_themes(&self) -> anyhow::Result<Vec<MapTheme>> {
        self.service.get_all_themes().await
    }

    pub async fn get_theme(&self, key: String) -> anyhow::Result<Option<MapTheme>> {
        self.service.get_theme(key).await
    }

    pub async fn set_active_theme_id(&self, theme_id: String) -> anyhow::Result<()> {
        self.service.set_active_theme_id(theme_id).await
    }

    pub async fn get_active_theme_id(&self) -> anyhow::Result<Option<String>> {
        self.service.get_active_theme_id().await
    }

    pub async fn set_active_theme(&self, theme_key: String) -> anyhow::Result<()> {
        self.service.set_active_theme(theme_key).await
    }

    pub async fn create_theme(&self, key: String, fields: ThemeFields) -> anyhow::Result<()> {
        self.service.create_theme(key, fields).await
    }

    pub async fn update_viewport_state(&self, state: ViewportState) -> anyhow::Result<()> {
        self.service.update_viewport_state(state).await
    }

    pub async fn update_theme(&self, theme: MapTheme) -> anyhow::Result<()> {
        self.service.update_theme(theme).await
    }

    pub async fn create_tag(&self, tag: Tag) -> anyhow::Result<()> {
        self.service.create_tag(tag).await
    }

    pub async fn update_tag(&self, tag: Tag) -> anyhow::Result<()> {
        self.service.update_tag(tag).await
    }

    pub async fn get_tag(&self, key: String) -> anyhow::Result<Option<Tag>> {
        self.service.get_tag(key).await
    }

    pub async fn get_all_tags(&self) -> anyhow::Result<Vec<Tag>> {
        self.service.get_all_tags().await
    }

    pub async fn delete_tag(&self, key: String) -> anyhow::Result<()> {
        self.service.delete_tag(key).await
    }

    pub async fn save_template_from_selection(
        &self,
        name: String,
        node_keys: Vec<TypedRecordId>,
        relation_keys: Vec<TypedRecordId>,
    ) -> anyhow::Result<()> {
        self.service
            .save_template_from_selection(name, node_keys, relation_keys)
            .await
    }

    pub async fn instantiate_template(
        &self,
        key: String,
        target_x: f64,
        target_y: f64,
    ) -> anyhow::Result<()> {
        self.service
            .instantiate_template(key, target_x, target_y)
            .await
    }

    pub async fn get_all_templates(&self) -> anyhow::Result<Vec<Template>> {
        self.service.get_all_templates().await
    }

    pub async fn delete_template(&self, key: String) -> anyhow::Result<()> {
        self.service.delete_template(key).await
    }

    pub async fn query_search(&self, query: String) -> anyhow::Result<Vec<Nodes>> {
        self.service.query_search(query).await
    }

    pub async fn get_graph_snapshot(&self) -> anyhow::Result<GraphSnapshot> {
        self.service.get_graph_snapshot().await
    }

    pub async fn save_map_to_file(
        &self,
        file_path: String,
        attachment_dir: String,
    ) -> anyhow::Result<()> {
        self.service
            .save_map_to_file(file_path, attachment_dir)
            .await
    }

    pub async fn load_map_from_file(
        &self,
        file_path: String,
        attachment_dir: String,
    ) -> anyhow::Result<()> {
        self.service
            .load_map_from_file(file_path, attachment_dir)
            .await
    }

    pub fn ingest_asset(
        &self,
        asset_dir: String,
        file_name: String,
        file_bytes: Vec<u8>,
        mime_type: String,
    ) -> anyhow::Result<Attachment> {
        crate::services::asset_vault::AssetVault::ingest_bytes(&asset_dir, &file_name, &file_bytes, &mime_type)
    }

    pub fn get_asset_absolute_path(
        &self,
        asset_dir: String,
        hash: String,
        extension: String,
    ) -> String {
        crate::services::asset_vault::AssetVault::resolve_path(&asset_dir, &hash, &extension)
            .to_string_lossy()
            .to_string()
    }

    // Layout Engine FFI Endpoints
    pub async fn set_opt_area(&self, bounds: Option<BoundingBox>) -> anyhow::Result<()> {
        self.service.set_opt_area(bounds).await
    }

    pub async fn get_opt_area(&self) -> anyhow::Result<Option<BoundingBox>> {
        self.service.get_opt_area().await
    }

    pub async fn trigger_layout_optimization(
        &self,
        config: LayoutConfig,
        live_positions: Vec<LayoutPatch>,
    ) -> anyhow::Result<()> {
        self.service
            .trigger_layout_optimization(config, live_positions)
            .await
    }

    pub async fn compute_auto_placement(
        &self,
        source_id: TypedRecordId,
        port_side: PortSide,
    ) -> anyhow::Result<(f64, f64)> {
        self.service.compute_auto_placement(source_id, port_side).await
    }

    pub async fn set_alignment_constraint(
        &self,
        node_ids: Vec<TypedRecordId>,
        axis: Axis,
    ) -> anyhow::Result<()> {
        self.service.set_alignment_constraint(node_ids, axis).await
    }

    pub async fn add_anchor_spring(
        &self,
        node_id: TypedRecordId,
        x: f64,
        y: f64,
        strength: f64,
    ) -> anyhow::Result<()> {
        self.service.add_anchor_spring(node_id, x, y, strength).await
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
