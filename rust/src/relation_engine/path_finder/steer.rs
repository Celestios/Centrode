use crate::domain::id::TypedRecordId;
use crate::relation_engine::geometry::Point;
use crate::relation_engine::path_finder::{grid::Grid, port::compute_obstacle_cost};
use crate::relation_engine::types::InputNode;

#[derive(Clone, Debug)]
pub struct CostGrid {
    pub costs: Vec<f64>,
    pub width: usize,
    pub height: usize,
}

impl CostGrid {
    pub fn new(grid: &Grid, nodes: &[InputNode], outer_bbox_distance: f64) -> Self {
        let width = grid.width;
        let height = grid.height;
        let mut costs = vec![0.0; width * height];
        let inner_bbox_scale = 1.0 / 3.0;
        let obstacle_weight = 200.0;

        for col in 0..width {
            for row in 0..height {
                let cp = grid.grid_to_world(col as i32, row as i32);
                let cost = compute_obstacle_cost(
                    cp,
                    nodes,
                    outer_bbox_distance,
                    inner_bbox_scale,
                    obstacle_weight,
                );
                costs[col * height + row] = cost;
            }
        }
        Self {
            costs,
            width,
            height,
        }
    }

    pub fn get(&self, col: i32, row: i32) -> f64 {
        if col < 0 || col >= self.width as i32 || row < 0 || row >= self.height as i32 {
            return 0.0;
        }
        self.costs[(col as usize) * self.height + (row as usize)]
    }
}

pub struct AStarContext<'a> {
    pub grid: &'a Grid,
    pub nodes: &'a [InputNode],
    pub start_node_id: &'a TypedRecordId,
    pub end_node_id: &'a TypedRecordId,
    pub start_pt: Point,
    pub start_terminus: Point,
    pub start_dir: Option<(i32, i32)>,
    pub use_start_penalty: bool,
    pub start_stub_len: f64,
    pub end_pt: Point,
    pub end_terminus: Point,
    pub end_dir: Option<(i32, i32)>,
    pub use_end_penalty: bool,
    pub end_stub_len: f64,
    pub outer_bbox_distance: f64,
    pub port_penalty: f64,
    pub cost_grid: &'a CostGrid,
}

pub trait Steer {
    fn neighbors(&self) -> Vec<(i32, i32, f64)>;
    fn heuristic(&self, from: Point, to: Point) -> f64;
    fn transition_cost(
        &self,
        from_key: (i32, i32),
        to_key: (i32, i32),
        dir: (i32, i32),
        prev_key: Option<(i32, i32)>,
        step_cost: f64,
        context: &AStarContext,
    ) -> f64;
}

pub(crate) fn compute_direction_penalty(
    from_key: (i32, i32),
    to_key: (i32, i32),
    dir: (i32, i32),
    context: &AStarContext,
) -> f64 {
    let (ns, has_start) = match context.start_dir {
        Some((dx, dy)) if context.use_start_penalty => {
            (Point::new(dx as f64, dy as f64).normalize(), 1.0)
        }
        _ => (Point::new(0.0, 0.0), 0.0),
    };

    let (ne, has_end) = match context.end_dir {
        Some((dx, dy)) if context.use_end_penalty => {
            (Point::new(dx as f64, dy as f64).normalize(), 1.0)
        }
        _ => (Point::new(0.0, 0.0), 0.0),
    };

    let step_dir = Point::new(dir.0 as f64, dir.1 as f64).normalize();

    let (sgc, sgr) = context.grid.world_to_grid(context.start_terminus);
    let start_key = (sgc, sgr);
    let (egc, egr) = context.grid.world_to_grid(context.end_terminus);
    let end_key = (egc, egr);

    let is_start = (from_key == start_key) as i32 as f64;
    let dot_s = step_dir.x * ns.x + step_dir.y * ns.y;
    let penalty_start = context.port_penalty * has_start * is_start * (1.0 - dot_s).max(0.0);

    let is_end = (to_key == end_key) as i32 as f64;
    let dot_e = step_dir.x * (-ne.x) + step_dir.y * (-ne.y);
    let penalty_end = context.port_penalty * has_end * is_end * (1.0 - dot_e).max(0.0);

    penalty_start + penalty_end
}
