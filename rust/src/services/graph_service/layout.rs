use crate::bridge::stream::{self, GraphEvent};
use crate::domain::base_models::BoundingBox;
use crate::layout_engine::config::LayoutConfig;
use crate::relation_engine::config::RelationEngineConfig;
use crate::relation_engine::input::InputNode;
use crate::services::graph_service::GraphService;

impl GraphService {
    pub async fn set_opt_area(&self, bounds: Option<BoundingBox>) -> anyhow::Result<()> {
        let mut map_data = self.repo.get_map_data().await?;
        map_data.opt_area = bounds;
        self.repo.update_map_data(map_data).await?;
        Ok(())
    }

    pub async fn get_opt_area(&self) -> anyhow::Result<Option<BoundingBox>> {
        let map_data = self.repo.get_map_data().await?;
        Ok(map_data.opt_area)
    }

    pub async fn trigger_layout_optimization(
        &self,
        config: LayoutConfig,
    ) -> anyhow::Result<()> {
        let opt_area = self.get_opt_area().await?;
        if opt_area.is_none() {
            return Ok(());
        }

        let snapshot = self.repo.get_graph_snapshot().await?;
        let engine_arc = self.layout_engine.clone();
        let rel_engine_arc = self.relation_engine.clone();

        if let Ok(mut engine) = engine_arc.lock() {
            engine.config = config;
            engine.sync_from_canvas(
                &snapshot.nodes,
                &snapshot.relations,
                opt_area,
            );
        }

        tokio::spawn(async move {
            let margin = RelationEngineConfig::default().routing.obstacle_margin;

            loop {
                let result = {
                    let mut engine = match engine_arc.lock() {
                        Ok(e) => e,
                        Err(_) => break,
                    };
                    let batch_res = engine.run_batch();

                    if let Ok(mut rel_engine) = rel_engine_arc.lock() {
                        for patch in &batch_res.position_patches {
                            if let Some(physics) = engine.state.nodes.get(&patch.id) {
                                rel_engine.update_node_cache(
                                    InputNode {
                                        id: physics.id.clone(),
                                        x: physics.x,
                                        y: physics.y,
                                        width: physics.width,
                                        height: physics.height,
                                        is_obstacle: true,
                                    },
                                    margin,
                                );
                            }
                        }
                    }

                    batch_res
                };

                let converged = result.converged;
                stream::publish_event(GraphEvent::LayoutTick(result));

                if converged {
                    break;
                }

                tokio::task::yield_now().await;
            }
        });

        Ok(())
    }
}

