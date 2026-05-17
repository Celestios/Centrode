use flutter_rust_bridge::frb;
use surrealdb::types::SurrealValue;

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
}

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
    pub width: i32,
    pub height: i32,
}
