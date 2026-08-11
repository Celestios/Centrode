use crate::domain::styles::{RelationDirection, RelationLayout, RelationStyle};
pub use crate::domain::types::IRelation;
use surrealdb::types::SurrealValue;

#[derive(Debug, Clone, SurrealValue)]
pub struct IRelationFields {
    pub verb: String,
    pub style: Option<RelationStyle>,
    pub resolved_style: Option<RelationStyle>,
    pub layout: Option<RelationLayout>,
    pub resolved_layout: Option<RelationLayout>,
    pub direction: RelationDirection,
    pub layer: String,
    pub created_at: i64,
    pub updated_at: i64,
}
