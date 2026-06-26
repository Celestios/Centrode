use super::{BodyStrategy, Point, RelationEngineConfig};

pub struct TaperBody;

impl BodyStrategy for TaperBody {
    fn compute_widths(
        &self,
        path: &[Point],
        _base_width: f64,
        config: &RelationEngineConfig,
    ) -> Vec<f64> {
        let n = path.len();
        if n == 0 {
            return Vec::new();
        }
        if n == 1 {
            return vec![config.body.taper_start_width];
        }

        // Compute cumulative arc lengths for accurate parameterization
        let mut lengths = vec![0.0; n];
        let mut total_length = 0.0;
        for i in 1..n {
            total_length += path[i - 1].distance_to(path[i]);
            lengths[i] = total_length;
        }

        let start = config.body.taper_start_width;
        let end = config.body.taper_end_width;

        let mut widths = Vec::with_capacity(n);
        for &len in &lengths {
            let t = if total_length > 1e-6 {
                len / total_length
            } else {
                0.0
            };
            widths.push(start + (end - start) * t);
        }
        widths
    }
}
