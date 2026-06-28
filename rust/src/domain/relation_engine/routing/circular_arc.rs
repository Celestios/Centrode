use crate::domain::relation_engine::geometry::{Point, Rect};
use crate::domain::relation_engine::state::CanvasState;
use crate::domain::relation_engine::computed::PathType;
use super::{RoutingStrategy, RouteContext};

pub struct CircularArcRouting;

impl RoutingStrategy for CircularArcRouting {
    fn route(&self, ctx: &RouteContext, state: &CanvasState) -> (Vec<Point>, PathType) {
        let distance = ctx.start.distance_to(ctx.end);
        let radius_factor = ctx.config.routing.bezier_projection_factor;
        let radius = (distance * radius_factor).clamp(
            ctx.config.routing.bezier_clamp_min,
            ctx.config.routing.bezier_clamp_max,
        );

        let cp1 = ctx.start + ctx.from_normal * radius;
        let center = three_point_circle_center(ctx.start, cp1, ctx.end);

        if let Some(c) = center {
            let r = c.distance_to(ctx.start);
            if r < 1e-6 {
                return (vec![ctx.start, ctx.end], PathType::Straight);
            }

            let start_angle = (ctx.start - c).direction();
            let end_angle = (ctx.end - c).direction();

            let n = 32;
            let mut points = Vec::with_capacity(n + 1);

            let mid = ctx.start.lerp(ctx.end, 0.5);
            let to_mid = mid - c;
            let cross = (ctx.start - c).x * to_mid.y - (ctx.start - c).y * to_mid.x;

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
            super::bezier::BezierRouting.route(ctx, state)
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
