use crate::domain::relation_engine::geometry::{Point, Rect};
use crate::domain::relation_engine::config::RelationEngineConfig;
use crate::domain::relation_engine::state::CanvasState;
use crate::domain::relation_engine::computed::PathType;
use crate::domain::relation_engine::visibility_graph::{a_star_with_params, RouteCostParams, VisibilityGraph};
use super::RoutingStrategy;

pub struct OrthogonalRouting;

impl RoutingStrategy for OrthogonalRouting {
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
        let waypoints = if obstacles.is_empty() {
            vec![start, end]
        } else {
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
            a_star_with_params(&graph, &cost_params, Some(&start), Some(&end), state)
                .unwrap_or_else(|| vec![start, end])
        };

        let ortho_points = snap_to_orthogonal(&waypoints);

        let points = if config.routing.corner_radius > 1e-6 {
            crate::domain::relation_engine::geometry::round_corners(&ortho_points, config.routing.corner_radius)
        } else {
            ortho_points
        };

        (points, PathType::Orthogonal)
    }
}

fn snap_to_orthogonal(waypoints: &[Point]) -> Vec<Point> {
    if waypoints.len() < 2 {
        return waypoints.to_vec();
    }

    let mut result = vec![waypoints[0]];

    for i in 0..waypoints.len() - 1 {
        let p1 = result.last().copied().unwrap();
        let p2 = waypoints[i + 1];

        if (p1.x - p2.x).abs() < 0.1 || (p1.y - p2.y).abs() < 0.1 {
            result.push(p2);
        } else {
            let corner = Point::new(p2.x, p1.y);
            result.push(corner);
            result.push(p2);
        }
    }

    result.dedup_by(|a, b| a.distance_to(*b) < 0.1);
    result
}

fn rects_overlap(a: &Rect, b: &Rect) -> bool {
    a.left() <= b.right() && a.right() >= b.left() && a.top() <= b.bottom() && a.bottom() >= b.top()
}
