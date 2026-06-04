use flutter_rust_bridge::frb;
use surrealdb::types::SurrealValue;
use crate::domain::schema::SurqlSchemaField;

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

impl SurqlSchemaField for NodeStyle {
    fn field_type() -> String { "object".to_string() }
    fn sub_field_paths() -> Vec<(String, String)> {
        vec![
            ("bg_color".to_string(), "int".to_string()),
            ("stroke_color".to_string(), "int".to_string()),
            ("stroke_width".to_string(), "int".to_string()),
            ("font_family".to_string(), "string".to_string()),
            ("font_size".to_string(), "float".to_string()),
            ("shape".to_string(), "string".to_string()),
            ("width".to_string(), "int".to_string()),
            ("height".to_string(), "int".to_string()),
            ("text_color".to_string(), "int".to_string()),
            ("border_radius".to_string(), "float".to_string()),
            ("padding".to_string(), "float".to_string()),
            ("shadow_color".to_string(), "int".to_string()),
            ("shadow_blur".to_string(), "float".to_string()),
            ("shadow_spread".to_string(), "float".to_string()),
            ("shadow_offset_x".to_string(), "float".to_string()),
            ("shadow_offset_y".to_string(), "float".to_string()),
            ("strategy_type".to_string(), "string".to_string()),
        ]
    }
}

impl SurqlSchemaField for RelationStyle {
    fn field_type() -> String { "object".to_string() }
    fn sub_field_paths() -> Vec<(String, String)> {
        vec![
            ("bg_color".to_string(), "int".to_string()),
            ("stroke_color".to_string(), "int".to_string()),
            ("stroke_width".to_string(), "int".to_string()),
            ("font_family".to_string(), "string".to_string()),
            ("font_size".to_string(), "float".to_string()),
            ("shape".to_string(), "string".to_string()),
            ("arrow_type".to_string(), "string".to_string()),
            ("arrow_size".to_string(), "float".to_string()),
            ("width".to_string(), "int".to_string()),
            ("height".to_string(), "int".to_string()),
            ("text_color".to_string(), "int".to_string()),
            ("shadow_color".to_string(), "int".to_string()),
            ("shadow_blur".to_string(), "float".to_string()),
            ("shadow_offset_x".to_string(), "float".to_string()),
            ("shadow_offset_y".to_string(), "float".to_string()),
            ("strategy_type".to_string(), "string".to_string()),
            ("stroke_pattern".to_string(), "string".to_string()),
        ]
    }
}

impl SurqlSchemaField for RelationLayout {
    fn field_type() -> String { "object".to_string() }
    fn sub_field_paths() -> Vec<(String, String)> {
        vec![
            ("from_side".to_string(), "string".to_string()),
            ("to_side".to_string(), "string".to_string()),
            ("strategy_type".to_string(), "string".to_string()),
        ]
    }
}

impl SurqlSchemaField for NodeLayout {
    fn field_type() -> String { "object".to_string() }
    fn sub_field_paths() -> Vec<(String, String)> {
        vec![
            ("strategy_type".to_string(), "string".to_string()),
        ]
    }
}

