use std::collections::HashMap;

use super::computed::PathType;
use super::config::{RelationEngineConfig, RoutingMode};
use super::geometry::{Point, Rect};
use super::input::{InputEdge, InputNode};
use super::visibility_graph::{a_star_with_params, RouteCostParams, VisibilityGraph};

pub fn route_relation(
    edge: &InputEdge,
    node_map: &HashMap<&str, &InputNode>,
    obstacles: &[Rect],
    config: &RelationEngineConfig,
) -> (Vec<Point>, PathType) {
    let from_node = match node_map.get(edge.from_node_id.as_str()) {
        Some(n) => *n,
        None => return (vec![Point::zero(), Point::zero()], PathType::Straight),
    };
    let to_node = match node_map.get(edge.to_node_id.as_str()) {
        Some(n) => *n,
        None => return (vec![Point::zero(), Point::zero()], PathType::Straight),
    };

    let to_center = to_node.center();
    let from_center = from_node.center();

    let start = match &edge.from_side {
        Some(side) => from_node.resolve_port(side, to_center),
        None => from_node.closest_port_to(to_center),
    };

    let end = match &edge.to_side {
        Some(side) => to_node.resolve_port(side, from_center),
        None => to_node.closest_port_to(from_center),
    };

    let exclude_ids: std::collections::HashSet<&str> =
        [edge.from_node_id.as_str(), edge.to_node_id.as_str()]
            .into_iter()
            .collect();

    let filtered_obstacles: Vec<Rect> = obstacles
        .iter()
        .enumerate()
        .filter(|(i, _)| {
            !exclude_ids.contains(node_map.keys().nth(*i).unwrap_or(&""))
        })
        .map(|(_, r)| *r)
        .collect();

    let routing_mode = edge
        .strategy_type
        .as_deref()
        .map(RoutingMode::from_str)
        .unwrap_or(config.routing_mode);

    let from_normal = from_node.port_normal(start);
    let to_normal = to_node.port_normal(end);

    match routing_mode {
        RoutingMode::Polyline => {
            let points = route_polyline(start, end, &filtered_obstacles, config);
            (points, PathType::Straight)
        }
        RoutingMode::Bezier => {
            let points = route_bezier(start, end, from_normal, to_normal, config);
            (points, PathType::CubicBezier)
        }
        RoutingMode::Orthogonal => {
            let points = route_orthogonal(start, end, &filtered_obstacles, config);
            (points, PathType::Orthogonal)
        }
        RoutingMode::CircularArc => {
            let points = route_circular_arc(start, end, from_normal, to_normal, config);
            (points, PathType::CircularArc)
        }
        RoutingMode::SineWave => {
            let points = route_sine_wave(start, end, config);
            (points, PathType::SineWave)
        }
    }
}

fn route_polyline(
    start: Point,
    end: Point,
    obstacles: &[Rect],
    config: &RelationEngineConfig,
) -> Vec<Point> {
    if obstacles.is_empty() {
        return vec![start, end];
    }

    let graph = VisibilityGraph::build(obstacles, start, end, config.obstacle_margin);
    let cost_params = RouteCostParams::default();
    a_star_with_params(&graph, &cost_params, Some(&start), Some(&end))
        .unwrap_or_else(|| vec![start, end])
}

fn route_bezier(
    start: Point,
    end: Point,
    from_normal: Point,
    to_normal: Point,
    config: &RelationEngineConfig,
) -> Vec<Point> {
    let distance = start.distance_to(end);
    let proj = (distance * config.bezier_projection_factor).clamp(
        config.bezier_clamp_min,
        config.bezier_clamp_max,
    );

    let cp1 = start + from_normal * proj;
    let cp2 = end + to_normal * proj;

    super::geometry::sample_cubic_bezier(start, cp1, cp2, end, 32)
}

fn route_orthogonal(
    start: Point,
    end: Point,
    obstacles: &[Rect],
    config: &RelationEngineConfig,
) -> Vec<Point> {
    let waypoints = if obstacles.is_empty() {
        vec![start, end]
    } else {
        let graph = VisibilityGraph::build(obstacles, start, end, config.obstacle_margin);
        let cost_params = RouteCostParams::default();
        a_star_with_params(&graph, &cost_params, Some(&start), Some(&end))
            .unwrap_or_else(|| vec![start, end])
    };

    let ortho_points = snap_to_orthogonal(&waypoints);

    if config.corner_radius > 1e-6 {
        super::geometry::round_corners(&ortho_points, config.corner_radius)
    } else {
        ortho_points
    }
}

