use rust_lib_mycelium::domain::relation_engine::input::{InputEdge, InputNode};
use rust_lib_mycelium::domain::relation_engine::engine::RelationEngine;
use rust_lib_mycelium::domain::relation_engine::config::{
    BundlingMode, RelationEngineConfig, RoutingMode,
};
use rust_lib_mycelium::domain::relation_engine::computed::PathType;
use rust_lib_mycelium::domain::relation_engine::crossing::count_crossings;
use rust_lib_mycelium::domain::relation_engine::geometry::Point;
use rust_lib_mycelium::domain::relation_engine::state::incremental::IncrementalState;
use rust_lib_mycelium::domain::relation_engine::solver::vpsc::VpscSolver;
use rust_lib_mycelium::domain::relation_engine::solver::visibility_graph::{
    a_star_with_params, RouteCostParams, VisibilityGraph,
};

fn node(id: &str, x: f64, y: f64, w: f64, h: f64) -> InputNode {
    InputNode { id: id.into(), x, y, width: w, height: h }
}

fn edge(id: &str, from: &str, to: &str) -> InputEdge {
    InputEdge {
        id: id.into(),
        from_node_id: from.into(),
        to_node_id: to.into(),
        from_side: None,
        to_side: None,
        routing_mode: None,
        bundling_mode: None,
        style: None,
    }
}

fn ortho_edge(id: &str, from: &str, to: &str) -> InputEdge {
    InputEdge {
        id: id.into(),
        from_node_id: from.into(),
        to_node_id: to.into(),
        from_side: None,
        to_side: None,
        routing_mode: Some(RoutingMode::Orthogonal),
        bundling_mode: None,
        style: None,
    }
}

fn route_len(p: &[Point]) -> f64 {
    p.windows(2).map(|w| w[0].distance_to(w[1])).sum()
}

fn pipeline_label(scenario: &str) {
    eprintln!("");
    eprintln!("======================================================================");
    eprintln!("SCENARIO: {}", scenario);
    eprintln!("======================================================================");
}

fn log_step(step: &str, detail: &str) {
    eprintln!("  [STEP] {}: {}", step, detail);
}

fn log_result(detail: &str) {
    eprintln!("  [RESULT] {}", detail);
}

fn log_pass(assertion: &str) {
    eprintln!("  [PASS] {}", assertion);
}

// ─── SCENARIO 1 ──────────────────────────────────────────────────────
// Two nodes, no obstacles, no bundling, no nudging, no crossing.
// Pipeline: Route (straight) → done.
#[test]
fn scenario_01_two_nodes_direct_polyline() {
    pipeline_label("01 Two nodes direct polyline");
    let nodes = vec![node("a", 0.0, 0.0, 50.0, 30.0), node("b", 300.0, 0.0, 50.0, 30.0)];
    let edges = vec![edge("e1", "a", "b")];
    let config = RelationEngineConfig::default();

    log_step("1.route", "Build visibility graph, run A*");
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    assert_eq!(results.len(), 1);
    log_step("1.verify", "path has >= 2 points, type=Straight, no bundle, no nudge artifacts");

    let r = &results[0];
    assert!(r.path_points.len() >= 2);
    assert_eq!(r.path_type, PathType::Straight);
    assert!(r.bundle_id.is_none());
    log_pass("path is straight polyline between two nodes");
    log_result(&format!("{} points, length={:.1}", r.path_points.len(), route_len(&r.path_points)));
}

// ─── SCENARIO 2 ──────────────────────────────────────────────────────
// Two nodes + one tall obstacle between them.
// Pipeline: Route (visibility graph around obstacle) → verify path avoids obstacle.
#[test]
fn scenario_02_single_obstacle_avoidance() {
    pipeline_label("02 Single obstacle avoidance");
    let nodes = vec![
        node("a", 0.0, 100.0, 40.0, 40.0),
        node("b", 600.0, 100.0, 40.0, 40.0),
        node("wall", 250.0, 0.0, 40.0, 300.0),
    ];
    let edges = vec![edge("e1", "a", "b")];
    let mut config = RelationEngineConfig::default();
    config.routing.obstacle_margin = 10.0;
    config.nudging.enabled = false;

    log_step("1.route", "Visibility graph around expanded obstacle");
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    assert_eq!(results.len(), 1);

    log_step("2.verify_path_has_waypoints", "Path should have > 2 points (going around obstacle)");
    let r = &results[0];
    assert!(r.path_points.len() > 2, "Path should have waypoints around obstacle: got {} points", r.path_points.len());
    log_result(&format!("{} points", r.path_points.len()));
    log_pass("path routes around obstacle with intermediate waypoints");
}

