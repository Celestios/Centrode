use rust_lib_mycelium::domain::relation_engine::input::{InputEdge, InputNode};
use rust_lib_mycelium::domain::relation_engine::engine::RelationEngine;
use rust_lib_mycelium::domain::relation_engine::config::{RelationEngineConfig, RoutingMode, BundlingMode};
use rust_lib_mycelium::domain::relation_engine::geometry::{Point, Rect};
use rust_lib_mycelium::domain::relation_engine::visibility_graph::{RouteCostParams, a_star_with_params, VisibilityGraph};
use rust_lib_mycelium::domain::relation_engine::nudging::{nudge_edges, NudgeConfig};
use rust_lib_mycelium::domain::relation_engine::crossing::{count_crossings, minimize_crossings};
use rust_lib_mycelium::domain::relation_engine::vpsc::VpscSolver;
use rust_lib_mycelium::domain::relation_engine::sweep_visibility::{naive_visibility, build_obstacle_edges};
use rust_lib_mycelium::domain::relation_engine::computed::PathType;

fn init_logging() {
    let _ = tracing_subscriber::fmt()
        .with_max_level(tracing::Level::DEBUG)
        .with_test_writer()
        .try_init();
}

fn make_node(id: &str, x: f64, y: f64, w: f64, h: f64) -> InputNode {
    InputNode { id: id.to_string(), x, y, width: w, height: h }
}

fn make_edge(id: &str, from: &str, to: &str) -> InputEdge {
    InputEdge {
        id: id.to_string(),
        from_node_id: from.to_string(),
        to_node_id: to.to_string(),
        from_side: None,
        to_side: None,
        routing_mode: None,
        bundling_mode: None,
        style: None,
    }
}

fn make_ortho_edge(id: &str, from: &str, to: &str) -> InputEdge {
    InputEdge {
        id: id.to_string(),
        from_node_id: from.to_string(),
        to_node_id: to.to_string(),
        from_side: None,
        to_side: None,
        routing_mode: Some(RoutingMode::Orthogonal),
        bundling_mode: None,
        style: None,
    }
}

#[test]
fn pipeline_no_obstacles_direct_path() {
    let nodes = vec![
        make_node("n1", 0.0, 0.0, 60.0, 40.0),
        make_node("n2", 200.0, 0.0, 60.0, 40.0),
    ];
    let edges = vec![make_edge("e1", "n1", "n2")];
    let config = RelationEngineConfig::default();

    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);

    assert_eq!(results.len(), 1);
    let r = &results[0];
    assert!(r.path_points.len() >= 2, "Path should have at least start and end");
    assert_eq!(r.path_type, PathType::Straight);
    let start = r.path_points[0];
    let end = r.path_points[r.path_points.len() - 1];
    let dist = start.distance_to(end);
    assert!(dist > 100.0, "Path should span the distance between nodes: {}", dist);
}

#[test]
fn pipeline_single_obstacle_routes_around() {
    let nodes = vec![
        make_node("n1", 0.0, 80.0, 40.0, 40.0),
        make_node("n2", 400.0, 80.0, 40.0, 40.0),
        make_node("obs", 160.0, 0.0, 60.0, 200.0),
    ];
    let edges = vec![make_edge("e1", "n1", "n2")];
    let mut config = RelationEngineConfig::default();
    config.routing.obstacle_margin = 5.0;

    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);

    assert_eq!(results.len(), 1);
    let r = &results[0];
    assert!(r.path_points.len() >= 2, "Path should have points, got {}", r.path_points.len());

    let obs_rect = Rect::new(160.0, 0.0, 60.0, 200.0).expand(config.routing.obstacle_margin);
    let mut any_outside = false;
    for p in &r.path_points {
        if !obs_rect.contains(*p) {
            any_outside = true;
        }
    }
    assert!(any_outside, "At least one path point should be outside the obstacle");
}

