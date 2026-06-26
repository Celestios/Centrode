/// Resolves the final ARGB32 color based on selection state and theme colors.
pub fn resolve_relation_color(
    base_color_argb: u32,
    is_selected: bool,
    selection_accent_argb: u32,
) -> u32 {
    if is_selected {
        selection_accent_argb
    } else {
        base_color_argb
    }
}

/// Converts ARGB components to u32 representation.
pub fn to_argb32(a: u8, r: u8, g: u8, b: u8) -> u32 {
    ((a as u32) << 24) | ((r as u32) << 16) | ((g as u32) << 8) | (b as u32)
}
