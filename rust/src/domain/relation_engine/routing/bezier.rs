use crate::domain::relation_engine::geometry::{Point, round_corners, sample_quadratic_bezier};
use crate::domain::relation_engine::config::RelationEngineConfig;
use crate::domain::relation_engine::computed::PathType;
use crate::domain::relation_engine::input::ResolvedPorts;
use super::{RoutingStrategy, prune_collinear_waypoints};

pub struct BezierRouting {}

impl RoutingStrategy for BezierRouting {
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

        match n {
            2 => {
                let p0 = pruned[0];
                let p3 = pruned[1];
                let dist = p0.distance_to(p3);
                if dist < 1.0 { return pruned; }

                let sn = ports.start_normal;
                let mid = (p0 + p3) * 0.5;

                // Chord and perpendicular
                let chord = p3 - p0;
                let perp = Point::new(-chord.y, chord.x).normalized();

                // Align perp1 with sn's half-plane, perp2 goes the opposite way
                let sign = if sn.dot(perp) >= 0.0 { 1.0 } else { -1.0 };
                let perp1 = perp * sign;
                let perp2 = Point::new(-perp1.x, -perp1.y);

                // Midpoints of two halves
                let mid_first = (p0 + mid) * 0.5;
                let mid_second = (mid + p3) * 0.5;

                let factor = config.routing.projection_factor;
                let offset = (dist * 0.5 * factor)
                    .clamp(config.routing.clamp_min * 0.5, config.routing.clamp_max * 0.5);

                let cp1 = mid_first + perp1 * offset;
                let cp2 = mid_second + perp2 * offset;

                let num_samples = ((dist / 8.0).round() as usize).clamp(8, 24);
                let num_samples_half = num_samples / 2;

                let mut first_half = sample_quadratic_bezier(p0, cp1, mid, num_samples_half);
                let second_half = sample_quadratic_bezier(mid, cp2, p3, num_samples_half);

                first_half.extend(second_half.into_iter().skip(1));
                first_half
            }
            _ => {
                let p0 = pruned[0];
                let pn = pruned[n - 1];
                let w1 = pruned[1];
                let wn = pruned[n - 2];

                let sn = ports.start_normal;
                let en = ports.end_normal;
                let factor = config.routing.projection_factor;

                // 1. First section: quadratic Bezier between p0 and w1
                let dist_start = p0.distance_to(w1);
                let mid_start = (p0 + w1) * 0.5;
                let chord_start = w1 - p0;
                let mut perp_start = Point::new(-chord_start.y, chord_start.x).normalized();
                if sn.dot(perp_start) < 0.0 {
                    perp_start = Point::new(-perp_start.x, -perp_start.y);
                }
                let offset_start = (dist_start * factor)
                    .clamp(config.routing.clamp_min, config.routing.clamp_max);
                let cp_start = mid_start + perp_start * offset_start;
                let num_samples_start = ((dist_start / 8.0).round() as usize).clamp(8, 24);
                let first_part = sample_quadratic_bezier(p0, cp_start, w1, num_samples_start);

                // 2. Last section: quadratic Bezier between wn and pn
                let dist_end = wn.distance_to(pn);
                let mid_end = (wn + pn) * 0.5;
                let chord_end = pn - wn;
                let mut perp_end = Point::new(-chord_end.y, chord_end.x).normalized();
                if en.dot(perp_end) < 0.0 {
                    perp_end = Point::new(-perp_end.x, -perp_end.y);
                }
                let offset_end = (dist_end * factor)
                    .clamp(config.routing.clamp_min, config.routing.clamp_max);
                let cp_end = mid_end + perp_end * offset_end;
                let num_samples_end = ((dist_end / 8.0).round() as usize).clamp(8, 24);
                let last_part = sample_quadratic_bezier(wn, cp_end, pn, num_samples_end);

                // 3. Middle sections: round corners of pruned[1..n-1]
                let radius = config.routing.corner_radius.max(20.0);
                let middle_part = round_corners(&pruned[1..n-1], radius);

                // Combine parts
                let mut result = Vec::new();
                result.extend(first_part);
                if middle_part.len() > 1 {
                    result.extend(middle_part.into_iter().skip(1));
                }
                result.extend(last_part.into_iter().skip(1));
                result.dedup_by(|a, b| a.distance_to(*b) < 1e-6);
                result
            }
        }
    }

    fn path_type(&self) -> PathType { PathType::CubicBezier }
}
