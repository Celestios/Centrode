use std::collections::HashMap;

use super::geometry::{Point, Rect};
use super::config::{RoutingMode, BundlingMode};
use crate::domain::base_models::Coordinates;
use crate::domain::nodes::Nodes;
use crate::domain::relations::IRelation;
use crate::domain::styles::{PortSide, PortType, RelationStyle};

#[derive(Debug, Clone)]
pub struct InputNode {
    pub id: String,
    pub x: f64,
    pub y: f64,
    pub width: f64,
    pub height: f64,
    pub is_obstacle: bool,
}

#[derive(Debug, Clone)]
pub struct InputPort {
    pub position: Point,
    pub side: PortSide,
    pub port_type: PortType,
}

#[derive(Debug, Clone)]
pub struct ResolvedPorts {
    pub start: InputPort,
    pub end: InputPort,
    pub start_normal: Point,
    pub end_normal: Point,
    pub start_exit: Point,
    pub end_exit: Point,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Side {
    Start,
    End,
}

impl InputNode {
    pub fn rect(&self) -> Rect {
        Rect::new(self.x, self.y, self.width, self.height)
    }

    pub fn center(&self) -> Point {
        Point::new(self.x + self.width / 2.0, self.y + self.height / 2.0)
    }

    pub fn resolve_port(&self, side: &PortSide, other: Point) -> InputPort {
        let rect = self.rect();
        match side {
            PortSide::Top => InputPort {
                position: Point::new(rect.left() + rect.width * 0.5, rect.top()),
                side: PortSide::Top,
                port_type: PortType::Middle,
            },
            PortSide::Right => InputPort {
                position: Point::new(rect.right(), rect.top() + rect.height * 0.5),
                side: PortSide::Right,
                port_type: PortType::Middle,
            },
            PortSide::Bottom => InputPort {
                position: Point::new(rect.left() + rect.width * 0.5, rect.bottom()),
                side: PortSide::Bottom,
                port_type: PortType::Middle,
            },
            PortSide::Left => InputPort {
                position: Point::new(rect.left(), rect.top() + rect.height * 0.5),
                side: PortSide::Left,
                port_type: PortType::Middle,
            },
            PortSide::TopLeft => InputPort {
                position: Point::new(rect.left(), rect.top()),
                side: PortSide::TopLeft,
                port_type: PortType::Corner,
            },
            PortSide::TopRight => InputPort {
                position: Point::new(rect.right(), rect.top()),
                side: PortSide::TopRight,
                port_type: PortType::Corner,
            },
            PortSide::BottomLeft => InputPort {
                position: Point::new(rect.left(), rect.bottom()),
                side: PortSide::BottomLeft,
                port_type: PortType::Corner,
            },
            PortSide::BottomRight => InputPort {
                position: Point::new(rect.right(), rect.bottom()),
                side: PortSide::BottomRight,
                port_type: PortType::Corner,
            },
            PortSide::Auto => self.closest_port_to(other),
        }
    }

    pub fn closest_port_to(&self, point: Point) -> InputPort {
        let rect = self.rect();
        let center = self.center();

        let candidates = [
            (Point::new(center.x, rect.top()), PortSide::Top, PortType::Middle),
            (Point::new(rect.right(), center.y), PortSide::Right, PortType::Middle),
            (Point::new(center.x, rect.bottom()), PortSide::Bottom, PortType::Middle),
            (Point::new(rect.left(), center.y), PortSide::Left, PortType::Middle),
            (Point::new(rect.left(), rect.top()), PortSide::TopLeft, PortType::Corner),
            (Point::new(rect.right(), rect.top()), PortSide::TopRight, PortType::Corner),
            (Point::new(rect.left(), rect.bottom()), PortSide::BottomLeft, PortType::Corner),
            (Point::new(rect.right(), rect.bottom()), PortSide::BottomRight, PortType::Corner),
        ];

        let best = candidates
            .into_iter()
            .min_by(|a, b| {
                a.0.distance_sq(point)
                    .partial_cmp(&b.0.distance_sq(point))
                    .unwrap()
            })
            .unwrap_or((center, PortSide::Auto, PortType::Middle));

        InputPort {
            position: best.0,
            side: best.1,
            port_type: best.2,
        }
    }

