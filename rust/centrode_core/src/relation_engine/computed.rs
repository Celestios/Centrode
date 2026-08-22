use crate::domain::id::TypedRecordId;
use crate::relation_engine::config;
use crate::relation_engine::endpoint_shapes::EndpointShape;
use crate::relation_engine::geometry::{Point, Rect};
use flutter_rust_bridge::frb;

#[frb(non_opaque)]
#[derive(Clone, Debug, PartialEq)]
pub enum PathType {
    Straight,
    BSpline,
    Orthogonal,
    Bezier,
    SineWave,
}

#[frb(non_opaque)]
#[derive(Clone, Debug, PartialEq)]
pub enum LabelAnchor {
    Center,
    Left,
    Right,
}

#[frb(non_opaque)]
#[derive(Clone, Debug, PartialEq)]
pub struct ComputedRelation {
    pub id: TypedRecordId,
    pub path_points: Vec<Point>,
    pub path_type: PathType,
    pub start_tangent: Point,
    pub end_tangent: Point,
    pub body_widths: Vec<f64>,
    pub body_type: config::BodyType,
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
    pub depends_on_nodes: Vec<TypedRecordId>,
    pub bundle_id: Option<String>,
    pub bundle_offset: Option<f64>,
    // PathForger additions:
    pub control_points: Vec<Point>,
    pub knots: Vec<f64>,
    pub nudge_colors: Vec<String>,
    pub hit_test_points: Vec<Point>,
    pub compose_active: bool,
    // Pre-computed endpoint shape polygons (world coordinates)
    pub start_shape_path: Vec<Point>,
    pub end_shape_path: Vec<Point>,
    pub start_shape_filled: bool,
    pub end_shape_filled: bool,
    // Handle positions inset from endpoint shapes
    pub start_handle_pos: Point,
    pub end_handle_pos: Point,
}

impl ComputedRelation {
    pub fn new_basic(id: TypedRecordId, path_points: Vec<Point>, path_type: PathType) -> Self {
        Self {
            id,
            path_points,
            path_type,
            start_tangent: Point::new(0.0, 0.0),
            end_tangent: Point::new(0.0, 0.0),
            body_widths: vec![],
            body_type: config::BodyType::Uniform,
            start_endpoint: EndpointShape::None,
            end_endpoint: EndpointShape::None,
            start_direction: 0.0,
            end_direction: 0.0,
            label_position: Point::new(0.0, 0.0),
            label_anchor: LabelAnchor::Center,
            bbox: Rect::new(0.0, 0.0, 0.0, 0.0),
            start_point: Point::new(0.0, 0.0),
            end_point: Point::new(0.0, 0.0),
            start_arrow_center: Point::new(0.0, 0.0),
            end_arrow_center: Point::new(0.0, 0.0),
            start_margin: 0.0,
            end_margin: 0.0,
            depends_on_nodes: vec![],
            bundle_id: None,
            bundle_offset: None,
            control_points: vec![],
            knots: vec![],
            nudge_colors: vec![],
            hit_test_points: vec![],
            compose_active: false,
            start_shape_path: vec![],
            end_shape_path: vec![],
            start_shape_filled: false,
            end_shape_filled: false,
            start_handle_pos: Point::new(0.0, 0.0),
            end_handle_pos: Point::new(0.0, 0.0),
        }
    }
}
