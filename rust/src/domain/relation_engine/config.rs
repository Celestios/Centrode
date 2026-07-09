use flutter_rust_bridge::frb;

use crate::domain::styles::EndpointShape;

pub fn resolve_endpoint_shape(
    shape: Option<&EndpointShape>,
    default: EndpointShapeType,
) -> EndpointShapeType {
    shape.map(|s| EndpointShapeType::from(*s)).unwrap_or(default)
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[frb]
pub enum RoutingMode {
    Polyline,
    Bezier,
    Orthogonal,
    CircularArc,
    SineWave,
}

impl Default for RoutingMode {
    fn default() -> Self {
        RoutingMode::Polyline
    }
}

impl RoutingMode {
    pub fn from_str(s: &str) -> Self {
        match s.to_lowercase().as_str() {
            "bezier" => RoutingMode::Bezier,
            "orthogonal" => RoutingMode::Orthogonal,
            "straight" => RoutingMode::Polyline,
            "circular_arc" | "circulararc" | "arc" => RoutingMode::CircularArc,
            "sinewave" | "sine_wave" | "sine" | "snake" => RoutingMode::SineWave,
            _ => RoutingMode::Polyline,
        }
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[frb]
pub enum BundlingMode {
    Proximity,
    SharedEndpoint,
    None,
}

impl Default for BundlingMode {
    fn default() -> Self {
        BundlingMode::None
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[frb]
pub enum BodyType {
    Uniform,
    Taper,
    WidthModulate,
    Bundled,
}

impl Default for BodyType {
    fn default() -> Self {
        BodyType::Uniform
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[frb]
pub enum EndpointShapeType {
    None,
    Arrow,
    OpenArrow,
    Circle,
    Diamond,
    Square,
}

impl Default for EndpointShapeType {
    fn default() -> Self {
        EndpointShapeType::None
    }
}

impl EndpointShapeType {
    pub fn from_str(s: &str) -> Self {
        match s {
            "Arrow" | "arrow" => EndpointShapeType::Arrow,
            "OpenArrow" | "openArrow" => EndpointShapeType::OpenArrow,
            "Circle" | "circle" => EndpointShapeType::Circle,
            "Diamond" | "diamond" => EndpointShapeType::Diamond,
            "Square" | "square" => EndpointShapeType::Square,
            _ => EndpointShapeType::None,
        }
    }
}

impl From<crate::domain::styles::EndpointShape> for EndpointShapeType {
    fn from(shape: crate::domain::styles::EndpointShape) -> Self {
        match shape {
            crate::domain::styles::EndpointShape::None => EndpointShapeType::None,
            crate::domain::styles::EndpointShape::Arrow => EndpointShapeType::Arrow,
            crate::domain::styles::EndpointShape::OpenArrow => EndpointShapeType::OpenArrow,
            crate::domain::styles::EndpointShape::Circle => EndpointShapeType::Circle,
            crate::domain::styles::EndpointShape::Diamond => EndpointShapeType::Diamond,
            crate::domain::styles::EndpointShape::Square => EndpointShapeType::Square,
        }
    }
}

#[derive(Debug, Clone)]
#[frb]
pub struct RoutingConfig {
    pub routing_mode: RoutingMode,
    pub obstacle_margin: f64,
    pub corner_radius: f64,
    pub bezier_curvature: f64,
    pub bezier_projection_factor: f64,
    pub bezier_clamp_min: f64,
    pub bezier_clamp_max: f64,
    pub sine_wave: SnakeConfig,
    pub grid_size: f64,
    pub extension_min: f64,
    pub extension_scale: f64,
}

impl Default for RoutingConfig {
    fn default() -> Self {
        Self {
            routing_mode: RoutingMode::Polyline,
            obstacle_margin: 45.0,
            corner_radius: 8.0,
            bezier_curvature: 0.25,
            bezier_projection_factor: 0.4,
            bezier_clamp_min: 30.0,
            bezier_clamp_max: 150.0,
            sine_wave: SnakeConfig::default(),
            grid_size: 8.0,
            extension_min: 8.0,
            extension_scale: 0.1,
        }
    }
}

#[derive(Debug, Clone)]
#[frb]
pub struct NudgingConfig {
    pub enabled: bool,
    pub distance: f64,
    pub decay_factor: f64,
}

impl Default for NudgingConfig {
    fn default() -> Self {
        Self {
            enabled: true,
            distance: 4.0,
            decay_factor: 0.5,
        }
    }
}

#[derive(Debug, Clone)]
#[frb]
pub struct BundlingConfig {
    pub mode: BundlingMode,
    pub threshold: f64,
}

impl Default for BundlingConfig {
    fn default() -> Self {
        Self {
            mode: BundlingMode::None,
            threshold: 50.0,
        }
    }
}

#[derive(Debug, Clone)]
#[frb]
pub struct BodyConfig {
    pub default_type: BodyType,
    pub taper_start_width: f64,
    pub taper_end_width: f64,
    pub width_modulate_amplitude: f64,
    pub width_modulate_frequency: f64,
}

impl Default for BodyConfig {
    fn default() -> Self {
        Self {
            default_type: BodyType::Uniform,
            taper_start_width: 2.0,
            taper_end_width: 2.0,
            width_modulate_amplitude: 1.5,
            width_modulate_frequency: 3.0,
        }
    }
}

#[derive(Debug, Clone)]
#[frb]
pub struct EndpointConfig {
    pub default_start_shape: EndpointShapeType,
    pub default_end_shape: EndpointShapeType,
    pub arrow_size: f64,
}

impl Default for EndpointConfig {
    fn default() -> Self {
        Self {
            default_start_shape: EndpointShapeType::None,
            default_end_shape: EndpointShapeType::Arrow,
            arrow_size: 10.0,
        }
    }
}

#[derive(Debug, Clone)]
#[frb]
pub struct SnakeConfig {
    pub amplitude: f64,
    pub frequency: f64,
    pub obstacle_avoidance: bool,
}

impl Default for SnakeConfig {
    fn default() -> Self {
        Self {
            amplitude: 20.0,
            frequency: 3.0,
            obstacle_avoidance: false,
        }
    }
}

#[derive(Debug, Clone)]
#[frb]
pub struct RelationEngineConfig {
    pub routing: RoutingConfig,
    pub nudging: NudgingConfig,
    pub bundling: BundlingConfig,
    pub crossing_minimization: bool,
    pub incremental_mode: bool,
    pub body: BodyConfig,
    pub endpoint: EndpointConfig,
}

impl Default for RelationEngineConfig {
    fn default() -> Self {
        Self {
            routing: RoutingConfig::default(),
            nudging: NudgingConfig::default(),
            bundling: BundlingConfig::default(),
            crossing_minimization: true,
            incremental_mode: true,
            body: BodyConfig::default(),
            endpoint: EndpointConfig::default(),
        }
    }
}
