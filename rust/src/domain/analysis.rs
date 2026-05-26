use crate::domain::base_models::{BoundingBox, IsTable, RecordStrings};
use crate::domain::nodes::{INode, InterNode, TaskNode};
use crate::domain::relations::IRelation;
use surrealdb::engine::local::Db;
use surrealdb::Surreal;

pub struct DecaySignificanceStrategy;

impl DecaySignificanceStrategy {
    pub async fn recalculate_area(
        &self,
        db: &Surreal<Db>,
        center_node_id: RecordStrings,
    ) -> anyhow::Result<()> {
        tracing::info!(
            "ANALYSIS: Recalculating significance area for center node: {:?}",
            center_node_id.to_str()
        );

        // Calculate raw scores for nodes within a 2-step radius using index-driven SELECTs
        // Escape the reserved keyword `in` with backticks
        let sql = format!(
            "
            LET $targets = (SELECT VALUE `out` FROM {0} WHERE `in` = $center);
            
            FOR $node_id IN $targets {{
                LET $neighbors = (SELECT VALUE `out` FROM {0} WHERE `in` = $node_id);
                LET $d1 = array::len($neighbors);
                LET $d2 = array::len(SELECT VALUE id FROM {0} WHERE $neighbors CONTAINS `in`);
                
                LET $raw_score = ($d1 * 1.0) + ($d2 * 0.5);
                
                -- Local normalization to 0-4 based on a fixed threshold or global mean
                LET $level = math::min([4, math::floor($raw_score / 2.0)]);
                
                UPDATE $node_id SET significance = $level;
            }};
            ",
            IRelation::LABEL,
        );

        db.query(sql)
            .bind(("center", center_node_id.into_record()))
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
        let sql = format!(
            "
            LET $xs = (SELECT VALUE position.x FROM {0}, {1}, {2} WHERE position.x != NONE);
            LET $ys = (SELECT VALUE position.y FROM {0}, {1}, {2} WHERE position.y != NONE);
            RETURN {{
                min_x: <float> math::min($xs),
                max_x: <float> math::max($xs),
                min_y: <float> math::min($ys),
                max_y: <float> math::max($ys)
            }};
            ",
            INode::LABEL,
            TaskNode::LABEL,
            InterNode::LABEL,
        );

        let mut res = db.query(sql).await?;
        let min_x: Option<f64> = res.take((2, "min_x"))?;
        let max_x: Option<f64> = res.take((2, "max_x"))?;
        let min_y: Option<f64> = res.take((2, "min_y"))?;
        let max_y: Option<f64> = res.take((2, "max_y"))?;

        if let (Some(mx), Some(mxx), Some(my), Some(mxy)) = (min_x, max_x, min_y, max_y) {
            if mx.is_finite() && mxx.is_finite() && my.is_finite() && mxy.is_finite() {
                return Ok(BoundingBox::new(mx, my, mxx, mxy));
            }
        }

        tracing::warn!(
            "ANALYSIS: Zero-Node Collapse detected or incomplete bounds. Falling back to default empty bounding box."
        );
        Ok(BoundingBox::default())
    }
}
