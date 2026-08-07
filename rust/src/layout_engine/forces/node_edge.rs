use crate::layout_engine::types::NodePhysics;

pub fn node_edge_repulsion_force(
    node: &NodePhysics,
    from: &NodePhysics,
    to: &NodePhysics,
    k_edge: f64,
) -> (f64, f64) {
    if node.id == from.id || node.id == to.id {
        return (0.0, 0.0);
    }

    let vx = to.cx() - from.cx();
    let vy = to.cy() - from.cy();
    let len_sq = vx * vx + vy * vy;
    if len_sq < 1.0 {
        return (0.0, 0.0);
    }

    let t = ((node.cx() - from.cx()) * vx + (node.cy() - from.cy()) * vy) / len_sq;
    if t < 0.0 || t > 1.0 {
        return (0.0, 0.0);
    }

    let proj_x = from.cx() + t * vx;
    let proj_y = from.cy() + t * vy;

    let dx = node.cx() - proj_x;
    let dy = node.cy() - proj_y;
    let dist_sq = dx * dx + dy * dy;
    let dist = dist_sq.sqrt();

    let radius = 120.0;
    if dist > 0.001 && dist < radius {
        let factor = (radius - dist) / radius;
        let force = (k_edge / dist_sq.max(10.0)) * factor;
        (force * dx / dist, force * dy / dist)
    } else {
        (0.0, 0.0)
    }
}
