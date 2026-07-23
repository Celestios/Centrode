use crate::domain::id::TypedRecordId;
use crate::domain::nodes::{IsNode, Nodes};
use crate::domain::relations::IRelation;
use crate::domain::traits::{AuxiliaryEntity, SurrealTable, TableKind};
use surrealdb::types::SurrealValue;
use uuid::Uuid;

#[derive(Debug, Clone, SurrealValue)]
pub struct Template {
    pub key: TypedRecordId,
    pub name: String,
    pub created_at: i64,
    pub updated_at: i64,
    pub nodes: Vec<Nodes>,
    pub relations: Vec<IRelation>,
}

impl Template {
    pub const LABEL: &'static str = "Template";
}

impl SurrealTable for Template {
    const KIND: TableKind = TableKind::Template;

    fn get_key(&self) -> &Uuid {
        &self.key.key
    }
}

impl AuxiliaryEntity for Template {}

impl Template {
    pub fn from_selection(
        name: String,
        mut nodes: Vec<Nodes>,
        relations: Vec<IRelation>,
    ) -> anyhow::Result<Self> {
        if nodes.is_empty() {
            return Err(anyhow::anyhow!("Cannot save template from empty selection"));
        }

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