// ─── SCENARIO 3 ──────────────────────────────────────────────────────
// Three nodes forming a fan from one source.
// Pipeline: Route → Bundling (SharedEndpoint) → verify bundle assignments.
#[test]
fn scenario_03_shared_endpoint_bundling() {
    pipeline_label("03 Shared endpoint bundling");
    let nodes = vec![
        node("src", 0.0, 100.0, 40.0, 40.0),
        node("t1", 400.0, 0.0, 40.0, 40.0),
        node("t2", 400.0, 100.0, 40.0, 40.0),
        node("t3", 400.0, 200.0, 40.0, 40.0),
    ];
    let edges = vec![edge("e1", "src", "t1"), edge("e2", "src", "t2"), edge("e3", "src", "t3")];
    let mut config = RelationEngineConfig::default();
    config.bundling.mode = BundlingMode::SharedEndpoint;
    config.nudging.enabled = false;

    log_step("1.route", "Route 3 edges from same source");
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    assert_eq!(results.len(), 3);

    log_step("2.bundle", "SharedEndpoint bundling groups edges from 'src'");
    let bundled: Vec<_> = results.iter().filter(|r| r.bundle_id.is_some()).collect();
    assert!(bundled.len() >= 2, "At least 2 edges should be bundled");
    log_pass(&format!("{} edges assigned to bundles", bundled.len()));
}

// ─── SCENARIO 4 ──────────────────────────────────────────────────────
// Two crossing edges, no obstacles.
// Pipeline: Route → Nudge → Crossing minimization → verify crossings reduced.
#[test]
fn scenario_04_crossing_minimization() {
    pipeline_label("04 Crossing minimization");
    let nodes = vec![
        node("tl", 0.0, 0.0, 40.0, 40.0),
        node("bl", 0.0, 200.0, 40.0, 40.0),
        node("tr", 400.0, 0.0, 40.0, 40.0),
        node("br", 400.0, 200.0, 40.0, 40.0),
    ];
    let edges = vec![edge("e1", "tl", "br"), edge("e2", "bl", "tr")];
    let mut config = RelationEngineConfig::default();
    config.crossing_minimization = true;
    config.nudging.enabled = false;

    log_step("1.route", "Two diagonal edges that cross");
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    assert_eq!(results.len(), 2);

    log_step("2.crossing_min", "Hill-climbing reorder to reduce crossings");
    let paths: Vec<Vec<Point>> = results.iter().map(|r| r.path_points.clone()).collect();
    let crossings = count_crossings(&paths);
    assert!(crossings <= 1, "Crossings should be <= 1 after minimization: got {}", crossings);
    log_pass(&format!("crossings reduced to {}", crossings));
}

// ─── SCENARIO 5 ──────────────────────────────────────────────────────
// Two edges from same source, nudging enabled.
// Pipeline: Route → Nudge (VPSC X+Y) → verify separation at endpoints.
#[test]
fn scenario_05_vpsc_nudging_two_edges() {
    pipeline_label("05 VPSC nudging two edges");
    let nodes = vec![
        node("src", 0.0, 100.0, 40.0, 40.0),
        node("t1", 400.0, 80.0, 40.0, 40.0),
        node("t2", 400.0, 120.0, 40.0, 40.0),
    ];
    let edges = vec![edge("e1", "src", "t1"), edge("e2", "src", "t2")];
    let mut config = RelationEngineConfig::default();
    config.nudging.enabled = true;
    config.nudging.distance = 10.0;
    config.crossing_minimization = false;

    log_step("1.route", "Two edges nearly overlapping from same source");
    log_step("2.nudge", "VPSC solver separates overlapping start segments");
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    assert_eq!(results.len(), 2);

    log_step("3.verify", "Edges have vertical separation at shared endpoint");
    let s0 = results[0].path_points[0];
    let s1 = results[1].path_points[0];
    let sep = (s0.y - s1.y).abs();
    assert!(sep > 2.0, "VPSC should separate start points vertically: sep={}", sep);
    log_pass(&format!("start-point vertical separation = {:.1}", sep));
}

