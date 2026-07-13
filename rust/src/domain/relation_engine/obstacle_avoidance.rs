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
    use crate::domain::relation_engine::routing::polyline::PolylineRouting;
    compute_waypoints_with_strategy(from, to, obstacles, margin, &PolylineRouting {})
}

pub fn compute_waypoints_with_strategy<S: crate::domain::relation_engine::routing::RoutingStrategy + ?Sized>(
    from: Point,
    to: Point,
    obstacles: &[Rect],
    margin: f64,
    strategy: &S,
) -> Vec<Point> {
    if obstacles.is_empty() {
        return vec![from, to];
    }
    let filtered = filter_obstacles_in_bounds(obstacles, from, to, margin);
    let has_blocking = filtered.iter().any(|obs| obs.intersects_segment(from, to));
    if !has_blocking {
        return vec![from, to];
    }

    // Dynamic margin scaling based on closest gap between filtered obstacles
    let mut min_gap = f64::INFINITY;
    for i in 0..filtered.len() {
        for j in (i + 1)..filtered.len() {
            let r1 = &filtered[i];
            let r2 = &filtered[j];
            let dx = 0.0f64.max((r1.left() - r2.right()).max(r2.left() - r1.right()));
            let dy = 0.0f64.max((r1.top() - r2.bottom()).max(r2.top() - r1.bottom()));
            let gap = (dx * dx + dy * dy).sqrt();
            if gap < min_gap {
                min_gap = gap;
            }
        }
    }

    let mut adaptive_margin = margin;
    if min_gap.is_finite() && min_gap > 0.0 {
        adaptive_margin = (min_gap * 0.35).clamp(8.0, margin);
    }

    let graph = VisibilityGraph::build(&filtered, from, to, adaptive_margin);
    let cost_params = RouteCostParams::default();
    super::solver::visibility_graph::a_star_with_strategy(&graph, strategy, &cost_params, Some(&to), &CanvasState::new())
        .unwrap_or_else(|| vec![from, to])
}
