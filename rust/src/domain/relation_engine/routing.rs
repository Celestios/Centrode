pub mod polyline;
pub mod orthogonal;
pub mod bezier;
pub mod circular_arc;
pub mod sine_wave;

use std::collections::HashMap;
use super::geometry::{Point, Rect};
use super::config::{RelationEngineConfig, RoutingMode};
use super::state::CanvasState;
use super::computed::PathType;
use super::input::{InputEdge, InputNode};

pub struct RouteContext {
    pub start: Point,
    pub end: Point,
    pub from_normal: Point,
    pub to_normal: Point,
    pub from_rect: Rect,
    pub to_rect: Rect,
    pub obstacles: Vec<Rect>,
    pub config: RelationEngineConfig,
}

pub fn filter_obstacles_in_bounds(
    obstacles: &[Rect],
    start: Point,
    end: Point,
    margin: f64,
) -> Vec<Rect> {
    let min_x = start.x.min(end.x) - margin * 2.0;
    let max_x = start.x.max(end.x) + margin * 2.0;
    let min_y = start.y.min(end.y) - margin * 2.0;
    let max_y = start.y.max(end.y) + margin * 2.0;
    let route_bounds = Rect::new(min_x, min_y, max_x - min_x, max_y - min_y);
    obstacles.iter().filter(|obs| obs.overlaps(&route_bounds)).copied().collect()
}

pub trait RoutingStrategy: Send + Sync {
    fn route(&self, ctx: &RouteContext, state: &CanvasState) -> (Vec<Point>, PathType);
}

pub fn resolve_strategy(mode: RoutingMode) -> Box<dyn RoutingStrategy> {
    match mode {
        RoutingMode::Polyline => Box::new(polyline::PolylineRouting),
        RoutingMode::Bezier => Box::new(bezier::BezierRouting),
        RoutingMode::Orthogonal => Box::new(orthogonal::OrthogonalRouting),
        RoutingMode::CircularArc => Box::new(circular_arc::CircularArcRouting),
        RoutingMode::SineWave => Box::new(sine_wave::SineWaveRouting),
    }
}

pub fn route_relation(
    edge: &InputEdge,
    node_map: &HashMap<&str, &InputNode>,
    _obstacles: &[Rect],
    config: &RelationEngineConfig,
    state: &CanvasState,
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

    let start_port = match &edge.from_side {
        Some(side) => from_node.resolve_port(side, to_center),
        None => from_node.closest_port_to(to_center),
    };

    let end_port = match &edge.to_side {
        Some(side) => to_node.resolve_port(side, from_center),
        None => to_node.closest_port_to(from_center),
    };

    let start = start_port.position;
    let end = end_port.position;

    let exclude_ids: std::collections::HashSet<&str> =
        [edge.from_node_id.as_str(), edge.to_node_id.as_str()]
            .into_iter()
            .collect();

    let filtered_obstacles: Vec<Rect> = node_map
        .values()
        .filter(|node| !exclude_ids.contains(node.id.as_str()))
        .map(|node| node.rect())
        .collect();

    let routing_mode = edge.routing_mode.unwrap_or(config.routing.routing_mode);

    let from_normal = super::input::normal_for_side(&start_port.side);
    let to_normal = super::input::normal_for_side(&end_port.side);

    let ctx = RouteContext {
        start,
        end,
        from_normal,
        to_normal,
        from_rect: from_node.rect(),
        to_rect: to_node.rect(),
        obstacles: filtered_obstacles,
        config: config.clone(),
    };
    let strategy = resolve_strategy(routing_mode);
    strategy.route(&ctx, state)
}

pub fn node_clearance(from: Point, from_normal: Point, node_rect: Rect) -> f64 {
    let margin = 20.0;
    if from_normal.x.abs() >= from_normal.y.abs() {
        if from_normal.x > 0.0 {
            (node_rect.right() - from.x).max(0.0) + margin
        } else {
            (from.x - node_rect.left()).max(0.0) + margin
        }
    } else {
        if from_normal.y > 0.0 {
            (node_rect.bottom() - from.y).max(0.0) + margin
        } else {
            (from.y - node_rect.top()).max(0.0) + margin
        }
    }
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
