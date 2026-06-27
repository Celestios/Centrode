use crate::domain::relation_engine::geometry::{Point, Rect};
use crate::domain::relation_engine::config::RelationEngineConfig;
use crate::domain::relation_engine::state::CanvasState;
use crate::domain::relation_engine::computed::PathType;
use super::RoutingStrategy;

pub struct CircularArcRouting;

impl RoutingStrategy for CircularArcRouting {
    fn route(
        &self,
        start: Point,
        end: Point,
        from_normal: Point,
        to_normal: Point,
        from_rect: Rect,
        to_rect: Rect,
        obstacles: &[Rect],
        config: &RelationEngineConfig,
        state: &CanvasState,
    ) -> (Vec<Point>, PathType) {
        let distance = start.distance_to(end);
        let radius_factor = config.routing.bezier_projection_factor;
        let radius = (distance * radius_factor).clamp(
            config.routing.bezier_clamp_min,
            config.routing.bezier_clamp_max,
        );

        let cp1 = start + from_normal * radius;
        let center = three_point_circle_center(start, cp1, end);

        if let Some(c) = center {
            let r = c.distance_to(start);
            if r < 1e-6 {
                return (vec![start, end], PathType::Straight);
            }

            let start_angle = (start - c).direction();
            let end_angle = (end - c).direction();

            let n = 32;
            let mut points = Vec::with_capacity(n + 1);

            let mid = start.lerp(end, 0.5);
            let to_mid = mid - c;
            let cross = (start - c).x * to_mid.y - (start - c).y * to_mid.x;

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

                points.push(Point::new(
                    c.x + r * angle.cos(),
                    c.y + r * angle.sin(),
                ));
            }

            (points, PathType::CircularArc)
        } else {
            super::bezier::BezierRouting.route(start, end, from_normal, to_normal, from_rect, to_rect, obstacles, config, state)
        }
    }
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
