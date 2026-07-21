use crate::domain::relation_engine::geometry::Point;
use crate::domain::relation_engine::path_finder::steer::{Steer, AStarContext, compute_direction_penalty};

pub struct OctilinearSteer {}

impl OctilinearSteer {
    pub fn new() -> Self {
        Self {}
    }
}

impl Steer for OctilinearSteer {
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
        let dx = (from.x - to.x).abs();
        let dy = (from.y - to.y).abs();
        let min_d = dx.min(dy);
        let max_d = dx.max(dy);
        max_d + (2.0f64.sqrt() - 1.0) * min_d
    }

    fn transition_cost(
        &self,
        from_key: (i32, i32),
        to_key: (i32, i32),
        dir: (i32, i32),
        prev_key: Option<(i32, i32)>,
        step_cost: f64,
        context: &AStarContext,
    ) -> f64 {
        let mut cost = step_cost * context.grid.cell_size;

        // Constants matching default OctilinearConfig
        let turn_penalty = 50.0;

        cost += context.cost_grid.get(to_key.0, to_key.1);

        if let Some(prev) = prev_key {
            let prev_dir = (from_key.0 - prev.0, from_key.1 - prev.1);
            if prev_dir != dir {
                cost += context.grid.cell_size * turn_penalty;
            }
        }

        let dir_penalty = compute_direction_penalty(from_key, to_key, dir, context);
        cost + dir_penalty
    }
}
