use crate::domain::id::TypedRecordId;
use crate::domain::nodes::{IsNode, Nodes};
use crate::domain::relations::IRelation;
use crate::domain::traits::TableKind;
pub use crate::domain::types::Template;

impl Template {
    pub fn from_selection(
        name: String,
        mut nodes: Vec<Nodes>,
        relations: Vec<IRelation>,
    ) -> anyhow::Result<Self> {
        if nodes.is_empty() {
            return Err(anyhow::anyhow!("Cannot save template from empty selection"));
        }

        let mut sum_x: f64 = 0.0;
        let mut sum_y: f64 = 0.0;
        for node in &nodes {
            let pos = node.position();
            sum_x += pos.x as f64;
            sum_y += pos.y as f64;
        }
        let count: f64 = nodes.len() as f64;
        let centroid_x: i32 = (sum_x / count).round() as i32;
        let centroid_y: i32 = (sum_y / count).round() as i32;

        for node in &mut nodes {
            let pos = node.position_mut();
            pos.x -= centroid_x;
            pos.y -= centroid_y;
        }

        let now = chrono::Utc::now().timestamp_millis();
        let key = TypedRecordId::new_v4(TableKind::Template);

        Ok(Self {
            key,
            name,
            created_at: now,
            updated_at: now,
            nodes,
            relations,
        })
    }
}
