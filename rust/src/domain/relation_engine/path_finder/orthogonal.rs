use crate::domain::relation_engine::geometry::Point;
use crate::domain::relation_engine::path_finder::steer::{Steer, AStarContext};
use crate::domain::relation_engine::config::RoutingConfig;

pub struct OrthogonalSteer {
    _config: RoutingConfig,
}

impl OrthogonalSteer {
    pub fn new(config: RoutingConfig) -> Self {
        Self { _config: config }
    }
}

impl Steer for OrthogonalSteer {
    fn neighbors(&self) -> Vec<(i32, i32, f64)> {
        vec![
            (0, -1, 1.0),
            (1, 0, 1.0),
            (0, 1, 1.0),
            (-1, 0, 1.0),
        ]
    }

    fn heuristic(&self, from: Point, to: Point) -> f64 {
        (from.x - to.x).abs() + (from.y - to.y).abs()
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

        // Constants matching default OrthogonalConfig
        let turn_penalty = 50.0;

        cost += context.cost_grid.get(to_key.0, to_key.1);

        if let Some(prev) = prev_key {
            let prev_dir = (from_key.0 - prev.0, from_key.1 - prev.1);
            if prev_dir != dir {
                cost += context.grid.cell_size * turn_penalty;
            }
        }

        cost
    }
}
