use flutter_rust_bridge::frb;
use centrode_macros::{SurrealDbEnum, SurqlSchemaField};
use surrealdb::types::SurrealValue;

#[repr(u8)]
#[derive(Copy, Clone, Debug, PartialEq, Eq, Hash, SurrealDbEnum)]
pub enum EndpointShape {
    None = 0,
    Arrow = 1,
    OpenArrow = 2,
    Circle = 3,
    Diamond = 4,
    Square = 5,
}

#[repr(u8)]
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Default, SurrealDbEnum)]
pub enum RelationDirection {
    #[default]
    Forward = 0,
    Backward = 1,
    Undirected = 2,
}

#[repr(u8)]
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Default, SurrealDbEnum)]
pub enum PortSide {
    #[default]
    Auto = 0,
    Top = 1,
    Right = 2,
    Bottom = 3,
    Left = 4,
    TopLeft = 5,
    TopRight = 6,
    BottomLeft = 7,
    BottomRight = 8,
}

#[repr(u8)]
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Default, SurrealDbEnum)]
pub enum PortType {
    #[default]
    Middle = 0,
    Corner = 1,
    Edge = 2,
}

#[frb(dart_metadata=("freezed"))]
#[derive(Debug, Clone, PartialEq, SurrealValue, SurqlSchemaField)]
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

#[frb(dart_metadata=("freezed"))]
#[derive(Debug, Clone, PartialEq, SurrealValue, SurqlSchemaField)]
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

#[frb(dart_metadata=("freezed"))]
#[derive(Debug, Clone, PartialEq, SurrealValue, SurqlSchemaField)]
pub struct ControlPoint {
    pub x: f64,
    pub y: f64,
}

#[frb(dart_metadata=("freezed"))]
#[derive(Debug, Clone, PartialEq, SurrealValue, SurqlSchemaField)]
pub struct RelationLayout {
    pub from_side: Option<PortSide>,
    pub to_side: Option<PortSide>,
    pub strategy_type: String,
    pub control_point_1: Option<ControlPoint>,
    pub control_point_2: Option<ControlPoint>,
}

#[frb(dart_metadata=("freezed"))]
#[derive(Debug, Clone, PartialEq, SurrealValue, SurqlSchemaField)]
pub struct NodeLayout {
    pub strategy_type: String,
}

