use flutter_rust_bridge::frb;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[frb]
pub enum RoutingMode {
    Polyline,
    Bezier,
    Orthogonal,
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

#[derive(Debug, Clone)]
#[frb]
pub struct RelationEngineConfig {
    pub routing_mode: RoutingMode,
    pub obstacle_margin: f64,
    pub corner_radius: f64,
    pub incremental_mode: bool,
    pub nudging_enabled: bool,
    pub nudging_distance: f64,
    pub bundling_mode: BundlingMode,
    pub bundling_threshold: f64,
    pub crossing_minimization: bool,
    pub bezier_curvature: f64,
    pub bezier_projection_factor: f64,
    pub bezier_clamp_min: f64,
    pub bezier_clamp_max: f64,
    pub default_body_type: BodyType,
    pub taper_start_width: f64,
    pub taper_end_width: f64,
    pub width_modulate_amplitude: f64,
    pub width_modulate_frequency: f64,
    pub default_start_shape: EndpointShapeType,
    pub default_end_shape: EndpointShapeType,
    pub arrow_size: f64,
    pub snake_amplitude: f64,
    pub snake_frequency: f64,
    pub snake_obstacle_avoidance: bool,
}

impl Default for RelationEngineConfig {
    fn default() -> Self {
        Self {
            routing_mode: RoutingMode::Polyline,
            obstacle_margin: 45.0,
            corner_radius: 8.0,
            incremental_mode: true,
            nudging_enabled: true,
            nudging_distance: 4.0,
            bundling_mode: BundlingMode::None,
            bundling_threshold: 50.0,
            crossing_minimization: true,
            bezier_curvature: 0.25,
            bezier_projection_factor: 0.4,
            bezier_clamp_min: 30.0,
            bezier_clamp_max: 150.0,
            default_body_type: BodyType::Uniform,
            taper_start_width: 2.0,
            taper_end_width: 2.0,
            width_modulate_amplitude: 1.5,
            width_modulate_frequency: 3.0,
            default_start_shape: EndpointShapeType::None,
            default_end_shape: EndpointShapeType::Arrow,
            arrow_size: 10.0,
            snake_amplitude: 20.0,
            snake_frequency: 3.0,
            snake_obstacle_avoidance: false,
        }
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
