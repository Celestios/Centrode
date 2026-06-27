use flutter_rust_bridge::frb;
use surrealdb::types::{SurrealValue, Value};
use crate::define_surql_schema_struct;
use crate::domain::schema::SurqlSchemaField;

#[derive(Debug, Clone, PartialEq, Eq, Hash, Default)]
#[frb]
pub enum PortSide {
    #[default]
    Auto,
    Top,
    Right,
    Bottom,
    Left,
    TopLeft,
    TopRight,
    BottomLeft,
    BottomRight,
}

impl PortSide {
    pub fn as_str(&self) -> &'static str {
        match self {
            PortSide::Auto => "Auto",
            PortSide::Top => "Top",
            PortSide::Right => "Right",
            PortSide::Bottom => "Bottom",
            PortSide::Left => "Left",
            PortSide::TopLeft => "TopLeft",
            PortSide::TopRight => "TopRight",
            PortSide::BottomLeft => "BottomLeft",
            PortSide::BottomRight => "BottomRight",
        }
    }

    pub fn from_str(s: &str) -> Self {
        match s.to_lowercase().as_str() {
            "top" => PortSide::Top,
            "right" => PortSide::Right,
            "bottom" => PortSide::Bottom,
            "left" => PortSide::Left,
            "topleft" => PortSide::TopLeft,
            "topright" => PortSide::TopRight,
            "bottomleft" => PortSide::BottomLeft,
            "bottomright" => PortSide::BottomRight,
            _ => PortSide::Auto,
        }
    }
}

impl SurrealValue for PortSide {
    fn kind_of() -> surrealdb::types::Kind {
        surrealdb::types::Kind::String
    }

    fn from_value(value: Value) -> Result<Self, surrealdb::types::Error> {
        match value {
            Value::String(s) => Ok(PortSide::from_str(&s)),
            _ => Err(surrealdb::types::Error::thrown(format!(
                "Expected string for PortSide, found: {:?}", value
            ))),
        }
    }

    fn into_value(self) -> Value {
        Value::String(self.as_str().to_string())
    }
}

impl SurqlSchemaField for PortSide {
    fn field_type() -> String { "string".to_string() }
    fn sub_field_paths() -> Vec<(String, String)> { vec![] }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Default)]
#[frb]
pub enum PortType {
    #[default]
    Middle,
    Corner,
    Edge,
}

impl PortType {
    pub fn as_str(&self) -> &'static str {
        match self {
            PortType::Middle => "Middle",
            PortType::Corner => "Corner",
            PortType::Edge => "Edge",
        }
    }

    pub fn from_str(s: &str) -> Self {
        match s.to_lowercase().as_str() {
            "corner" => PortType::Corner,
            "edge" => PortType::Edge,
            _ => PortType::Middle,
        }
    }
}

impl SurrealValue for PortType {
    fn kind_of() -> surrealdb::types::Kind {
        surrealdb::types::Kind::String
    }

    fn from_value(value: Value) -> Result<Self, surrealdb::types::Error> {
        match value {
            Value::String(s) => Ok(PortType::from_str(&s)),
            _ => Err(surrealdb::types::Error::thrown(format!(
                "Expected string for PortType, found: {:?}", value
            ))),
        }
    }

    fn into_value(self) -> Value {
        Value::String(self.as_str().to_string())
    }
}

impl SurqlSchemaField for PortType {
    fn field_type() -> String { "string".to_string() }
    fn sub_field_paths() -> Vec<(String, String)> { vec![] }
}

#[derive(Debug, Clone, PartialEq, Eq, Hash, Default)]
#[frb]
pub enum EndpointShape {
    #[default]
    None,
    Arrow,
    OpenArrow,
    Circle,
    Diamond,
    Square,
}

impl EndpointShape {
    pub fn as_str(&self) -> &'static str {
        match self {
            EndpointShape::None => "None",
            EndpointShape::Arrow => "Arrow",
            EndpointShape::OpenArrow => "OpenArrow",
            EndpointShape::Circle => "Circle",
            EndpointShape::Diamond => "Diamond",
            EndpointShape::Square => "Square",
        }
    }

    pub fn from_str(s: &str) -> Self {
        match s {
            "Arrow" => EndpointShape::Arrow,
            "OpenArrow" => EndpointShape::OpenArrow,
            "Circle" => EndpointShape::Circle,
            "Diamond" => EndpointShape::Diamond,
            "Square" => EndpointShape::Square,
            _ => EndpointShape::None,
        }
    }
}

impl SurrealValue for EndpointShape {
    fn kind_of() -> surrealdb::types::Kind {
        surrealdb::types::Kind::String
    }

    fn from_value(value: Value) -> Result<Self, surrealdb::types::Error> {
        match value {
            Value::String(s) => Ok(EndpointShape::from_str(&s)),
            _ => Err(surrealdb::types::Error::thrown(format!(
                "Expected string for EndpointShape, found: {:?}", value
            ))),
        }
    }

    fn into_value(self) -> Value {
        Value::String(self.as_str().to_string())
    }
}

impl SurqlSchemaField for EndpointShape {
    fn field_type() -> String { "string".to_string() }
    fn sub_field_paths() -> Vec<(String, String)> { vec![] }
}

define_surql_schema_struct! {
    #[frb(dart_metadata=("freezed"))]
    #[derive(Debug, Clone, PartialEq, SurrealValue)]
    pub struct NodeStyle {
        pub bg_color: u32,
        pub stroke_color: u32,
        pub stroke_width: i32,
        pub font_family: String,
        pub font_size: f64,
        pub shape: String,
        pub width: i32,
        pub height: i32,
        // --- Advanced Visual Properties ---
        pub text_color: u32,
        pub border_radius: f64,
        pub padding: f64,
        pub shadow_color: u32,
        pub shadow_blur: f64,
        pub shadow_spread: f64,
        pub shadow_offset_x: f64,
        pub shadow_offset_y: f64,
        pub strategy_type: String,
    }
}

define_surql_schema_struct! {
    #[frb(dart_metadata=("freezed"))]
    #[derive(Debug, Clone, PartialEq, SurrealValue)]
    pub struct RelationStyle {
        pub bg_color: u32,
        pub stroke_color: u32,
        pub stroke_width: i32,
        pub font_family: String,
        pub font_size: f64,
        pub shape: String,
        pub arrow_type: String,
        pub arrow_size: f64,
        pub start_shape: Option<EndpointShape>,
        pub end_shape: Option<EndpointShape>,
        pub width: i32,
        pub height: i32,
        // --- Advanced Visual Properties ---
        pub text_color: u32,
        pub shadow_color: u32,
        pub shadow_blur: f64,
        pub shadow_offset_x: f64,
        pub shadow_offset_y: f64,
        pub strategy_type: String,
        pub stroke_pattern: String,
        pub body_strategy: String,
    }
}

define_surql_schema_struct! {
    #[frb(dart_metadata=("freezed"))]
    #[derive(Debug, Clone, PartialEq, SurrealValue)]
    pub struct RelationLayout {
        pub from_side: Option<PortSide>,
        pub to_side: Option<PortSide>,
        pub strategy_type: String,
    }
}

define_surql_schema_struct! {
    #[frb(dart_metadata=("freezed"))]
    #[derive(Debug, Clone, PartialEq, SurrealValue)]
    pub struct NodeLayout {
        pub strategy_type: String,
    }
}
