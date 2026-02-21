use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GraphLayout {
    pub x: f64,
    pub y: f64,
    pub w: f64,
    pub h: f64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct KanbanLayout {
    pub col: String, // uuid-of-column
    pub rank: i32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TimelineLayout {
    pub start: i64,
    pub end: i64,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NodeLayout {
    pub graph: Option<GraphLayout>,
    pub kanban: Option<KanbanLayout>,
    pub timeline: Option<TimelineLayout>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VisualFormatting {
    pub layout: NodeLayout,
    pub overrides: Option<StyleProfile>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StyleProfile {
    pub shape: String,        // e.g., "rounded_rect"
    pub bg_color: String,     // e.g., "#1E1E1E"
    pub stroke_color: String, // e.g., "#FFFFFF"
    pub stroke_width: f32,
    pub font_family: String,  
}

impl StyleProfile {
    pub fn merge(&mut self, other: &StyleProfile) {
        if !other.shape.is_empty() {
            self.shape = other.shape.clone();
        }
        if !other.bg_color.is_empty() {
            self.bg_color = other.bg_color.clone();
        }
        if !other.stroke_color.is_empty() {
            self.stroke_color = other.stroke_color.clone();
        }
        if other.stroke_width != 0.0 {
            self.stroke_width = other.stroke_width;
        }
        if !other.font_family.is_empty() {
            self.font_family = other.font_family.clone();
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ThemeConfig {
    pub name: String,
    pub global_default: StyleProfile,
    // Specific overrides per node type (e.g., "TaskNode" -> Green)
    pub type_definitions: HashMap<String, StyleProfile>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ViewportState {
    pub x_offset: f64,
    pub y_offset: f64,
    pub zoom_level: f64,
    pub active_view: String, // "graph", "kanban", or "timeline"
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MapConfig {
    pub map_name: String,
    pub viewport_state: ViewportState, // Persistence of camera
    pub theme: ThemeConfig,            // Persistence of style system
}

pub fn resolve_node_style(theme: &ThemeConfig, node_type: &str, aesthetics_json: &Option<String>) -> Result<StyleProfile, serde_json::Error> {
    // 1. Start with Global Default
    let mut final_style = theme.global_default.clone();

    // 2. Apply Type-Specific Theme (e.g., TaskNodes are usually square)
    if let Some(type_style) = theme.type_definitions.get(node_type) {
        final_style.merge(type_style);
    }

    // 3. Apply Instance Overrides (User explicitly colored this node)
    if let Some(json) = aesthetics_json {
        let formatting: VisualFormatting = serde_json::from_str(json)?;
        if let Some(override_style) = formatting.overrides {
            final_style.merge(&override_style);
        }
    }

    Ok(final_style)
}