use crate::domain::relation_engine::geometry::Point;

/// Offsets an icon position outward from a node port along its normal direction.
pub fn resolve_icon_offset(
    port_position: Point,
    port_normal: Point,
    icon_size: f64,
    padding: f64,
) -> Point {
    let offset = port_normal * (icon_size * 0.5 + padding);
    port_position + offset
}
