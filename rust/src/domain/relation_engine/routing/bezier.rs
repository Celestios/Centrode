use crate::domain::relation_engine::geometry::{Point, Rect};
use crate::domain::relation_engine::config::RelationEngineConfig;
use crate::domain::relation_engine::state::CanvasState;
use crate::domain::relation_engine::computed::PathType;
use super::RoutingStrategy;

pub struct BezierRouting;

impl RoutingStrategy for BezierRouting {
    fn route(
        &self,
        start: Point,
        end: Point,
        from_normal: Point,
        to_normal: Point,
        _obstacles: &[Rect],
        config: &RelationEngineConfig,
        _state: &CanvasState,
    ) -> (Vec<Point>, PathType) {
        let distance = start.distance_to(end);
        let proj = (distance * config.routing.bezier_projection_factor).clamp(
            config.routing.bezier_clamp_min,
            config.routing.bezier_clamp_max,
        );

        let cp1 = start + from_normal * proj;
        let cp2 = end + to_normal * proj;

        let points = crate::domain::relation_engine::geometry::sample_cubic_bezier(start, cp1, cp2, end, 32);

        (points, PathType::CubicBezier)
    }
}
