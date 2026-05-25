use crate::domain::base_models::{IsTable, Record, RecordStrings};
use surrealdb::types::{RecordId, SurrealValue, Value};

#[derive(Debug, Clone)]
pub enum TagEdge {
    Hydrated(Tag),
    Pointer(RecordStrings),
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
            val @ Value::RecordId(_) => RecordStrings::from_value(val).map(Self::Pointer),
            val @ Value::Object(_) => {
                if let Some(record) = Record::from_record_value(val.clone()) {
                    if let Some((key, fields)) = record.to_type::<TagFields>() {
                        return Ok(Self::Hydrated(Tag { key, fields }));
                    }
                }
                Err(surrealdb::types::Error::thrown(format!(
                    "Expected Hydrated Tag or Pointer, found: {:?}",
                    val
                )))
            }
            unsupported => Err(surrealdb::types::Error::thrown(format!(
                "Expected Object or RecordId for TagEdge, found: {:?}",
                unsupported,
            ))),
        }
    }

    fn into_value(self) -> Value {
        match self {
            Self::Hydrated(v) => RecordId::new(Tag::LABEL, v.key).into_value(),
            Self::Pointer(p) => RecordId::new(p.table, p.key).into_value(),
        }
    }
}

#[derive(Debug, Clone, SurrealValue)]
pub struct Tag {
    pub key: String,
    pub fields: TagFields,
}

impl IsTable for Tag {
    const LABEL: &'static str = "Tag";

    fn get_key(&self) -> &str {
        &self.key
    }
}

#[derive(Debug, Clone, SurrealValue)]
pub struct TagFields {
    pub name: String,
    pub color: u32,
    pub created_at: i64,
    pub updated_at: i64,
}
