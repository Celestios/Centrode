use crate::domain::relation_engine::geometry::{Point, sample_cubic_bezier};
use crate::domain::relation_engine::config::RelationEngineConfig;
use crate::domain::relation_engine::computed::PathType;
use crate::domain::relation_engine::input::{ResolvedPorts, Side};
use super::{RoutingStrategy, TransitionInput};

pub struct BezierRouting;

impl RoutingStrategy for BezierRouting {
    fn compute_transition(
        &self,
        input: &TransitionInput,
        config: &RelationEngineConfig,
    ) -> Vec<Point> {
        match input.side {
            Side::Start => {
                let stub_exit = input.stub_exit;
                let stub_normal = input.start_normal;
                let body_start = input.body_start;

                let dist = stub_exit.distance_to(body_start);
                if dist < 1.0 { return vec![]; }
                let factor = config.routing.bezier_projection_factor;
                let proj = (dist * factor).max(config.routing.bezier_clamp_min);
                let cp1 = stub_exit + stub_normal * proj;
                let dir_to_body = (body_start - stub_exit).normalized();
                let cp2 = body_start - dir_to_body * proj;
                sample_cubic_bezier(stub_exit, cp1, cp2, body_start, 8)
            }
            Side::End => {
                let body_end = input.body_end;
                let stub_entry = input.stub_entry;
                let stub_normal = input.end_normal;

                let dist = body_end.distance_to(stub_entry);
                if dist < 1.0 { return vec![]; }
                let factor = config.routing.bezier_projection_factor;
                let proj = (dist * factor).max(config.routing.bezier_clamp_min);
                let dir_from_body = (stub_entry - body_end).normalized();
                let cp1 = body_end + dir_from_body * proj;
                let cp2 = stub_entry + stub_normal * proj;
                sample_cubic_bezier(body_end, cp1, cp2, stub_entry, 8)
            }
        }
    }

    fn compute_body(
        &self, waypoints: &[Point], _ports: &ResolvedPorts, config: &RelationEngineConfig,
    ) -> Vec<Point> {
        if waypoints.len() <= 2 {
            sample_smooth_curve_through(waypoints, config)
        } else {
            waypoints.to_vec()
        }
    }

    fn path_type(&self) -> PathType { PathType::CubicBezier }
}

// ── Internal helpers ──────────────────────────────────────────────────────────

/// Samples a smooth curve through waypoints using cubic bezier segments.
fn sample_smooth_curve_through(waypoints: &[Point], config: &RelationEngineConfig) -> Vec<Point> {
    if waypoints.len() <= 1 {
        return waypoints.to_vec();
    }
    let mut result = Vec::new();
    for window in waypoints.windows(2) {
        let start = window[0];
        let end = window[1];
        let dist = start.distance_to(end);
        let proj = (dist * config.routing.bezier_projection_factor)
            .min(config.routing.bezier_clamp_max)
            .max(config.routing.bezier_clamp_min.min(dist * 0.5));
        let dir = (end - start).normalized();
        let cp1 = start + dir * proj;
        let cp2 = end - dir * proj;
        let seg = sample_cubic_bezier(start, cp1, cp2, end, 16);
        if result.is_empty() {
            result.extend(seg);
        } else {
            result.extend(seg[1..].iter().copied());
        }
    }
    result
}

/// Standard bezier curve between two endpoints with outward normals.
/// Kept as an internal helper for reference / direct use.
#[allow(dead_code)]
fn standard_bezier(
    start: Point, end: Point,
    from_normal: Point, to_normal: Point,
    config: &RelationEngineConfig,
) -> (Vec<Point>, PathType) {
    let distance = start.distance_to(end);
    let proj = (distance * config.routing.bezier_projection_factor)
        .min(config.routing.bezier_clamp_max)
        .max(config.routing.bezier_clamp_min.min(distance * 0.5));

    let cp1 = start + from_normal * proj;
    let cp2 = end + to_normal * proj;
    let points = sample_cubic_bezier(start, cp1, cp2, end, 32);
    (points, PathType::CubicBezier)
}
