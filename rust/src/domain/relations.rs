use crate::domain::base_models::{IsTable, Record};
use crate::domain::styles::{RelationStyle, RelationLayout};
use surrealdb::types::{RecordId, RecordIdKey, SurrealValue, Value};

#[derive(Debug, Clone, SurrealValue)]
pub struct IRelation {
    pub key: String,
    #[surreal(rename = "in")]
    pub in_: String,
    pub out: String,
    pub fields: IRelationFields,
}

impl IsTable for IRelation {
    const LABEL: &'static str = "IRelation";

    fn get_key(&self) -> &str {
        &self.key
    }
}

impl IRelation {
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

    pub fn to_db_value(self) -> Value {
        let in_id = self.get_in_id();
        let out_id = self.get_out_id();
        let mut val = self.fields.into_value();
        if let Value::Object(ref mut obj) = val {
            obj.insert("id".to_string(), Value::RecordId(RecordId::new(Self::LABEL, self.key)));
            obj.insert("in".to_string(), Value::RecordId(in_id));
            obj.insert("out".to_string(), Value::RecordId(out_id));
        }
        val
    }

    pub fn from_db_value(value: Value) -> Option<Self> {
        let mut record = Record::from_record_value(value)?;
        let in_val = if let Value::Object(ref mut obj) = record.fields {
            obj.remove("in")
        } else {
            None
        };
        let out_val = if let Value::Object(ref mut obj) = record.fields {
            obj.remove("out")
        } else {
            None
        };

        let in_str = match in_val {
            Some(Value::RecordId(rid)) => {
                let key_str = match rid.key {
                    RecordIdKey::String(s) => s,
                    _ => return None,
                };
                format!("{}:{}", rid.table, key_str)
            }
            Some(Value::String(s)) => s,
            _ => return None,
        };
        let out_str = match out_val {
            Some(Value::RecordId(rid)) => {
                let key_str = match rid.key {
                    RecordIdKey::String(s) => s,
                    _ => return None,
                };
                format!("{}:{}", rid.table, key_str)
            }
            Some(Value::String(s)) => s,
            _ => return None,
        };

        let (key, fields) = record.to_type::<IRelationFields>()?;
        Some(IRelation {
            key,
            in_: in_str,
            out: out_str,
            fields,
        })
    }
}

#[derive(Debug, Clone, SurrealValue)]
pub struct IRelationFields {
    pub verb: String,
    pub style: Option<RelationStyle>,
    pub resolved_style: Option<RelationStyle>,
    pub layout: Option<RelationLayout>,
    pub resolved_layout: Option<RelationLayout>,
    pub directionless: bool,
    pub layer: String,
    pub created_at: i64,
    pub updated_at: i64,
}

