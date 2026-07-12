use crate::domain::relation_engine::geometry::{Point, is_horiz, round_corners};
use crate::domain::relation_engine::config::RelationEngineConfig;
use crate::domain::relation_engine::computed::PathType;
use crate::domain::relation_engine::input::{ResolvedPorts, Side};
use super::{RoutingStrategy, TransitionInput};

pub struct OrthogonalRouting {}

impl RoutingStrategy for OrthogonalRouting {
    fn compute_transition(
        &self,
        input: &TransitionInput,
        _config: &RelationEngineConfig,
    ) -> Vec<Point> {
        match input.side {
            Side::Start => {
                let stub_exit = input.stub_exit;
                let body_start = input.body_start;
                if (stub_exit.x - body_start.x).abs() < 0.1 || (stub_exit.y - body_start.y).abs() < 0.1 {
                    vec![]
                } else {
                    vec![Point::new(body_start.x, stub_exit.y)]
                }
            }
            Side::End => {
                let body_end = input.body_end;
                let stub_entry = input.stub_entry;
                if (body_end.x - stub_entry.x).abs() < 0.1 || (body_end.y - stub_entry.y).abs() < 0.1 {
                    vec![]
                } else {
                    vec![Point::new(stub_entry.x, body_end.y)]
                }
            }
        }
    }

    fn compute_body(
        &self, waypoints: &[Point], ports: &ResolvedPorts, _config: &RelationEngineConfig,
    ) -> Vec<Point> {
        snap_to_orthogonal(waypoints, ports.start_normal, ports.end_normal)
    }

    fn post_process(&self, path: &mut Vec<Point>, config: &RelationEngineConfig) {
        if config.routing.corner_radius > 1e-6 {
            *path = round_corners(path, config.routing.corner_radius);
        }
    }

    fn path_type(&self) -> PathType { PathType::Orthogonal }
}

fn snap_to_orthogonal(waypoints: &[Point], from_normal: Point, to_normal: Point) -> Vec<Point> {
    if waypoints.len() < 2 {
        return waypoints.to_vec();
    }
    if waypoints.len() == 2 {
        let p1 = waypoints[0];
        let p2 = waypoints[1];
        if (p1.x - p2.x).abs() < 0.1 || (p1.y - p2.y).abs() < 0.1 {
            return waypoints.to_vec();
        }
        let sh = is_horiz(from_normal);
        let eh = is_horiz(to_normal);
        return match (sh, eh) {
            (true, true) => {
                let mx = (p1.x + p2.x) / 2.0;
                vec![p1, Point::new(mx, p1.y), Point::new(mx, p2.y), p2]
            }
            (false, false) => {
                let my = (p1.y + p2.y) / 2.0;
                vec![p1, Point::new(p1.x, my), Point::new(p2.x, my), p2]
            }
            (true, false) => vec![p1, Point::new(p2.x, p1.y), p2],
            (false, true) => vec![p1, Point::new(p1.x, p2.y), p2],
        };
    }

    let mut result = vec![waypoints[0]];
    for i in 0..waypoints.len() - 1 {
        let p1 = result.last().copied().unwrap();
        let p2 = waypoints[i + 1];
        if (p1.x - p2.x).abs() < 0.1 || (p1.y - p2.y).abs() < 0.1 {
            result.push(p2);
        } else {
            let first_horizontal = if i == 0 {
                is_horiz(from_normal)
            } else if i + 1 == waypoints.len() - 2 {
                !is_horiz(to_normal)
            } else {
                let prev = result[result.len() - 2];
                let d = p1 - prev;
                d.y.abs() > d.x.abs()
            };
            let corner = if first_horizontal {
                Point::new(p2.x, p1.y)
            } else {
                Point::new(p1.x, p2.y)
            };
            result.push(corner);
            result.push(p2);
        }
    }
    result.dedup_by(|a, b| a.distance_to(*b) < 0.1);
    result
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::domain::relation_engine::geometry::Rect;

    fn rect(x: f64, y: f64, w: f64, h: f64) -> Rect {
        Rect::new(x, y, w, h)
    }

    #[test]
    fn snap_two_points_hh() {
        let pts = snap_to_orthogonal(
            &[Point::new(0.0, 0.0), Point::new(100.0, 0.0)],
            Point::new(1.0, 0.0), Point::new(-1.0, 0.0),
        );
        assert_eq!(pts.len(), 2);
    }

    #[test]
    fn snap_two_points_offset() {
        let pts = snap_to_orthogonal(
            &[Point::new(0.0, 0.0), Point::new(100.0, 50.0)],
            Point::new(1.0, 0.0), Point::new(-1.0, 0.0),
        );
        assert!(pts.len() >= 3);
        for seg in pts.windows(2) {
            let dx = (seg[0].x - seg[1].x).abs();
            let dy = (seg[0].y - seg[1].y).abs();
            assert!(dx < 0.1 || dy < 0.1, "Segment not axis-aligned: {:?}", seg);
        }
    }

    #[test]
    fn snap_two_points_vv() {
        let pts = snap_to_orthogonal(
            &[Point::new(0.0, 0.0), Point::new(0.0, 100.0)],
            Point::new(0.0, 1.0), Point::new(0.0, -1.0),
        );
        assert_eq!(pts.len(), 2);
    }

    #[test]
    fn snap_three_points() {
        let pts = snap_to_orthogonal(
            &[Point::new(0.0, 0.0), Point::new(50.0, 50.0), Point::new(100.0, 0.0)],
            Point::new(1.0, 0.0), Point::new(-1.0, 0.0),
        );
        assert!(pts.len() >= 3);
        for seg in pts.windows(2) {
            let dx = (seg[0].x - seg[1].x).abs();
            let dy = (seg[0].y - seg[1].y).abs();
            assert!(dx < 0.1 || dy < 0.1, "Segment not axis-aligned: {:?}", seg);
        }
    }
}
