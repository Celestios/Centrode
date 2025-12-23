use serde::{Deserialize, Serialize};
use surrealdb::sql::Thing;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IRelation {
    #[serde(alias = "id", skip_serializing_if = "Option::is_none")]
    pub id: Option<Thing>,
    pub verb: String,
    pub visual_formatting: Option<String>,
    pub directionless: bool,
    pub layer: u8,
}

#[derive(Debug, Clone)]
pub struct RelationInput {
    pub from: String,
    pub to: String,  
    pub props: IRelation,
}