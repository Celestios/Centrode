use crate::domain::relation_engine::geometry::{Point, Rect};
use crate::domain::relation_engine::config::RelationEngineConfig;
use crate::domain::relation_engine::state::CanvasState;
use crate::domain::relation_engine::computed::PathType;
use super::RoutingStrategy;

pub struct SineWaveRouting;

impl RoutingStrategy for SineWaveRouting {
    fn route(
        &self,
        start: Point,
        end: Point,
        _from_normal: Point,
        _to_normal: Point,
        _obstacles: &[Rect],
        config: &RelationEngineConfig,
        _state: &CanvasState,
    ) -> (Vec<Point>, PathType) {
        let amplitude = config.snake.amplitude;
        let frequency = config.snake.frequency;

        let n = 64;
        let mut points = Vec::with_capacity(n + 1);

        for i in 0..=n {
            let t = i as f64 / n as f64;

            let base = start.lerp(end, t);

            let dir = end - start;
            let perp = Point::new(-dir.y, dir.x).normalized();

            let wave = (t * frequency * std::f64::consts::TAU).sin() * amplitude;

            points.push(base + perp * wave);
        }

        (points, PathType::SineWave)
    }
}
