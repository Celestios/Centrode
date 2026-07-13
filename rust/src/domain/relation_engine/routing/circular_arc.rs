use crate::domain::relation_engine::geometry::Point;
use crate::domain::relation_engine::config::RelationEngineConfig;
use crate::domain::relation_engine::computed::PathType;
use crate::domain::relation_engine::input::{ResolvedPorts, Side};
use super::{RoutingStrategy, TransitionInput};

pub struct CircularArcRouting {}

impl RoutingStrategy for CircularArcRouting {
    fn compute_transition(
        &self,
        input: &TransitionInput,
        _config: &RelationEngineConfig,
    ) -> Vec<Point> {
        match input.side {
            Side::Start => {
                if input.stub_exit.distance_to(input.body_start) < 1.0 {
                    vec![]
                } else {
                    vec![input.body_start]
                }
            }
            Side::End => {
                if input.body_end.distance_to(input.stub_entry) < 1.0 {
                    vec![]
                } else {
                    vec![input.stub_entry]
                }
            }
        }
    }

    fn compute_body(
        &self, waypoints: &[Point], ports: &ResolvedPorts, config: &RelationEngineConfig,
    ) -> Vec<Point> {
        if waypoints.len() <= 2 {
            let start = waypoints[0];
            let end = waypoints[waypoints.len() - 1];
            let distance = start.distance_to(end);
            let radius_factor = config.routing.projection_factor;
            let radius = (distance * radius_factor).clamp(
                config.routing.clamp_min,
                config.routing.clamp_max,
            );
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
            let cp1 = start + normal * radius;
            let center = three_point_circle_center(start, cp1, end);
            if let Some(c) = center {
                let r = c.distance_to(start);
                if r < 1e-6 {
                    return waypoints.to_vec();
                }
                let start_angle = (start - c).direction();
                let end_angle = (end - c).direction();
                let n = 32;
                let mid = start.lerp(end, 0.5);
                let to_mid = mid - c;
                let cross = (start - c).x * to_mid.y - (start - c).y * to_mid.x;
                let mut points = Vec::with_capacity(n + 1);
                for i in 0..=n {
                    let t = i as f64 / n as f64;
                    let mut angle = start_angle + (end_angle - start_angle) * t;
                    if cross > 0.0 {
                        if end_angle < start_angle {
                            angle = start_angle + (end_angle + std::f64::consts::TAU - start_angle) * t;
                        }
                    } else {
                        if end_angle > start_angle {
                            angle = start_angle + (end_angle - std::f64::consts::TAU - start_angle) * t;
                        }
                    }
                    points.push(Point::new(c.x + r * angle.cos(), c.y + r * angle.sin()));
                }
                points
            } else {
                waypoints.to_vec()
            }
        } else {
            waypoints.to_vec()
        }
    }

    fn path_type(&self) -> PathType { PathType::CircularArc }
}

fn three_point_circle_center(p1: Point, p2: Point, p3: Point) -> Option<Point> {
    let ax = p1.x;
    let ay = p1.y;
    let bx = p2.x;
    let by = p2.y;
    let cx = p3.x;
    let cy = p3.y;

    let d = 2.0 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by));

    if d.abs() < 1e-10 {
        return None;
    }

    let ux = ((ax * ax + ay * ay) * (by - cy)
        + (bx * bx + by * by) * (cy - ay)
        + (cx * cx + cy * cy) * (ay - by))
        / d;
    let uy = ((ax * ax + ay * ay) * (cx - bx)
        + (bx * bx + by * by) * (ax - cx)
        + (cx * cx + cy * cy) * (bx - ax))
        / d;

    Some(Point::new(ux, uy))
}