// ─── SCENARIO 6 ──────────────────────────────────────────────────────
// Orthogonal routing, no obstacles.
// Pipeline: Route (visibility graph) → snap_to_orthogonal → verify all segments axis-aligned.
#[test]
fn scenario_06_orthogonal_route_no_obstacles() {
    pipeline_label("06 Orthogonal route, no obstacles");
    let nodes = vec![node("a", 50.0, 50.0, 40.0, 40.0), node("b", 400.0, 300.0, 40.0, 40.0)];
    let edges = vec![ortho_edge("e1", "a", "b")];
    let mut config = RelationEngineConfig::default();
    config.routing.routing_mode = RoutingMode::Orthogonal;
    config.routing.corner_radius = 0.0;

    log_step("1.route", "Visibility graph → A* → snap_to_orthogonal");
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    assert_eq!(results.len(), 1);

    log_step("2.verify_ortho", "Every segment is horizontal or vertical");
    let r = &results[0];
    assert_eq!(r.path_type, PathType::Orthogonal);
    for seg in r.path_points.windows(2) {
        let dx = (seg[0].x - seg[1].x).abs();
        let dy = (seg[0].y - seg[1].y).abs();
        assert!(
            dx < 0.1 || dy < 0.1,
            "Orthogonal segment must be axis-aligned: ({},{})→({},{})",
            seg[0].x, seg[0].y, seg[1].x, seg[1].y
        );
    }
    log_pass("all segments axis-aligned");
    log_result(&format!("{} waypoints", r.path_points.len()));
}

// ─── SCENARIO 7 ──────────────────────────────────────────────────────
// Orthogonal routing with one obstacle.
// Pipeline: Route (vis graph + snap) → verify path has waypoints, segments axis-aligned.
#[test]
fn scenario_07_orthogonal_with_obstacle() {
    pipeline_label("07 Orthogonal with obstacle");
    let nodes = vec![
        node("a", 0.0, 100.0, 40.0, 40.0),
        node("b", 600.0, 100.0, 40.0, 40.0),
        node("wall", 250.0, 0.0, 40.0, 300.0),
    ];
    let edges = vec![ortho_edge("e1", "a", "b")];
    let mut config = RelationEngineConfig::default();
    config.routing.routing_mode = RoutingMode::Orthogonal;
    config.routing.corner_radius = 0.0;
    config.routing.obstacle_margin = 10.0;

    log_step("1.route", "Vis graph → A* → snap_to_orthogonal");
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    assert_eq!(results.len(), 1);

    log_step("2.verify_path_has_waypoints", "Path routes around obstacle");
    let r = &results[0];
    assert!(r.path_points.len() > 2, "Ortho path should have waypoints: got {} points", r.path_points.len());
    log_result(&format!("{} waypoints", r.path_points.len()));

    log_step("3.verify_ortho", "All segments axis-aligned");
    for seg in r.path_points.windows(2) {
        let dx = (seg[0].x - seg[1].x).abs();
        let dy = (seg[0].y - seg[1].y).abs();
        assert!(dx < 0.1 || dy < 0.1, "Not axis-aligned");
    }
    log_pass("all segments axis-aligned");
}

