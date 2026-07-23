use crate::bridge::api::RelationEngine;
use crate::bridge::stream::{self, GraphEvent};
use crate::domain::id::TypedRecordId;
use crate::domain::nodes::{IsNode, Nodes};
use crate::domain::patches::{EntityPatch, SymmetricEntityPatch};
use crate::domain::relation_engine::config::RelationEngineConfig;
use crate::domain::relation_engine::input::InputNode;
use crate::domain::traits::TableKind;
use crate::persistence::repo::Repository;
use std::sync::{Arc, Mutex};
use tracing::{debug, error, info};

pub struct NodeFfi {
    repo: Repository,
}

impl NodeFfi {
    pub fn new(repo: Repository) -> Self {
        Self { repo }
    }

    pub async fn create_node(&self, input: Nodes, _relation_engine: &Arc<Mutex<RelationEngine>>) -> anyhow::Result<()> {
        debug!("FFI: create_node called with input: {:?}", input);
        self.repo.create_node(input.clone()).await?;

        let id = *input.id();
        self.repo
            .record_patch_history(
                id,
                EntityPatch::CreateNode(input.clone(), vec![]),
                EntityPatch::DeleteNode(input, vec![]),
            )
            .await?;

        Self::broadcast_boundaries(&self.repo).await;
        Ok(())
    }

    pub async fn get_node(&self, id: TypedRecordId) -> anyhow::Result<Option<Nodes>> {
        debug!("Fetching node: {:?}", id);
        self.repo.get_node(id).await
    }

    pub async fn update_node(&self, input: Nodes) -> anyhow::Result<()> {
        let id = *input.id();
        if let Some(old) = self
            .repo
            .get_node(id)
            .await?
        {
            self.repo.update_node(input.clone()).await.map_err(|e| {
                error!("FFI: Repository failed to update node {}", e);
                e
            })?;

            self.repo
                .record_patch_history(
                    id,
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
        relation_engine: &Arc<Mutex<RelationEngine>>,
    ) -> anyhow::Result<()> {
        if self
            .repo
            .apply_patch_check_position(&mutation.id, &mutation.forward)
            .await?
        {
            Self::broadcast_boundaries(&self.repo).await;
        }
        let margin = RelationEngineConfig::default().routing.obstacle_margin;
        if let Ok(mut engine) = relation_engine.lock() {
            engine.apply_cache_patch(&mutation.id, &mutation.forward, margin);
        }
        self.repo
            .record_patch_history(mutation.id, mutation.forward, mutation.reverse)
            .await?;
        Ok(())
    }

    pub async fn delete_node_entry(
        &self,
        id: TypedRecordId,
    ) -> anyhow::Result<()> {
        debug!("Deleting node: {:?}", id);
        let Some(node) = self.repo.get_node(id).await? else {
            return Err(anyhow::anyhow!("Node not found for deletion"));
        };

        let connected_relations = self.repo.get_connected_relations(&id).await?;

        self.repo.delete_node(id).await?;

        self.repo
            .record_patch_history(
                id,
                EntityPatch::DeleteNode(node.clone(), connected_relations.clone()),
                EntityPatch::CreateNode(node, connected_relations),
            )
            .await?;

        Self::broadcast_boundaries(&self.repo).await;
        Ok(())
    }

    pub fn update_node_cache_positions(
        &self,
        positions: Vec<(TypedRecordId, f64, f64, f64, f64)>,
        relation_engine: &Arc<Mutex<RelationEngine>>,
    ) {
        let margin = RelationEngineConfig::default().routing.obstacle_margin;
        if let Ok(mut engine) = relation_engine.lock() {
            for (id, x, y, w, h) in positions {
                engine.update_node_cache(
                    InputNode {
                        id,
                        x,
                        y,
                        width: w,
                        height: h,
                        is_obstacle: true,
                    },
                    margin,
                );
            }
        }
    }

    pub async fn broadcast_boundaries(repo: &Repository) {
        match repo.calculate_global_bounds().await {
            Ok(bounds) => {
                info!("FFI: Broadcasting bounds: {:?}", bounds);
                stream::publish_event(GraphEvent::BoundaryUpdated(bounds));
            }
            Err(e) => {
                error!("FFI: Failed to calculate global bounds: {}", e);
            }
        }
    }
}
