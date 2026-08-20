use crate::layout_engine::types::NodePhysics;

pub fn density_dispersion_force(
    node: &NodePhysics,
    all_nodes: &[&NodePhysics],
    degree: usize,
    k_density: f64,
) -> (f64, f64) {
    if all_nodes.len() <= 1 {
        return (0.0, 0.0);
    }

    let sigma_sq = 150.0 * 150.0;
    let mut total_weight = 0.0;
    let mut center_x = 0.0;
    let mut center_y = 0.0;

    for other in all_nodes {
        if other.id == node.id {
            continue;
        }
        let dx = node.cx() - other.cx();
        let dy = node.cy() - other.cy();
        let dist_sq = dx * dx + dy * dy;
        let weight = (-dist_sq / (2.0 * sigma_sq)).exp();

        total_weight += weight;
        center_x += other.cx() * weight;
        center_y += other.cy() * weight;
    }

    if total_weight < 0.01 {
        return (0.0, 0.0);
    }

    center_x /= total_weight;
    center_y /= total_weight;

    let dir_x = node.cx() - center_x;
    let dir_y = node.cy() - center_y;
    let dist = (dir_x * dir_x + dir_y * dir_y).sqrt().max(1.0);

    let ejection_weight = 1.0 / (1.0 + degree as f64);
    let force = k_density * ejection_weight * total_weight;

    (force * dir_x / dist, force * dir_y / dist)
}
