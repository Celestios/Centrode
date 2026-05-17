use crate::domain::base_models::BoundingBox;
use surrealdb::engine::local::Db;
use surrealdb::types::RecordId;
use surrealdb::Surreal;

pub struct DecaySignificanceStrategy;

impl DecaySignificanceStrategy {
    pub async fn recalculate_area(
        &self,
        db: &Surreal<Db>,
        center_node_id: RecordId,
    ) -> anyhow::Result<()> {
        tracing::info!(
            "ANALYSIS: Recalculating significance area for center node: {:?}",
            center_node_id
        );

        // Use SurrealDB Graph Traversal for O(1) local lookup
        // Calculate raw scores for nodes within a 2-step radius
        let sql = "
            LET $targets = (SELECT id FROM (SELECT ->relates_to->(inode, task_node) AS neighbors FROM $center).neighbors);
            
            FOR $node_id IN $targets {
                LET $d1 = count(SELECT * FROM $node_id->relates_to);
                LET $d2 = count(SELECT * FROM $node_id->relates_to->(inode, task_node)->relates_to);
                
                LET $raw_score = ($d1 * 1.0) + ($d2 * 0.5);
                
                -- Local normalization to 0-4 based on a fixed threshold or global mean
                LET $level = math::min(4, math::floor($raw_score / 2.0));
                
                UPDATE $node_id SET significance = $level;
            };
        ";

        db.query(sql)
            .bind(("center", center_node_id.clone()))
            .await?;

        tracing::info!(
            "ANALYSIS: Significance area recalculated successfully for {:?}",
            center_node_id
        );
        Ok(())
    }
}

// -----------------------------------------------------------------------------
// Graph Analysis: Elastic Boundary Calculation
// -----------------------------------------------------------------------------

pub struct GraphAnalysis;

impl GraphAnalysis {
    /// Calculates the absolute bounding box of all nodes in the graph using a native aggregate query.
    pub async fn calculate_global_bounds(db: &Surreal<Db>) -> anyhow::Result<BoundingBox> {
        // SurrealQL: Extract clean arrays, filter out nulls, and compute strict boundaries
        let sql = "
            LET $xs = (SELECT VALUE position.x FROM inode, task_node, inter_node WHERE position.x != NONE);
            LET $ys = (SELECT VALUE position.y FROM inode, task_node, inter_node WHERE position.y != NONE);
            RETURN {
                min_x: math::min($xs),
                max_x: math::max($xs),
                min_y: math::min($ys),
                max_y: math::max($ys)
            };
        ";

        let mut res = db.query(sql).await?;
        let bounds: Option<BoundingBox> = res.take(0)?;
        bounds.ok_or_else(|| anyhow::anyhow!("No nodes found to calculate bounds"))
    }
}
