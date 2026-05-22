use crate::domain::base_models::{IsTable, RecordStrings};
use surrealdb::types::{RecordId, SurrealValue, Value};

#[derive(Debug, Clone)]
pub enum TagEdge {
    Hydrated(Tag),
    Pointer(RecordStrings),
}

impl SurrealValue for TagEdge {
    fn kind_of() -> surrealdb::types::Kind {
        surrealdb::types::Kind::Either(vec![surrealdb::types::Kind::Record(vec![]), Tag::kind_of()])
    }

    fn from_value(value: Value) -> Result<Self, surrealdb::types::Error> {
        match value {
            val @ Value::RecordId(_) => RecordStrings::from_value(val).map(Self::Pointer),
            val @ Value::Object(_) => Tag::from_value(val).map(Self::Hydrated),
            unsupported => Err(surrealdb::types::Error::thrown(format!(
                "Expected Object or RecordId for RecordEdge, found: {:?}",
                unsupported,
            ))),
        }
    }

    /// unlike standard into_value, this will convert both variants to their ids automatically.
    fn into_value(self) -> Value {
        match self {
            Self::Hydrated(v) => RecordId::new(Tag::LABEL, v.name).into_value(),
            Self::Pointer(p) => RecordId::new(p.table, p.key).into_value(),
        }
    }
}

#[derive(Debug, Clone, SurrealValue)]
pub struct Tag {
    pub name: String,
    pub color: u32,
}

impl IsTable for Tag {
    const LABEL: &'static str = "Tag";
    fn get_key(&self) -> &str {
        &self.name
    }
}
