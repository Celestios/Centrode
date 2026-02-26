use crate::domain::base_models::BoundingBox;
use serde::Deserialize;
use surrealdb::engine::local::Db;
use surrealdb::Surreal;

pub struct DecaySignificanceStrategy;

impl DecaySignificanceStrategy {
    pub async fn recalculate_area(
        &self,
        db: &Surreal<Db>,
        center_node_id: &str,
    ) -> anyhow::Result<()> {
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

        let center_id = center_node_id.to_string();
        db.query(sql).bind(("center", center_id)).await?;
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

        #[derive(Deserialize, Debug)]
        struct BoundsResult {
            min_x: Option<f64>,
            max_x: Option<f64>,
            min_y: Option<f64>,
            max_y: Option<f64>,
        }

        let mut res = db.query(sql).await?;
        let bounds: Option<BoundsResult> = res.take(2)?;

        // Safely extract floats and cast them down to i32 for the FFI boundary
        if let Some(b) = bounds {
            if let (Some(mx), Some(mxx), Some(my), Some(mxy)) = (b.min_x, b.max_x, b.min_y, b.max_y)
            {
                return Ok(BoundingBox {
                    min_x: mx as i32,
                    max_x: mxx as i32,
                    min_y: my as i32,
                    max_y: mxy as i32,
                });
            }
        }

        Ok(BoundingBox::default())
    }
}
