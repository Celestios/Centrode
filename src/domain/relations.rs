use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IRelation {
    pub verb: String,
    pub visual_formatting: Option<String>,
    pub directionless: bool,
    pub layer: u8,
}

#[derive(Debug, Clone)]
pub struct RelationInput {
    pub from: String, // SurrealDB RecordId (e.g., "inode:xyz")
    pub to: String,   // SurrealDB RecordId
    pub props: IRelation,
}