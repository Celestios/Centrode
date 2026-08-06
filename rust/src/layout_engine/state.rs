use crate::domain::base_models::BoundingBox;
use crate::domain::id::TypedRecordId;
use crate::layout_engine::types::{AlignmentConstraint, AnchorSpring, LayoutEdge, NodePhysics};
use std::collections::HashMap;

pub struct LayoutState {
    pub nodes: HashMap<TypedRecordId, NodePhysics>,
    pub edges: Vec<LayoutEdge>,
    pub opt_area: Option<BoundingBox>,
    pub alpha: f64,
    pub iteration: u32,
    pub energy_history: Vec<f64>,
    pub anchors: HashMap<TypedRecordId, AnchorSpring>,
    pub alignments: Vec<AlignmentConstraint>,
}

impl LayoutState {
    pub fn new() -> Self {
        Self {
            nodes: HashMap::new(),
            edges: Vec::new(),
            opt_area: None,
            alpha: 1.0,
            iteration: 0,
            energy_history: Vec::new(),
            anchors: HashMap::new(),
            alignments: Vec::new(),
        }
    }

    pub fn clear(&mut self) {
        self.nodes.clear();
        self.edges.clear();
        self.energy_history.clear();
        self.anchors.clear();
        self.alignments.clear();
        self.alpha = 1.0;
        self.iteration = 0;
    }
}
