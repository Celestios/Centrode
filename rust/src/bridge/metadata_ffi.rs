use crate::bridge::stream::{self, GraphEvent};
use crate::domain::base_models::ViewportState;
use crate::domain::id::TypedRecordId;
use crate::domain::nodes::Nodes;
use crate::domain::snapshot::GraphSnapshot;
use crate::domain::tags::Tag;
use crate::domain::templates::Template;
use crate::domain::theme::{Theme, ThemeFields};
use crate::domain::relations::IRelation;
use crate::domain::traits::SurrealTable;
use crate::format::packager;
use crate::persistence::repo::Repository;
use surrealdb::types::{SurrealValue, Value};
use std::collections::BTreeMap;

pub struct MetadataFfi {
    repo: Repository,
}

impl MetadataFfi {
    pub fn new(repo: Repository) -> Self {
        Self { repo }
    }

    pub async fn get_all_themes(&self) -> anyhow::Result<Vec<Theme>> {
        self.repo.list_themes().await
    }

    pub async fn get_theme(&self, key: String) -> anyhow::Result<Option<Theme>> {
        self.repo.get_theme(key).await
    }

    pub async fn set_active_theme_id(&self, _theme_id: String) -> anyhow::Result<()> {
        Ok(())
    }

    pub async fn get_active_theme_id(&self) -> anyhow::Result<Option<String>> {
        Ok(None)
    }

    pub async fn set_active_theme(&self, _theme_key: String) -> anyhow::Result<()> {
        Ok(())
    }

    pub async fn create_theme(&self, key: String, fields: ThemeFields) -> anyhow::Result<()> {
        let u = uuid::Uuid::parse_str(&key).unwrap_or_else(|_| uuid::Uuid::nil());
        let typed_id = TypedRecordId::new(crate::domain::traits::TableKind::MapTheme, u);
        self.repo.save_theme(Theme { key: typed_id, fields }).await?;
        Ok(())
    }

    pub async fn update_viewport_state(&self, _state: ViewportState) -> anyhow::Result<()> {
        Ok(())
    }

    pub async fn update_theme(&self, theme: Theme) -> anyhow::Result<()> {
        self.repo.save_theme(theme).await?;
        Ok(())
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

    pub async fn save_template_from_selection(
        &self,
        name: String,
        node_keys: Vec<TypedRecordId>,
        relation_keys: Vec<TypedRecordId>,
    ) -> anyhow::Result<()> {
        let mut nodes = Vec::new();
        for key in node_keys {
            if let Some(n) = self.repo.get_node(key).await? {
                nodes.push(n);
            }
        }

        let mut relations = Vec::new();
        for key in relation_keys {
            if let Ok(r) = self.repo.get_relation(key).await {
                relations.push(r);
            }
        }

        self.repo.save_template(name, nodes, relations).await?;
        Ok(())
    }

    pub async fn instantiate_template(
        &self,
        key: String,
        target_x: f64,
        target_y: f64,
    ) -> anyhow::Result<()> {
        self.repo
            .apply_template(key, target_x, target_y)
            .await?;
        stream::publish_event(GraphEvent::SnapshotLoaded);
        Ok(())
    }

    pub async fn get_all_templates(&self) -> anyhow::Result<Vec<Template>> {
        self.repo.list_templates().await
    }

    pub async fn delete_template(&self, key: String) -> anyhow::Result<()> {
        self.repo.delete_template(key).await
    }

    pub async fn query_search(&self, query: String) -> anyhow::Result<Vec<Nodes>> {
        self.repo.query_search(query).await
    }

    pub async fn get_graph_snapshot(&self) -> anyhow::Result<GraphSnapshot> {
        self.repo.get_graph_snapshot().await
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
}
