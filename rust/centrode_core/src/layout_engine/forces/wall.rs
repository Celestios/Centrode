use crate::domain::base_models::BoundingBox;
use crate::layout_engine::config::ForceConfig;
use crate::layout_engine::types::NodePhysics;

pub fn wall_force(node: &NodePhysics, area: &BoundingBox, config: &ForceConfig) -> (f64, f64) {
    let mut fx = 0.0;
    let mut fy = 0.0;
    let padding = config.wall_padding;
    let kw = config.wall_strength;

    let left_pen = area.min_x + padding - node.x;
    if left_pen > 0.0 {
        fx += kw * left_pen;
    }

    let right_pen = (node.x + node.width) - (area.max_x - padding);
    if right_pen > 0.0 {
        fx -= kw * right_pen;
    }

    let top_pen = area.min_y + padding - node.y;
    if top_pen > 0.0 {
        fy += kw * top_pen;
    }

    let bottom_pen = (node.y + node.height) - (area.max_y - padding);
    if bottom_pen > 0.0 {
        fy -= kw * bottom_pen;
    }

    (fx, fy)
}
