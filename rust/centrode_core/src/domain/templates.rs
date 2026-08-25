use crate::id::TypedRecordId;
use crate::nodes::{IsNode, Nodes};
use crate::relations::IRelation;
use crate::traits::TableKind;
pub use crate::types::Template;

impl Template {
    pub fn from_selection(
        name: String,
        mut nodes: Vec<Nodes>,
        relations: Vec<IRelation>,
    ) -> anyhow::Result<Self> {
        Self::validate_selection(&nodes)?;
        let (centroid_x, centroid_y) = Self::compute_centroid(&nodes);
        Self::normalize_positions(&mut nodes, centroid_x, centroid_y);
        Ok(Self::construct_template(name, nodes, relations))
    }

    fn validate_selection(nodes: &[Nodes]) -> anyhow::Result<()> {
        if nodes.is_empty() {
            return Err(anyhow::anyhow!("Cannot save template from empty selection"));
        }
        Ok(())
    }

    fn compute_centroid(nodes: &[Nodes]) -> (i32, i32) {
        let mut sum_x: f64 = 0.0;
        let mut sum_y: f64 = 0.0;
        for node in nodes {
            let pos = node.position();
            sum_x += pos.x as f64;
            sum_y += pos.y as f64;
        }
        let count = nodes.len() as f64;
        (
            (sum_x / count).round() as i32,
            (sum_y / count).round() as i32,
        )
    }

    fn normalize_positions(nodes: &mut [Nodes], centroid_x: i32, centroid_y: i32) {
        for node in nodes {
            let pos = node.position_mut();
            pos.x -= centroid_x;
            pos.y -= centroid_y;
        }
    }

    fn construct_template(
        name: String,
        nodes: Vec<Nodes>,
        relations: Vec<IRelation>,
    ) -> Self {
        let now = chrono::Utc::now().timestamp_millis();
        let key = TypedRecordId::new_v4(TableKind::Template);

        Self {
            key,
            name,
            created_at: now,
            updated_at: now,
            nodes,
            relations,
        }
    }
}
