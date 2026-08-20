use crate::domain::id::TypedRecordId;
use crate::domain::traits::TableKind;
use crate::relation_engine::geometry::Point;
use crate::relation_engine::geometry;
use crate::relation_engine::shaper::core::{Shaper, ShaperContext};
use crate::relation_engine::computed::{ComputedRelation, PathType};
use crate::relation_engine::config::RoutingConfig;
use crate::relation_engine::path_finder::simplify::simplify_path;

fn bspline_basis(i: usize, degree: usize, knots: &[f64], u: f64) -> f64 {
    if degree == 0 {
        return if u >= knots[i] && u < knots[i + 1] { 1.0 } else { 0.0 };
    }
    let d1 = knots[i + degree] - knots[i];
    let d2 = knots[i + degree + 1] - knots[i + 1];
    let c1 = if d1 > 0.0 { (u - knots[i]) / d1 * bspline_basis(i, degree - 1, knots, u) } else { 0.0 };
    let c2 = if d2 > 0.0 { (knots[i + degree + 1] - u) / d2 * bspline_basis(i + 1, degree - 1, knots, u) } else { 0.0 };
    c1 + c2
}

fn bspline_curve_point(cps: &[Point], degree: usize, knots: &[f64], u: f64) -> Point {
    let n = cps.len();
    let mut x = 0.0;
    let mut y = 0.0;
    for i in 0..n {
        let b = bspline_basis(i, degree, knots, u);
        x += cps[i].x * b;
        y += cps[i].y * b;
    }
    Point::new(x, y)
}

fn generate_knots(n: usize, degree: usize) -> Vec<f64> {
    let knot_count = n + degree + 1;
    let mut knots = vec![0.0; knot_count];
    let interior = knot_count - 2 * degree;
    for i in 0..knot_count {
        knots[i] = if i < degree {
            0.0
        } else if i >= knot_count - degree {
            1.0
        } else {
            (i - degree) as f64 / (interior - 1).max(1) as f64
        };
    }
    knots
}

fn evaluate_bspline(cps: &[Point], num_samples: usize) -> (Vec<Point>, Vec<f64>) {
    if cps.len() < 2 {
        return (cps.to_vec(), vec![]);
    }

    let degree = (cps.len() - 1).min(3);
    let knots = generate_knots(cps.len(), degree);
    let mut points = Vec::with_capacity(num_samples);
    for i in 0..num_samples {
        let t = i as f64 / (num_samples - 1) as f64;
        let u = if t >= 1.0 { 1.0 - 1e-10 } else { t };
        points.push(bspline_curve_point(cps, degree, &knots, u));
    }
    if let Some(first) = points.first_mut() {
        *first = cps[0];
    }
    if let Some(last) = points.last_mut() {
        *last = *cps.last().unwrap();
    }
    (points, knots)
}

pub struct BSplineShaper {
    config: RoutingConfig,
}

impl BSplineShaper {
    pub fn new(config: RoutingConfig) -> Self {
        Self { config }
    }
}

impl Shaper for BSplineShaper {
    fn shape(&self, raw_path: &[Point], context: &ShaperContext) -> ComputedRelation {
        let mut path = raw_path.to_vec();
        if context.start_stub_len > 0.0 {
            path.insert(0, context.start_pt);
        }
        if context.end_stub_len > 0.0 {
            path.push(context.end_pt);
        }
        let rdp_eps = self.config.rdp_epsilon();
        let path_len = geometry::polyline_length(&path);
        let bspline_samples = ((path_len / 5.0).clamp(10.0, 200.0)) as usize;

        let simplified = simplify_path(
            &path,
            rdp_eps,
            context.cell_size,
            context.start_stub_len > 0.0,
            context.end_stub_len > 0.0,
        );
        let (bspline_pts, knots) = evaluate_bspline(&simplified, bspline_samples);
        let mut computed = ComputedRelation::new_basic(TypedRecordId::nil(TableKind::IRelation), bspline_pts, PathType::BSpline);
        computed.control_points = simplified;
        computed.knots = knots;
        computed
    }

    fn reshape(&self, prepped_path: &[Point], _context: &ShaperContext) -> ComputedRelation {
        let path_len = geometry::polyline_length(prepped_path);
        let bspline_samples = ((path_len / 5.0).clamp(10.0, 200.0)) as usize;
        let (bspline_pts, knots) = evaluate_bspline(prepped_path, bspline_samples);
        let mut computed = ComputedRelation::new_basic(TypedRecordId::nil(TableKind::IRelation), bspline_pts, PathType::BSpline);
        computed.control_points = prepped_path.to_vec();
        computed.knots = knots;
        computed
    }
}
