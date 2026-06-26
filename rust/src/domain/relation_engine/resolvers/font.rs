/// Maps a requested font family to a fallback if empty or invalid.
pub fn resolve_font_family(requested: &str, default_font: &str) -> String {
    if requested.trim().is_empty() {
        default_font.to_string()
    } else {
        requested.to_string()
    }
}
