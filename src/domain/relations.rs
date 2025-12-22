use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IRelation {
    #[serde(alias = "id", skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
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