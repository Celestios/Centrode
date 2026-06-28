use crate::domain::relation_engine::geometry::{Point, cubic_bezier_point};
use crate::domain::relation_engine::state::CanvasState;
use crate::domain::relation_engine::computed::PathType;
use super::{RoutingStrategy, RouteContext};

pub struct SineWaveRouting;

fn cubic_bezier_tangent(p0: Point, p1: Point, p2: Point, p3: Point, t: f64) -> Point {
    let mt = 1.0 - t;
    let term1 = p1 - p0;
    let term2 = p2 - p1;
    let term3 = p3 - p2;
    term1 * (3.0 * mt * mt) + term2 * (6.0 * mt * t) + term3 * (3.0 * t * t)
}

impl RoutingStrategy for SineWaveRouting {
    fn route(&self, ctx: &RouteContext, _state: &CanvasState) -> (Vec<Point>, PathType) {
        let amplitude = ctx.config.routing.sine_wave.amplitude;
        let frequency = ctx.config.routing.sine_wave.frequency;

        let distance = ctx.start.distance_to(ctx.end);
        let cycles = distance * (frequency / 300.0);

        let dist_from = (ctx.end - ctx.start).dot(ctx.from_normal);
        let dist_to = (ctx.start - ctx.end).dot(ctx.to_normal);
        let use_bezier = dist_from < 0.0 || dist_to < 0.0;

        let (cp1, cp2) = if use_bezier {
            let proj = (distance * ctx.config.routing.bezier_projection_factor)
                .min(ctx.config.routing.bezier_clamp_max)
                .max(ctx.config.routing.bezier_clamp_min.min(distance * 0.5));
            (ctx.start + ctx.from_normal * proj, ctx.end + ctx.to_normal * proj)
        } else {
            (Point::zero(), Point::zero())
        };

        let n = ((distance * 0.2) as usize).max(64).min(1024);
        let mut points = Vec::with_capacity(n + 1);

        for i in 0..=n {
            let t = i as f64 / n as f64;

            let (base, tangent) = if use_bezier {
                let base = cubic_bezier_point(ctx.start, cp1, cp2, ctx.end, t);
                let tangent = cubic_bezier_tangent(ctx.start, cp1, cp2, ctx.end, t);
                (base, tangent)
            } else {
                let base = ctx.start.lerp(ctx.end, t);
                let tangent = ctx.end - ctx.start;
                (base, tangent)
            };

            let dir = if tangent.x.abs() < 1e-6 && tangent.y.abs() < 1e-6 {
                ctx.end - ctx.start
            } else {
                tangent
            };
            let perp = Point::new(-dir.y, dir.x).normalized();

            let envelope = (t * std::f64::consts::PI).sin();
            let wave = (t * cycles * std::f64::consts::TAU).sin() * amplitude * envelope;

            points.push(base + perp * wave);
        }

        (points, PathType::SineWave)
    }
}
