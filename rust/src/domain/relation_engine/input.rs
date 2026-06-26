use super::geometry::{Point, Rect};
use crate::domain::base_models::Coordinates;
use crate::domain::nodes::Nodes;
use crate::domain::relations::IRelation;
use crate::domain::styles::PortSide;

#[derive(Debug, Clone)]
pub struct InputNode {
    pub id: String,
    pub x: f64,
    pub y: f64,
    pub width: f64,
    pub height: f64,
}

impl InputNode {
    pub fn rect(&self) -> Rect {
        Rect::new(self.x, self.y, self.width, self.height)
    }

    pub fn center(&self) -> Point {
        Point::new(self.x + self.width / 2.0, self.y + self.height / 2.0)
    }

    pub fn resolve_port(&self, side: &PortSide, other: Point) -> Point {
        let rect = self.rect();
        match side {
            PortSide::Top => {
                let t = ((other.x - rect.left()) / rect.width).clamp(0.1, 0.9);
                Point::new(rect.left() + rect.width * t, rect.top())
            }
            PortSide::Right => {
                let t = ((other.y - rect.top()) / rect.height).clamp(0.1, 0.9);
                Point::new(rect.right(), rect.top() + rect.height * t)
            }
            PortSide::Bottom => {
                let t = ((other.x - rect.left()) / rect.width).clamp(0.1, 0.9);
                Point::new(rect.left() + rect.width * t, rect.bottom())
            }
            PortSide::Left => {
                let t = ((other.y - rect.top()) / rect.height).clamp(0.1, 0.9);
                Point::new(rect.left(), rect.top() + rect.height * t)
            }
            PortSide::TopLeft => Point::new(rect.left(), rect.top()),
            PortSide::TopRight => Point::new(rect.right(), rect.top()),
            PortSide::BottomLeft => Point::new(rect.left(), rect.bottom()),
            PortSide::BottomRight => Point::new(rect.right(), rect.bottom()),
            PortSide::Auto => self.closest_port_to(other),
        }
    }

    pub fn closest_port_to(&self, point: Point) -> Point {
        let rect = self.rect();
        let center = self.center();

        let candidates = [
            (Point::new(center.x, rect.top()), (point.y - rect.top()).abs()),
            (Point::new(rect.right(), center.y), (point.x - rect.right()).abs()),
            (Point::new(center.x, rect.bottom()), (point.y - rect.bottom()).abs()),
            (Point::new(rect.left(), center.y), (point.x - rect.left()).abs()),
        ];

        candidates
            .iter()
            .min_by(|a, b| a.1.partial_cmp(&b.1).unwrap())
            .map(|(p, _)| *p)
            .unwrap_or(center)
    }

    pub fn port_normal(&self, port_pos: Point) -> Point {
        let center = self.center();

        if (port_pos - center).length() < 1e-6 {
            return Point::new(1.0, 0.0);
        }

        let dx = (port_pos.x - center.x).abs();
        let dy = (port_pos.y - center.y).abs();

        if dx > dy {
            if port_pos.x > center.x {
                Point::new(1.0, 0.0)
            } else {
                Point::new(-1.0, 0.0)
            }
        } else {
            if port_pos.y > center.y {
                Point::new(0.0, 1.0)
            } else {
                Point::new(0.0, -1.0)
            }
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
                })
            }
            _ => None,
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
    pub strategy_type: Option<String>,
}

impl InputEdge {
    pub fn from_domain(rel: &IRelation) -> Self {
        let layout = rel.fields.resolved_layout.as_ref().or(rel.fields.layout.as_ref());
        InputEdge {
            id: rel.key.clone(),
            from_node_id: rel.in_.key.clone(),
            to_node_id: rel.out.key.clone(),
            from_side: layout.and_then(|l| l.from_side.clone()),
            to_side: layout.and_then(|l| l.to_side.clone()),
            strategy_type: layout.map(|l| l.strategy_type.clone()),
        }
    }
}
