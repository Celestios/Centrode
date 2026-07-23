use crate::domain::relation_engine::geometry::Point;
use crate::domain::relation_engine::shaper::core::{Shaper, ShaperContext};
use crate::domain::relation_engine::computed::{ComputedRelation, PathType};
use crate::domain::relation_engine::config::StraightConfig;

fn evaluate_straight(start: Point, end: Point, num_samples: usize) -> Vec<Point> {
    if num_samples <= 2 {
        return vec![start, end];
    }
    let mut points = Vec::with_capacity(num_samples);
    for i in 0..num_samples {
        let t = i as f64 / (num_samples - 1) as f64;
        points.push(start.lerp(end, t));
    }
    points
}

pub struct StraightShaper {
    config: StraightConfig,
}

impl StraightShaper {
    pub fn new(config: StraightConfig) -> Self {
        Self { config }
    }
}

impl Shaper for StraightShaper {
    fn shape(&self, raw_path: &[Point], _context: &ShaperContext) -> ComputedRelation {
        let start = raw_path[0];
        let end = raw_path[raw_path.len() - 1];
        let path_points = evaluate_straight(start, end, self.config.num_samples);
        use crate::domain::id::TypedRecordId;
        use crate::domain::traits::TableKind;
        let mut computed = ComputedRelation::new_basic(TypedRecordId::nil(TableKind::IRelation), path_points, PathType::Straight);
        computed.control_points = vec![start, end];
        computed
    }
}
