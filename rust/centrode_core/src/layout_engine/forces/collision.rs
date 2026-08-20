use crate::layout_engine::config::ForceConfig;
use crate::layout_engine::types::NodePhysics;

pub fn collision_force(a: &NodePhysics, b: &NodePhysics, config: &ForceConfig) -> (f64, f64) {
    let margin_a = config.base_margin + a.width.max(a.height) * config.margin_scale;
    let margin_b = config.base_margin + b.width.max(b.height) * config.margin_scale;

    let half_w_a = a.width / 2.0 + margin_a;
    let half_h_a = a.height / 2.0 + margin_a;
    let half_w_b = b.width / 2.0 + margin_b;
    let half_h_b = b.height / 2.0 + margin_b;

    let dx = a.cx() - b.cx();
    let dy = a.cy() - b.cy();

    let overlap_x = half_w_a + half_w_b - dx.abs();
    let overlap_y = half_h_a + half_h_b - dy.abs();

    if overlap_x > 0.0 && overlap_y > 0.0 {
        let kc = config.collision_strength;
        if overlap_x < overlap_y {
            (kc * overlap_x * dx.signum(), 0.0)
        } else {
            (0.0, kc * overlap_y * dy.signum())
        }
    } else {
        (0.0, 0.0)
    }
}
