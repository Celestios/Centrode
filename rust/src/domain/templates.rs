use crate::domain::base_models::IsTable;
use crate::domain::nodes::Nodes;
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
