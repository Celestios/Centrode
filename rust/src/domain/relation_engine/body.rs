use super::config::BodyType;
use super::config::RelationEngineConfig;
use super::geometry::Point;

pub fn compute_body_widths(
    path: &[Point],
    body_type: &BodyType,
    base_width: f64,
    config: &RelationEngineConfig,
) -> Vec<f64> {
    match body_type {
        BodyType::Uniform => vec![base_width; path.len()],
        BodyType::Taper => {
            let start_w = config.body.taper_start_width.max(0.5);
            let end_w = config.body.taper_end_width.max(0.5);
            let n = path.len();
            if n <= 1 {
                return vec![base_width; n];
            }
            (0..n)
                .map(|i| {
                    let t = i as f64 / (n - 1) as f64;
                    start_w + (end_w - start_w) * t
                })
                .collect()
        }
        BodyType::WidthModulate => {
            let amp = config.body.width_modulate_amplitude;
            let freq = config.body.width_modulate_frequency;
            let n = path.len();
            if n <= 1 {
                return vec![base_width; n];
            }
            (0..n)
                .map(|i| {
                    let t = i as f64 / (n - 1) as f64;
                    base_width + amp * (t * freq * 2.0 * std::f64::consts::PI).sin()
                })
                .collect()
        }
        BodyType::Bundled => vec![base_width; path.len()],
    }
}
