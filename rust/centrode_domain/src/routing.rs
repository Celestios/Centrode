use crate::styles::EndpointShape;
use surrealdb::types::SurrealValue;

#[derive(Clone, Copy, Debug, PartialEq, SurrealValue)]
pub struct Point {
    pub x: f64,
    pub y: f64,
}

impl Point {
    pub fn new(x: f64, y: f64) -> Self {
        Self { x, y }
    }
}

#[derive(Clone, Debug, PartialEq, SurrealValue)]
#[non_exhaustive]
pub enum RoutingMode {
    Polyline,
    BSpline,
    Orthogonal,
    Octilinear,
    Bezier {
        control_point_1: Option<Point>,
        control_point_2: Option<Point>,
    },
    SineWave {
        control_point_1: Option<Point>,
        control_point_2: Option<Point>,
    },
}
