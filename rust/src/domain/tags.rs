use crate::domain::id::TypedRecordId;
use crate::domain::schema::SurqlSchemaField;
use crate::domain::traits::{AuxiliaryEntity, SurrealTable, TableKind};
use crate::define_surql_schema_struct;
use surrealdb::types::{SurrealValue, Value};
use uuid::Uuid;

#[derive(Debug, Clone)]
#[non_exhaustive]
pub enum TagEdge {
    Hydrated(Tag),
    Pointer(TypedRecordId),
}

impl SurrealValue for TagEdge {
    fn kind_of() -> surrealdb::types::Kind {
        surrealdb::types::Kind::Either(vec![
            surrealdb::types::Kind::Record(vec![]),
            TagFields::kind_of(),
        ])
    }

    fn from_value(value: Value) -> Result<Self, surrealdb::types::Error> {
        match value {
            val @ Value::RecordId(_) => TypedRecordId::from_value(val).map(Self::Pointer),
            val @ Value::Object(_) => {
                let mut obj = match val {
                    Value::Object(o) => o,
                    _ => unreachable!(),
                };
                if let Some(id_val) = obj.remove("id") {
                    let key = TypedRecordId::from_value(id_val)?;
                    let fields = TagFields::from_value(Value::Object(obj))?;
                    return Ok(Self::Hydrated(Tag { key, fields }));
                }
                Err(surrealdb::types::Error::thrown(
                    "Expected Hydrated Tag with id or Pointer".to_string(),
                ))
            }
            unsupported => Err(surrealdb::types::Error::thrown(format!(
                "Expected Object or RecordId for TagEdge, found: {:?}",
                unsupported,
            ))),
        }
    }

    fn into_value(self) -> Value {
        match self {
            Self::Hydrated(v) => v.key.into_value(),
            Self::Pointer(p) => p.into_value(),
        }
    }
}

#[derive(Debug, Clone, SurrealValue)]
pub struct Tag {
    pub key: TypedRecordId,
    pub fields: TagFields,
}

impl Tag {
    pub const LABEL: &'static str = "Tag";
}

impl SurrealTable for Tag {
    const KIND: TableKind = TableKind::Tag;

    fn get_key(&self) -> &Uuid {
        &self.key.key
    }
}

impl AuxiliaryEntity for Tag {}

define_surql_schema_struct! {
    #[derive(Debug, Clone, SurrealValue)]
    pub struct TagFields {
        pub name: String,
        pub color: u32,
        pub created_at: i64,
        pub updated_at: i64,
    }
}

impl SurqlSchemaField for TagEdge {
    fn field_type() -> String { "any".to_string() }
    fn sub_field_paths() -> Vec<(String, String)> { vec![] }
}
