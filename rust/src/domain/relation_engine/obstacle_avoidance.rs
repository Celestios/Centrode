use super::geometry::{Point, Rect};
use super::solver::visibility_graph::{a_star_with_params, RouteCostParams, VisibilityGraph};
use super::state::CanvasState;

pub fn filter_obstacles_in_bounds(
    obstacles: &[Rect],
    start: Point,
    end: Point,
    margin: f64,
) -> Vec<Rect> {
    let min_x = start.x.min(end.x) - margin * 2.0;
    let max_x = start.x.max(end.x) + margin * 2.0;
    let min_y = start.y.min(end.y) - margin * 2.0;
    let max_y = start.y.max(end.y) + margin * 2.0;
    let route_bounds = Rect::new(min_x, min_y, max_x - min_x, max_y - min_y);
    obstacles.iter().filter(|obs| obs.overlaps(&route_bounds)).copied().collect()
}

pub fn compute_waypoints(
    from: Point,
    to: Point,
    obstacles: &[Rect],
    margin: f64,
) -> Vec<Point> {
    if obstacles.is_empty() {
        return vec![from, to];
    }
    let filtered = filter_obstacles_in_bounds(obstacles, from, to, margin);
    let has_blocking = filtered.iter().any(|obs| obs.intersects_segment(from, to));
    if !has_blocking {
        return vec![from, to];
    }
    let graph = VisibilityGraph::build(&filtered, from, to, margin);
    let cost_params = RouteCostParams::default();
    a_star_with_params(&graph, &cost_params, Some(&from), Some(&to), &CanvasState::new())
        .unwrap_or_else(|| vec![from, to])
}
