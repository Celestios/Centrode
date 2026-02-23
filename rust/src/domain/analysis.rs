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