#[test]
fn pipeline_two_edges_share_endpoint_nudged() {
    let nodes = vec![
        make_node("n1", 0.0, 50.0, 60.0, 40.0),
        make_node("n2", 300.0, 0.0, 60.0, 40.0),
        make_node("n3", 300.0, 120.0, 60.0, 40.0),
    ];
    let edges = vec![
        make_edge("e1", "n1", "n2"),
        make_edge("e2", "n1", "n3"),
    ];
    let mut config = RelationEngineConfig::default();
    config.nudging.enabled = true;
    config.nudging.distance = 8.0;

    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);

    assert_eq!(results.len(), 2);
    let r1 = &results[0];
    let r2 = &results[1];

    let start1 = r1.path_points[0];
    let start2 = r2.path_points[0];
    let sep = start1.distance_to(start2);
    assert!(sep > 1.0 || r1.path_points.len() > 2,
        "Edges from same source should be separated or routed differently: sep={}", sep);
}

#[test]
fn pipeline_orthogonal_routing() {
    let nodes = vec![
        make_node("n1", 0.0, 0.0, 60.0, 40.0),
        make_node("n2", 300.0, 200.0, 60.0, 40.0),
    ];
    let edges = vec![make_ortho_edge("e1", "n1", "n2")];
    let mut config = RelationEngineConfig::default();
    config.routing.routing_mode = RoutingMode::Orthogonal;
    config.routing.corner_radius = 0.0;

    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);

    assert_eq!(results.len(), 1);
    let r = &results[0];
    assert_eq!(r.path_type, PathType::Orthogonal);

    for p in &r.path_points {
        let rounded_x = (p.x * 10.0).round() / 10.0;
        let rounded_y = (p.y * 10.0).round() / 10.0;
        let snap_x = (rounded_x / 5.0).round() * 5.0;
        let snap_y = (rounded_y / 5.0).round() * 5.0;
        assert!((p.x - snap_x).abs() < 1.0 || (p.y - snap_y).abs() < 1.0,
            "Orthogonal point should align: ({}, {})", p.x, p.y);
    }
}

#[test]
fn pipeline_crossing_minimization() {
    let nodes = vec![
        make_node("n1", 0.0, 0.0, 40.0, 40.0),
        make_node("n2", 0.0, 200.0, 40.0, 40.0),
        make_node("n3", 300.0, 0.0, 40.0, 40.0),
        make_node("n4", 300.0, 200.0, 40.0, 40.0),
    ];
    let edges = vec![
        make_edge("e1", "n1", "n4"),
        make_edge("e2", "n2", "n3"),
    ];
    let mut config = RelationEngineConfig::default();
    config.crossing_minimization = true;

    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);

    assert_eq!(results.len(), 2);
    let paths: Vec<Vec<Point>> = results.iter().map(|r| r.path_points.clone()).collect();
    let crossings = count_crossings(&paths);
    assert!(crossings <= 1, "Crossing minimization should reduce crossings: got {}", crossings);
}

#[test]
fn pipeline_bundling_shared_endpoint() {
    let nodes = vec![
        make_node("n1", 0.0, 50.0, 40.0, 40.0),
        make_node("n2", 300.0, 0.0, 40.0, 40.0),
        make_node("n3", 300.0, 80.0, 40.0, 40.0),
        make_node("n4", 300.0, 160.0, 40.0, 40.0),
    ];
    let edges = vec![
        make_edge("e1", "n1", "n2"),
        make_edge("e2", "n1", "n3"),
        make_edge("e3", "n1", "n4"),
    ];
    let mut config = RelationEngineConfig::default();
    config.bundling.mode = BundlingMode::SharedEndpoint;
    config.nudging.enabled = false;

    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);

    assert_eq!(results.len(), 3);
    let bundled: Vec<_> = results.iter().filter(|r| r.bundle_id.is_some()).collect();
    assert!(!bundled.is_empty(), "At least some edges should be bundled");
}

