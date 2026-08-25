use crate::domain::id::TypedRecordId;
use crate::domain::traits::TableKind;
use crate::relation_engine::computed::{ComputedRelation, PathType};
use crate::relation_engine::config::RoutingConfig;
use crate::relation_engine::geometry::{smooth_path_corners, Point};
use crate::relation_engine::shaper::core::{thin_path, Shaper, ShaperContext};
use crate::relation_engine::shaper::simplify::{octilinearize_path, simplify_octilinear_path};

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

        let corner_radius = self.config.corner_radius;

        let path_points = if corner_radius > 0.0 {
            smooth_path_corners(&simplified, corner_radius)
        } else {
            simplified.clone()
        };

        let mut computed = ComputedRelation::new_basic(
            TypedRecordId::nil(TableKind::IRelation),
            path_points,
            PathType::Orthogonal,
        );
        computed.control_points = simplified;
        computed
    }
}
