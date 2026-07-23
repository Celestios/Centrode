use crate::domain::id::TypedRecordId;
use crate::domain::styles::{RelationLayout, RelationStyle};
use crate::domain::traits::{RelationEntity, SurrealTable, TableKind};
use surrealdb::types::{RecordId, SurrealValue, Value};
use uuid::Uuid;

#[derive(Debug, Clone)]
pub struct IRelation {
    pub key: TypedRecordId,
    pub in_: TypedRecordId,
    pub out: TypedRecordId,
    pub fields: IRelationFields,
}

impl IRelation {
    pub const LABEL: &'static str = "IRelation";
}

impl SurrealTable for IRelation {
    const KIND: TableKind = TableKind::IRelation;

    fn get_key(&self) -> &Uuid {
        &self.key.key
    }
}

impl RelationEntity for IRelation {}

impl SurrealValue for IRelation {
    fn kind_of() -> surrealdb::types::Kind {
        surrealdb::types::Kind::Object
    }

    fn from_value(value: Value) -> Result<Self, surrealdb::types::Error> {
        let Value::Object(mut fields_map) = value else {
            return Err(surrealdb::types::Error::thrown(
                "Fields must be an object for IRelation".to_string(),
            ));
        };

        let id_val = fields_map.remove("id").ok_or_else(|| {
            surrealdb::types::Error::thrown("Missing 'id' field in IRelation".to_string())
        })?;
        let in_val = fields_map.remove("in").ok_or_else(|| {
            surrealdb::types::Error::thrown("Missing 'in' field in IRelation".to_string())
        })?;
        let out_val = fields_map.remove("out").ok_or_else(|| {
            surrealdb::types::Error::thrown("Missing 'out' field in IRelation".to_string())
        })?;

        let key = TypedRecordId::from_value(id_val)?;
        let in_ = TypedRecordId::from_value(in_val)?;
        let out = TypedRecordId::from_value(out_val)?;

        let fields_obj = Value::Object(fields_map);
        let fields = IRelationFields::from_value(fields_obj)?;

        Ok(IRelation {
            key,
            in_,
            out,
            fields,
        })
    }

    fn into_value(self) -> Value {
        let val = self.fields.into_value();
        match val {
            Value::Object(mut obj) => {
                obj.insert("id".to_string(), self.key.into_value());
                obj.insert("in".to_string(), self.in_.into_value());
                obj.insert("out".to_string(), self.out.into_value());
                Value::Object(obj)
            }
            other => {
                debug_assert!(false, "IRelationFields serialized to non-Object: {:?}", other);
                let mut obj = std::collections::BTreeMap::new();
                obj.insert("id".to_string(), self.key.into_value());
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
