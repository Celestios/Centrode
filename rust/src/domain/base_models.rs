use core::convert::Into;
use surrealdb::types::{RecordId, RecordIdKey, SurrealValue, Value};

// -----------------------------------------------------------------------------
// Core Identity & Spatial Types (Restored)
// -----------------------------------------------------------------------------

#[derive(Debug, Clone, SurrealValue)]
pub struct Record {
    pub id: RecordId,
    pub fields: Value,
}

impl Record {
    pub fn from_record_value(value: Value) -> Option<Self> {
        if let Value::Object(mut obj) = value {
            if let Some(Value::RecordId(id)) = obj.remove("id") {
                return Some(Record {
                    id,
                    fields: Value::Object(obj),
                });
            }
        }
        None
    }

    pub fn to_type<T: SurrealValue>(self) -> Option<(String, T)> {
        let key = match self.id.key {
            RecordIdKey::String(s) => s,
            _ => return None,
        };
        let parsed_fields: T = T::from_value(self.fields).ok()?;
        Some((key, parsed_fields))
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct RecordStrings {
    pub table: String,
    pub key: String,
}
impl std::str::FromStr for RecordStrings {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let mut parts = s.splitn(2, ':');
        let table = parts.next().ok_or("Missing table name")?.to_string();
        let key = parts.next().ok_or("Missing record key")?.to_string();

        if table.is_empty() || key.is_empty() {
            return Err("Table or Key cannot be empty".to_string());
        }

        Ok(RecordStrings { table, key })
    }
}

impl From<&str> for RecordStrings {
    fn from(s: &str) -> Self {
        s.parse()
            .unwrap_or_else(|e| panic!("Invalid RecordStrings literal '{}': {}", s, e))
    }
}

impl std::fmt::Display for RecordStrings {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}:{}", self.table, self.key)
    }
}

impl RecordStrings {
    pub fn to_str(&self) -> String {
        format!("{}:{}", self.table.as_str(), self.key.as_str())
    }

    pub fn into_record(&self) -> RecordId {
        RecordId::new(self.table.clone(), self.key.clone())
    }
}

impl SurrealValue for RecordStrings {
    fn kind_of() -> surrealdb::types::Kind {
        surrealdb::types::Kind::Record(vec![])
    }

    fn into_value(self) -> Value {
        RecordId::new(self.table, self.key).into_value()
    }

    fn from_value(value: Value) -> Result<Self, surrealdb::types::Error> {
        match value {
            Value::RecordId(rid) => {
                let key_str = match rid.key {
                    RecordIdKey::String(s) => s.clone(),
                    unsupported => {
                        return Err(surrealdb::types::Error::thrown(format!(
                            "Expected scalar Record key, found: {:?}",
                            unsupported
                        )))
                    }
                };

                Ok(Self {
                    table: rid.table.to_string(),
                    key: key_str,
                })
            }
            unsupported => Err(surrealdb::types::Error::thrown(format!(
                "RecordStrings expected Value::RecordId, found: {:?}",
                unsupported
            ))),
        }
    }
}

pub trait IsTable {
    const LABEL: &'static str;

    fn get_label() -> &'static str {
        Self::LABEL
    }

    fn get_key(&self) -> &str;

    fn get_record_id(&self) -> RecordId {
        RecordId::new(Self::LABEL, self.get_key())
    }
}

#[derive(Debug, Clone, SurrealValue, PartialEq, Eq)]
pub struct Comment {
    pub text: String,
    pub created_at: i64,
}

#[derive(Debug, Clone, SurrealValue, PartialEq, Eq)]
pub struct Coordinates {
    pub x: i32,
    pub y: i32,
}

#[derive(Debug, Clone, SurrealValue, PartialEq, Eq)]
pub struct Size {
    pub width: i32,
    pub height: i32,
}

#[derive(Debug, Clone, SurrealValue, PartialEq)]
pub struct ViewportState {
    pub x_offset: f64,
    pub y_offset: f64,
    pub zoom_level: f64,
    pub active_view: String,
}

impl Default for ViewportState {
    fn default() -> Self {
        Self {
            x_offset: 0.0,
            y_offset: 0.0,
            zoom_level: 1.0,
            active_view: "canvas".to_string(),
        }
    }
}

#[derive(Debug, Clone, SurrealValue, Default)]
pub enum DisplayMode {
    #[default]
    Importance,
    Leveling,
}

#[derive(Debug, Clone, SurrealValue)]
pub struct MapData {
    pub map_name: String,
    pub viewport_state: ViewportState,
    pub active_theme_id: Option<String>,
    pub display_mode: DisplayMode,
}

impl Default for MapData {
    fn default() -> Self {
        Self {
            map_name: "Untitled Map".to_string(),
            viewport_state: ViewportState::default(),
            active_theme_id: None,
            display_mode: DisplayMode::default(),
        }
    }
}

impl MapData {
    pub const LABEL: &'static str = "MapMetaData";
    pub const KEY: &'static str = "singleton";

    pub fn get_record_id(&self) -> RecordId {
        RecordId::new(Self::LABEL, Self::KEY)
    }
}

// -----------------------------------------------------------------------------
// Elastic Boundary (BoundingBox)
// -----------------------------------------------------------------------------

#[derive(Debug, Clone, SurrealValue, PartialEq)]
pub struct BoundingBox {
    pub min_x: f64,
    pub min_y: f64,
    pub max_x: f64,
    pub max_y: f64,
}

impl BoundingBox {
    pub fn new(
        min_x: impl Into<f64>,
        min_y: impl Into<f64>,
        max_x: impl Into<f64>,
        max_y: impl Into<f64>,
    ) -> Self {
        Self {
            min_x: min_x.into(),
            min_y: min_y.into(),
            max_x: max_x.into(),
            max_y: max_y.into(),
        }
    }
}

impl Default for BoundingBox {
    fn default() -> Self {
        Self {
            min_x: -500.0,
            min_y: -500.0,
            max_x: 500.0,
            max_y: 500.0,
        }
    }
}
