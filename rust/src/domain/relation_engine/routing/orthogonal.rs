use crate::domain::relation_engine::geometry::{Point, Rect, is_horiz};
use crate::domain::relation_engine::config::RelationEngineConfig;
use crate::domain::relation_engine::state::CanvasState;
use crate::domain::relation_engine::computed::PathType;
use crate::domain::relation_engine::solver::visibility_graph::{a_star_with_params, RouteCostParams, VisibilityGraph};
use super::{RoutingStrategy, node_clearance};

pub struct OrthogonalRouting;

impl RoutingStrategy for OrthogonalRouting {
    fn route(
        &self,
        start: Point,
        end: Point,
        from_normal: Point,
        to_normal: Point,
        from_rect: Rect,
        to_rect: Rect,
        obstacles: &[Rect],
        config: &RelationEngineConfig,
        state: &CanvasState,
    ) -> (Vec<Point>, PathType) {
        let points = if obstacles.is_empty() {
            ortho_route(start, end, from_normal, to_normal, from_rect, to_rect)
        } else {
            obstacle_route(start, end, from_normal, to_normal, obstacles, config, state)
        };
        let points = if config.routing.corner_radius > 1e-6 {
            crate::domain::relation_engine::geometry::round_corners(&points, config.routing.corner_radius)
        } else {
            points
        };
        (points, PathType::Orthogonal)
    }
}

fn ortho_route(start: Point, end: Point, n: Point, m: Point, from_rect: Rect, to_rect: Rect) -> Vec<Point> {
    if is_horiz(n) == is_horiz(m) {
        route_parallel(start, end, n, m, from_rect, to_rect)
    } else {
        route_cross(start, end, n, m, from_rect, to_rect)
    }
}

fn route_parallel(start: Point, end: Point, n: Point, m: Point, from_rect: Rect, to_rect: Rect) -> Vec<Point> {
    let horizontal = is_horiz(n);
    let aligned = if horizontal {
        (start.y - end.y).abs()
    } else {
        (start.x - end.x).abs()
    };
    let ext = node_clearance(start, n, from_rect).max(node_clearance(end, m, to_rect));

    if n.dot(m) < -0.5 {
        if aligned < 0.1 {
            return vec![start, end];
        }
        return if horizontal {
            let mx = (start.x + end.x) / 2.0;
            vec![start, Point::new(mx, start.y), Point::new(mx, end.y), end]
        } else {
            let my = (start.y + end.y) / 2.0;
            vec![start, Point::new(start.x, my), Point::new(end.x, my), end]
        };
    }

    if horizontal {
        let mx = if n.x > 0.0 {
            start.x.max(end.x) + ext
        } else {
            start.x.min(end.x) - ext
        };
        if aligned < 0.1 {
            let node_mid_y = (from_rect.top() + from_rect.bottom()) / 2.0;
            let detour_y = if start.y < node_mid_y {
                from_rect.top() - ext
            } else {
                from_rect.bottom() + ext
            };
            return vec![
                start,
                Point::new(mx, start.y),
                Point::new(mx, detour_y),
                Point::new(end.x, detour_y),
                end,
            ];
        }
        vec![start, Point::new(mx, start.y), Point::new(mx, end.y), end]
    } else {
        let my = if n.y > 0.0 {
            start.y.max(end.y) + ext
        } else {
            start.y.min(end.y) - ext
        };
        if aligned < 0.1 {
            let node_mid_x = (from_rect.left() + from_rect.right()) / 2.0;
            let detour_x = if start.x < node_mid_x {
                from_rect.left() - ext
            } else {
                from_rect.right() + ext
            };
            return vec![
                start,
                Point::new(start.x, my),
                Point::new(detour_x, my),
                Point::new(detour_x, end.y),
                end,
            ];
        }
        vec![start, Point::new(start.x, my), Point::new(end.x, my), end]
    }
}

fn route_cross(start: Point, end: Point, n: Point, m: Point, from_rect: Rect, to_rect: Rect) -> Vec<Point> {
    let ext_s = node_clearance(start, n, from_rect);
    let ext_e = node_clearance(end, m, to_rect);
    let exit = start + n * ext_s;
    let entry = end + m * ext_e;

    if (exit.x - end.x).abs() < 0.1 {
        return vec![start, Point::new(start.x, end.y), end];
    }
    if (start.y - entry.y).abs() < 0.1 {
        return vec![start, Point::new(end.x, start.y), end];
    }

    vec![
        start,
        Point::new(exit.x, start.y),
        Point::new(exit.x, entry.y),
        Point::new(end.x, entry.y),
        end,
    ]
}

