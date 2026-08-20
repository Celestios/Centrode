use crate::layout_engine::types::{AnchorSpring, NodePhysics};

pub fn anchor_force(node: &NodePhysics, anchor: &AnchorSpring) -> (f64, f64) {
    let dx = anchor.anchor_x - node.x;
    let dy = anchor.anchor_y - node.y;
    (anchor.strength * dx, anchor.strength * dy)
}
