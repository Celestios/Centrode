pub mod endpoint;
pub mod body;

use super::config::EndpointShapeType;
use super::geometry::Point;

#[derive(Debug, Clone)]
pub struct EndpointResult {
    pub position: Point,
    pub direction: f64,
    pub shape: EndpointShapeType,
}

#[derive(Debug, Clone)]
pub struct BodyResult {
    pub point_count: usize,
    pub total_points: usize,
}