fn obstacle_route(
    start: Point, end: Point, from_normal: Point, to_normal: Point,
    obstacles: &[Rect], config: &RelationEngineConfig, state: &CanvasState,
) -> Vec<Point> {
    let port_margin = config.routing.corner_radius.max(20.0);
    let start_exit = if (end - start).dot(from_normal) >= 0.0 {
        start
    } else {
        start + from_normal * port_margin
    };
    let end_entry = if (start - end).dot(to_normal) >= 0.0 {
        end
    } else {
        end + to_normal * port_margin
    };

    let margin = config.routing.obstacle_margin;
    let min_x = start_exit.x.min(end_entry.x) - margin * 2.0;
    let max_x = start_exit.x.max(end_entry.x) + margin * 2.0;
    let min_y = start_exit.y.min(end_entry.y) - margin * 2.0;
    let max_y = start_exit.y.max(end_entry.y) + margin * 2.0;
    let route_bounds = Rect::new(min_x, min_y, max_x - min_x, max_y - min_y);

    let filtered: Vec<Rect> = obstacles
        .iter()
        .filter(|obs| obs.overlaps(&route_bounds))
        .copied()
        .collect();

    let graph = VisibilityGraph::build(&filtered, start_exit, end_entry, margin);
    let cost_params = RouteCostParams::default();
    let mut path = a_star_with_params(&graph, &cost_params, Some(&start_exit), Some(&end_entry), state)
        .unwrap_or_else(|| vec![start_exit, end_entry]);

    path.insert(0, start);
    path.push(end);
    snap_to_orthogonal(&path, from_normal, to_normal)
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

    fn rect(x: f64, y: f64, w: f64, h: f64) -> Rect {
        Rect::new(x, y, w, h)
    }

    #[test]
    fn facing_hh_direct() {
        let pts = ortho_route(
            Point::new(40.0, 50.0), Point::new(200.0, 50.0),
            Point::new(1.0, 0.0), Point::new(-1.0, 0.0),
            rect(0.0, 30.0, 40.0, 40.0), rect(200.0, 30.0, 40.0, 40.0),
        );
        assert_eq!(pts.len(), 2);
    }

    #[test]
    fn facing_hh_offset() {
        let pts = ortho_route(
            Point::new(40.0, 0.0), Point::new(200.0, 100.0),
            Point::new(1.0, 0.0), Point::new(-1.0, 0.0),
            rect(0.0, 0.0, 40.0, 40.0), rect(200.0, 80.0, 40.0, 40.0),
        );
        assert_eq!(pts.len(), 4);
        assert_eq!(pts[1].x, pts[2].x);
    }

    #[test]
    fn same_dir_hh_same_y() {
        let pts = ortho_route(
            Point::new(0.0, 100.0), Point::new(200.0, 100.0),
            Point::new(-1.0, 0.0), Point::new(-1.0, 0.0),
            rect(0.0, 50.0, 40.0, 100.0), rect(200.0, 50.0, 40.0, 100.0),
        );
        assert_eq!(pts.len(), 5, "degenerate U-turn needs perpendicular detour");
        assert!(pts[2].y < 50.0 || pts[2].y > 150.0, "detour must clear node: y={}", pts[2].y);
    }

    #[test]
    fn same_dir_left_to_right() {
        let pts = ortho_route(
            Point::new(0.0, 50.0), Point::new(200.0, 50.0),
            Point::new(1.0, 0.0), Point::new(1.0, 0.0),
            rect(0.0, 30.0, 40.0, 40.0), rect(200.0, 30.0, 40.0, 40.0),
        );
        assert!(pts.len() >= 4, "same-dir needs U-turn, got {} pts", pts.len());
        assert!(pts[1].x > 200.0, "turn should be right of both nodes: x={}", pts[1].x);
    }

    #[test]
    fn facing_vv_direct() {
        let pts = ortho_route(
            Point::new(50.0, 40.0), Point::new(50.0, 200.0),
            Point::new(0.0, 1.0), Point::new(0.0, -1.0),
            rect(30.0, 0.0, 40.0, 40.0), rect(30.0, 200.0, 40.0, 40.0),
        );
        assert_eq!(pts.len(), 2);
    }

    #[test]
    fn hv_perpendicular() {
        let pts = ortho_route(
            Point::new(40.0, 50.0), Point::new(200.0, 100.0),
            Point::new(1.0, 0.0), Point::new(0.0, 1.0),
            rect(0.0, 30.0, 40.0, 40.0), rect(200.0, 100.0, 40.0, 40.0),
        );
        assert!(pts.len() >= 3);
        assert_eq!(pts[0], Point::new(40.0, 50.0));
        assert_eq!(*pts.last().unwrap(), Point::new(200.0, 100.0));
    }

    #[test]
    fn wide_node_left_port_facing_right() {
        let pts = ortho_route(
            Point::new(0.0, 100.0), Point::new(400.0, 100.0),
            Point::new(1.0, 0.0), Point::new(1.0, 0.0),
            rect(0.0, 50.0, 200.0, 100.0), rect(400.0, 80.0, 40.0, 40.0),
        );
        assert!(pts.len() >= 4, "same-dir needs U-turn, got {} pts", pts.len());
        assert!(pts[1].x > 420.0, "turn should clear wide node: x={}", pts[1].x);
    }

    #[test]
    fn same_dir_vv_same_x() {
        let pts = ortho_route(
            Point::new(100.0, 0.0), Point::new(100.0, 200.0),
            Point::new(0.0, -1.0), Point::new(0.0, -1.0),
            rect(50.0, 0.0, 100.0, 40.0), rect(50.0, 200.0, 100.0, 40.0),
        );
        assert_eq!(pts.len(), 5, "vertical degenerate needs detour");
    }
}
