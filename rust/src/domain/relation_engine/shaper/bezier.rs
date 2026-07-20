use crate::domain::relation_engine::geometry::Point;
use crate::domain::relation_engine::shaper::core::{Shaper, ShaperContext};
use crate::domain::relation_engine::computed::{ComputedRelation, PathType};
use crate::domain::relation_engine::config::BezierConfig;

fn evaluate_cubic_bezier(
    p0: Point,
    p1: Point,
    p2: Point,
    p3: Point,
    num_samples: usize,
) -> Vec<Point> {
    if num_samples < 2 {
        return vec![p0, p3];
    }
    let mut points = Vec::with_capacity(num_samples);
    for i in 0..num_samples {
        let t = i as f64 / (num_samples - 1) as f64;
        let u = 1.0 - t;
        let point = p0 * (u * u * u) + p1 * (3.0 * u * u * t) + p2 * (3.0 * u * t * t) + p3 * (t * t * t);
        points.push(point);
    }
    points
}

pub struct BezierShaper {
    config: BezierConfig,
}

impl BezierShaper {
    pub fn new(config: BezierConfig) -> Self {
        Self { config }
    }
}

impl Shaper for BezierShaper {
    fn shape(&self, raw_path: &[Point], _context: &ShaperContext) -> ComputedRelation {
        let p0 = raw_path[0];
        let p3 = raw_path[raw_path.len() - 1];
        let p1 = Point::new(
            p0.x + self.config.start_offset_x,
            p0.y + self.config.start_offset_y,
        );
        let p2 = Point::new(
            p3.x + self.config.end_offset_x,
            p3.y + self.config.end_offset_y,
        );
        let path_points = evaluate_cubic_bezier(
            p0, p1, p2, p3, self.config.num_samples,
        );
        let mut computed = ComputedRelation::new_basic(String::new(), path_points, PathType::BSpline);
        computed.control_points = vec![p0, p1, p2, p3];
        computed
    }
}