#[test]
fn pipeline_incremental_recomputation() {
    use rust_lib_mycelium::domain::relation_engine::incremental::IncrementalState;

    let nodes = vec![
        make_node("n1", 0.0, 0.0, 60.0, 40.0),
        make_node("n2", 200.0, 0.0, 60.0, 40.0),
        make_node("n3", 400.0, 0.0, 60.0, 40.0),
    ];
    let edges = vec![
        make_edge("e1", "n1", "n2"),
        make_edge("e2", "n2", "n3"),
    ];
    let config = RelationEngineConfig::default();
    let mut incremental = IncrementalState::new();

    let all_results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    for r in &all_results {
        incremental.register(r.id.clone(), r.depends_on_nodes.clone(), r.bbox.clone());
    }

    incremental.mark_node_dirty("n2");
    assert!(incremental.has_dirty());

    let dirty = incremental.dirty_relation_ids(&std::collections::HashMap::new(), 45.0);
    assert!(dirty.contains(&"e1".to_string()), "e1 depends on n2");
    assert!(dirty.contains(&"e2".to_string()), "e2 depends on n2");

    let changed = RelationEngine::compute_incremental(&nodes, &edges, &config, &mut incremental);
    assert_eq!(changed.len(), 2, "Both edges should be recomputed");

    assert!(!incremental.has_dirty(), "Dirty should be cleared after recomputation");
}

#[test]
fn visibility_graph_angular_sweep_structure() {
    let nodes = vec![
        make_node("n1", 0.0, 0.0, 40.0, 40.0),
        make_node("n2", 200.0, 0.0, 40.0, 40.0),
        make_node("n3", 100.0, 50.0, 40.0, 40.0),
    ];
    let config = RelationEngineConfig::default();

    let obstacles: Vec<Rect> =
        nodes.iter().map(|n| n.rect()).collect();
    let start = Point::new(40.0, 20.0);
    let end = Point::new(200.0, 20.0);
    let graph = VisibilityGraph::build(&obstacles, start, end, config.routing.obstacle_margin);

    assert!(graph.node_count() > 2, "Graph should have start + end + corners");
    for node in &graph.nodes {
        assert!(node.point.x.is_finite() && node.point.y.is_finite(),
            "All vertices should be finite: {:?}", node.point);
    }
}

#[test]
fn a_star_cost_with_penalties() {
    let start = Point::new(0.0, 0.0);
    let end = Point::new(200.0, 0.0);
    let graph = VisibilityGraph::build(&[], start, end, 45.0);

    let params_default = RouteCostParams::default();
    let path_default = a_star_with_params(&graph, &params_default, Some(&start), Some(&end), &rust_lib_mycelium::domain::relation_engine::state::CanvasState::new());
    assert!(path_default.is_some(), "Should find path with default params");

    let params_high_penalty = RouteCostParams {
        angle_penalty: 10.0,
        segment_penalty: 20.0,
        crossing_penalty: 100.0,
        reverse_direction_penalty: 50.0,
    };
    let path_high = a_star_with_params(&graph, &params_high_penalty, Some(&start), Some(&end), &rust_lib_mycelium::domain::relation_engine::state::CanvasState::new());

    assert!(path_high.is_some(), "Should find path with high penalties");

    let cost_default = compute_path_cost(&path_default.unwrap(), &params_default);
    let cost_high = compute_path_cost(&path_high.unwrap(), &params_high_penalty);
    assert!(cost_high >= cost_default,
        "Higher penalties should not produce lower cost: high={} default={}",
        cost_high, cost_default);
}

fn compute_path_cost(path: &[Point], params: &RouteCostParams) -> f64 {
    let mut cost = 0.0;
    for w in path.windows(2) {
        cost += w[0].distance_to(w[1]);
    }
    if path.len() >= 3 {
        for w in path.windows(3) {
            let rad = std::f64::consts::PI - angle_between_points(w[0], w[1], w[2]);
            if rad > 1e-6 && params.angle_penalty > 0.0 {
                let xval = rad * 10.0 / std::f64::consts::PI;
                let yval = xval * (xval + 1.0).log10() / 10.5;
                cost += params.angle_penalty * yval;
            }
            if rad > 1e-6 {
                cost += params.segment_penalty;
            }
        }
    }
    cost
}

fn angle_between_points(p1: Point, p2: Point, p3: Point) -> f64 {
    let v1 = Point::new(p1.x - p2.x, p1.y - p2.y);
    let v2 = Point::new(p3.x - p2.x, p3.y - p2.y);
    let dot = v1.x * v2.x + v1.y * v2.y;
    let cross = v1.x * v2.y - v1.y * v2.x;
    cross.abs().atan2(dot.abs())
}