    pub fn from_domain(node: &Nodes) -> Option<Self> {
        match node {
            Nodes::INode(n) => {
                let id = n.id.key.clone();
                let pos = n.position.clone();
                let size = n.size.clone();
                Some(InputNode {
                    id,
                    x: pos.x as f64,
                    y: pos.y as f64,
                    width: size.width as f64,
                    height: size.height as f64,
                    is_obstacle: true,
                })
            }
            Nodes::TaskNode(n) => {
                let id = n.id.key.clone();
                let pos = Coordinates { x: 0, y: 0 };
                let size = n.size.clone();
                Some(InputNode {
                    id,
                    x: pos.x as f64,
                    y: pos.y as f64,
                    width: size.width as f64,
                    height: size.height as f64,
                    is_obstacle: true,
                })
            }
            Nodes::DrawingNode(n) => {
                let id = n.id.key.clone();
                let size = n.size.clone();
                Some(InputNode {
                    id,
                    x: 0.0,
                    y: 0.0,
                    width: size.width as f64,
                    height: size.height as f64,
                    is_obstacle: false,
                })
            }
            Nodes::FrameNode(n) => {
                let id = n.id.key.clone();
                let size = n.size.clone();
                Some(InputNode {
                    id,
                    x: 0.0,
                    y: 0.0,
                    width: size.width as f64,
                    height: size.height as f64,
                    is_obstacle: false,
                })
            }
            _ => None,
        }
    }
}

pub fn normal_for_side(side: &PortSide) -> Point {
    match side {
        PortSide::Top => Point::new(0.0, -1.0),
        PortSide::Right => Point::new(1.0, 0.0),
        PortSide::Bottom => Point::new(0.0, 1.0),
        PortSide::Left => Point::new(-1.0, 0.0),
        PortSide::TopLeft => Point::new(-1.0, -1.0).normalized(),
        PortSide::TopRight => Point::new(1.0, -1.0).normalized(),
        PortSide::BottomLeft => Point::new(-1.0, 1.0).normalized(),
        PortSide::BottomRight => Point::new(1.0, 1.0).normalized(),
        PortSide::Auto => Point::new(1.0, 0.0),
    }
}

pub fn resolve_orthogonal_normal(side: &PortSide, start: Point, end: Point) -> Point {
    let dx = end.x - start.x;
    let dy = end.y - start.y;
    match side {
        PortSide::Top => Point::new(0.0, -1.0),
        PortSide::Right => Point::new(1.0, 0.0),
        PortSide::Bottom => Point::new(0.0, 1.0),
        PortSide::Left => Point::new(-1.0, 0.0),
        PortSide::TopLeft => {
            if dx.abs() > dy.abs() {
                Point::new(-1.0, 0.0)
            } else {
                Point::new(0.0, -1.0)
            }
        }
        PortSide::TopRight => {
            if dx.abs() > dy.abs() {
                Point::new(1.0, 0.0)
            } else {
                Point::new(0.0, -1.0)
            }
        }
        PortSide::BottomLeft => {
            if dx.abs() > dy.abs() {
                Point::new(-1.0, 0.0)
            } else {
                Point::new(0.0, 1.0)
            }
        }
        PortSide::BottomRight => {
            if dx.abs() > dy.abs() {
                Point::new(1.0, 0.0)
            } else {
                Point::new(0.0, 1.0)
            }
        }
        PortSide::Auto => {
            Point::new(1.0, 0.0)
        }
    }
}

#[derive(Debug, Clone)]
pub struct InputEdge {
    pub id: String,
    pub from_node_id: String,
    pub to_node_id: String,
    pub from_side: Option<PortSide>,
    pub to_side: Option<PortSide>,
    pub routing_mode: Option<RoutingMode>,
    pub bundling_mode: Option<BundlingMode>,
    pub style: Option<RelationStyle>,
}

pub fn resolve_edge_ports<'a>(
    edge: &InputEdge,
    node_map: &'a HashMap<&str, &'a InputNode>,
) -> Option<(InputPort, InputPort)> {
    let from_node = node_map.get(edge.from_node_id.as_str())?;
    let to_node = node_map.get(edge.to_node_id.as_str())?;
    let to_center = to_node.center();
    let from_center = from_node.center();

    let start_port = match &edge.from_side {
        Some(side) => from_node.resolve_port(side, to_center),
        None => from_node.closest_port_to(to_center),
    };
    let end_port = match &edge.to_side {
        Some(side) => to_node.resolve_port(side, from_center),
        None => to_node.closest_port_to(from_center),
    };

    Some((start_port, end_port))
}

