use super::geometry::Point;
use super::config::{RelationEngineConfig, BodyType};

pub mod uniform;
pub mod taper;
pub mod width_modulate;

pub trait BodyStrategy: Send + Sync {
    fn compute_widths(
        &self,
        path: &[Point],
        base_width: f64,
        config: &RelationEngineConfig,
    ) -> Vec<f64>;
}

pub fn resolve_strategy(body_type: BodyType) -> Box<dyn BodyStrategy> {
    match body_type {
        BodyType::Uniform | BodyType::Bundled => Box::new(uniform::UniformBody),
        BodyType::Taper => Box::new(taper::TaperBody),
        BodyType::WidthModulate => Box::new(width_modulate::WidthModulateBody),
    }
}

pub fn compute_body_widths(
    path: &[Point],
    body_type: &BodyType,
    base_width: f64,
    config: &RelationEngineConfig,
    has_start_shape: bool,
    has_end_shape: bool,
) -> Vec<f64> {
    let mut widths = resolve_strategy(*body_type).compute_widths(path, base_width, config);

    let n = path.len();
    if n >= 2 {
        let mut lengths = vec![0.0; n];
        let mut total_length = 0.0;
        for i in 1..n {
            total_length += path[i - 1].distance_to(path[i]);
            lengths[i] = total_length;
        }

        let taper_dist = (2.0 * base_width).max(15.0);
        for i in 0..n {
            let d_start = lengths[i];
            let d_end = total_length - lengths[i];
            let mut scale = 1.0f64;

            if has_start_shape && d_start < taper_dist {
                scale = scale.min(d_start / taper_dist);
            }
            if has_end_shape && d_end < taper_dist {
                scale = scale.min(d_end / taper_dist);
            }
            widths[i] *= scale;
        }
    }

    widths
}