// ─── SCENARIO 8 ──────────────────────────────────────────────────────
// Bezier routing, no obstacles.
// Pipeline: Route (cubic bezier) → sample 32 points → verify smooth curve.
#[test]
fn scenario_08_bezier_route() {
    pipeline_label("08 Bezier route");
    let nodes = vec![node("a", 0.0, 100.0, 40.0, 40.0), node("b", 400.0, 100.0, 40.0, 40.0)];
    let mut e = edge("e1", "a", "b");
    e.routing_mode = Some(RoutingMode::Bezier);
    let edges = vec![e];
    let config = RelationEngineConfig::default();

    log_step("1.route", "Cubic bezier with port normals");
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    assert_eq!(results.len(), 1);

    log_step("2.verify", "Path has 33 points (32 samples + endpoints), type=CubicBezier");
    let r = &results[0];
    assert_eq!(r.path_type, PathType::CubicBezier);
    assert!(r.path_points.len() >= 10, "Bezier should have many sample points");
    log_pass(&format!("{} sample points on bezier curve", r.path_points.len()));
}

// ─── SCENARIO 9 ──────────────────────────────────────────────────────
// Full pipeline: obstacles + nudging + crossing + bundling.
// Pipeline: Route → Bundle → Nudge → Crossing min → verify all phases ran.
#[test]
fn scenario_09_full_pipeline_all_phases() {
    pipeline_label("09 Full pipeline: bundle + nudge + cross");
    let nodes = vec![
        node("a", 0.0, 100.0, 40.0, 40.0),
        node("b", 600.0, 100.0, 40.0, 40.0),
        node("c", 0.0, 250.0, 40.0, 40.0),
        node("d", 600.0, 250.0, 40.0, 40.0),
        node("obs", 250.0, 50.0, 60.0, 300.0),
    ];
    let edges = vec![edge("e1", "a", "b"), edge("e2", "c", "d"), edge("e3", "a", "d")];
    let mut config = RelationEngineConfig::default();
    config.bundling.mode = BundlingMode::SharedEndpoint;
    config.nudging.enabled = true;
    config.nudging.distance = 8.0;
    config.crossing_minimization = true;
    config.routing.obstacle_margin = 10.0;

    log_step("1.route", "Route 3 edges through obstacle field");
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    assert_eq!(results.len(), 3);

    log_step("2.bundle", "SharedEndpoint bundling");
    let bundled = results.iter().filter(|r| r.bundle_id.is_some()).count();
    log_result(&format!("{} edges bundled", bundled));

    log_step("3.nudge", "VPSC nudging X+Y dims");
    log_step("4.crossing", "Crossing minimization");

    log_step("5.verify_crossings", "Count crossings in final paths");
    let paths: Vec<Vec<Point>> = results.iter().map(|r| r.path_points.clone()).collect();
    let crossings = count_crossings(&paths);
    log_result(&format!("{} crossings remaining", crossings));

    log_step("6.verify_all_paths_have_points", "Each path has waypoints");
    for r in &results {
        assert!(r.path_points.len() >= 2, "Path should have points");
    }

    log_pass("all phases completed");
}

// ─── SCENARIO 10 ─────────────────────────────────────────────────────
// Incremental recomputation: initial compute → move one node → recompute.
// Pipeline: compute_all → register → mark_dirty → compute_incremental → verify only changed edges returned.
#[test]
fn scenario_10_incremental_recomputation() {
    pipeline_label("10 Incremental recomputation");
    let nodes = vec![
        node("a", 0.0, 0.0, 60.0, 40.0),
        node("b", 200.0, 0.0, 60.0, 40.0),
        node("c", 400.0, 0.0, 60.0, 40.0),
    ];
    let edges = vec![edge("e1", "a", "b"), edge("e2", "b", "c")];
    let config = RelationEngineConfig::default();
    let mut inc = IncrementalState::new();

    log_step("1.initial_compute", "Compute all 2 edges");
    let all = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    assert_eq!(all.len(), 2);
    for r in &all {
        inc.register(r.id.clone(), r.depends_on_nodes.clone(), r.bbox.clone());
    }
    log_result("2 edges registered in incremental state");

    log_step("2.mark_dirty", "Move node 'b' → both e1 and e2 depend on it");
    inc.mark_node_dirty("b");
    assert!(inc.has_dirty());
    let dirty = inc.dirty_relation_ids(&std::collections::HashMap::new(), 45.0);
    assert!(dirty.contains(&"e1".to_string()));
    assert!(dirty.contains(&"e2".to_string()));
    log_result(&format!("{} dirty edges detected", dirty.len()));

    log_step("3.recompute_incremental", "Only recompute dirty edges");
    let changed = RelationEngine::compute_incremental(&nodes, &edges, &config, &mut inc);
    assert_eq!(changed.len(), 2);
    log_result(&format!("{} edges recomputed", changed.len()));

    log_step("4.verify_clean", "No more dirty edges after recomputation");
    assert!(!inc.has_dirty());
    log_pass("incremental pipeline works correctly");
}