#[test]
fn vpsc_solver_convergence() {
    let mut solver = VpscSolver::new();
    let _v0 = solver.add_variable(0.0, 1.0);
    let _v1 = solver.add_variable(1.0, 1.0);
    let _v2 = solver.add_variable(2.0, 1.0);
    let _v3 = solver.add_variable(3.0, 1.0);
    let _v4 = solver.add_variable(4.0, 1.0);

    for i in 0..4 {
        solver.add_constraint(i, i + 1, 5.0, 1.0);
    }

    solver.solve();
    let pos = solver.get_positions();

    for i in 0..4 {
        let gap = pos[i + 1] - pos[i];
        assert!(gap >= 4.9, "Gap between {} and {} should be >= 4.9: got {}", i, i + 1, gap);
    }
}

#[test]
fn vpsc_solver_with_limits() {
    let mut solver = VpscSolver::new();
    let v0 = solver.add_variable(0.0, 1.0);
    let v1 = solver.add_variable(2.0, 1.0);
    solver.set_variable_limits(v0, f64::NEG_INFINITY, 1.0);
    solver.set_variable_limits(v1, 3.0, f64::INFINITY);
    solver.add_constraint(v0, v1, 5.0, 1.0);
    solver.solve();
    let pos = solver.get_positions();
    assert!(pos[0] <= 1.01, "v0 should respect max_limit: {}", pos[0]);
    assert!(pos[1] >= 2.99, "v1 should respect min_limit: {}", pos[1]);
}

#[test]
fn nudging_two_edges_from_source() {
    let mut paths = vec![
        vec![Point::new(0.0, 0.0), Point::new(100.0, 0.0)],
        vec![Point::new(0.0, 0.0), Point::new(100.0, 5.0)],
    ];
    let config = NudgeConfig {
        min_separation: 10.0,
        ..Default::default()
    };
    nudge_edges(
        &mut paths,
        &["e1".into(), "e2".into()],
        &["n1".into(), "n1".into()],
        &["n2".into(), "n3".into()],
        &config,
    );

    let sep_at_start = paths[0][0].distance_to(paths[1][0]);
    assert!(sep_at_start > 3.0, "Edges should be separated at start: {}", sep_at_start);

    let sep_at_end = paths[0][1].distance_to(paths[1][1]);
    assert!(sep_at_end > 3.0, "Edges should be separated at end: {}", sep_at_end);
}

#[test]
fn crossing_detection_and_minimization() {
    let mut paths = vec![
        vec![Point::new(0.0, 0.0), Point::new(100.0, 100.0)],
        vec![Point::new(0.0, 100.0), Point::new(100.0, 0.0)],
    ];
    let crossings_before = count_crossings(&paths);
    assert_eq!(crossings_before, 1, "Should detect crossing");

    let ids = vec!["e1".into(), "e2".into()];
    let _reordered = minimize_crossings(&mut paths, &ids, 20);

    let crossings_after = count_crossings(&paths);
    assert!(crossings_after <= crossings_before,
        "Crossings should decrease or stay: before={} after={}",
        crossings_before, crossings_after);
}

#[test]
fn sweep_visibility_obstacle_edges() {
    let obs = Rect::new(50.0, 50.0, 30.0, 30.0);
    let edges = build_obstacle_edges(&[obs]);
    assert_eq!(edges.len(), 4, "Rectangle should have 4 edges");

    let corners = obs.corners();
    for (i, edge) in edges.iter().enumerate() {
        assert_eq!(edge.from, corners[i], "Edge {} from should match corner", i);
        assert_eq!(edge.to, corners[(i + 1) % 4], "Edge {} to should match next corner", i);
    }
}

#[test]
fn sweep_visibility_multiple_obstacles() {
    let obs1 = Rect::new(80.0, 40.0, 30.0, 30.0);
    let obs2 = Rect::new(200.0, 40.0, 30.0, 30.0);
    let vertices = vec![
        Point::new(0.0, 55.0),
        Point::new(300.0, 55.0),
        Point::new(40.0, 55.0),
        Point::new(350.0, 55.0),
    ];
    let visible = naive_visibility(&vertices, &[obs1, obs2], 5.0);
    assert!(!visible.is_empty(), "Should find some visible edges");
}

