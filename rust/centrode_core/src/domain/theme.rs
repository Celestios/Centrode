pub use crate::types::MapTheme;
use surrealdb::types::SurrealValue;

#[derive(Debug, Clone, SurrealValue)]
pub struct FontWeight(pub u8);

#[derive(Debug, Clone, SurrealValue)]
pub struct ThemeFields {
    pub name: String,
    // ── Core palette (5 canonical anchors) ──
    pub primary_color: u32,
    pub secondary_color: u32,
    pub tertiary_color: u32,
    pub accent_color: u32,
    pub canvas_accent_color: u32,
    // ── Typography ──
    pub font_family: String,
    pub body_font_size: f64,
    pub body_font_weight: FontWeight,
    // ── Shape ──
    pub border_radius: f64,
    // ── AppBar ──
    pub app_bar_elevation: f64,
    pub app_bar_title_font_size: f64,
    pub app_bar_title_font_weight: FontWeight,
    // ── Material 3 ──
    pub use_material3: bool,
}
