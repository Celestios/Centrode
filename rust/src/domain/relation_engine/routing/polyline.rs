use crate::domain::relation_engine::geometry::Point;
use crate::domain::relation_engine::state::CanvasState;
use crate::domain::relation_engine::computed::PathType;
use crate::domain::relation_engine::solver::visibility_graph::{a_star_with_params, RouteCostParams, VisibilityGraph};
use super::{RoutingStrategy, RouteContext, filter_obstacles_in_bounds};

pub struct PolylineRouting;

impl RoutingStrategy for PolylineRouting {
    fn route(&self, ctx: &RouteContext, state: &CanvasState) -> (Vec<Point>, PathType) {
        if ctx.obstacles.is_empty() {
            return (vec![ctx.start, ctx.end], PathType::Straight);
        }

        let margin = ctx.config.routing.obstacle_margin;
        let filtered = filter_obstacles_in_bounds(&ctx.obstacles, ctx.start, ctx.end, margin);

        let has_blocking_obstacle = filtered.iter().any(|obs| obs.intersects_segment(ctx.start, ctx.end));
        if !has_blocking_obstacle {
            return (vec![ctx.start, ctx.end], PathType::Straight);
        }

        let graph = VisibilityGraph::build(&filtered, ctx.start, ctx.end, margin);
        let cost_params = RouteCostParams::default();
        let points = a_star_with_params(&graph, &cost_params, Some(&ctx.start), Some(&ctx.end), state)
            .unwrap_or_else(|| vec![ctx.start, ctx.end]);

        if points.len() == 2 {
            (points, PathType::Straight)
        } else {
            (points, PathType::Orthogonal)
        }
    }
}
