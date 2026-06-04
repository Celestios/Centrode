use crate::domain::base_models::IsTable;
use crate::domain::nodes::{IsNode, Nodes};
use crate::domain::relations::IRelation;
use surrealdb::types::SurrealValue;

#[derive(Debug, Clone, SurrealValue)]
pub struct Template {
    pub key: String,
    pub name: String,
    pub created_at: i64,
    pub updated_at: i64,
    pub nodes: Vec<Nodes>,
    pub relations: Vec<IRelation>,
}

impl IsTable for Template {
    const LABEL: &'static str = "Template";

    fn get_key(&self) -> &str {
        &self.key
    }
}

impl Template {
    pub fn from_selection(
        name: String,
        mut nodes: Vec<Nodes>,
        relations: Vec<IRelation>,
    ) -> anyhow::Result<Self> {
        if nodes.is_empty() {
            return Err(anyhow::anyhow!("Cannot save template from empty selection"));
        }

        // Calculate centroid of selected nodes
        let mut sum_x = 0.0;
        let mut sum_y = 0.0;
        for node in &nodes {
            let pos = node.position();
            sum_x += pos.x as f64;
            sum_y += pos.y as f64;
        }
        let count = nodes.len() as f64;
        let centroid_x = (sum_x / count).round() as i32;
        let centroid_y = (sum_y / count).round() as i32;

        // Shift coordinates relative to (0, 0)
        for node in &mut nodes {
            let pos = node.position_mut();
            pos.x -= centroid_x;
            pos.y -= centroid_y;
        }

        let now = chrono::Utc::now().timestamp_millis();
        let key = uuid::Uuid::new_v4().to_string();

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
