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

    let mid = polyline_midpoint(path);
    (mid, true)
}
