use crate::domain::nodes::{IsNode, Nodes};
use crate::domain::relations::IRelation;
use crate::relation_engine::config::{BundlingMode, RoutingMode};
use crate::relation_engine::geometry;
pub use crate::relation_engine::types::{InputEdge, InputNode};

impl InputNode {
    pub fn from_domain(node: &Nodes) -> Option<Self> {
        let is_obstacle = match node {
            Nodes::INode(_) | Nodes::TaskNode(_) => true,
            _ => false,
        };
        let id = node.id().clone();
        let pos = node.position();
        let (x, y) = (pos.x as f64, pos.y as f64);
        let (width, height) = match node {
            Nodes::INode(n) => (n.size.width as f64, n.size.height as f64),
            Nodes::TaskNode(n) => (n.size.width as f64, n.size.height as f64),
            Nodes::CommentNode(n) => (n.size.width as f64, n.size.height as f64),
            Nodes::DrawingNode(n) => (n.size.width as f64, n.size.height as f64),
            Nodes::ShapeNode(n) => (n.size.width as f64, n.size.height as f64),
            Nodes::FrameNode(n) => (n.size.width as f64, n.size.height as f64),
            Nodes::MediaNode(n) => (n.size.width as f64, n.size.height as f64),
            Nodes::InterNode(_) => (0.0, 0.0),
        };
        Some(Self {
            id,
            x,
            y,
            width,
            height,
            is_obstacle,
        })
    }
}

impl InputEdge {
    pub fn from_domain(rel: &IRelation) -> Self {
        let layout = rel
            .fields
            .layout
            .as_ref()
            .or(rel.fields.resolved_layout.as_ref());
        let style = rel
            .fields
            .style
            .as_ref()
            .or(rel.fields.resolved_style.as_ref());

        let from_side = layout.and_then(|l| l.from_side.clone());
        let to_side = layout.and_then(|l| l.to_side.clone());

        let control_point_1 = layout.and_then(|l| {
            l.control_point_1
                .as_ref()
                .map(|cp| geometry::Point::new(cp.x, cp.y))
        });
        let control_point_2 = layout.and_then(|l| {
            l.control_point_2
                .as_ref()
                .map(|cp| geometry::Point::new(cp.x, cp.y))
        });

        let routing_mode = layout.and_then(|l| match l.strategy_type.as_str() {
            "bspline" => Some(RoutingMode::BSpline),
            "bezier" => Some(RoutingMode::Bezier {
                control_point_1,
                control_point_2,
            }),
            "sinewave" | "sine_wave" => Some(RoutingMode::SineWave {
                control_point_1,
                control_point_2,
            }),
            "orthogonal" => Some(RoutingMode::Orthogonal),
            "octilinear" => Some(RoutingMode::Octilinear),
            _ => Some(RoutingMode::Polyline),
        });

        let bundling_mode = style.map(|s| {
            if s.body_strategy == "bundled" {
                BundlingMode::SharedEndpoint
            } else {
                BundlingMode::None
            }
        });

        Self {
            id: rel.key.clone(),
            from_node_id: rel.in_.clone(),
            to_node_id: rel.out.clone(),
            from_side,
            to_side,
            routing_mode,
            bundling_mode,
            style: style.cloned(),
        }
    }
}
