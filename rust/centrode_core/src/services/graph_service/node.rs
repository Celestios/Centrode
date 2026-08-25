use crate::bridge::stream::GraphEvent;
use crate::domain::id::TypedRecordId;
use crate::domain::nodes::{IsNode, Nodes};
use crate::domain::patches::{EntityPatch, NodePatch, SymmetricEntityPatch};
use crate::relation_engine::config::RelationEngineConfig;
use crate::relation_engine::input::InputNode;
use crate::repo::traits::{HistoryRepository, LayoutRepository, NodeRepository, RelationRepository};
use crate::services::graph_service::GraphService;
use tracing::{debug, error, info};

impl GraphService {
    pub async fn create_node(&self, input: Nodes) -> anyhow::Result<()> {
        debug!("FFI: create_node called with input: {:?}", input);
        self.repo.nodes.create_node(input.clone()).await?;

        let id = *input.id();
        self.repo
            .history
            .record_patch_history(
                id,
                EntityPatch::CreateNode(input.clone(), vec![]),
                EntityPatch::DeleteNode(input, vec![]),
            )
            .await?;

        self.broadcast_boundaries().await;
        Ok(())
    }

    pub async fn get_node(&self, id: TypedRecordId) -> anyhow::Result<Option<Nodes>> {
        debug!("Fetching node: {:?}", id);
        self.repo.nodes.get_node(id).await
    }

    pub async fn update_node(&self, input: Nodes) -> anyhow::Result<()> {
        let id = *input.id();
        if let Some(old) = self.repo.nodes.get_node(id).await? {
            self.repo.nodes.update_node(input.clone()).await.map_err(|e| {
                error!("FFI: Repository failed to update node {}", e);
                e
            })?;

            self.repo
                .history
                .record_patch_history(
                    id,
                    EntityPatch::Node(vec![NodePatch::Position(input.position().clone())]),
                    EntityPatch::Node(vec![NodePatch::Position(old.position().clone())]),
                )
                .await?;
        } else {
            self.repo.nodes.update_node(input).await.map_err(|e| {
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
            .nodes
            .apply_patch_check_position(&mutation.id, &mutation.forward)
            .await?
        {
            self.broadcast_boundaries().await;
        }
        let margin = RelationEngineConfig::default().routing.obstacle_margin;
        if let Ok(mut engine) = self.relation_engine.lock() {
            engine.apply_cache_patch(&mutation.id, &mutation.forward, margin);
        }
        self.repo
            .history
            .record_patch_history(mutation.id, mutation.forward, mutation.reverse)
            .await?;
        Ok(())
    }

    pub async fn delete_node_entry(&self, id: TypedRecordId) -> anyhow::Result<()> {
        debug!("Deleting node: {:?}", id);
        let Some(node) = self.repo.nodes.get_node(id).await? else {
            return Err(anyhow::anyhow!("Node not found for deletion"));
        };

        let connected_relations = self.repo.relations.get_connected_relations(&id).await?;

        self.repo.nodes.delete_node(id).await?;

        self.repo
            .history
            .record_patch_history(
                id,
                EntityPatch::DeleteNode(node.clone(), connected_relations.clone()),
                EntityPatch::CreateNode(node, connected_relations),
            )
            .await?;

        self.broadcast_boundaries().await;
        Ok(())
    }

    pub fn update_node_cache_positions(&self, positions: Vec<(TypedRecordId, f64, f64, f64, f64)>) {
        let margin = RelationEngineConfig::default().routing.obstacle_margin;
        if let Ok(mut engine) = self.relation_engine.lock() {
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

    pub async fn broadcast_boundaries(&self) {
        match self.repo.layout.calculate_global_bounds().await {
            Ok(bounds) => {
                info!("FFI: Broadcasting bounds: {:?}", bounds);
                self.publish_event(GraphEvent::BoundaryUpdated(bounds));
            }
            Err(e) => {
                error!("FFI: Failed to calculate global bounds: {}", e);
            }
        }
    }
}