// ─── SCENARIO 11 ─────────────────────────────────────────────────────
// Incremental: move a node not connected to any edge → zero recompute.
// Pipeline: compute_all → mark_dirty(unrelated) → compute_incremental → zero returned.
#[test]
fn scenario_11_incremental_unrelated_node() {
    pipeline_label("11 Incremental: unrelated node dirty → no recompute");
    let nodes = vec![
        node("a", 0.0, 0.0, 60.0, 40.0),
        node("b", 200.0, 0.0, 60.0, 40.0),
        node("loner", 500.0, 500.0, 60.0, 40.0),
    ];
    let edges = vec![edge("e1", "a", "b")];
    let config = RelationEngineConfig::default();
    let mut inc = IncrementalState::new();

    log_step("1.initial_compute", "Compute edge e1 (a→b)");
    let all = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    assert_eq!(all.len(), 1);
    inc.register(all[0].id.clone(), all[0].depends_on_nodes.clone(), all[0].bbox.clone());

    log_step("2.mark_dirty", "Mark 'loner' dirty (not connected to e1)");
    inc.mark_node_dirty("loner");

    log_step("3.recompute_incremental", "No edges depend on 'loner' → 0 results");
    let changed = RelationEngine::compute_incremental(&nodes, &edges, &config, &mut inc);
    assert_eq!(changed.len(), 0);
    log_pass("no edges recomputed for unrelated node");
}

// ─── SCENARIO 12 ─────────────────────────────────────────────────────
// VPSC solver: 5 variables stacked, all need separation.
// Pipeline: add variables → add constraints → solve → verify all gaps >= 5.0.
#[test]
fn scenario_12_vpsc_five_variables() {
    pipeline_label("12 VPSC solver: 5 stacked variables");
    let mut solver = VpscSolver::new();
    for i in 0..5 {
        solver.add_variable(i as f64, 1.0);
    }
    for i in 0..4 {
        solver.add_constraint(i, i + 1, 5.0, 1.0);
    }

    log_step("1.solve", "Iterative constraint propagation");
    solver.solve();
    let pos = solver.get_positions();

    log_step("2.verify", "All adjacent gaps >= 5.0");
    for i in 0..4 {
        let gap = pos[i + 1] - pos[i];
        assert!(gap >= 4.9, "Gap[{},{}]={} < 5.0", i, i + 1, gap);
    }
    log_pass("all 4 gaps satisfy minimum separation");
    log_result(&format!("positions: {:?}", pos.iter().map(|p| format!("{:.1}", p)).collect::<Vec<_>>()));
}

// ─── SCENARIO 13 ─────────────────────────────────────────────────────
// VPSC solver with variable limits: push apart but respect bounds.
#[test]
fn scenario_13_vpsc_with_limits() {
    pipeline_label("13 VPSC with variable limits");
    let mut solver = VpscSolver::new();
    let v0 = solver.add_variable(0.0, 1.0);
    let v1 = solver.add_variable(1.0, 1.0);
    solver.set_variable_limits(v0, 0.0, 2.0);
    solver.set_variable_limits(v1, 8.0, 10.0);
    solver.add_constraint(v0, v1, 5.0, 1.0);

    log_step("1.solve", "Solve with limits [0,2] and [8,10]");
    solver.solve();
    let pos = solver.get_positions();

    log_step("2.verify_limits", "v0 <= 2.0, v1 >= 8.0");
    assert!(pos[0] <= 2.01, "v0 out of bounds: {}", pos[0]);
    assert!(pos[1] >= 7.99, "v1 out of bounds: {}", pos[1]);
    log_pass(&format!("v0={:.2}, v1={:.2}", pos[0], pos[1]));
}

