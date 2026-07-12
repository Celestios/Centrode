use crate::domain::relation_engine::geometry::{Point, cubic_bezier_point, sample_cubic_bezier};
use crate::domain::relation_engine::config::RelationEngineConfig;
use crate::domain::relation_engine::computed::PathType;
use crate::domain::relation_engine::input::{ResolvedPorts, Side};
use super::{RoutingStrategy, TransitionInput};

pub struct SineWaveRouting {}

fn cubic_bezier_tangent(p0: Point, p1: Point, p2: Point, p3: Point, t: f64) -> Point {
    let mt = 1.0 - t;
    let term1 = p1 - p0;
    let term2 = p2 - p1;
    let term3 = p3 - p2;
    term1 * (3.0 * mt * mt) + term2 * (6.0 * mt * t) + term3 * (3.0 * t * t)
}

impl RoutingStrategy for SineWaveRouting {
    fn compute_transition(
        &self,
        input: &TransitionInput,
        config: &RelationEngineConfig,
    ) -> Vec<Point> {
        let factor = config.routing.bezier_projection_factor;
        match input.side {
            Side::Start => {
                let stub_exit = input.stub_exit;
                let stub_normal = input.start_normal;
                let body_start = input.body_start;
                let dist = stub_exit.distance_to(body_start);
                if dist < 1.0 { return vec![]; }
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
                let proj = (dist * factor).max(config.routing.bezier_clamp_min);
                let dir_from_body = (stub_entry - body_end).normalized();
                let cp1 = body_end + dir_from_body * proj;
                let cp2 = stub_entry + stub_normal * proj;
                sample_cubic_bezier(body_end, cp1, cp2, stub_entry, 8)
            }
        }
    }

    fn compute_body(
        &self, waypoints: &[Point], ports: &ResolvedPorts, config: &RelationEngineConfig,
    ) -> Vec<Point> {
        if waypoints.len() < 2 {
            return waypoints.to_vec();
        }
        let start = waypoints[0];
        let end = waypoints[waypoints.len() - 1];
        let amplitude = config.routing.sine_wave.amplitude;
        let frequency = config.routing.sine_wave.frequency;
        let distance = start.distance_to(end);
        let cycles = distance * (frequency / 300.0);
        let proj = (distance * config.routing.bezier_projection_factor)
            .min(config.routing.bezier_clamp_max)
            .max(config.routing.bezier_clamp_min.min(distance * 0.5));
        let edge = end - start;
        let normal = if edge.length() > 1e-6 {
            let edge_perp = edge.perpendicular().normalized();
            let dot_start = edge_perp.dot(ports.start_normal);
            let dot_end = edge_perp.dot(ports.end_normal);
            if dot_start.abs() > 1e-5 {
                if dot_start < 0.0 { edge_perp * -1.0 } else { edge_perp }
            } else if dot_end.abs() > 1e-5 {
                if dot_end < 0.0 { edge_perp * -1.0 } else { edge_perp }
            } else {
                if edge_perp.y > 0.0 { edge_perp * -1.0 } else { edge_perp }
            }
        } else {
            ports.start_normal
        };
        let cp1 = start + normal * proj;
        let cp2 = end + normal * proj;
        let n = ((distance * 0.2) as usize).max(64).min(1024);
        let mut points = Vec::with_capacity(n + 1);
        for i in 0..=n {
            let t = i as f64 / n as f64;
            let base = cubic_bezier_point(start, cp1, cp2, end, t);
            let tangent = cubic_bezier_tangent(start, cp1, cp2, end, t);
            let dir = if tangent.x.abs() < 1e-6 && tangent.y.abs() < 1e-6 {
                end - start
            } else {
                tangent
            };
            let perp = Point::new(-dir.y, dir.x).normalized();
            let envelope = (t * std::f64::consts::PI).sin();
            let wave = (t * cycles * std::f64::consts::TAU).sin() * amplitude * envelope;
            points.push(base + perp * wave);
        }
        points
    }

    fn path_type(&self) -> PathType { PathType::SineWave }
}
