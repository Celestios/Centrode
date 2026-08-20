use crate::domain::id::TypedRecordId;
use crate::domain::styles::{PortSide, RelationStyle};
use crate::relation_engine::config::{BundlingMode, RoutingMode};
use crate::relation_engine::geometry::Rect;

#[derive(Clone, Debug)]
pub struct InputNode {
    pub id: TypedRecordId,
    pub x: f64,
    pub y: f64,
    pub width: f64,
    pub height: f64,
    pub is_obstacle: bool,
}

impl InputNode {
    pub fn bounding_box(&self) -> Rect {
        Rect::new(self.x, self.y, self.width, self.height)
    }

    pub fn outer_bounding_box(&self, margin: f64) -> Rect {
        Rect::new(
            self.x - margin,
            self.y - margin,
            self.width + 2.0 * margin,
            self.height + 2.0 * margin,
        )
    }
}

#[derive(Clone, Debug)]
pub struct InputEdge {
    pub id: TypedRecordId,
    pub from_node_id: TypedRecordId,
    pub to_node_id: TypedRecordId,
    pub from_side: Option<PortSide>,
    pub to_side: Option<PortSide>,
    pub routing_mode: Option<RoutingMode>,
    pub bundling_mode: Option<BundlingMode>,
    pub style: Option<RelationStyle>,
}
