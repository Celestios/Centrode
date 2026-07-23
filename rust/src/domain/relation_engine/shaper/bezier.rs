use crate::domain::relation_engine::geometry::Point;
use crate::domain::relation_engine::shaper::core::{Shaper, ShaperContext};
use crate::domain::relation_engine::computed::{ComputedRelation, PathType};
use crate::domain::relation_engine::config::BezierConfig;
use crate::domain::relation_engine::geometry_utils::evaluate_cubic_bezier;

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
        use crate::domain::id::TypedRecordId;
        use crate::domain::traits::TableKind;
        let mut computed = ComputedRelation::new_basic(TypedRecordId::nil(TableKind::IRelation), path_points, PathType::Bezier);
        computed.control_points = vec![p0, p1, p2, p3];
        computed
    }
}
