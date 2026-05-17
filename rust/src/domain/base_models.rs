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

pub struct RecordStrings {
    pub table: String,
    pub key: String,
}

impl RecordStrings {
    pub fn to_str(&self) -> String {
        format!("{}/{}", self.table.as_str(), self.key.as_str())
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
            min_x: -2500.0,
            min_y: -2500.0,
            max_x: 2500.0,
            max_y: 2500.0,
        }
    }
}
