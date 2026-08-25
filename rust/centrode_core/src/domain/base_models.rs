use crate::id::TypedRecordId;
use crate::traits::TableKind;
pub use crate::types::MapData;
use centrode_macros::{SurqlSchemaField, SurrealDbEnum};
use serde::{Deserialize, Serialize};
use surrealdb::types::{RecordId, SurrealValue, Value};
use uuid::Uuid;

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
}

#[derive(Debug, Clone, SurrealValue, PartialEq, Eq, SurqlSchemaField)]
pub struct Comment {
    pub text: String,
    pub created_at: i64,
}

#[derive(Debug, Clone, SurrealValue, PartialEq, Eq, SurqlSchemaField)]
pub struct Attachment {
    pub id: String,
    pub hash: String,
    pub name: String,
    pub mime_type: String,
    pub byte_size: i64,
    pub width: Option<u32>,
    pub height: Option<u32>,
    pub duration_ms: Option<u32>,
}

#[derive(Debug, Clone, SurrealValue, PartialEq, Eq, SurqlSchemaField)]
pub struct Coordinates {
    pub x: i32,
    pub y: i32,
}

#[derive(Debug, Clone, SurrealValue, PartialEq, Eq, SurqlSchemaField)]
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

#[repr(u8)]
#[derive(Copy, Clone, Debug, PartialEq, Eq, Hash, Default, SurrealDbEnum)]
pub enum DisplayMode {
    #[default]
    Importance = 0,
    Leveling = 1,
}

impl Default for MapData {
    fn default() -> Self {
        Self {
            map_name: "Untitled Map".to_string(),
            viewport_state: ViewportState::default(),
            active_theme_id: None,
            display_mode: DisplayMode::default(),
            opt_area: None,
            language: None,
        }
    }
}

impl MapData {
    pub const KEY: &'static str = "singleton";
    pub const SINGLETON_KEY: Uuid = Uuid::nil();

    pub fn record_id() -> TypedRecordId {
        TypedRecordId::new(TableKind::MapData, Self::SINGLETON_KEY)
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

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct MapDescriptor {
    pub id: String,
    pub name: String,
    pub storage_path: String,
    pub created_at_ms: i64,
    pub modified_at_ms: i64,
    pub accessed_at_ms: i64,
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
