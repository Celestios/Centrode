use super::config::EndpointShapeType;
use super::config::RelationEngineConfig;
use super::geometry::Point;

pub fn compute_endpoints(
    start_tangent: Point,
    end_tangent: Point,
    config: &RelationEngineConfig,
) -> (EndpointShapeType, f64, EndpointShapeType, f64) {
    let start_dir = start_tangent.direction();
    let end_dir = end_tangent.direction();
    (
        config.default_start_shape,
        start_dir,
        config.default_end_shape,
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
