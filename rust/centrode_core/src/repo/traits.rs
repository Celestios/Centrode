use anyhow::Result;
use crate::domain::base_models::{BoundingBox, MapData};
use crate::domain::id::TypedRecordId;
use crate::domain::nodes::Nodes;
use crate::domain::patches::{EntityPatch, NodePatch, RelationPatch};
use crate::domain::relations::{IRelation, IRelationFields};
use crate::domain::snapshot::GraphSnapshot;
use crate::domain::styles::RelationStyle;
use crate::domain::tags::Tag;
use crate::domain::templates::Template;
use crate::domain::theme::MapTheme;
use crate::domain::types::CustomWord;
use crate::repo::history::HistoryRecord;
use surrealdb::types::RecordId;

pub trait NodeRepository: Send + Sync {
    fn create_node(&self, input: Nodes) -> impl std::future::Future<Output = Result<()>> + Send;
    fn get_node(&self, id: TypedRecordId) -> impl std::future::Future<Output = Result<Option<Nodes>>> + Send;
    fn update_node(&self, input: Nodes) -> impl std::future::Future<Output = Result<()>> + Send;
    fn delete_node(&self, id: TypedRecordId) -> impl std::future::Future<Output = Result<()>> + Send;
    fn patch_node(&self, id: RecordId, patch: &NodePatch) -> impl std::future::Future<Output = Result<()>> + Send;
    fn patch_entity(&self, id: RecordId, patch: &EntityPatch) -> impl std::future::Future<Output = Result<()>> + Send;
    fn apply_patch_check_position(&self, id: &TypedRecordId, patch: &EntityPatch) -> impl std::future::Future<Output = Result<bool>> + Send;
}

pub trait RelationRepository: Send + Sync {
    fn create_relation(&self, input: IRelation) -> impl std::future::Future<Output = Result<()>> + Send;
    fn get_relation(&self, id: TypedRecordId) -> impl std::future::Future<Output = Result<IRelation>> + Send;
    fn update_relation(&self, id: TypedRecordId, fields: IRelationFields) -> impl std::future::Future<Output = Result<()>> + Send;
    fn delete_relation(&self, id: TypedRecordId) -> impl std::future::Future<Output = Result<()>> + Send;
    fn reroute_relation(&self, rel_id: TypedRecordId, updated: IRelation) -> impl std::future::Future<Output = Result<()>> + Send;
    fn get_connected_relations(&self, node_id: &TypedRecordId) -> impl std::future::Future<Output = Result<Vec<IRelation>>> + Send;
    fn get_all_relations(&self) -> impl std::future::Future<Output = Result<Vec<IRelation>>> + Send;
    fn patch_relation(&self, id: RecordId, patch: &RelationPatch) -> impl std::future::Future<Output = Result<()>> + Send;
}

pub trait LayoutRepository: Send + Sync {
    fn trigger_significance_update(&self, node_id: &TypedRecordId) -> impl std::future::Future<Output = Result<()>> + Send;
    fn recalculate_significance_area(&self, center_node_id: TypedRecordId) -> impl std::future::Future<Output = Result<()>> + Send;
    fn calculate_global_bounds(&self) -> impl std::future::Future<Output = Result<BoundingBox>> + Send;
}

pub trait HistoryRepository: Send + Sync {
    fn record_patch_history(&self, id: TypedRecordId, forward: EntityPatch, reverse: EntityPatch) -> impl std::future::Future<Output = Result<()>> + Send;
    fn undo_count(&self) -> impl std::future::Future<Output = Result<u32>> + Send;
    fn redo_count(&self) -> impl std::future::Future<Output = Result<u32>> + Send;
    fn undo_event(&self) -> impl std::future::Future<Output = Result<Option<HistoryRecord>>> + Send;
    fn redo_event(&self) -> impl std::future::Future<Output = Result<Option<HistoryRecord>>> + Send;
}

pub trait ThemeRepository: Send + Sync {
    fn get_theme(&self, key: String) -> impl std::future::Future<Output = Result<Option<MapTheme>>> + Send;
    fn get_theme_by_key(&self, key: &str) -> impl std::future::Future<Output = Result<Option<MapTheme>>> + Send;
    fn save_theme(&self, theme: MapTheme) -> impl std::future::Future<Output = Result<MapTheme>> + Send;
    fn list_themes(&self) -> impl std::future::Future<Output = Result<Vec<MapTheme>>> + Send;
}

pub trait TemplateRepository: Send + Sync {
    fn get_template(&self, key: String) -> impl std::future::Future<Output = Result<Option<Template>>> + Send;
    fn save_template(&self, name: String, nodes: Vec<Nodes>, relations: Vec<IRelation>) -> impl std::future::Future<Output = Result<Template>> + Send;
    fn list_templates(&self) -> impl std::future::Future<Output = Result<Vec<Template>>> + Send;
    fn delete_template(&self, key: String) -> impl std::future::Future<Output = Result<()>> + Send;
    fn apply_template(&self, key: String, target_x: f64, target_y: f64) -> impl std::future::Future<Output = Result<(Vec<Nodes>, Vec<IRelation>)>> + Send;
}

pub trait SnapshotRepository: Send + Sync {
    fn get_map_data(&self) -> impl std::future::Future<Output = Result<MapData>> + Send;
    fn update_map_data(&self, data: MapData) -> impl std::future::Future<Output = Result<()>> + Send;
    fn get_graph_snapshot(&self) -> impl std::future::Future<Output = Result<GraphSnapshot>> + Send;
    fn clear_graph(&self) -> impl std::future::Future<Output = Result<()>> + Send;
    fn set_graph_snapshot(&self, snapshot: GraphSnapshot) -> impl std::future::Future<Output = Result<()>> + Send;
    fn query_search(&self, query: String) -> impl std::future::Future<Output = Result<Vec<Nodes>>> + Send;
}

pub trait DictionaryRepository: Send + Sync {
    fn get_relation_spec(&self, verb: &str) -> impl std::future::Future<Output = Result<Option<RelationStyle>>> + Send;
    fn list_relation_specs(&self) -> impl std::future::Future<Output = Result<Vec<(String, RelationStyle)>>> + Send;
    fn add_custom_word(&self, word: &str, word_type: &str) -> impl std::future::Future<Output = Result<()>> + Send;
    fn list_custom_words(&self) -> impl std::future::Future<Output = Result<Vec<CustomWord>>> + Send;
    fn remove_custom_word(&self, word: &str) -> impl std::future::Future<Output = Result<()>> + Send;
    fn store_embedding(&self, text_payload: &str) -> impl std::future::Future<Output = Result<()>> + Send;
    fn search_similar_labels(&self, query: &str, limit: usize) -> impl std::future::Future<Output = Result<Vec<String>>> + Send;
    fn detect_map_language(&self, node_texts: &[String]) -> String;
    fn predict_relation_labels(&self, source_text: &str, target_text: &str, language: Option<String>, limit: usize) -> impl std::future::Future<Output = Result<Vec<String>>> + Send;
}

pub trait TagRepository: Send + Sync {
    fn create_tag(&self, tag: Tag) -> impl std::future::Future<Output = Result<()>> + Send;
    fn update_tag(&self, tag: Tag) -> impl std::future::Future<Output = Result<()>> + Send;
    fn get_tag(&self, key: String) -> impl std::future::Future<Output = Result<Option<Tag>>> + Send;
    fn get_all_tags(&self) -> impl std::future::Future<Output = Result<Vec<Tag>>> + Send;
    fn delete_tag(&self, key: String) -> impl std::future::Future<Output = Result<()>> + Send;
}
