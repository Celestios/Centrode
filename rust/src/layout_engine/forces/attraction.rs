use crate::layout_engine::types::NodePhysics;

pub fn link_spring_force(a: &NodePhysics, b: &NodePhysics, ks: f64, ideal: f64) -> (f64, f64) {
    let dx = b.cx() - a.cx();
    let dy = b.cy() - a.cy();
    let dist = (dx * dx + dy * dy).sqrt().max(1.0);
    let displacement = dist - ideal;
    let force = ks * displacement;
    (force * dx / dist, force * dy / dist)
}
