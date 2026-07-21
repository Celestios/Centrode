use crate::domain::base_models::{IsTable, Record, RecordStrings};
use crate::domain::styles::{RelationLayout, RelationStyle};
use surrealdb::types::{RecordId, RecordIdKey, SurrealValue, Value};

#[derive(Debug, Clone)]
pub struct IRelation {
    pub key: String,
    pub in_: RecordStrings,
    pub out: RecordStrings,
    pub fields: IRelationFields,
}

impl IsTable for IRelation {
    const LABEL: &'static str = "IRelation";

    fn get_key(&self) -> &str {
        &self.key
    }
}

impl SurrealValue for IRelation {
    fn kind_of() -> surrealdb::types::Kind {
        surrealdb::types::Kind::Object
    }

    fn from_value(value: Value) -> Result<Self, surrealdb::types::Error> {
        let record = Record::from_record_value(value).ok_or_else(|| {
            surrealdb::types::Error::thrown(
                "Expected an object with an 'id' field for IRelation".to_string(),
            )
        })?;

        let RecordIdKey::String(key) = record.id.key else {
            return Err(surrealdb::types::Error::thrown(
                "RecordId key must be a string".to_string(),
            ));
        };

        let Value::Object(mut fields_map) = record.fields else {
            return Err(surrealdb::types::Error::thrown(
                "Fields must be an object".to_string(),
            ));
        };

        let in_val = fields_map.remove("in").ok_or_else(|| {
            surrealdb::types::Error::thrown("Missing 'in' field in IRelation".to_string())
        })?;
        let out_val = fields_map.remove("out").ok_or_else(|| {
            surrealdb::types::Error::thrown("Missing 'out' field in IRelation".to_string())
        })?;

        let in_rs = RecordStrings::from_value(in_val)?;
        let out_rs = RecordStrings::from_value(out_val)?;

        let fields_obj = Value::Object(fields_map);
        let fields = IRelationFields::from_value(fields_obj)?;

        Ok(IRelation {
            key,
            in_: in_rs,
            out: out_rs,
            fields,
        })
    }

    fn into_value(self) -> Value {
        let val = self.fields.into_value();
        match val {
            Value::Object(mut obj) => {
                obj.insert("id".to_string(), RecordId::new(Self::LABEL, self.key).into_value());
                obj.insert("in".to_string(), self.in_.into_value());
                obj.insert("out".to_string(), self.out.into_value());
                Value::Object(obj)
            }
            other => {
                debug_assert!(false, "IRelationFields serialized to non-Object: {:?}", other);
                let mut obj = std::collections::BTreeMap::new();
                obj.insert("id".to_string(), RecordId::new(Self::LABEL, self.key).into_value());
                obj.insert("in".to_string(), self.in_.into_value());
                obj.insert("out".to_string(), self.out.into_value());
                Value::Object(obj.into())
            }
        }
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
