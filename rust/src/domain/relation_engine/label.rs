use super::computed::PathType;
use super::config::RelationEngineConfig;
use super::geometry::{cubic_bezier_point, polyline_midpoint, Point};

pub fn compute_label_position(
    path: &[Point],
    path_type: &PathType,
    _config: &RelationEngineConfig,
) -> (Point, bool) {
    if path.is_empty() {
        return (Point::zero(), true);
    }
    if path.len() == 1 {
        return (path[0], true);
    }

    match path_type {
        PathType::CubicBezier if path.len() >= 4 => {
            let p0 = path[0];
            let p1 = path[1];
            let p2 = path[2];
            let p3 = path[3];
            let mid = cubic_bezier_point(p0, p1, p2, p3, 0.5);
            (mid, true)
        }
        PathType::CircularArc if path.len() >= 3 => {
            let mid = path[path.len() / 2];
            (mid, true)
        }
        _ => {
            let mid = polyline_midpoint(path);
            (mid, true)
        }
    }
}
