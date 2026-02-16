use serde::{Deserialize, Serialize};
// [REMOVED] use surrealdb::sql::Thing;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IRelation {
    // [CHANGED]
    #[serde(alias = "id", skip_serializing_if = "Option::is_none", with = "crate::domain::serde_helpers::option_thing_string")]
    pub id: Option<String>,
    // Map SurrealDB's inherent 'in' and 'out' pointer fields
    #[serde(rename = "in", alias = "in", skip_serializing_if = "Option::is_none", default, with = "crate::domain::serde_helpers::option_thing_string")]
    pub in_id: Option<String>,
    #[serde(rename = "out", alias = "out", skip_serializing_if = "Option::is_none", default, with = "crate::domain::serde_helpers::option_thing_string")]
    pub out_id: Option<String>,
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