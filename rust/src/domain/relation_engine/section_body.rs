use super::geometry::Point;
use super::config::{BodyType, RelationEngineConfig};
use super::sections::BodyResult;

#[derive(Debug, Clone, Copy)]
pub enum BodyResolver {
    Uniform,
    Taper,
    WidthModulate,
}

impl BodyResolver {
    #[inline(always)]
    pub fn generate(
        &self,
        path: &[Point],
        base_width: f64,
        config: &RelationEngineConfig,
        widths_buffer: &mut Vec<f64>,
    ) -> BodyResult {
        match self {
            Self::Uniform => uniform_generate(path, base_width, widths_buffer),
            Self::Taper => taper_generate(path, config, widths_buffer),
            Self::WidthModulate => width_modulate_generate(path, base_width, config, widths_buffer),
        }
    }

    pub fn from_body_type(body_type: BodyType) -> Self {
        match body_type {
            BodyType::Uniform | BodyType::Bundled => Self::Uniform,
            BodyType::Taper => Self::Taper,
            BodyType::WidthModulate => Self::WidthModulate,
        }
    }
}

#[inline(always)]
fn uniform_generate(
    path: &[Point],
    base_width: f64,
    widths_buffer: &mut Vec<f64>,
) -> BodyResult {
    let start_idx = widths_buffer.len();
    widths_buffer.resize(start_idx + path.len(), base_width);
    BodyResult {
        point_count: path.len(),
        total_points: widths_buffer.len(),
    }
}

#[inline(always)]
fn taper_generate(
    path: &[Point],
    config: &RelationEngineConfig,
    widths_buffer: &mut Vec<f64>,
) -> BodyResult {
    let n = path.len();
    let start_idx = widths_buffer.len();

    if n == 0 {
        return BodyResult { point_count: 0, total_points: start_idx };
    }

    let mut lengths = vec![0.0; n];
    let mut total_length = 0.0;
    for i in 1..n {
        total_length += path[i - 1].distance_to(path[i]);
        lengths[i] = total_length;
    }

    let start_w = config.body.taper_start_width;
    let end_w = config.body.taper_end_width;

    widths_buffer.reserve(n);
    for &len in &lengths {
        let t = if total_length > 1e-6 { len / total_length } else { 0.0 };
        widths_buffer.push(start_w + (end_w - start_w) * t);
    }

    BodyResult {
        point_count: n,
        total_points: widths_buffer.len(),
    }
}

#[inline(always)]
fn width_modulate_generate(
    path: &[Point],
    base_width: f64,
    config: &RelationEngineConfig,
    widths_buffer: &mut Vec<f64>,
) -> BodyResult {
    let n = path.len();
    let start_idx = widths_buffer.len();

    if n == 0 {
        return BodyResult { point_count: 0, total_points: start_idx };
    }

    let mut lengths = vec![0.0; n];
    let mut total_length = 0.0;
    for i in 1..n {
        total_length += path[i - 1].distance_to(path[i]);
        lengths[i] = total_length;
    }

    let amplitude = config.body.width_modulate_amplitude;
    let frequency = config.body.width_modulate_frequency;

    widths_buffer.reserve(n);
    for &len in &lengths {
        let w = base_width + amplitude * (len * (frequency / 300.0) * 2.0 * std::f64::consts::PI).sin();
        widths_buffer.push(w.max(0.1));
    }

    BodyResult {
        point_count: n,
        total_points: widths_buffer.len(),
    }
}

pub fn compute_widths(
    path: &[Point],
    body_type: BodyType,
    base_width: f64,
    config: &RelationEngineConfig,
    widths_buffer: &mut Vec<f64>,
) -> BodyResult {
    BodyResolver::from_body_type(body_type).generate(path, base_width, config, widths_buffer)
}
