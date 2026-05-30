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
    // --- Advanced Visual Properties ---
    pub text_color: u32,
    pub shadow_color: u32,
    pub shadow_blur: f64,
    pub shadow_offset_x: f64,
    pub shadow_offset_y: f64,
    pub strategy_type: String,
    pub stroke_pattern: String,
}

#[frb(dart_metadata=("freezed"))]
#[derive(Debug, Clone, PartialEq, SurrealValue)]
pub struct RelationLayout {
    pub from_side: String,
    pub to_side: String,
    pub strategy_type: String,
}

#[frb(dart_metadata=("freezed"))]
#[derive(Debug, Clone, PartialEq, SurrealValue)]
pub struct NodeLayout {
    pub strategy_type: String,
}

