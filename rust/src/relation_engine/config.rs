use crate::domain::styles::EndpointShape;
use crate::relation_engine::geometry;
use surrealdb::types::SurrealValue;

#[derive(Clone, Debug, PartialEq, SurrealValue)]
#[non_exhaustive]
pub enum RoutingMode {
    Polyline,
    BSpline,
    Orthogonal,
    Octilinear,
    Bezier {
        control_point_1: Option<geometry::Point>,
        control_point_2: Option<geometry::Point>,
    },
    SineWave {
        control_point_1: Option<geometry::Point>,
        control_point_2: Option<geometry::Point>,
    },
}

#[derive(Clone, Debug, PartialEq)]
pub struct RoutingConfig {
    pub routing_mode: RoutingMode,
    pub obstacle_margin: f64,
    pub corner_radius: f64,
    pub projection_factor: f64,
    pub clamp_min: f64,
    pub clamp_max: f64,
    pub extension_min: f64,
    pub extension_scale: f64,
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
            extension_min: 15.0,
            extension_scale: 0.15,
        }
    }
}

impl RoutingConfig {
    pub fn cell_size(&self) -> f64 {
        20.0
    }

    pub fn margin(&self) -> f64 {
        5.0
    }

    pub fn outer_bbox_distance(&self) -> f64 {
        match self.routing_mode {
            RoutingMode::Orthogonal | RoutingMode::Octilinear => 22.5,
            _ => 40.0,
        }
    }

    pub fn port_penalty(&self) -> f64 {
        1000.0
    }

    pub fn inner_bbox_scale(&self) -> f64 {
        match self.routing_mode {
            RoutingMode::Orthogonal | RoutingMode::Octilinear => 2.0 / 3.0,
            _ => 1.0 / 3.0,
        }
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
        20.0
    }

    pub fn nudge_count(&self) -> usize {
        5
    }

    pub fn straight_config(&self) -> StraightConfig {
        StraightConfig { num_samples: 2 }
    }

    pub fn bezier_config(&self) -> BezierConfig {
        BezierConfig {
            num_samples: 100,
            start_offset_x: 50.0,
            start_offset_y: 0.0,
            end_offset_x: -50.0,
            end_offset_y: 0.0,
        }
    }
}

#[derive(Clone, Debug, PartialEq)]
pub struct StraightConfig {
    pub num_samples: usize,
}

#[derive(Clone, Debug, PartialEq)]
pub struct BezierConfig {
    pub num_samples: usize,
    pub start_offset_x: f64,
    pub start_offset_y: f64,
    pub end_offset_x: f64,
    pub end_offset_y: f64,
}

#[derive(Clone, Debug, PartialEq)]
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

impl NudgingConfig {
    pub fn min_spacing(&self) -> f64 {
        self.distance * 3.75
    }
    pub fn search_radius(&self) -> f64 {
        self.distance * 15.0
    }
}

#[derive(Clone, Debug, PartialEq)]
#[non_exhaustive]
pub enum BundlingMode {
    Proximity,
    SharedEndpoint,
    None,
}

#[derive(Clone, Debug, PartialEq)]
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
#[non_exhaustive]
pub enum BodyType {
    Uniform,
    Taper,
    WidthModulate,
    Bundled,
}

#[derive(Clone, Debug, PartialEq)]
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
pub struct EndpointConfig {
    pub default_start_shape: EndpointShape,
    pub default_end_shape: EndpointShape,
    pub arrow_size: f64,
}

impl Default for EndpointConfig {
    fn default() -> Self {
        Self {
            default_start_shape: EndpointShape::None,
            default_end_shape: EndpointShape::Arrow,
            arrow_size: 16.0,
        }
    }
}

#[derive(Clone, Debug, PartialEq)]
pub struct RelationEngineConfig {
    pub routing: RoutingConfig,
    pub nudging: NudgingConfig,
    pub bundling: BundlingConfig,
    pub crossing_minimization: bool,
    pub incremental_mode: bool,
    pub body: BodyConfig,
    pub endpoint: EndpointConfig,
    pub apply_compose: Option<bool>,
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
            apply_compose: None,
        }
    }
}