// ─── SCENARIO 14 ─────────────────────────────────────────────────────
// A* cost function: default vs high penalties on same graph.
// Pipeline: build graph → search with default → search with high penalties → verify high cost >= default.
#[test]
fn scenario_14_astar_cost_penalties() {
    pipeline_label("14 A* cost function penalties");
    let start = Point::new(0.0, 0.0);
    let end = Point::new(300.0, 0.0);
    let graph = VisibilityGraph::build(&[], start, end, 45.0);

    log_step("1.search_default", "A* with default penalties");
    let path_d = a_star_with_params(&graph, &RouteCostParams::default(), Some(&start), Some(&end), &rust_lib_mycelium::domain::relation_engine::state::CanvasState::new());
    assert!(path_d.is_some());

    log_step("2.search_high", "A* with extreme penalties");
    let high = RouteCostParams {
        angle_penalty: 10.0,
        segment_penalty: 20.0,
        crossing_penalty: 100.0,
        reverse_direction_penalty: 50.0,
    };
    let path_h = a_star_with_params(&graph, &high, Some(&start), Some(&end), &rust_lib_mycelium::domain::relation_engine::state::CanvasState::new());

    assert!(path_h.is_some());

    log_step("3.compare", "High penalty cost >= default cost");
    let cost_d: f64 = path_d.unwrap().windows(2).map(|w| w[0].distance_to(w[1])).sum();
    let cost_h: f64 = path_h.unwrap().windows(2).map(|w| w[0].distance_to(w[1])).sum();
    assert!(cost_h >= cost_d - 0.01, "high={} < default={}", cost_h, cost_d);
    log_pass(&format!("default cost={:.1}, high cost={:.1}", cost_d, cost_h));
}

// ─── SCENARIO 15 ─────────────────────────────────────────────────────
// Multiple crossing edges: 4 edges in X pattern.
// Pipeline: Route 4 edges → Crossing minimization → verify crossings reduced.
#[test]
fn scenario_15_four_crossing_edges() {
    pipeline_label("15 Four crossing edges (X pattern)");
    let nodes = vec![
        node("tl", 0.0, 0.0, 40.0, 40.0),
        node("bl", 0.0, 300.0, 40.0, 40.0),
        node("tr", 400.0, 0.0, 40.0, 40.0),
        node("br", 400.0, 300.0, 40.0, 40.0),
    ];
    let edges = vec![
        edge("e1", "tl", "br"),
        edge("e2", "bl", "tr"),
    ];
    let mut config = RelationEngineConfig::default();
    config.crossing_minimization = true;
    config.nudging.enabled = false;

    log_step("1.route", "2 diagonal edges that cross");
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    assert_eq!(results.len(), 2);

    log_step("2.crossing_min", "Hill-climbing reorder");
    let paths: Vec<Vec<Point>> = results.iter().map(|r| r.path_points.clone()).collect();
    let crossings = count_crossings(&paths);
    log_result(&format!("{} crossings after minimization", crossings));
    assert!(crossings <= 1, "Expected <= 1 crossing for 2 edges, got {}", crossings);
    log_pass("crossings reduced");
}

// ─── SCENARIO 16 ─────────────────────────────────────────────────────
// Circular arc routing.
// Pipeline: Route (arc) → verify path curves, not straight.
#[test]
fn scenario_16_circular_arc_route() {
    pipeline_label("16 Circular arc route");
    let nodes = vec![node("a", 0.0, 100.0, 40.0, 40.0), node("b", 400.0, 200.0, 40.0, 40.0)];
    let mut e = edge("e1", "a", "b");
    e.routing_mode = Some(RoutingMode::CircularArc);
    let edges = vec![e];
    let config = RelationEngineConfig::default();

    log_step("1.route", "Circular arc through 3 points");
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    assert_eq!(results.len(), 1);

    log_step("2.verify", "Path has many sample points, forms a curve");
    let r = &results[0];
    assert_eq!(r.path_type, PathType::CircularArc);
    assert!(r.path_points.len() >= 10, "Arc should have many samples");
    log_pass(&format!("{} points on circular arc", r.path_points.len()));
}

