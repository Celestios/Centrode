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
) -> Vec<f64> {
    resolve_strategy(*body_type).compute_widths(path, base_width, config)
}
