use crate::domain::relation_engine::geometry::{Point, smooth_path_corners};
use crate::domain::relation_engine::shaper::core::{Shaper, ShaperContext, thin_path};
use crate::domain::relation_engine::computed::{ComputedRelation, PathType};
use crate::domain::relation_engine::config::RoutingConfig;
use crate::domain::relation_engine::shaper::simplify::{octilinearize_path, simplify_octilinear_path};

pub struct OctilinearShaper {
    config: RoutingConfig,
}

impl OctilinearShaper {
    pub fn new(config: RoutingConfig) -> Self {
        Self { config }
    }
}

impl Shaper for OctilinearShaper {
    fn shape(&self, raw_path: &[Point], context: &ShaperContext) -> ComputedRelation {
        let thinned = thin_path(raw_path, context.cell_size);
        let mut path = thinned;
        if context.start_stub_len > 0.0 {
            path.insert(0, context.start_pt);
        }
        if context.end_stub_len > 0.0 {
            path.push(context.end_pt);
        }
        self.reshape(&path, context)
    }

    fn reshape(&self, prepped_path: &[Point], context: &ShaperContext) -> ComputedRelation {
        let oct_path = octilinearize_path(prepped_path);
        let simplified = simplify_octilinear_path(&oct_path, context.cell_size);

        // Constants matching default OctilinearConfig
        let corner_radius = 12.0;
        let corner_samples = 10;

        let path_points = if corner_radius > 0.0 && corner_samples > 0 {
            smooth_path_corners(&simplified, corner_radius, corner_samples)
        } else {
            simplified.clone()
        };

        use crate::domain::id::TypedRecordId;
        use crate::domain::traits::TableKind;
        let mut computed = ComputedRelation::new_basic(TypedRecordId::nil(TableKind::IRelation), path_points, PathType::Orthogonal);
        computed.control_points = simplified;
        computed
    }
}
