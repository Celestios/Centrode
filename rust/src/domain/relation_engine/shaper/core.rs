use crate::domain::relation_engine::geometry::Point;
use crate::domain::relation_engine::computed::ComputedRelation;

pub struct ShaperContext {
    pub start_pt: Point,
    pub end_pt: Point,
    pub start_dir: Option<(i32, i32)>,
    pub end_dir: Option<(i32, i32)>,
    pub start_stub_len: f64,
    pub end_stub_len: f64,
    pub cell_size: f64,
}

pub trait Shaper {
    fn shape(&self, raw_path: &[Point], context: &ShaperContext) -> ComputedRelation;

    fn reshape(&self, prepped_path: &[Point], context: &ShaperContext) -> ComputedRelation {
        self.shape(prepped_path, context)
    }
}

/// Remove collinear intermediate grid points from an A* path.
pub fn thin_path(path: &[Point], cell_size: f64) -> Vec<Point> {
    if path.len() <= 2 {
        return path.to_vec();
    }
    let n = path.len();
    if n <= 3 {
        return path.to_vec();
    }

    let grid_dir = |a: Point, b: Point| -> (i32, i32) {
        let dx = b.x - a.x;
        let dy = b.y - a.y;
        (
            (dx / cell_size).round() as i32,
            (dy / cell_size).round() as i32,
        )
    };

    let mut result = vec![path[0]];

    let mut prev_dir = grid_dir(path[1], path[2]);

    for i in 2..n - 1 {
        let dir = grid_dir(path[i], path[i + 1]);
        if dir != prev_dir {
            result.push(path[i]);
            prev_dir = dir;
        }
    }

    result.push(*path.last().unwrap());
    result
}
