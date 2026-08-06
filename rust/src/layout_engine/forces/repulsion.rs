use crate::layout_engine::types::NodePhysics;

pub fn repulsion_force(a: &NodePhysics, b: &NodePhysics, kr: f64) -> (f64, f64) {
    let dx = a.cx() - b.cx();
    let dy = a.cy() - b.cy();
    let dist_sq = (dx * dx + dy * dy).max(1.0);
    let dist = dist_sq.sqrt();
    let force = kr / dist_sq;
    (force * dx / dist, force * dy / dist)
}
