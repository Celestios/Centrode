use crate::domain::relation_engine::geometry::Point;
use crate::domain::relation_engine::path_finder::steer::{Steer, AStarContext};
use crate::domain::relation_engine::path_finder::port::compute_obstacle_cost;
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
        let cp = context.grid.grid_to_world(to_key.0, to_key.1);
        let mut cost = step_cost * context.grid.cell_size;

        // Constants matching default OrthogonalConfig
        let inner_bbox_scale = 1.0 / 3.0;
        let obstacle_weight = 200.0;
        let turn_penalty = 50.0;

        cost += compute_obstacle_cost(
            cp,
            context.nodes,
            context.outer_bbox_distance,
            inner_bbox_scale,
            obstacle_weight,
        );

        if let Some(prev) = prev_key {
            let prev_dir = (from_key.0 - prev.0, from_key.1 - prev.1);
            if prev_dir != dir {
                cost += context.grid.cell_size * turn_penalty;
            }
        }

        cost
    }
}
