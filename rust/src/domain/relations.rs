use crate::domain::base_models::IsTable;
use crate::domain::styles::RelationStyle;
use surrealdb::types::{RecordId, SurrealValue};

#[derive(Debug, Clone, SurrealValue)]
pub struct IRelation {
    pub key: String,
    pub fields: IRelationFields,
}

impl IsTable for IRelation {
    const LABEL: &'static str = "IRelation";

    fn get_key(&self) -> &str {
        &self.key
    }
}

#[derive(Debug, Clone, SurrealValue)]
pub struct IRelationFields {
    #[surreal(rename = "in")]
    pub in_: String,
    pub out: String,
    pub verb: String,
    pub style: Option<RelationStyle>,
    pub resolved_style: Option<RelationStyle>,
    pub directionless: bool,
    pub layer: String,
    pub created_at: i64,
    pub updated_at: i64,
}

impl IRelationFields {
    pub fn get_in_id(&self) -> RecordId {
        let (table, key) = self
            .in_
            .split_once(':')
            .expect("`in_` must contain a ':' separating table and key");
        RecordId::new(table, key)
    }

    pub fn get_out_id(&self) -> RecordId {
        let (table, key) = self
            .out
            .split_once(':')
            .expect("`out` must contain a ':' separating table and key");
        RecordId::new(table, key)
    }
}
