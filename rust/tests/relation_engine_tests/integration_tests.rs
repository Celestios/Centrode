use rust_lib_mycelium::domain::relation_engine::{
    engine::RelationEngine,
    config::{RelationEngineConfig, RoutingMode},
    types::{InputNode, InputEdge},
};
use rust_lib_mycelium::domain::styles::PortSide;

fn create_node(id: &str, x: f64, y: f64, w: f64, h: f64) -> InputNode {
    InputNode {
        id: id.to_string(),
        x,
        y,
        width: w,
        height: h,
        is_obstacle: true,
    }
}

fn create_edge(id: &str, from: &str, to: &str, mode: RoutingMode) -> InputEdge {
    InputEdge {
        id: id.to_string(),
        from_node_id: from.to_string(),
        to_node_id: to.to_string(),
        from_side: Some(PortSide::Right),
        to_side: Some(PortSide::Left),
        routing_mode: Some(mode),
        bundling_mode: None,
        style: None,
    }
}

#[test]
fn test_relation_engine_orthogonal_compute() {
    let mut config = RelationEngineConfig::default();
    config.routing.routing_mode = RoutingMode::Orthogonal;

    let nodes = vec![
        create_node("a", 100.0, 200.0, 120.0, 80.0),
        create_node("obs", 400.0, 180.0, 100.0, 120.0),
        create_node("b", 720.0, 200.0, 120.0, 80.0),
    ];
    let edges = vec![create_edge("e1", "a", "b", RoutingMode::Orthogonal)];

    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);

    assert_eq!(results.len(), 1);
    assert!(!results[0].path_points.is_empty(), "Orthogonal path should contain points");
}

#[test]
fn test_relation_engine_octilinear_compute() {
    let mut config = RelationEngineConfig::default();
    config.routing.routing_mode = RoutingMode::Octilinear;

    let nodes = vec![
        create_node("a", 100.0, 200.0, 120.0, 80.0),
        create_node("b", 720.0, 350.0, 120.0, 80.0),
    ];
    let edges = vec![create_edge("e1", "a", "b", RoutingMode::Octilinear)];

    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);

    assert_eq!(results.len(), 1);
    assert!(!results[0].path_points.is_empty(), "Octilinear path should contain points");
}

#[test]
fn test_relation_engine_direct_compute() {
    let config = RelationEngineConfig::default();

    let nodes = vec![
        create_node("a", 100.0, 200.0, 120.0, 80.0),
        create_node("b", 720.0, 200.0, 120.0, 80.0),
    ];
    let edges = vec![create_edge("e1", "a", "b", RoutingMode::Polyline)];

    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);

    assert_eq!(results.len(), 1);
    assert!(results[0].path_points.len() >= 2);
}

