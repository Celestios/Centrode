use flutter_rust_bridge::frb;
use crate::domain::relation_engine::geometry::{Point, Rect};
use crate::domain::styles::{EndpointShape, PortSide};

#[derive(Clone, Debug, PartialEq)]
#[frb]
pub enum PathType {
    Straight,
    BSpline,
    Orthogonal,
    CircularArc,
    SineWave,
}

#[derive(Clone, Debug, PartialEq)]
#[frb]
pub enum LabelAnchor {
    Center,
    Left,
    Right,
}

#[derive(Clone, Debug, PartialEq)]
#[frb]
pub struct ComputedRelation {
    pub id: String,
    pub path_points: Vec<Point>,
    pub path_type: PathType,
    pub start_tangent: Point,
    pub end_tangent: Point,
    pub body_widths: Vec<f64>,
    pub body_type: crate::domain::relation_engine::config::BodyType,
    pub start_endpoint: EndpointShape,
    pub end_endpoint: EndpointShape,
    pub start_direction: f64,
    pub end_direction: f64,
    pub label_position: Point,
    pub label_anchor: LabelAnchor,
    pub bbox: Rect,
    pub start_point: Point,
    pub end_point: Point,
    pub start_arrow_center: Point,
    pub end_arrow_center: Point,
    pub start_margin: f64,
    pub end_margin: f64,
    pub depends_on_nodes: Vec<String>,
    pub bundle_id: Option<String>,
    pub bundle_offset: Option<f64>,
    // PathForger additions:
    pub control_points: Vec<Point>,
    pub knots: Vec<f64>,
    pub nudge_colors: Vec<String>,
}