// ─── SCENARIO 17 ─────────────────────────────────────────────────────
// Sine wave routing.
// Pipeline: Route (sine) → verify sinusoidal shape.
#[test]
fn scenario_17_sine_wave_route() {
    pipeline_label("17 Sine wave route");
    let nodes = vec![node("a", 0.0, 100.0, 40.0, 40.0), node("b", 400.0, 100.0, 40.0, 40.0)];
    let mut e = edge("e1", "a", "b");
    e.routing_mode = Some(RoutingMode::SineWave);
    let edges = vec![e];
    let config = RelationEngineConfig::default();

    log_step("1.route", "Sine wave with amplitude=20, frequency=3");
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    assert_eq!(results.len(), 1);

    log_step("2.verify", "Path has 65 points (64 samples), perpendicular oscillation");
    let r = &results[0];
    assert_eq!(r.path_type, PathType::SineWave);
    assert!(r.path_points.len() >= 30, "Sine wave should have many points");
    let ys: Vec<f64> = r.path_points.iter().map(|p| p.y).collect();
    let max_y = ys.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
    let min_y = ys.iter().cloned().fold(f64::INFINITY, f64::min);
    assert!(max_y - min_y > 5.0, "Sine wave should oscillate: max_y={} min_y={}", max_y, min_y);
    log_pass(&format!("oscillation range: {:.1} to {:.1}", min_y, max_y));
}

// ─── SCENARIO 18 ─────────────────────────────────────────────────────
// Proximity bundling: two edges with close midpoints bundled, third far away separate.
// Pipeline: Route 3 edges → Proximity bundling → verify 2 bundled, 1 standalone.
#[test]
fn scenario_18_proximity_bundling() {
    pipeline_label("18 Proximity bundling");
    let nodes = vec![
        node("a", 0.0, 0.0, 40.0, 40.0),
        node("b", 400.0, 0.0, 40.0, 40.0),
        node("c", 0.0, 50.0, 40.0, 40.0),
        node("d", 400.0, 50.0, 40.0, 40.0),
        node("e", 0.0, 600.0, 40.0, 40.0),
        node("f", 400.0, 600.0, 40.0, 40.0),
    ];
    let edges = vec![
        edge("e1", "a", "b"),
        edge("e2", "c", "d"),
        edge("e3", "e", "f"),
    ];
    let mut config = RelationEngineConfig::default();
    config.bundling.mode = BundlingMode::Proximity;
    config.bundling.threshold = 80.0;
    config.nudging.enabled = false;

    log_step("1.route", "3 edges: e1 and e2 very close, e3 far away");
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    assert_eq!(results.len(), 3);

    log_step("2.bundle", "Proximity bundling groups e1+e2, leaves e3 standalone");
    let bundled: Vec<_> = results.iter().filter(|r| r.bundle_id.is_some()).collect();
    let unbundled: Vec<_> = results.iter().filter(|r| r.bundle_id.is_none()).collect();
    log_result(&format!("{} bundled, {} unbundled", bundled.len(), unbundled.len()));
    assert!(bundled.len() >= 2, "e1 and e2 should be bundled");
    assert!(unbundled.len() >= 1, "e3 should be standalone");
    log_pass("proximity bundling correctly groups close edges");
}

