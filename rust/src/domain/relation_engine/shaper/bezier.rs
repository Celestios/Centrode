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
    fn shape(&self, _raw_path: &[Point], context: &ShaperContext) -> ComputedRelation {
        let p0 = context.start_pt;
        let p3 = context.end_pt;
        let (p1, p2) = super::core::resolve_control_points(
            p0,
            p3,
            context.start_normal,
            context.end_normal,
            context.start_node_size,
            context.end_node_size,
            context.custom_control_point_1,
            context.custom_control_point_2,
            true,
        );
        let path_points = evaluate_cubic_bezier(
            p0, p1, p2, p3, self.config.num_samples,
        );
        let mut computed = ComputedRelation::new_basic(String::new(), path_points, PathType::BSpline);
        computed.control_points = vec![p0, p1, p2, p3];
        computed
    }
}
