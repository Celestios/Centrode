use crate::domain::id::TypedRecordId;
use crate::domain::styles::PortSide;
use flutter_rust_bridge::frb;

#[derive(Clone, Debug)]
pub struct NodePhysics {
    pub id: TypedRecordId,
    pub x: f64,
    pub y: f64,
    pub width: f64,
    pub height: f64,
    pub vx: f64,
    pub vy: f64,
}

impl NodePhysics {
    pub fn cx(&self) -> f64 {
        self.x + self.width / 2.0
    }

    pub fn cy(&self) -> f64 {
        self.y + self.height / 2.0
    }
}

#[derive(Clone, Debug)]
pub struct LayoutEdge {
    pub id: TypedRecordId,
    pub from_id: TypedRecordId,
    pub to_id: TypedRecordId,
    pub from_side: Option<PortSide>,
    pub to_side: Option<PortSide>,
}

#[frb]
#[derive(Clone, Debug)]
pub struct LayoutPatch {
    pub id: TypedRecordId,
    pub x: f64,
    pub y: f64,
}

#[frb]
#[derive(Clone, Debug)]
pub struct PortPatch {
    pub relation_id: TypedRecordId,
    pub from_side: PortSide,
    pub to_side: PortSide,
}

#[derive(Clone, Debug)]
pub struct AnchorSpring {
    pub anchor_x: f64,
    pub anchor_y: f64,
    pub strength: f64,
    pub decay_rate: f64,
}

#[frb]
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Axis {
    Horizontal,
    Vertical,
}

#[derive(Clone, Debug)]
pub struct AlignmentConstraint {
    pub node_ids: Vec<TypedRecordId>,
    pub axis: Axis,
}

#[frb]
#[derive(Clone, Debug)]
pub struct LayoutTickResult {
    pub position_patches: Vec<LayoutPatch>,
    pub port_patches: Vec<PortPatch>,
    pub converged: bool,
    pub iteration: u32,
    pub energy: f64,
}

