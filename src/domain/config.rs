use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MapConfig {
    pub map_name: String,
    pub global_settings: String, // JSON blob
}