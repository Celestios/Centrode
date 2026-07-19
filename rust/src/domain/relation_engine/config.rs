use flutter_rust_bridge::frb;

#[derive(Clone, Debug, PartialEq)]
#[frb]
pub enum RoutingMode {
    Polyline,
    BSpline,
    Orthogonal,
    CircularArc,
    SineWave,
}

#[derive(Clone, Debug, PartialEq)]
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
            frequency: 0.05,
            obstacle_avoidance: true,
        }
    }
}

#[derive(Clone, Debug, PartialEq)]
#[frb]
pub struct KinodynamicConfig {
    pub kappa_max: f64,
    pub lattice_cell_size: f64,
    pub angular_resolution: f64,
    pub curvature_bins: u32,
    pub narrow_phase_tolerance: f64,
    pub weight_arc_length: f64,
    pub weight_curvature: f64,
    pub weight_obstacle: f64,
    pub obstacle_falloff: f64,
}

impl Default for KinodynamicConfig {
    fn default() -> Self {
        Self {
            kappa_max: 0.05,
            lattice_cell_size: 20.0,
            angular_resolution: 0.2618,
            curvature_bins: 5,
            narrow_phase_tolerance: 5.0,
            weight_arc_length: 1.0,
            weight_curvature: 0.1,
            weight_obstacle: 5.0,
            obstacle_falloff: 50.0,
        }
    }
}

#[derive(Clone, Debug, PartialEq)]
#[frb]
pub struct RoutingConfig {
    pub routing_mode: RoutingMode,
    pub obstacle_margin: f64,
    pub corner_radius: f64,
    pub projection_factor: f64,
    pub clamp_min: f64,
    pub clamp_max: f64,
    pub sine_wave: SnakeConfig,
    pub extension_min: f64,
    pub extension_scale: f64,
    pub kinodynamic: KinodynamicConfig,
}

impl Default for RoutingConfig {
    fn default() -> Self {
        Self {
            routing_mode: RoutingMode::Polyline,
            obstacle_margin: 20.0,
            corner_radius: 12.0,
            projection_factor: 1.0,
            clamp_min: 10.0,
            clamp_max: 200.0,
            sine_wave: SnakeConfig::default(),
            extension_min: 15.0,
            extension_scale: 0.15,
            kinodynamic: KinodynamicConfig::default(),
        }
    }
}

impl RoutingConfig {
    pub fn cell_size(&self) -> f64 {
        20.0
    }

    pub fn margin(&self) -> f64 {
        self.obstacle_margin
    }

    pub fn outer_bbox_distance(&self) -> f64 {
        self.obstacle_margin + 20.0
    }

    pub fn port_penalty(&self) -> f64 {
        1000.0
    }

    pub fn inner_bbox_scale(&self) -> f64 {
        1.0 / 3.0
    }

    pub fn corner_radius(&self) -> f64 {
        self.corner_radius
    }

    pub fn corner_samples(&self) -> usize {
        10
    }

    pub fn rdp_epsilon(&self) -> f64 {
        10.0
    }

    pub fn nudge_amplitude(&self) -> f64 {
        self.sine_wave.amplitude
    }

    pub fn nudge_count(&self) -> usize {
        5
    }
}

#[derive(Clone, Debug, PartialEq)]
#[frb]
pub struct NudgingConfig {
    pub min_spacing: f64,
    pub search_radius: f64,
}

impl Default for NudgingConfig {
    fn default() -> Self {
        Self {
            min_spacing: 15.0,
            search_radius: 60.0,
        }
    }
}

#[derive(Clone, Debug, PartialEq)]
#[frb]
pub enum BundlingMode {
    Proximity,
    SharedEndpoint,
    None,
}

#[derive(Clone, Debug, PartialEq)]
#[frb]
pub struct BundlingConfig {
    pub mode: BundlingMode,
    pub threshold: f64,
}

impl Default for BundlingConfig {
    fn default() -> Self {
        Self {
            mode: BundlingMode::None,
            threshold: 30.0,
        }
    }
}

#[derive(Clone, Debug, PartialEq)]
#[frb]
pub enum BodyType {
    Uniform,
    Taper,
    WidthModulate,
    Bundled,
}

#[derive(Clone, Debug, PartialEq)]
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
            taper_start_width: 8.0,
            taper_end_width: 2.0,
            width_modulate_amplitude: 2.0,
            width_modulate_frequency: 0.02,
        }
    }
}

#[derive(Clone, Debug, PartialEq)]
#[frb]
pub enum EndpointShapeType {
    None,
    Arrow,
    OpenArrow,
    Circle,
    Diamond,
    Square,
}

#[derive(Clone, Debug, PartialEq)]
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
            arrow_size: 16.0,
        }
    }
}

#[derive(Clone, Debug, PartialEq)]
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
            crossing_minimization: false,
            incremental_mode: true,
            body: BodyConfig::default(),
            endpoint: EndpointConfig::default(),
        }
    }
}
