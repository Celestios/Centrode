use super::{BodyStrategy, Point, RelationEngineConfig};
use std::f64::consts::PI;

pub struct WidthModulateBody;

impl BodyStrategy for WidthModulateBody {
    fn compute_widths(
        &self,
        path: &[Point],
        base_width: f64,
        config: &RelationEngineConfig,
    ) -> Vec<f64> {
        let n = path.len();
        if n == 0 {
            return Vec::new();
        }
        if n == 1 {
            return vec![base_width];
        }

        let mut lengths = vec![0.0; n];
        let mut total_length = 0.0;
        for i in 1..n {
            total_length += path[i - 1].distance_to(path[i]);
            lengths[i] = total_length;
        }

        let amplitude = config.body.width_modulate_amplitude;
        let frequency = config.body.width_modulate_frequency;

        let mut widths = Vec::with_capacity(n);
        for &len in &lengths {
            let t = if total_length > 1e-6 {
                len / total_length
            } else {
                0.0
            };
            let w = base_width + amplitude * (t * frequency * 2.0 * PI).sin();
            widths.push(w.max(0.1)); // Keep width positive
        }
        widths
    }
}
