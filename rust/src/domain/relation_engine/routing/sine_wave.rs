use crate::domain::relation_engine::geometry::{Point, Rect, cubic_bezier_point};
use crate::domain::relation_engine::config::RelationEngineConfig;
use crate::domain::relation_engine::state::CanvasState;
use crate::domain::relation_engine::computed::PathType;
use super::RoutingStrategy;

pub struct SineWaveRouting;

fn cubic_bezier_tangent(p0: Point, p1: Point, p2: Point, p3: Point, t: f64) -> Point {
    let mt = 1.0 - t;
    let term1 = p1 - p0;
    let term2 = p2 - p1;
    let term3 = p3 - p2;
    term1 * (3.0 * mt * mt) + term2 * (6.0 * mt * t) + term3 * (3.0 * t * t)
}

impl RoutingStrategy for SineWaveRouting {
    fn route(
        &self,
        start: Point,
        end: Point,
        from_normal: Point,
        to_normal: Point,
        _from_rect: Rect,
        _to_rect: Rect,
        _obstacles: &[Rect],
        config: &RelationEngineConfig,
        _state: &CanvasState,
    ) -> (Vec<Point>, PathType) {
        let amplitude = config.snake.amplitude;
        let frequency = config.snake.frequency;

        let distance = start.distance_to(end);
        let cycles = distance * (frequency / 300.0);

        let dist_from = (end - start).dot(from_normal);
        let dist_to = (start - end).dot(to_normal);
        let use_bezier = dist_from < 0.0 || dist_to < 0.0;

        let (cp1, cp2) = if use_bezier {
            let proj = (distance * config.routing.bezier_projection_factor)
                .min(config.routing.bezier_clamp_max)
                .max(config.routing.bezier_clamp_min.min(distance * 0.5));
            (start + from_normal * proj, end + to_normal * proj)
        } else {
            (Point::zero(), Point::zero())
        };

        let n = ((distance * 0.2) as usize).max(64).min(1024);
        let mut points = Vec::with_capacity(n + 1);

        for i in 0..=n {
            let t = i as f64 / n as f64;

            let (base, tangent) = if use_bezier {
                let base = cubic_bezier_point(start, cp1, cp2, end, t);
                let tangent = cubic_bezier_tangent(start, cp1, cp2, end, t);
                (base, tangent)
            } else {
                let base = start.lerp(end, t);
                let tangent = end - start;
                (base, tangent)
            };

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

        (points, PathType::SineWave)
    }
}


// all paths coming out of any kind of port should be perpendicular to node surface and since for orthogonal
// that would be a 45 degree angle at corner ports we can allow both a horizontal or a vertical departure.
// so that's it, this is not dependent on the direction of relation path.
//
// by all paths coming out of any port,
// i meant the endpart.
// , you should create a strategy
// trait for relation style. then you should define other traits for each kind of relation section. for example there are different endpointshapes,