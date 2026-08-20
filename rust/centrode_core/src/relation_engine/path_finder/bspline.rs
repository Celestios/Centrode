use crate::relation_engine::geometry::Point;
use crate::relation_engine::path_finder::steer::{compute_direction_penalty, AStarContext, Steer};

pub struct BSplineSteer {}

impl BSplineSteer {
    pub fn new() -> Self {
        Self {}
    }
}

impl Steer for BSplineSteer {
    fn neighbors(&self) -> Vec<(i32, i32, f64)> {
        let diag = 2.0f64.sqrt();
        vec![
            (0, -1, 1.0),
            (1, 0, 1.0),
            (0, 1, 1.0),
            (-1, 0, 1.0),
            (1, -1, diag),
            (1, 1, diag),
            (-1, 1, diag),
            (-1, -1, diag),
        ]
    }

    fn heuristic(&self, from: Point, to: Point) -> f64 {
        from.distance_to(to)
    }

    fn transition_cost(
        &self,
        from_key: (i32, i32),
        to_key: (i32, i32),
        dir: (i32, i32),
        _prev_key: Option<(i32, i32)>,
        step_cost: f64,
        context: &AStarContext,
    ) -> f64 {
        let cp = context.grid.grid_to_world(to_key.0, to_key.1);
        let line_dx = context.end_pt.x - context.start_pt.x;
        let line_dy = context.end_pt.y - context.start_pt.y;
        let line_len = (line_dx * line_dx + line_dy * line_dy).sqrt().max(1e-12);

        // Constants matching default BSplineConfig
        let line_weight = 1.0;

        let penalty =
            (line_dx * (context.start_pt.y - cp.y) - line_dy * (context.start_pt.x - cp.x)).abs()
                / line_len
                * line_weight;

        let obstacle_cost = context.cost_grid.get(to_key.0, to_key.1);

        let dir_penalty = compute_direction_penalty(from_key, to_key, dir, context);

        step_cost * context.grid.cell_size + penalty + obstacle_cost + dir_penalty
    }
}
