use crate::domain::base_models::BoundingBox;
use crate::domain::id::TypedRecordId;
use crate::domain::nodes::{INode, InterNode, TaskNode};
use crate::domain::relations::IRelation;
use crate::domain::traits::SurrealTable;
use crate::persistence::repo::Repository;

use anyhow::Result;

impl Repository {
    pub async fn trigger_significance_update(&self, node_id: &TypedRecordId) -> Result<()> {
        let self_clone = self.clone();
        let id_clone = *node_id;

        tokio::spawn(async move {
            if let Err(e) = self_clone.recalculate_significance_area(id_clone).await {
                tracing::error!("Significance update failed: {}", e);
            }
        });

        Ok(())
    }

    pub async fn recalculate_significance_area(&self, center_node_id: TypedRecordId) -> Result<()> {
        tracing::info!(
            "ANALYSIS: Recalculating significance area for center node: {:?}",
            center_node_id.to_string()
        );

        let sql = format!(
            "
            LET $targets = (SELECT VALUE `out` FROM {0} WHERE `in` = $center);
            
            FOR $node_id IN $targets {{
                LET $neighbors = (SELECT VALUE `out` FROM {0} WHERE `in` = $node_id);
                LET $d1 = array::len($neighbors);
                LET $d2 = array::len(SELECT VALUE id FROM {0} WHERE $neighbors CONTAINS `in`);
                
                LET $raw_score = ($d1 * 1.0) + ($d2 * 0.5);
                
                LET $level = math::min([4, math::floor($raw_score / 2.0)]);
                
                UPDATE $node_id SET significance = $level;
            }};
            ",
            IRelation::LABEL,
        );

        self.db.query(sql)
            .bind(("center", center_node_id.into_record()))
            .await?;

        tracing::info!(
            "ANALYSIS: Significance area recalculated successfully for {:?}",
            center_node_id
        );
        Ok(())
    }

    pub async fn calculate_global_bounds(&self) -> Result<BoundingBox> {
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

        let mut res = self.db.query(sql).await?;
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
