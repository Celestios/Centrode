use crate::domain::relation_engine::geometry::Point;
use crate::domain::relation_engine::shaper::core::{Shaper, ShaperContext};
use crate::domain::relation_engine::computed::{ComputedRelation, PathType};

pub struct SineWaveShaper {
    amplitude: f64,
    frequency: f64,
    num_samples: usize,
}

impl SineWaveShaper {
    pub fn new(amplitude: f64, frequency: f64, num_samples: usize) -> Self {
        Self {
            amplitude,
            frequency,
            num_samples,
        }
    }
}

impl Shaper for SineWaveShaper {
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
            false,
        );
        let dist = p0.distance_to(p3);
        let num_samples = ((dist / 4.0).ceil() as usize).max(self.num_samples).max(100);
        
        let mut path_points = Vec::with_capacity(num_samples);
        if dist > 1.0 {
            let cycles = dist * (self.frequency / 200.0);
            for i in 0..num_samples {
                let t = i as f64 / (num_samples - 1) as f64;
                let u = 1.0 - t;
                let base = p0 * (u * u * u) + p1 * (3.0 * u * u * t) + p2 * (3.0 * u * t * t) + p3 * (t * t * t);
                let tangent = (p1 - p0) * (3.0 * u * u) + (p2 - p1) * (6.0 * u * t) + (p3 - p2) * (3.0 * t * t);
                let perp = Point::new(-tangent.y, tangent.x).normalize();
                let offset = self.amplitude
                    * (t * cycles * 2.0 * std::f64::consts::PI).sin()
                    * (t * std::f64::consts::PI).sin();
                path_points.push(base + perp * offset);
            }
        } else {
            path_points.push(p0);
            path_points.push(p3);
        }

        let mut computed = ComputedRelation::new_basic(String::new(), path_points, PathType::BSpline);
        computed.control_points = vec![p0, p1, p2, p3];
        computed
    }
}
