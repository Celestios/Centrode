use crate::domain::relation_engine::geometry::Point;
use crate::domain::relation_engine::shaper::core::{Shaper, ShaperContext, thin_path};
use crate::domain::relation_engine::computed::{ComputedRelation, PathType};
use crate::domain::relation_engine::config::RoutingConfig;
use crate::domain::relation_engine::shaper::simplify::{orthogonalize_path, simplify_orthogonal_path};

fn smooth_orthogonal_path(
    points: &[Point],
    corner_radius: f64,
    num_samples_per_corner: usize,
) -> Vec<Point> {
    if points.len() <= 2 || corner_radius <= 0.0 || num_samples_per_corner == 0 {
        return points.to_vec();
    }

    let mut result = Vec::new();
    result.push(points[0]);

    for i in 1..points.len() - 1 {
        let prev = points[i - 1];
        let curr = points[i];
        let next = points[i + 1];

        let v1 = Point::new(curr.x - prev.x, curr.y - prev.y);
        let v2 = Point::new(next.x - curr.x, next.y - curr.y);

        let d1 = v1.x.hypot(v1.y);
        let d2 = v2.x.hypot(v2.y);

        if d1 < 1e-6 || d2 < 1e-6 {
            result.push(curr);
            continue;
        }

        let v1_unit = Point::new(v1.x / d1, v1.y / d1);
        let v2_unit = Point::new(v2.x / d2, v2.y / d2);

        let cross = v1_unit.x * v2_unit.y - v1_unit.y * v2_unit.x;
        if cross.abs() < 1e-6 {
            result.push(curr);
            continue;
        }

        let r = corner_radius.min(d1 / 2.0).min(d2 / 2.0);

        if r < 1e-3 {
            result.push(curr);
            continue;
        }

        let p_start = Point::new(curr.x - v1_unit.x * r, curr.y - v1_unit.y * r);

        for j in 0..=num_samples_per_corner {
            let t = j as f64 / num_samples_per_corner as f64;
            let angle = t * std::f64::consts::FRAC_PI_2;
            let p_arc = Point::new(
                p_start.x + v1_unit.x * r * angle.sin() + v2_unit.x * r * (1.0 - angle.cos()),
                p_start.y + v1_unit.y * r * angle.sin() + v2_unit.y * r * (1.0 - angle.cos()),
            );

            if let Some(last) = result.last() {
                if (p_arc.x - last.x).abs() > 1e-6 || (p_arc.y - last.y).abs() > 1e-6 {
                    result.push(p_arc);
                }
            } else {
                result.push(p_arc);
            }
        }
    }

    let last = *points.last().unwrap();
    if let Some(prev) = result.last() {
        if (last.x - prev.x).abs() > 1e-6 || (last.y - prev.y).abs() > 1e-6 {
            result.push(last);
        }
    } else {
        result.push(last);
    }

    result
}

pub struct OrthogonalShaper {
    config: RoutingConfig,
}

impl OrthogonalShaper {
    pub fn new(config: RoutingConfig) -> Self {
        Self { config }
    }
}

impl Shaper for OrthogonalShaper {
    fn shape(&self, raw_path: &[Point], context: &ShaperContext) -> ComputedRelation {
        let thinned = thin_path(raw_path, context.cell_size);
        let mut path = thinned;
        let has_start_stub = context.start_stub_len > 0.0;
        let has_end_stub = context.end_stub_len > 0.0;
        if has_start_stub {
            path.insert(0, context.start_pt);
        }
        if has_end_stub {
            path.push(context.end_pt);
        }
        self.reshape(&path, context)
    }

    fn reshape(&self, prepped_path: &[Point], context: &ShaperContext) -> ComputedRelation {
        let has_start_stub = context.start_stub_len > 0.0;
        let has_end_stub = context.end_stub_len > 0.0;
        let orth_path = orthogonalize_path(
            prepped_path,
            context.start_dir,
            context.end_dir,
            has_start_stub,
            has_end_stub,
        );
        let simplified = simplify_orthogonal_path(&orth_path, context.cell_size);
        let path_points = if self.config.corner_radius > 0.0 && self.config.corner_samples() > 0 {
            smooth_orthogonal_path(&simplified, self.config.corner_radius, self.config.corner_samples())
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
