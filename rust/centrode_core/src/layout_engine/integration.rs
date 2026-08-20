use crate::domain::base_models::BoundingBox;
use crate::domain::id::TypedRecordId;
use crate::layout_engine::types::NodePhysics;
use std::collections::HashMap;

pub fn integrate_positions(nodes: &mut HashMap<TypedRecordId, NodePhysics>, dt: f64) {
    for node in nodes.values_mut() {
        node.x += node.vx * dt;
        node.y += node.vy * dt;
    }
}

pub fn clamp_to_walls(
    nodes: &mut HashMap<TypedRecordId, NodePhysics>,
    area: &BoundingBox,
    padding: f64,
) {
    for node in nodes.values_mut() {
        let min_x = area.min_x + padding;
        let max_x = area.max_x - node.width - padding;
        let min_y = area.min_y + padding;
        let max_y = area.max_y - node.height - padding;

        let clamped_x = node.x.clamp(min_x, max_x);
        if clamped_x != node.x {
            node.x = clamped_x;
            node.vx = 0.0;
        }

        let clamped_y = node.y.clamp(min_y, max_y);
        if clamped_y != node.y {
            node.y = clamped_y;
            node.vy = 0.0;
        }
    }
}

pub fn compute_energy(nodes: &HashMap<TypedRecordId, NodePhysics>) -> f64 {
    nodes.values().map(|n| n.vx * n.vx + n.vy * n.vy).sum()
}

pub fn max_velocity(nodes: &HashMap<TypedRecordId, NodePhysics>) -> f64 {
    nodes
        .values()
        .map(|n| (n.vx * n.vx + n.vy * n.vy).sqrt())
        .fold(0.0f64, f64::max)
}

pub fn decay_alpha(alpha: f64, decay: f64) -> f64 {
    alpha * (1.0 - decay)
}
