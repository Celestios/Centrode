use crate::relation_engine::geometry::Point;
use crate::relation_engine::computed::ComputedRelation;

pub struct ShaperContext {
    pub start_pt: Point,
    pub end_pt: Point,
    pub start_dir: Option<(i32, i32)>,
    pub end_dir: Option<(i32, i32)>,
    pub start_normal: Point,
    pub end_normal: Point,
    pub start_node_size: (f64, f64),
    pub end_node_size: (f64, f64),
    pub custom_control_point_1: Option<Point>,
    pub custom_control_point_2: Option<Point>,
    pub start_stub_len: f64,
    pub end_stub_len: f64,
    pub cell_size: f64,
}

pub fn resolve_control_points(
    start: Point,
    end: Point,
    start_normal: Point,
    end_normal: Point,
    start_node_size: (f64, f64),
    end_node_size: (f64, f64),
    custom_cp1: Option<Point>,
    custom_cp2: Option<Point>,
    is_bezier: bool,
) -> (Point, Point) {
    let get_scale = |size: (f64, f64), normal: Point| -> f64 {
        let nx = normal.x.abs();
        let ny = normal.y.abs();
        if (nx - ny).abs() < 1e-5 {
            size.0.max(size.1)
        } else if nx > ny {
            size.0
        } else {
            size.1
        }
    };

    let start_size = get_scale(start_node_size, start_normal);
    let end_size = get_scale(end_node_size, end_normal);

    let mut cp1 = match custom_cp1 {
        Some(cp) => cp,
        None => start + start_normal * start_size,
    };

    let mut cp2 = match custom_cp2 {
        Some(cp) => cp,
        None => end + end_normal * end_size,
    };

    let to_target = end - start;
    let to_start = start - end;

    let is_totally_opposite = start_normal.x * to_target.x + start_normal.y * to_target.y < 0.0
        && end_normal.x * to_start.x + end_normal.y * to_start.y < 0.0
        && start_normal.x * end_normal.x + start_normal.y * end_normal.y < -0.9;

    let cp1_mult = if is_totally_opposite { 3.0 } else { 1.0 };
    let cp2_mult = if is_totally_opposite { 3.0 } else { 1.0 };

    // 1. Handle opposite direction exits to prevent going through the node
    if start_normal.x * to_target.x + start_normal.y * to_target.y < 0.0 {
        let perp = Point::new(-start_normal.y, start_normal.x);
        let dot = to_target.x * perp.x + to_target.y * perp.y;
        let side = if dot >= 0.0 { 1.0 } else { -1.0 };
        cp1 = start + start_normal * (start_size * cp1_mult) + perp * (side * start_size * cp1_mult);
    }

    if end_normal.x * to_start.x + end_normal.y * to_start.y < 0.0 {
        let perp = Point::new(-end_normal.y, end_normal.x);
        let dot = to_start.x * perp.x + to_start.y * perp.y;
        let side = if dot >= 0.0 { 1.0 } else { -1.0 };
        cp2 = end + end_normal * (end_size * cp2_mult) + perp * (side * end_size * cp2_mult);
    }

    // 2. Handle face-to-face ports (for Bezier only) to create a slight wave pattern
    if is_bezier {
        if start_normal.x * end_normal.x + start_normal.y * end_normal.y < -0.9 {
            let dist_len = to_target.length();
            if dist_len > 1.0 {
                let dir = to_target.normalize();
                if (start_normal.x * dir.x + start_normal.y * dir.y).abs() > 0.9 {
                    let perp = Point::new(-start_normal.y, start_normal.x);
                    let wave_offset = start_size * 0.3;
                    cp1 = cp1 + perp * wave_offset;
                    cp2 = cp2 - perp * wave_offset;
                }
            }
        }
    }

    (cp1, cp2)
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
