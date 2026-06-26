use std::collections::HashMap;

use super::body::compute_body_widths;
use super::bundling::{bundle_edges, BundlingStrategy};
use super::computed::{ComputedRelation, LabelAnchor, PathType};
use super::config::{BodyType, EndpointShapeType, RelationEngineConfig, RoutingMode};
use super::crossing::minimize_crossings;
use super::endpoint::{compute_endpoints, compute_tangents};
use super::geometry::{Point, Rect};
use super::incremental::IncrementalState;
use super::label::compute_label_position;
use super::nudging::{nudge_edges, NudgeConfig};
use super::visibility_graph::{a_star_with_params, RouteCostParams, VisibilityGraph};
use super::input::{InputEdge, InputNode};

pub struct RelationEngine;

impl RelationEngine {
    pub fn compute_relations(
        nodes: &[InputNode],
        edges: &[InputEdge],
        config: &RelationEngineConfig,
        relation_ids: Option<&[String]>,
    ) -> Vec<ComputedRelation> {
        let node_map: HashMap<&str, &InputNode> =
            nodes.iter().map(|n| (n.id.as_str(), n)).collect();

        let obstacles: Vec<Rect> = nodes.iter().map(|n| n.rect()).collect();

        let edges_to_compute: Vec<&InputEdge> = if let Some(ids) = relation_ids {
            edges.iter().filter(|e| ids.contains(&e.id)).collect()
        } else {
            edges.iter().collect()
        };

        // Phase 1: Route each edge individually
        let mut results: Vec<ComputedRelation> = edges_to_compute
            .iter()
            .map(|edge| compute_single_relation(edge, &node_map, &obstacles, config))
            .collect();

        // Phase 2: Bundle edges sharing endpoints or proximity
        let bundling_strategy = match config.bundling_mode {
            super::config::BundlingMode::SharedEndpoint => BundlingStrategy::SharedEndpoint,
            super::config::BundlingMode::Proximity => BundlingStrategy::Proximity {
                threshold: config.bundling_threshold,
            },
            super::config::BundlingMode::None => BundlingStrategy::None,
        };

        if !matches!(bundling_strategy, BundlingStrategy::None) && results.len() >= 2 {
            let paths: Vec<Vec<Point>> = results.iter().map(|r| r.path_points.clone()).collect();
            let edge_ids: Vec<String> = results.iter().map(|r| r.id.clone()).collect();
            let from_ids: Vec<String> = edges_to_compute.iter().map(|e| e.from_node_id.clone()).collect();
            let to_ids: Vec<String> = edges_to_compute.iter().map(|e| e.to_node_id.clone()).collect();

            let bundling_result = bundle_edges(
                &edge_ids,
                &paths,
                &from_ids,
                &to_ids,
                &bundling_strategy,
                2.0,
            );

            // Apply bundle assignments to results
            for result in &mut results {
                if let Some((bundle_id, offset)) = bundling_result.edge_assignments.get(&result.id) {
                    result.bundle_id = Some(bundle_id.clone());
                    result.bundle_offset = Some(*offset);
                }
            }
        }

        // Phase 3: Nudge overlapping edges apart
        if config.nudging_enabled && results.len() >= 2 {
            let nudge_config = NudgeConfig {
                enabled: true,
                min_separation: config.nudging_distance,
                nudge_final_segments: true,
            };

            let mut paths: Vec<Vec<Point>> = results.iter().map(|r| r.path_points.clone()).collect();
            let edge_ids: Vec<String> = results.iter().map(|r| r.id.clone()).collect();
            let from_ids: Vec<String> = edges_to_compute.iter().map(|e| e.from_node_id.clone()).collect();
            let to_ids: Vec<String> = edges_to_compute.iter().map(|e| e.to_node_id.clone()).collect();

            nudge_edges(&mut paths, &edge_ids, &from_ids, &to_ids, &nudge_config);

            // Update results with nudged paths
            for (i, result) in results.iter_mut().enumerate() {
                result.path_points = paths[i].clone();
                result.bbox = compute_bbox(&result.path_points);
            }
        }

        // Phase 4: Minimize crossings
        if config.crossing_minimization && results.len() >= 2 {
            let mut paths: Vec<Vec<Point>> = results.iter().map(|r| r.path_points.clone()).collect();
            let edge_ids: Vec<String> = results.iter().map(|r| r.id.clone()).collect();

            let reordered_ids = minimize_crossings(&mut paths, &edge_ids, 20);

            // Rebuild results in the new order, recomputing tangents, endpoints, etc.
            let id_to_result: HashMap<String, ComputedRelation> =
                results.into_iter().map(|r| (r.id.clone(), r)).collect();

            results = reordered_ids
                .iter()
                .filter_map(|id| id_to_result.get(id).cloned())
                .collect();

            for result in &mut results {
                // Find the reordered path for this result
                if let Some(idx) = reordered_ids.iter().position(|rid| rid == &result.id) {
                    result.path_points = paths[idx].clone();
                    let (start_tangent, end_tangent) = compute_tangents(&result.path_points);
                    result.start_tangent = start_tangent;
                    result.end_tangent = end_tangent;

                    let (start_shape, start_dir, end_shape, end_dir) =
                        compute_endpoints(start_tangent, end_tangent, config);
                    result.start_endpoint = start_shape;
                    result.start_direction = start_dir;
                    result.end_endpoint = end_shape;
                    result.end_direction = end_dir;

                    result.body_widths = compute_body_widths(
                        &result.path_points,
                        &result.body_type,
                        2.0,
                        config,
                    );
                    let (label_pos, _) = compute_label_position(
                        &result.path_points,
                        &result.path_type,
                        config,
                    );
                    result.label_position = label_pos;
                    result.bbox = compute_bbox(&result.path_points);
                }
            }
        }

        results
    }