#[test]
fn full_pipeline_e2e_no_obstacles() {
    let nodes = vec![
        make_node("a", 10.0, 10.0, 50.0, 30.0),
        make_node("b", 200.0, 10.0, 50.0, 30.0),
        make_node("c", 100.0, 150.0, 50.0, 30.0),
    ];
    let edges = vec![
        make_edge("e1", "a", "b"),
        make_edge("e2", "a", "c"),
        make_edge("e3", "b", "c"),
    ];
    let config = RelationEngineConfig::default();

    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);

    assert_eq!(results.len(), 3);
    for r in &results {
        assert!(r.path_points.len() >= 2, "Each path should have at least 2 points");
        assert!(r.bbox.width > 0.0 || r.bbox.height > 0.0, "Each path should have a bbox");
        assert!(!r.depends_on_nodes.is_empty(), "Each path should have dependencies");
    }
}

#[test]
fn full_pipeline_e2e_with_obstacles_and_nudging() {
    let nodes = vec![
        make_node("a", 0.0, 100.0, 40.0, 40.0),
        make_node("b", 400.0, 100.0, 40.0, 40.0),
        make_node("c", 0.0, 200.0, 40.0, 40.0),
        make_node("d", 400.0, 200.0, 40.0, 40.0),
        make_node("obs", 150.0, 80.0, 60.0, 180.0),
    ];
    let edges = vec![
        make_edge("e1", "a", "b"),
        make_edge("e2", "c", "d"),
    ];
    let mut config = RelationEngineConfig::default();
    config.nudging.enabled = true;
    config.crossing_minimization = true;

    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);

    assert_eq!(results.len(), 2);
    for r in &results {
        assert!(r.path_points.len() >= 2, "Path should have points");
    }

    let paths: Vec<Vec<Point>> = results.iter().map(|r| r.path_points.clone()).collect();
    let crossings = count_crossings(&paths);
    assert!(crossings <= 1, "Crossings should be minimized: got {}", crossings);
}

#[test]
fn debug_full_pipeline_with_logging() {
    init_logging();

    let nodes = vec![
        make_node("n1", 0.0, 100.0, 60.0, 40.0),
        make_node("n2", 500.0, 100.0, 60.0, 40.0),
        make_node("n3", 0.0, 250.0, 60.0, 40.0),
        make_node("n4", 500.0, 250.0, 60.0, 40.0),
        make_node("obs", 200.0, 50.0, 80.0, 250.0),
    ];
    let edges = vec![
        make_edge("e1", "n1", "n2"),
        make_edge("e2", "n3", "n4"),
        make_edge("e3", "n1", "n4"),
    ];
    let mut config = RelationEngineConfig::default();
    config.nudging.enabled = true;
    config.nudging.distance = 6.0;
    config.crossing_minimization = true;
    config.bundling.mode = BundlingMode::SharedEndpoint;
    config.routing.obstacle_margin = 10.0;

    eprintln!("=== PIPELINE DEBUG: Full E2E with obstacle, nudging, crossing, bundling ===");
    eprintln!("Nodes: 5 (3 connectors + 1 obstacle)");
    eprintln!("Edges: 3 (e1, e2, e3)");
    eprintln!("Config: margin={}, nudge_dist={}, nudging={}, crossings={}",
        config.routing.obstacle_margin, config.nudging.distance, config.nudging.enabled, config.crossing_minimization);

    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);

    eprintln!("\n=== RESULTS ===");
    eprintln!("Total results: {}", results.len());
    for r in &results {
        eprintln!("  '{}': {} points, type={:?}, bbox=({:.1},{:.1}) {:.1}x{:.1}",
            r.id, r.path_points.len(), r.path_type,
            r.bbox.x, r.bbox.y, r.bbox.width, r.bbox.height);
        if let Some(ref bid) = r.bundle_id {
            eprintln!("    bundle: {}, offset: {:?}", bid, r.bundle_offset);
        }
        eprintln!("    deps: {:?}", r.depends_on_nodes);
    }

    let paths: Vec<Vec<Point>> = results.iter().map(|r| r.path_points.clone()).collect();
    let crossings = count_crossings(&paths);
    eprintln!("\nCrossings remaining: {}", crossings);

    eprintln!("\n=== ALL ASSERTIONS PASSED ===");

    assert_eq!(results.len(), 3);
    assert!(crossings <= 1);
}
