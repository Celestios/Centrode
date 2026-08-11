pub use crate::domain::types::MapTheme;
use centrode_macros::SurrealDbEnum;
use surrealdb::types::SurrealValue;

#[repr(u8)]
#[derive(Copy, Clone, Debug, PartialEq, Eq, Hash, SurrealDbEnum)]
pub enum ThemeBrightness {
    Light = 0,
    Dark = 1,
}

#[derive(Debug, Clone, SurrealValue)]
pub struct FontWeight(pub u8);

#[derive(Debug, Clone, SurrealValue)]
pub struct ThemeFields {
    pub name: String,
    // ── Core palette ──
    pub primary_color: u32,
    pub secondary_color: u32,
    pub accent_color: u32,
    pub canvas_accent_color: u32,
    pub scaffold_background_color: u32,
    pub card_color: u32,
    pub divider_color: u32,
    pub text_color: u32,
    // ── Typography ──
    pub font_family: String,
    pub body_font_size: f64,
    pub body_font_weight: FontWeight,
    pub body_text_color: u32,
    // ── Shape ──
    pub border_radius: f64,
    // ── AppBar ──
    pub app_bar_background_color: u32,
    pub app_bar_foreground_color: u32,
    pub app_bar_elevation: f64,
    pub app_bar_title_font_size: f64,
    pub app_bar_title_font_weight: FontWeight,
    // ── Material 3 & Brightness ──
    pub use_material3: bool,
    pub brightness: ThemeBrightness,
}