    /// Compute relations with incremental invalidation.
    ///
    /// Uses the incremental state to determine which relations need recomputation.
    /// Returns only the changed relations.
    pub fn compute_incremental(
        nodes: &[InputNode],
        edges: &[InputEdge],
        config: &RelationEngineConfig,
        incremental: &mut IncrementalState,
    ) -> Vec<ComputedRelation> {
        if !incremental.has_dirty() {
            return Vec::new();
        }

        let dirty_ids = incremental.dirty_relation_ids(&HashMap::new());
        incremental.clear_dirty();

        if dirty_ids.is_empty() {
            return Vec::new();
        }

        let results = Self::compute_relations(
            nodes,
            edges,
            config,
            Some(&dirty_ids),
        );

        // Update incremental state with new dependencies and bboxes
        for result in &results {
            incremental.register(
                result.id.clone(),
                result.depends_on_nodes.clone(),
                result.bbox.clone(),
            );
        }

        results
    }
}

fn compute_single_relation(
    edge: &InputEdge,
    node_map: &HashMap<&str, &InputNode>,
    obstacles: &[Rect],
    config: &RelationEngineConfig,
) -> ComputedRelation {
    let from_node = match node_map.get(edge.from_node_id.as_str()) {
        Some(n) => *n,
        None => return empty_computed_relation(&edge.id, &edge.from_node_id, &edge.to_node_id),
    };
    let to_node = match node_map.get(edge.to_node_id.as_str()) {
        Some(n) => *n,
        None => return empty_computed_relation(&edge.id, &edge.from_node_id, &edge.to_node_id),
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

    let (path_points, path_type) = match routing_mode {
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
    };

    let (start_tangent, end_tangent) = compute_tangents(&path_points);
    let (start_shape, start_dir, end_shape, end_dir) =
        compute_endpoints(start_tangent, end_tangent, config);

    let body_type = config.default_body_type;
    let base_width = 2.0;
    let body_widths = compute_body_widths(&path_points, &body_type, base_width, config);

    let (label_pos, _) = compute_label_position(&path_points, &path_type, config);

    let depends_on_nodes = vec![
        edge.from_node_id.clone(),
        edge.to_node_id.clone(),
    ];

    let bbox = compute_bbox(&path_points);

    ComputedRelation {
        id: edge.id.clone(),
        path_points,
        path_type,
        start_tangent,
        end_tangent,
        body_widths,
        body_type,
        start_endpoint: start_shape,
        end_endpoint: end_shape,
        start_direction: start_dir,
        end_direction: end_dir,
        label_position: label_pos,
        label_anchor: LabelAnchor::Center,
        bundle_id: None,
        bundle_offset: None,
        hit_test_points: Vec::new(),
        depends_on_nodes,
        bbox,
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

/// Route via a circular arc through three points: start, a control point, and end.
/// The control point is derived from port normals to create a smooth arc.
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

    // Control point is the intersection of normals from start and end
    let cp1 = start + from_normal * radius;
    let _cp2 = end + to_normal * radius;

    // Approximate the circle center from three points
    let center = three_point_circle_center(start, cp1, end);

    if let Some(c) = center {
        let r = c.distance_to(start);
        if r < 1e-6 {
            return vec![start, end];
        }

        // Sample the arc from start to end going through the control region
        let start_angle = (start - c).direction();
        let end_angle = (end - c).direction();

        let n = 32;
        let mut points = Vec::with_capacity(n + 1);

        // Determine sweep direction based on which side the control points are
        let mid = start.lerp(end, 0.5);
        let to_mid = mid - c;
        let cross = (start - c).x * to_mid.y - (start - c).y * to_mid.x;

        for i in 0..=n {
            let t = i as f64 / n as f64;
            let mut angle = start_angle + (end_angle - start_angle) * t;

            // If the control points are on one side, ensure we sweep the right way
            if cross > 0.0 {
                // Ensure counter-clockwise sweep
                if end_angle < start_angle {
                    angle = start_angle + (end_angle + std::f64::consts::TAU - start_angle) * t;
                }
            } else {
                // Ensure clockwise sweep
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
        // Points are collinear, fall back to bezier-like curve
        route_bezier(start, end, from_normal, to_normal, config)
    }
}

/// Find the center of a circle passing through three points.
/// Returns None if points are collinear.
fn three_point_circle_center(p1: Point, p2: Point, p3: Point) -> Option<Point> {
    let ax = p1.x;
    let ay = p1.y;
    let bx = p2.x;
    let by = p2.y;
    let cx = p3.x;
    let cy = p3.y;

    let d = 2.0 * (ax * (by - cy) + bx * (cy - ay) + cx * (ay - by));

    if d.abs() < 1e-10 {
        return None; // Collinear
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

/// Route via a sine wave from start to end.
/// No obstacle interaction — free-form path.
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

        // Linear interpolation from start to end
        let base = start.lerp(end, t);

        // Perpendicular direction
        let dir = end - start;
        let perp = Point::new(-dir.y, dir.x).normalized();

        // Sine displacement
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

fn empty_computed_relation(id: &str, from: &str, to: &str) -> ComputedRelation {
    ComputedRelation {
        id: id.to_string(),
        path_points: vec![Point::zero(), Point::zero()],
        path_type: PathType::Straight,
        start_tangent: Point::new(1.0, 0.0),
        end_tangent: Point::new(1.0, 0.0),
        body_widths: vec![2.0, 2.0],
        body_type: BodyType::Uniform,
        start_endpoint: EndpointShapeType::None,
        end_endpoint: EndpointShapeType::None,
        start_direction: 0.0,
        end_direction: 0.0,
        label_position: Point::zero(),
        label_anchor: LabelAnchor::Center,
        bundle_id: None,
        bundle_offset: None,
        hit_test_points: Vec::new(),
        depends_on_nodes: vec![from.to_string(), to.to_string()],
        bbox: Rect::new(0.0, 0.0, 0.0, 0.0),
    }
}

fn compute_bbox(points: &[Point]) -> Rect {
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
