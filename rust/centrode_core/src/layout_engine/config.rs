use flutter_rust_bridge::frb;

#[frb]
#[derive(Clone, Debug)]
pub struct ForceConfig {
    pub repulsion_constant: f64,
    pub spring_constant: f64,
    pub ideal_link_distance: f64,
    pub collision_strength: f64,
    pub base_margin: f64,
    pub margin_scale: f64,
    pub wall_strength: f64,
    pub wall_padding: f64,
    pub damping: f64,
    pub alpha_decay: f64,
    pub alpha_min: f64,
    pub relation_stretch_factor: f64,
    pub node_edge_repulsion: f64,
    pub density_dispersion_strength: f64,
}

impl Default for ForceConfig {
    fn default() -> Self {
        Self {
            repulsion_constant: 8000.0,
            spring_constant: 0.05,
            ideal_link_distance: 220.0,
            collision_strength: 1.2,
            base_margin: 35.0,
            margin_scale: 0.2,
            wall_strength: 1.0,
            wall_padding: 20.0,
            damping: 0.4,
            alpha_decay: 0.02,
            alpha_min: 0.001,
            relation_stretch_factor: 0.5,
            node_edge_repulsion: 1500.0,
            density_dispersion_strength: 300.0,
        }
    }
}

#[frb]
#[derive(Clone, Debug)]
pub struct ConvergenceCriteria {
    pub max_iterations: u32,
    pub energy_threshold: f64,
    pub displacement_threshold: f64,
    pub oscillation_window: u32,
}

impl Default for ConvergenceCriteria {
    fn default() -> Self {
        Self {
            max_iterations: 500,
            energy_threshold: 0.01,
            displacement_threshold: 0.5,
            oscillation_window: 10,
        }
    }
}

#[frb]
#[derive(Clone, Debug)]
pub struct LayoutConfig {
    pub force: ForceConfig,
    pub convergence: ConvergenceCriteria,
    pub batch_size: u32,
}

impl Default for LayoutConfig {
    fn default() -> Self {
        Self {
            force: ForceConfig::default(),
            convergence: ConvergenceCriteria::default(),
            batch_size: 1,
        }
    }
}
