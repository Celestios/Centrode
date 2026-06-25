use flutter_rust_bridge::frb;

use super::config::{BodyType, EndpointShapeType};
use super::geometry::{Point, Rect};

#[derive(Debug, Clone)]
#[frb]
pub struct ComputedRelation {
    pub id: String,
    pub path_points: Vec<Point>,
    pub path_type: PathType,
    pub start_tangent: Point,
    pub end_tangent: Point,
    pub body_widths: Vec<f64>,
    pub body_type: BodyType,
    pub start_endpoint: EndpointShapeType,
    pub end_endpoint: EndpointShapeType,
    pub start_direction: f64,
    pub end_direction: f64,
    pub label_position: Point,
    pub label_anchor: LabelAnchor,
    pub bundle_id: Option<String>,
    pub bundle_offset: Option<f64>,
    pub hit_test_points: Vec<Point>,
    pub depends_on_nodes: Vec<String>,
    pub bbox: Rect,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[frb]
pub enum PathType {
    Straight,
    CubicBezier,
    QuadraticBezier,
    Orthogonal,
    CircularArc,
    SineWave,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[frb]
pub enum LabelAnchor {
    Center,
    Left,
    Right,
}

impl ComputedRelation {
    pub fn compute_bbox(&self) -> Rect {
        if self.path_points.is_empty() {
            return Rect::new(0.0, 0.0, 0.0, 0.0);
        }

        let mut min_x = f64::MAX;
        let mut min_y = f64::MAX;
        let mut max_x = f64::MIN;
        let mut max_y = f64::MIN;

        for p in &self.path_points {
            if p.x < min_x {
                min_x = p.x;
            }
            if p.y < min_y {
                min_y = p.y;
            }
            if p.x > max_x {
                max_x = p.x;
            }
            if p.y > max_y {
                max_y = p.y;
            }
        }

        Rect::new(min_x, min_y, max_x - min_x, max_y - min_y)
    }
}