pub fn resolve_normal(side: &PortSide, port_pos: Point, other_center: Point, mode: RoutingMode) -> Point {
    match mode {
        RoutingMode::Orthogonal => resolve_orthogonal_normal_from_side(side, port_pos, other_center),
        _ => normal_for_side(side),
    }
}

fn resolve_orthogonal_normal_from_side(side: &PortSide, port: Point, other: Point) -> Point {
    match side {
        PortSide::Top => Point::new(0.0, -1.0),
        PortSide::Right => Point::new(1.0, 0.0),
        PortSide::Bottom => Point::new(0.0, 1.0),
        PortSide::Left => Point::new(-1.0, 0.0),
        PortSide::TopLeft => {
            if (other.x - port.x).abs() <= (other.y - port.y).abs() {
                Point::new(-1.0, 0.0)
            } else {
                Point::new(0.0, -1.0)
            }
        }
        PortSide::TopRight => {
            if (other.x - port.x).abs() <= (other.y - port.y).abs() {
                Point::new(1.0, 0.0)
            } else {
                Point::new(0.0, -1.0)
            }
        }
        PortSide::BottomLeft => {
            if (other.x - port.x).abs() <= (other.y - port.y).abs() {
                Point::new(-1.0, 0.0)
            } else {
                Point::new(0.0, 1.0)
            }
        }
        PortSide::BottomRight => {
            if (other.x - port.x).abs() <= (other.y - port.y).abs() {
                Point::new(1.0, 0.0)
            } else {
                Point::new(0.0, 1.0)
            }
        }
        PortSide::Auto => Point::new(1.0, 0.0),
    }
}

pub fn compute_extension(from_node: &InputNode, to_node: &InputNode, grid_size: f64, extension_min: f64, extension_scale: f64) -> f64 {
    let node_dim = from_node.width.min(from_node.height)
        .min(to_node.width).min(to_node.height);
    let raw = (node_dim * extension_scale).max(extension_min);
    (raw / grid_size).ceil() * grid_size
}

pub fn resolve_edge_ports_full(
    edge: &InputEdge,
    node_map: &HashMap<&str, &InputNode>,
    routing_mode: RoutingMode,
    extension_length: f64,
) -> Option<ResolvedPorts> {
    let from_node = node_map.get(edge.from_node_id.as_str())?;
    let to_node = node_map.get(edge.to_node_id.as_str())?;
    let to_center = to_node.center();
    let from_center = from_node.center();

    let start = match &edge.from_side {
        Some(side) => from_node.resolve_port(side, to_center),
        None => from_node.closest_port_to(to_center),
    };
    let end = match &edge.to_side {
        Some(side) => to_node.resolve_port(side, from_center),
        None => to_node.closest_port_to(from_center),
    };

    let start_normal = resolve_normal(&start.side, start.position, to_center, routing_mode);
    let end_normal = resolve_normal(&end.side, end.position, from_center, routing_mode);

    let start_exit = start.position + start_normal * extension_length;
    let end_exit = end.position + end_normal * extension_length;

    Some(ResolvedPorts { start, end, start_normal, end_normal, start_exit, end_exit })
}

impl InputEdge {
    pub fn from_domain(rel: &IRelation) -> Self {
        let layout = rel.fields.resolved_layout.as_ref().or(rel.fields.layout.as_ref());
        let style = rel.fields.resolved_style.as_ref().or(rel.fields.style.as_ref());
        
        let routing_mode = layout.map(|l| RoutingMode::from_str(&l.strategy_type));
        let bundling_mode = style.as_ref().map(|s| {
            match s.body_strategy.as_str() {
                "bundled" => BundlingMode::SharedEndpoint,
                _ => BundlingMode::None,
            }
        });

        InputEdge {
            id: rel.key.clone(),
            from_node_id: rel.in_.key.clone(),
            to_node_id: rel.out.key.clone(),
            from_side: layout.and_then(|l| l.from_side.clone()),
            to_side: layout.and_then(|l| l.to_side.clone()),
            routing_mode,
            bundling_mode,
            style: style.cloned(),
        }
    }
}
