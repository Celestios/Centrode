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
    pub start_margin: f64,
    pub end_margin: f64,
    pub start_arrow_center: Point,
    pub end_arrow_center: Point,
    pub end_point: Point,
    pub start_point: Point,
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