fn route_circular_arc(
    start: Point,
    end: Point,
    from_normal: Point,
    to_normal: Point,
    config: &RelationEngineConfig,
) -> Vec<Point> {
    let distance = start.distance_to(end);
    let radius_factor = config.bezier_projection_factor;
    let radius = (distance * radius_factor).clamp(
        config.bezier_clamp_min,
        config.bezier_clamp_max,
    );

    let cp1 = start + from_normal * radius;
    let _cp2 = end + to_normal * radius;

    let center = three_point_circle_center(start, cp1, end);

    if let Some(c) = center {
        let r = c.distance_to(start);
        if r < 1e-6 {
            return vec![start, end];
        }

        let start_angle = (start - c).direction();
        let end_angle = (end - c).direction();

        let n = 32;
        let mut points = Vec::with_capacity(n + 1);

        let mid = start.lerp(end, 0.5);
        let to_mid = mid - c;
        let cross = (start - c).x * to_mid.y - (start - c).y * to_mid.x;

        for i in 0..=n {
            let t = i as f64 / n as f64;
            let mut angle = start_angle + (end_angle - start_angle) * t;

            if cross > 0.0 {
                if end_angle < start_angle {
                    angle = start_angle + (end_angle + std::f64::consts::TAU - start_angle) * t;
                }
            } else {
                if end_angle > start_angle {
                    angle = start_angle + (end_angle - std::f64::consts::TAU - start_angle) * t;
                }
            }

            points.push(Point::new(
                c.x + r * angle.cos(),
                c.y + r * angle.sin(),
            ));
        }

        points
    } else {
        route_bezier(start, end, from_normal, to_normal, config)
    }
}

fn three_point_circle_center(p1: Point, p2: Point, p3: Point) -> Option<Point> {
    let ax = p1.x;
    let ay = p1.y;
    let bx = p2.x;
    let by = p2.y;
    let cx = p3.x;
    let cy = p3.y;

    let d = 2.0 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by));

    if d.abs() < 1e-10 {
        return None;
    }

    let ux = ((ax * ax + ay * ay) * (by - cy)
        + (bx * bx + by * by) * (cy - ay)
        + (cx * cx + cy * cy) * (ay - by))
        / d;
    let uy = ((ax * ax + ay * ay) * (cx - bx)
        + (bx * bx + by * by) * (ax - cx)
        + (cx * cx + cy * cy) * (bx - ax))
        / d;

    Some(Point::new(ux, uy))
}

fn route_sine_wave(
    start: Point,
    end: Point,
    config: &RelationEngineConfig,
) -> Vec<Point> {
    let amplitude = config.snake_amplitude;
    let frequency = config.snake_frequency;

    let n = 64;
    let mut points = Vec::with_capacity(n + 1);

    for i in 0..=n {
        let t = i as f64 / n as f64;

        let base = start.lerp(end, t);

        let dir = end - start;
        let perp = Point::new(-dir.y, dir.x).normalized();

        let wave = (t * frequency * std::f64::consts::TAU).sin() * amplitude;

        points.push(base + perp * wave);
    }

    points
}

fn snap_to_orthogonal(waypoints: &[Point]) -> Vec<Point> {
    if waypoints.len() < 2 {
        return waypoints.to_vec();
    }

    let mut result = vec![waypoints[0]];

    for i in 0..waypoints.len() - 1 {
        let p1 = result.last().copied().unwrap();
        let p2 = waypoints[i + 1];

        if (p1.x - p2.x).abs() < 0.1 || (p1.y - p2.y).abs() < 0.1 {
            result.push(p2);
        } else {
            let corner = Point::new(p2.x, p1.y);
            result.push(corner);
            result.push(p2);
        }
    }

    result.dedup_by(|a, b| a.distance_to(*b) < 0.1);
    result
}

pub fn compute_bbox(points: &[Point]) -> Rect {
    if points.is_empty() {
        return Rect::new(0.0, 0.0, 0.0, 0.0);
    }
    let mut min_x = f64::MAX;
    let mut min_y = f64::MAX;
    let mut max_x = f64::MIN;
    let mut max_y = f64::MIN;
    for p in points {
        if p.x < min_x { min_x = p.x; }
        if p.y < min_y { min_y = p.y; }
        if p.x > max_x { max_x = p.x; }
        if p.y > max_y { max_y = p.y; }
    }
    Rect::new(min_x, min_y, max_x - min_x, max_y - min_y)
}
