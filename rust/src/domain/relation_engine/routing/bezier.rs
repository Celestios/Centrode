use crate::domain::relation_engine::geometry::{Point, sample_cubic_bezier, sample_quadratic_bezier};
use crate::domain::relation_engine::config::RelationEngineConfig;
use crate::domain::relation_engine::computed::PathType;
use crate::domain::relation_engine::input::ResolvedPorts;
use super::{RoutingStrategy, TransitionInput, prune_collinear_waypoints};

pub struct BezierRouting {}

impl RoutingStrategy for BezierRouting {
    fn compute_transition(
        &self,
        _input: &TransitionInput,
        _config: &RelationEngineConfig,
    ) -> Vec<Point> {
        vec![]
    }

    fn compute_obstacle_waypoints(
        &self,
        from: Point,
        to: Point,
        obstacles: &[crate::domain::relation_engine::geometry::Rect],
        config: &RelationEngineConfig,
    ) -> Vec<Point> {
        let bezier_margin = (config.routing.obstacle_margin * 0.4).clamp(12.0, 20.0);
        crate::domain::relation_engine::obstacle_avoidance::compute_waypoints(
            from,
            to,
            obstacles,
            bezier_margin,
        )
    }

    fn compute_body(
        &self, waypoints: &[Point], ports: &ResolvedPorts, config: &RelationEngineConfig,
    ) -> Vec<Point> {
        let pruned = prune_collinear_waypoints(waypoints);
        let n = pruned.len();
        if n <= 1 { return pruned; }

        let factor = config.routing.bezier_projection_factor;

        match n {
            2 => {
                let p0 = pruned[0];
                let p3 = pruned[1];
                let dist = p0.distance_to(p3);
                if dist < 1.0 { return pruned; }

                let widen = config.routing.bezier_turn_wideness;
                let max_proj = dist * 0.42 * widen;
                let proj = (dist * factor * widen)
                    .min(config.routing.bezier_clamp_max * widen)
                    .min(max_proj)
                    .max(config.routing.bezier_clamp_min.min(max_proj));

                let mut cp1 = p0 + ports.start_normal * proj;
                let mut cp2 = p3 + ports.end_normal * proj;

                let dir = (p3 - p0).normalized();
                let perp = Point::new(dir.y, -dir.x);
                // Signed dot product (not abs): positive = normal faces target, negative = faces away
                let start_align = ports.start_normal.dot(dir);
                let end_align = -(ports.end_normal.dot(dir));
                // How much the normals face away [0, 1]
                let away_factor = ((-start_align).max(0.0) + (-end_align).max(0.0)) * 0.5;
                // Arc height grows with away-factor: inward faces get moderate arc, opposite faces get wide S
                let arc_height = dist * (0.06 + away_factor * config.routing.bezier_curvature * 0.48);
                cp2 = cp2 - perp * arc_height;

                let num_samples = ((dist / 8.0).round() as usize).clamp(8, 24);
                sample_cubic_bezier(p0, cp1, cp2, p3, num_samples)
            }
            _ => {
                // Compute total path length for adaptive corner radius
                let total_path_length: f64 = pruned.windows(2)
                    .map(|w| w[0].distance_to(w[1]))
                    .sum();
                let corner_max = (total_path_length * 0.12).clamp(config.routing.corner_radius * 8.0, 200.0);

                // Apply perpendicular offset to start/end segments using arc height
                let dir = (pruned[n - 1] - pruned[0]).normalized();
                let perp = Point::new(dir.y, -dir.x);
                let start_align = ports.start_normal.dot(dir);
                let end_align = -(ports.end_normal.dot(dir));
                let away_factor = ((-start_align).max(0.0) + (-end_align).max(0.0)) * 0.5;
                let arc_height = total_path_length * (0.06 + away_factor * config.routing.bezier_curvature * 0.45);

                let mut corners: Vec<(Point, Point, Point, f64)> = Vec::with_capacity(n - 2);
                for i in 1..n - 1 {
                    let prev = pruned[i - 1];
                    let curr = pruned[i];
                    let next = pruned[i + 1];
                    let l_in = prev.distance_to(curr);
                    let l_out = curr.distance_to(next);
                    let r = (l_in * 0.5).min(l_out * 0.5).min(corner_max);
                    let dir_in = (curr - prev).normalized();
                    let dir_out = (next - curr).normalized();
                    let p_start = curr - dir_in * r;
                    let p_end = curr + dir_out * r;
                    corners.push((p_start, curr, p_end, r));
                }

                let mut path = Vec::new();

                let first_target = corners[0].0;
                let dist_first = pruned[0].distance_to(first_target);
                if dist_first > 1.0 {
                    let widen = config.routing.bezier_turn_wideness;
                    let max_proj = dist_first * 0.42 * widen;
                    let proj = (dist_first * factor * widen)
                        .min(config.routing.bezier_clamp_max * widen)
                        .min(max_proj)
                        .max(config.routing.bezier_clamp_min.min(max_proj));
                    let cp1 = pruned[0] + ports.start_normal * proj;
                    let dir_to = (first_target - pruned[0]).normalized();
                    let cp2 = first_target - dir_to * proj;
                    let samples = ((dist_first / 8.0).round() as usize).clamp(8, 24);
                    path.extend(sample_cubic_bezier(pruned[0], cp1, cp2, first_target, samples));
                } else {
                    path.push(pruned[0]);
                    path.push(first_target);
                }

                for i in 0..corners.len() {
                    let (p_start, ctrl, p_end, r) = corners[i];

                    if i > 0 {
                        path.push(p_start);
                    }

                    let samples = ((r * 2.0 / 8.0).round() as usize).clamp(4, 12);
                    let arc = sample_quadratic_bezier(p_start, ctrl, p_end, samples);
                    path.extend(arc.into_iter().skip(1));
                }

                let last_p_end = corners.last().unwrap().2;
                let dist_last = last_p_end.distance_to(pruned[n - 1]);
                if dist_last > 1.0 {
                    let widen = config.routing.bezier_turn_wideness;
                    let max_proj = dist_last * 0.42 * widen;
                    let proj = (dist_last * factor * widen)
                        .min(config.routing.bezier_clamp_max * widen)
                        .min(max_proj)
                        .max(config.routing.bezier_clamp_min.min(max_proj));
                    let dir_from = (pruned[n - 1] - last_p_end).normalized();
                    let cp1 = last_p_end + dir_from * proj;
                    let cp2 = pruned[n - 1] + ports.end_normal * proj - perp * arc_height;
                    let samples = ((dist_last / 8.0).round() as usize).clamp(8, 24);
                    let seg = sample_cubic_bezier(last_p_end, cp1, cp2, pruned[n - 1], samples);
                    path.extend(seg.into_iter().skip(1));
                } else {
                    path.push(pruned[n - 1]);
                }

                path
            }
        }
    }

    fn path_type(&self) -> PathType { PathType::CubicBezier }
}