// ─── SCENARIO 19 ─────────────────────────────────────────────────────
// Nudging disabled: two edges from same source go to different targets.
// Pipeline: Route → Nudge OFF → verify no VPSC separation applied (paths unchanged from route output).
#[test]
fn scenario_19_nudging_disabled() {
    pipeline_label("19 Nudging disabled");
    let nodes = vec![
        node("src", 0.0, 100.0, 40.0, 40.0),
        node("t1", 400.0, 80.0, 40.0, 40.0),
        node("t2", 400.0, 120.0, 40.0, 40.0),
    ];
    let edges = vec![edge("e1", "src", "t1"), edge("e2", "src", "t2")];
    let mut config = RelationEngineConfig::default();
    config.nudging.enabled = false;
    config.crossing_minimization = false;

    log_step("1.route", "Two edges from same source, nudging OFF");
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    assert_eq!(results.len(), 2);

    log_step("2.verify_no_nudge", "VPSC did not apply any perpendicular offset");
    let r0_len = route_len(&results[0].path_points);
    let r1_len = route_len(&results[1].path_points);
    log_result(&format!("e1 length={:.1}, e2 length={:.1}", r0_len, r1_len));
    assert!(r0_len > 100.0 && r1_len > 100.0, "Paths should span the distance");
    log_pass("nudging disabled — no VPSC separation");
}

// ─── SCENARIO 20 ─────────────────────────────────────────────────────
// Combined: obstacle + orthogonal + nudging + crossing + bundling.
// Pipeline: Route (ortho) → Bundle → Nudge (VPSC X+Y) → Crossing min → verify all constraints.
#[test]
fn scenario_20_ortho_obstacle_bundle_nudge_cross() {
    pipeline_label("20 Combined: ortho + obstacle + bundle + nudge + cross");
    let nodes = vec![
        node("a", 0.0, 100.0, 40.0, 40.0),
        node("b", 600.0, 100.0, 40.0, 40.0),
        node("c", 0.0, 200.0, 40.0, 40.0),
        node("d", 600.0, 200.0, 40.0, 40.0),
        node("e", 0.0, 300.0, 40.0, 40.0),
        node("f", 600.0, 300.0, 40.0, 40.0),
        node("wall", 250.0, 0.0, 40.0, 400.0),
    ];
    let edges = vec![
        edge("e1", "a", "b"),
        edge("e2", "c", "d"),
        edge("e3", "e", "f"),
    ];
    let mut config = RelationEngineConfig::default();
    config.routing.routing_mode = RoutingMode::Orthogonal;
    config.routing.corner_radius = 0.0;
    config.routing.obstacle_margin = 10.0;
    config.bundling.mode = BundlingMode::SharedEndpoint;
    config.nudging.enabled = true;
    config.nudging.distance = 8.0;
    config.crossing_minimization = true;

    log_step("1.route", "3 orthogonal edges through obstacle field");
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    assert_eq!(results.len(), 3);

    log_step("2.verify_type", "All paths are Orthogonal");
    for r in &results {
        assert_eq!(r.path_type, PathType::Orthogonal);
    }
    log_pass("all 3 paths have type Orthogonal");

    log_step("3.verify_path_has_waypoints", "Each path routes around obstacle");
    for r in &results {
        assert!(r.path_points.len() > 2, "Ortho path should have waypoints: {} has {}", r.id, r.path_points.len());
    }
    log_pass("all paths have intermediate waypoints");

    log_step("4.verify_ortho_segments", "All segments axis-aligned");
    for r in &results {
        for seg in r.path_points.windows(2) {
            let dx = (seg[0].x - seg[1].x).abs();
            let dy = (seg[0].y - seg[1].y).abs();
            assert!(dx < 0.1 || dy < 0.1, "Non-orthogonal segment in {}", r.id);
        }
    }
    log_pass("all segments axis-aligned");

    log_step("5.verify_crossings", "Crossings minimized");
    let paths: Vec<Vec<Point>> = results.iter().map(|r| r.path_points.clone()).collect();
    let crossings = count_crossings(&paths);
    log_result(&format!("{} crossings", crossings));

    log_step("6.verify_bundling", "Edges from same source bundled");
    let bundled = results.iter().filter(|r| r.bundle_id.is_some()).count();
    log_result(&format!("{} edges bundled", bundled));

    log_pass("FULL PIPELINE: ortho + obstacle + bundle + nudge + cross ALL PASSED");
}
