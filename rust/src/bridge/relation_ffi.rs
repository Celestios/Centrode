use crate::bridge::api::RelationEngine;
use crate::domain::id::TypedRecordId;
use crate::domain::patches::EntityPatch;
use crate::domain::relations::IRelation;
use crate::domain::relation_engine::config::RelationEngineConfig;
use crate::domain::relation_engine::input::{InputEdge, InputNode};
use crate::domain::traits::TableKind;
use crate::persistence::repo::Repository;
use std::sync::{Arc, Mutex};
use tracing::{debug, error, info};

pub struct RelationFfi {
    repo: Repository,
    relation_engine: Arc<Mutex<RelationEngine>>,
}

impl RelationFfi {
    pub fn new(repo: Repository, relation_engine: Arc<Mutex<RelationEngine>>) -> Self {
        Self {
            repo,
            relation_engine,
        }
    }

    pub async fn rebuild_node_cache(&self) {
        let margin = RelationEngineConfig::default().routing.obstacle_margin;
        if let Ok(mut engine) = self.relation_engine.lock() {
            engine.state.clear();
            engine.cache.clear();
        }
        if let Ok(snapshot) = self.repo.get_graph_snapshot().await {
            if let Ok(mut engine) = self.relation_engine.lock() {
                for node in &snapshot.nodes {
                    if let Some(input_node) = InputNode::from_domain(node) {
                        engine.state.update_node(input_node, margin);
                    }
                }
            }
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
                input.key,
                EntityPatch::CreateRelation(input.clone()),
                EntityPatch::DeleteRelation(input),
            )
            .await?;

        Ok(())
    }

    pub async fn delete_relation(&self, id: TypedRecordId) -> anyhow::Result<()> {
        debug!("Deleting relation: {:?}", id);
        let rel = self.repo.get_relation(id).await?;

        self.repo
            .delete_relation(id)
            .await?;

        self.repo
            .record_patch_history(
                id,
                EntityPatch::DeleteRelation(rel.clone()),
                EntityPatch::CreateRelation(rel),
            )
            .await?;

        Ok(())
    }

    pub async fn update_relation(&self, input: IRelation) -> anyhow::Result<()> {
        debug!("FFI: update_relation called for {} with patch", input.key);

        self.repo
            .update_relation(input.key, input.fields)
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
        record: TypedRecordId,
        from: TypedRecordId,
        to: TypedRecordId,
    ) -> anyhow::Result<()> {
        debug!(
            "Rerouting relation {} to: {} -> {}",
            record,
            from,
            to
        );
        let id = record.to_string();
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

    pub async fn compute_relations(
        &self,
        config: RelationEngineConfig,
        _relation_ids: Option<Vec<TypedRecordId>>,
    ) -> anyhow::Result<Vec<crate::domain::relation_engine::computed::ComputedRelation>> {
        let mut is_empty = false;
        if let Ok(engine) = self.relation_engine.lock() {
            is_empty = engine.state.nodes.is_empty();
        }
        if is_empty {
            self.rebuild_node_cache().await;
        }

        let nodes: Vec<InputNode> = self
            .relation_engine
            .lock()
            .map_err(|_| anyhow::anyhow!("Failed to lock relation engine"))?
            .state
            .nodes
            .values()
            .cloned()
            .collect();
        let snapshot = self.repo.get_graph_snapshot().await?;
        let edges: Vec<InputEdge> = snapshot
            .relations
            .iter()
            .map(InputEdge::from_domain)
            .collect();

        let mut engine = match self.relation_engine.lock() {
            Ok(e) => e,
            Err(_) => return Err(anyhow::anyhow!("Failed to lock relation engine")),
        };

        let result = engine.compute_relations_stateful(
            &nodes,
            &edges,
            &config,
            None,
        );
        Ok(result)
    }

    pub async fn compute_single_relation(
        &self,
        config: RelationEngineConfig,
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
        let mut is_empty = false;
        if let Ok(engine) = self.relation_engine.lock() {
            is_empty = engine.state.nodes.is_empty();
        }
        if is_empty {
            self.rebuild_node_cache().await;
        }

        let mut nodes = self
            .relation_engine
            .lock()
            .map_err(|_| anyhow::anyhow!("Failed to lock relation engine"))?
            .state
            .nodes
            .values()
            .cloned()
            .collect::<Vec<InputNode>>();

        if let (Some(sx), Some(sy)) = (override_start_x, override_start_y) {
            if let Some(n) = nodes.iter_mut().find(|n| n.id == from_node_id) {
                n.x = sx;
                n.y = sy;
                n.width = 0.0;
                n.height = 0.0;
            } else {
                nodes.push(InputNode {
                    id: from_node_id.clone(),
                    x: sx,
                    y: sy,
                    width: 0.0,
                    height: 0.0,
                    is_obstacle: true,
                });
            }
        }

        if let (Some(ex), Some(ey)) = (override_end_x, override_end_y) {
            if let Some(n) = nodes.iter_mut().find(|n| n.id == to_node_id) {
                n.x = ex;
                n.y = ey;
                n.width = 0.0;
                n.height = 0.0;
            } else {
                nodes.push(InputNode {
                    id: to_node_id.clone(),
                    x: ex,
                    y: ey,
                    width: 0.0,
                    height: 0.0,
                    is_obstacle: true,
                });
            }
        }

        let edge = InputEdge {
            id: edge_id.clone(),
            from_node_id,
            to_node_id,
            from_side: from_side.clone(),
            to_side: to_side.clone(),
            routing_mode: routing_mode.clone(),
            bundling_mode: None,
            style: None,
        };

        let snapshot = self.repo.get_graph_snapshot().await?;
        let mut edges: Vec<InputEdge> = snapshot
            .relations
            .iter()
            .map(InputEdge::from_domain)
            .collect();

        if !edges.iter().any(|e| e.id == edge_id) {
            edges.push(edge);
        } else {
            if let Some(e) = edges.iter_mut().find(|e| e.id == edge_id) {
                *e = InputEdge {
                    id: edge_id.clone(),
                    from_node_id: e.from_node_id.clone(),
                    to_node_id: e.to_node_id.clone(),
                    from_side: from_side.or(e.from_side.clone()),
                    to_side: to_side.or(e.to_side.clone()),
                    routing_mode: routing_mode.or(e.routing_mode.clone()),
                    bundling_mode: e.bundling_mode.clone(),
                    style: e.style.clone(),
                };
            }
        }

        let mut engine = match self.relation_engine.lock() {
            Ok(e) => e,
            Err(_) => return Err(anyhow::anyhow!("Failed to lock relation engine")),
        };

        let results = engine.compute_relations_stateful(
            &nodes,
            &edges,
            &config,
            Some(&[edge_id.clone()]),
        );

        results
            .into_iter()
            .find(|r| r.id == edge_id)
            .ok_or_else(|| anyhow::anyhow!("Relation {:?} not found in results", edge_id))
    }
}
