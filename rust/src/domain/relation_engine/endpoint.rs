use super::config::EndpointShapeType;
use super::config::RelationEngineConfig;
use super::geometry::Point;
use super::input::InputNode;
use crate::domain::styles::{RelationStyle, EndpointShape};

pub fn compute_endpoints(
    start_tangent: Point,
    end_tangent: Point,
    config: &RelationEngineConfig,
    style: Option<&RelationStyle>,
    from_node: Option<&InputNode>,
    to_node: Option<&InputNode>,
    start_port: Point,
    end_port: Point,
) -> (EndpointShapeType, f64, EndpointShapeType, f64) {
    let start_dir = if let Some(node) = from_node {
        let center = node.center();
        let dx = start_port.x - center.x;
        let dy = start_port.y - center.y;
        if dx.abs() > 1e-6 || dy.abs() > 1e-6 {
            dy.atan2(dx) + std::f64::consts::PI
        } else {
            start_tangent.direction() + std::f64::consts::PI
        }
    } else {
        start_tangent.direction() + std::f64::consts::PI
    };

    let end_dir = if let Some(node) = to_node {
        let center = node.center();
        let dx = end_port.x - center.x;
        let dy = end_port.y - center.y;
        if dx.abs() > 1e-6 || dy.abs() > 1e-6 {
            dy.atan2(dx) + std::f64::consts::PI
        } else {
            end_tangent.direction()
        }
    } else {
        end_tangent.direction()
    };

    let start_shape = style
        .and_then(|s| s.start_shape.as_ref())
        .map(|s| match s {
            EndpointShape::None => EndpointShapeType::None,
            EndpointShape::Arrow => EndpointShapeType::Arrow,
            EndpointShape::OpenArrow => EndpointShapeType::OpenArrow,
            EndpointShape::Circle => EndpointShapeType::Circle,
            EndpointShape::Diamond => EndpointShapeType::Diamond,
            EndpointShape::Square => EndpointShapeType::Square,
        })
        .unwrap_or(config.endpoint.default_start_shape);

    let end_shape = style
        .and_then(|s| s.end_shape.as_ref())
        .map(|s| match s {
            EndpointShape::None => EndpointShapeType::None,
            EndpointShape::Arrow => EndpointShapeType::Arrow,
            EndpointShape::OpenArrow => EndpointShapeType::OpenArrow,
            EndpointShape::Circle => EndpointShapeType::Circle,
            EndpointShape::Diamond => EndpointShapeType::Diamond,
            EndpointShape::Square => EndpointShapeType::Square,
        })
        .unwrap_or(config.endpoint.default_end_shape);

    (
        start_shape,
        start_dir,
        end_shape,
        end_dir,
    )
}

pub fn compute_tangents(path: &[Point]) -> (Point, Point) {
    if path.len() < 2 {
        return (Point::new(1.0, 0.0), Point::new(1.0, 0.0));
    }

    let start_tangent = (path[1] - path[0]).normalized();
    let end_tangent = (path[path.len() - 1] - path[path.len() - 2]).normalized();

    (start_tangent, end_tangent)
}
