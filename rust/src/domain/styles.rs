use flutter_rust_bridge::frb;
use crate::define_surql_schema_struct;
use mycelium_macros::SurrealDbEnum;
use surrealdb::types::{SurrealValue, Value};
use crate::domain::schema::SurqlSchemaField;

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

pub use crate::domain::enums::EndpointShape;

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
    pub struct ControlPoint {
        pub x: f64,
        pub y: f64,
    }
}

define_surql_schema_struct! {
    #[frb(dart_metadata=("freezed"))]
    #[derive(Debug, Clone, PartialEq, SurrealValue)]
    pub struct RelationLayout {
        pub from_side: Option<PortSide>,
        pub to_side: Option<PortSide>,
        pub strategy_type: String,
        pub control_point_1: Option<ControlPoint>,
        pub control_point_2: Option<ControlPoint>,
    }
}

define_surql_schema_struct! {
    #[frb(dart_metadata=("freezed"))]
    #[derive(Debug, Clone, PartialEq, SurrealValue)]
    pub struct NodeLayout {
        pub strategy_type: String,
    }
}
