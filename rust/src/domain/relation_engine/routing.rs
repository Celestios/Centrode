use std::collections::HashMap;
use super::geometry::{Point, Rect};
use super::config::{RelationEngineConfig, RoutingMode};
use super::state::CanvasState;
use super::computed::PathType;
use super::input::{InputEdge, InputNode};

pub mod polyline;
pub mod orthogonal;
pub mod bezier;
pub mod circular_arc;
pub mod sine_wave;

pub trait RoutingStrategy: Send + Sync {
    fn route(
        &self,
        start: Point,
        end: Point,
        from_normal: Point,
        to_normal: Point,
        obstacles: &[Rect],
        config: &RelationEngineConfig,
        state: &CanvasState,
    ) -> (Vec<Point>, PathType);
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
    obstacles: &[Rect],
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

    // Map obstacles, keeping order alignment with node_map keys
    let filtered_obstacles: Vec<Rect> = obstacles
        .iter()
        .enumerate()
        .filter(|(i, _)| {
            !exclude_ids.contains(node_map.keys().nth(*i).unwrap_or(&""))
        })
        .map(|(_, r)| *r)
        .collect();

    let routing_mode = edge.routing_mode.unwrap_or(config.routing.routing_mode);

    let from_normal = from_node.port_normal(start);
    let to_normal = to_node.port_normal(end);

    let strategy = resolve_strategy(routing_mode);
    strategy.route(start, end, from_normal, to_normal, &filtered_obstacles, config, state)
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
