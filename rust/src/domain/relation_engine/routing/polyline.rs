use crate::domain::relation_engine::geometry::{Point, Rect};
use crate::domain::relation_engine::config::RelationEngineConfig;
use crate::domain::relation_engine::state::CanvasState;
use crate::domain::relation_engine::computed::PathType;
use crate::domain::relation_engine::visibility_graph::{a_star_with_params, RouteCostParams, VisibilityGraph};
use super::RoutingStrategy;

pub struct PolylineRouting;

impl RoutingStrategy for PolylineRouting {
    fn route(
        &self,
        start: Point,
        end: Point,
        _from_normal: Point,
        _to_normal: Point,
        obstacles: &[Rect],
        config: &RelationEngineConfig,
        state: &CanvasState,
    ) -> (Vec<Point>, PathType) {
        if obstacles.is_empty() {
            return (vec![start, end], PathType::Straight);
        }

        let margin = config.routing.obstacle_margin;
        let min_x = start.x.min(end.x) - margin * 2.0;
        let max_x = start.x.max(end.x) + margin * 2.0;
        let min_y = start.y.min(end.y) - margin * 2.0;
        let max_y = start.y.max(end.y) + margin * 2.0;
        let route_bounds = Rect::new(min_x, min_y, max_x - min_x, max_y - min_y);

        let filtered: Vec<Rect> = obstacles
            .iter()
            .filter(|&obs| rects_overlap(obs, &route_bounds))
            .copied()
            .collect();

        let graph = VisibilityGraph::build(&filtered, start, end, margin);
        let cost_params = RouteCostParams::default();
        let points = a_star_with_params(&graph, &cost_params, Some(&start), Some(&end), state)
            .unwrap_or_else(|| vec![start, end]);

        (points, PathType::Straight)
    }
}

fn rects_overlap(a: &Rect, b: &Rect) -> bool {
    a.left() <= b.right() && a.right() >= b.left() && a.top() <= b.bottom() && a.bottom() >= b.top()
}
