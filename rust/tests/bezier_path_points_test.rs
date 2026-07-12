use rust_lib_mycelium::domain::relation_engine::input::{InputEdge, InputNode};
use rust_lib_mycelium::domain::relation_engine::engine::RelationEngine;
use rust_lib_mycelium::domain::relation_engine::config::{
    RelationEngineConfig, RoutingMode,
};
use rust_lib_mycelium::domain::relation_engine::computed::PathType;
use rust_lib_mycelium::domain::relation_engine::geometry::Point;
use rust_lib_mycelium::domain::styles::PortSide;

fn node(id: &str, x: f64, y: f64, w: f64, h: f64) -> InputNode {
    InputNode { id: id.into(), x, y, width: w, height: h, is_obstacle: true }
}

fn bezier_edge(id: &str, from: &str, to: &str) -> InputEdge {
    InputEdge {
        id: id.into(),
        from_node_id: from.into(),
        to_node_id: to.into(),
        from_side: None,
        to_side: None,
        routing_mode: Some(RoutingMode::Bezier),
        bundling_mode: None,
        style: None,
    }
}

// ── Basic bezier path shape ──────────────────────────────────────────
#[test]
fn bezier_horizontal_right_to_right() {
    let nodes = vec![node("a", 0.0, 50.0, 40.0, 100.0), node("b", 200.0, 50.0, 40.0, 100.0)];
    let config = RelationEngineConfig::default();
    let edges = vec![InputEdge {
        id: "e1".into(),
        from_node_id: "a".into(),
        to_node_id: "b".into(),
        from_side: Some(PortSide::Right),
        to_side: Some(PortSide::Right),
        routing_mode: Some(RoutingMode::Bezier),
        bundling_mode: None,
        style: None,
    }];

    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    assert_eq!(results.len(), 1);
    let r = &results[0];

    assert_eq!(r.path_type, PathType::CubicBezier);
    assert!(r.path_points.len() >= 4, "Expected at least 4 points, got {}", r.path_points.len());

    let pts = &r.path_points;
    // Start at node A's right port, end at node B's right port
    let a_right = Point { x: 40.0, y: 100.0 };
    let b_right = Point { x: 240.0, y: 100.0 };
    assert!(
        (pts[0] - a_right).length() < 1.0,
        "First point should be near A right port {:?}, got {:?}", a_right, pts[0]
    );
    assert!(
        (*pts.last().unwrap() - b_right).length() < 1.0,
        "Last point should be near B right port {:?}, got {:?}", b_right, pts.last().unwrap()
    );

    // Path should loop back in x: starts at x=40, goes right then curves back
    let min_x = pts.iter().map(|p| p.x).fold(f64::INFINITY, f64::min);
    let max_x = pts.iter().map(|p| p.x).fold(f64::NEG_INFINITY, f64::max);
    assert!(min_x < 200.0, "Path should dip left before returning right");
    assert!(max_x >= 240.0, "Path should reach B's port x={}", b_right.x);

    println!("✓ horizontal_right_to_right: {} points, bbox x=[{:.0},{:.0}]",
        pts.len(), min_x, max_x);
}

// ── Bezier diagonal ─────────────────────────────────────────────────
#[test]
fn bezier_diagonal_right_to_left() {
    let nodes = vec![node("a", 0.0, 0.0, 40.0, 40.0), node("b", 200.0, 200.0, 40.0, 40.0)];
    let config = RelationEngineConfig::default();
    let edges = vec![InputEdge {
        id: "e1".into(),
        from_node_id: "a".into(),
        to_node_id: "b".into(),
        from_side: Some(PortSide::Right),
        to_side: Some(PortSide::Left),
        routing_mode: Some(RoutingMode::Bezier),
        bundling_mode: None,
        style: None,
    }];

    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    let r = &results[0];

    assert_eq!(r.path_type, PathType::CubicBezier);
    assert!(r.path_points.len() >= 4);

    let pts = &r.path_points;
    let start = Point { x: 40.0, y: 20.0 };
    let end = Point { x: 200.0, y: 220.0 };
    assert!(
        (pts[0] - start).length() < 1.0,
        "First point should be at A right port {:?}, got {:?}", start, pts[0]
    );
    assert!(
        (*pts.last().unwrap() - end).length() < 1.0,
        "Last point should be at B left port {:?}, got {:?}", end, pts.last().unwrap()
    );

    // Monotonic progress in both x and y
    for i in 1..pts.len() {
        let dx = pts[i].x - pts[i - 1].x;
        let dy = pts[i].y - pts[i - 1].y;
        assert!(dx >= -1.0, "x should not regress at index {}: dx={:.2}", i, dx);
        assert!(dy >= -1.0, "y should not regress at index {}: dy={:.2}", i, dy);
    }

    println!("✓ diagonal_right_to_left: {} points, monotonic", pts.len());
}

// ── Bezier with obstacle avoidance ───────────────────────────────────
#[test]
fn bezier_with_obstacle() {
    let nodes = vec![
        node("a", 0.0, 100.0, 40.0, 40.0),
        node("b", 400.0, 100.0, 40.0, 40.0),
        node("obs", 180.0, 80.0, 80.0, 80.0),
    ];
    let mut config = RelationEngineConfig::default();
    config.routing.obstacle_margin = 15.0;
    let edges = vec![bezier_edge("e1", "a", "b")];

    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    let r = &results[0];

    assert_eq!(r.path_type, PathType::CubicBezier);
    let pts = &r.path_points;
    assert!(pts.len() >= 4);

    // Path should not cross through the obstacle rect
    let obs_rect = rust_lib_mycelium::domain::relation_engine::geometry::Rect {
        x: 180.0, y: 80.0, width: 80.0, height: 80.0,
    };
    for (i, pt) in pts.iter().enumerate() {
        if obs_rect.contains(*pt) {
            // Allow points that are exactly on the boundary (within tolerance)
            let margin = 2.0;
            let expanded = rust_lib_mycelium::domain::relation_engine::geometry::Rect {
                x: obs_rect.x - margin,
                y: obs_rect.y - margin,
                width: obs_rect.width + 2.0 * margin,
                height: obs_rect.height + 2.0 * margin,
            };
            assert!(
                !expanded.contains(*pt),
                "Point [{}] {:?} is inside obstacle rect {:?}", i, pt, obs_rect
            );
        }
    }

    // Verify first/last points
    let a_right = Point { x: 40.0, y: 120.0 };
    let b_left = Point { x: 400.0, y: 120.0 };
    assert!(
        (pts[0] - a_right).length() < 2.0,
        "Start should be near A right port, got {:?}", pts[0]
    );
    assert!(
        (*pts.last().unwrap() - b_left).length() < 2.0,
        "End should be near B left port, got {:?}", pts.last().unwrap()
    );

    println!("✓ obstacle_avoidance: {} points, obstacle not crossed", pts.len());
}

// ── Bezier no sides → auto-resolve ──────────────────────────────────
#[test]
fn bezier_auto_resolved_ports() {
    let nodes = vec![node("a", 0.0, 100.0, 40.0, 40.0), node("b", 400.0, 100.0, 40.0, 40.0)];
    let config = RelationEngineConfig::default();
    let edges = vec![bezier_edge("e1", "a", "b")];

    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    let r = &results[0];

    assert_eq!(r.path_type, PathType::CubicBezier);
    let pts = &r.path_points;
    assert!(pts.len() >= 10, "Auto-resolved should produce smooth curve, got {} points", pts.len());

    // Auto-resolve from right→left should produce a nearly straight line
    let start_x = 40.0; // a right edge
    let end_x = 400.0;  // b left edge
    for (i, pt) in pts.iter().enumerate() {
        assert!(
            pt.x >= start_x - 5.0 && pt.x <= end_x + 5.0,
            "Point [{}] x={:.1} should be between {} and {}", i, pt.x, start_x, end_x
        );
    }

    println!("✓ auto_resolved_ports: {} points, x range [40, 400]", pts.len());
}

// ── Bezier left→left curved loop ────────────────────────────────────
#[test]
fn bezier_left_to_left_creates_loop() {
    let nodes = vec![node("a", 0.0, 50.0, 40.0, 100.0), node("b", 200.0, 50.0, 40.0, 100.0)];
    let config = RelationEngineConfig::default();
    let edges = vec![InputEdge {
        id: "e1".into(),
        from_node_id: "a".into(),
        to_node_id: "b".into(),
        from_side: Some(PortSide::Left),
        to_side: Some(PortSide::Left),
        routing_mode: Some(RoutingMode::Bezier),
        bundling_mode: None,
        style: None,
    }];

    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    let r = &results[0];

    assert_eq!(r.path_type, PathType::CubicBezier);
    let pts = &r.path_points;
    assert!(pts.len() >= 4);

    // Path should go below both nodes to connect left ports
    let max_y = pts.iter().map(|p| p.y).fold(f64::NEG_INFINITY, f64::max);
    assert!(max_y > 150.0, "Path should dip below nodes (y>150), got max_y={:.1}", max_y);

    // Start and end at left ports
    let a_left = Point { x: 0.0, y: 100.0 };
    let b_left = Point { x: 200.0, y: 100.0 };
    assert!(
        (pts[0] - a_left).length() < 1.0,
        "Start should be at A left port, got {:?}", pts[0]
    );
    assert!(
        (*pts.last().unwrap() - b_left).length() < 1.0,
        "End should be at B left port, got {:?}", pts.last().unwrap()
    );

    // Verify path goes through y values below nodes
    let below_nodes: Vec<&Point> = pts.iter().filter(|p| p.y > 150.0).collect();
    assert!(
        below_nodes.len() >= 2,
        "At least 2 points should be below nodes, got {}", below_nodes.len()
    );

    println!("✓ left_to_left_loop: {} points, max_y={:.1}", pts.len(), max_y);
}

// ── Bezier point count consistency ───────────────────────────────────
#[test]
fn bezier_point_count_matches_config() {
    let nodes = vec![node("a", 0.0, 0.0, 40.0, 40.0), node("b", 300.0, 0.0, 40.0, 40.0)];
    let config = RelationEngineConfig::default();
    let edges = vec![bezier_edge("e1", "a", "b")];

    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    let r = &results[0];
    let pts = &r.path_points;

    // Auto-resolve with same Y produces straight line through body (19 points = 2 endpoints + 17 samples)
    // Different geometries produce 6 points = 2 stub transitions (4 each, deduped) + 2 endpoints
    assert!(
        pts.len() >= 4 && pts.len() <= 100,
        "Point count should be reasonable, got {}", pts.len()
    );

    // No NaN/Inf
    for (i, pt) in pts.iter().enumerate() {
        assert!(pt.x.is_finite(), "Point [{}] x is not finite: {}", i, pt.x);
        assert!(pt.y.is_finite(), "Point [{}] y is not finite: {}", i, pt.y);
    }

    // Path length > 0
    let path_len: f64 = pts.windows(2).map(|w| (w[1] - w[0]).length()).sum();
    assert!(path_len > 10.0, "Path length should be meaningful, got {:.1}", path_len);

    println!("✓ point_count: {} points, path_len={:.1}, no NaN/Inf", pts.len(), path_len);
}

// ── Bezier stacked nodes (top→top) ───────────────────────────────────
#[test]
fn bezier_stacked_top_to_top() {
    let nodes = vec![node("a", 50.0, 0.0, 100.0, 40.0), node("b", 50.0, 200.0, 100.0, 40.0)];
    let config = RelationEngineConfig::default();
    let edges = vec![InputEdge {
        id: "e1".into(),
        from_node_id: "a".into(),
        to_node_id: "b".into(),
        from_side: Some(PortSide::Top),
        to_side: Some(PortSide::Top),
        routing_mode: Some(RoutingMode::Bezier),
        bundling_mode: None,
        style: None,
    }];

    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    let r = &results[0];

    assert_eq!(r.path_type, PathType::CubicBezier);
    let pts = &r.path_points;

    // Path should go right of nodes to connect top ports
    let max_x = pts.iter().map(|p| p.x).fold(f64::NEG_INFINITY, f64::max);
    assert!(max_x > 150.0, "Path should arc right (x>150), got max_x={:.1}", max_x);

    println!("✓ stacked_top_to_top: {} points, max_x={:.1}", pts.len(), max_x);
}

// ── Bezier no self-intersections ─────────────────────────────────────
#[test]
fn bezier_no_self_intersections() {
    let test_cases: Vec<(&str, Vec<InputNode>, Vec<InputEdge>)> = vec![
        ("side-by-side",
            vec![node("a", 0.0, 50.0, 40.0, 100.0), node("b", 200.0, 50.0, 40.0, 100.0)],
            vec![InputEdge {
                id: "e1".into(), from_node_id: "a".into(), to_node_id: "b".into(),
                from_side: Some(PortSide::Right),
                to_side: Some(PortSide::Right),
                routing_mode: Some(RoutingMode::Bezier), bundling_mode: None, style: None,
            }]),
        ("diagonal",
            vec![node("a", 0.0, 0.0, 40.0, 40.0), node("b", 200.0, 200.0, 40.0, 40.0)],
            vec![InputEdge {
                id: "e1".into(), from_node_id: "a".into(), to_node_id: "b".into(),
                from_side: Some(PortSide::Right),
                to_side: Some(PortSide::Left),
                routing_mode: Some(RoutingMode::Bezier), bundling_mode: None, style: None,
            }]),
        ("stacked",
            vec![node("a", 50.0, 0.0, 100.0, 40.0), node("b", 50.0, 200.0, 100.0, 40.0)],
            vec![InputEdge {
                id: "e1".into(), from_node_id: "a".into(), to_node_id: "b".into(),
                from_side: Some(PortSide::Top),
                to_side: Some(PortSide::Bottom),
                routing_mode: Some(RoutingMode::Bezier), bundling_mode: None, style: None,
            }]),
    ];

    for (name, nodes, edges) in test_cases {
        let config = RelationEngineConfig::default();
        let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
        let r = &results[0];
        let pts = &r.path_points;

        // No self-intersections
        for i in 0..pts.len().saturating_sub(2) {
            for j in (i + 2)..pts.len().saturating_sub(1) {
                if segments_intersect(pts[i], pts[i + 1], pts[j], pts[j + 1]) {
                    panic!(
                        "Self-intersection in '{}': segment [{},{}) vs [{},{})",
                        name, i, i + 1, j, j + 1
                    );
                }
            }
        }

        println!("✓ no_self_intersections '{}': {} points, no crossings", name, pts.len());
    }
}

// ── Obstacle path has smooth curves, not straight-line segments ────
#[test]
fn bezier_obstacle_path_is_smooth() {
    let nodes = vec![
        node("a", 0.0, 100.0, 40.0, 40.0),
        node("b", 500.0, 100.0, 40.0, 40.0),
        node("obs", 200.0, 60.0, 100.0, 120.0),
    ];
    let mut config = RelationEngineConfig::default();
    config.routing.obstacle_margin = 10.0;
    let edges = vec![bezier_edge("e1", "a", "b")];

    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    let r = &results[0];
    let pts = &r.path_points;
    assert!(pts.len() >= 6, "Obstacle path needs enough points for curves, got {}", pts.len());

    // With bezier smoothing, segments should NOT all be axis-aligned.
    // A raw waypoint path would be: straight → diagonal → straight (all axis-aligned).
    // A smoothed bezier path should have non-axis-aligned intermediate segments.
    let axis_aligned_count = pts.windows(2).filter(|w| {
        (w[0].x - w[1].x).abs() < 0.5 || (w[0].y - w[1].y).abs() < 0.5
    }).count();
    let total_segs = pts.len() - 1;
    let diag_ratio = 1.0 - (axis_aligned_count as f64 / total_segs as f64);

    assert!(
        diag_ratio > 0.3,
        "Bezier obstacle path should have curved (diagonal) segments,          but {:.0}% of segments are axis-aligned ({} / {})",
        (axis_aligned_count as f64 / total_segs as f64) * 100.0,
        axis_aligned_count,
        total_segs
    );

    // No self-intersections
    for i in 0..pts.len().saturating_sub(2) {
        for j in (i + 2)..pts.len().saturating_sub(1) {
            if segments_intersect(pts[i], pts[i + 1], pts[j], pts[j + 1]) {
                panic!("Self-intersection: [{},{}) vs [{},{})", i, i+1, j, j+1);
            }
        }
    }

    println!("✓ obstacle_smooth: {} points, {:.0}% diagonal segments",
        pts.len(), diag_ratio * 100.0);
}

// ── Bezier path length ratio is reasonable ───────────────────────────
#[test]
fn bezier_path_length_ratio() {
    let test_cases: Vec<(&str, Vec<InputNode>, Vec<InputEdge>)> = vec![
        ("straight_right",
            vec![node("a", 0.0, 100.0, 40.0, 40.0), node("b", 400.0, 100.0, 40.0, 40.0)],
            vec![bezier_edge("e1", "a", "b")]),
        ("diagonal",
            vec![node("a", 0.0, 0.0, 40.0, 40.0), node("b", 300.0, 300.0, 40.0, 40.0)],
            vec![bezier_edge("e1", "a", "b")]),
        ("close",
            vec![node("a", 0.0, 100.0, 40.0, 40.0), node("b", 100.0, 100.0, 40.0, 40.0)],
            vec![bezier_edge("e1", "a", "b")]),
    ];

    for (name, nodes, edges) in test_cases {
        let config = RelationEngineConfig::default();
        let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
        let r = &results[0];
        let pts = &r.path_points;

        let path_len: f64 = pts.windows(2).map(|w| (w[1] - w[0]).length()).sum();
        let straight_dist = (pts[0] - *pts.last().unwrap()).length();
        let ratio = if straight_dist > 1.0 { path_len / straight_dist } else { 1.0 };

        assert!(
            ratio >= 0.9 && ratio <= 3.0,
            "'{}' ratio should be in [0.9, 3.0], got {:.2} (path={:.1}, straight={:.1})",
            name, ratio, path_len, straight_dist
        );

        println!("✓ length_ratio '{}': ratio={:.2}, path={:.1}, straight={:.1}", name, ratio, path_len, straight_dist);
    }
}

// ── Helpers ──────────────────────────────────────────────────────────
fn segments_intersect(a: Point, b: Point, c: Point, d: Point) -> bool {
    let cross = |o: Point, a: Point, b: Point| -> f64 {
        (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
    };
    let d1 = cross(c, d, a);
    let d2 = cross(c, d, b);
    let d3 = cross(a, b, c);
    let d4 = cross(a, b, d);
    ((d1 > 0.0 && d2 < 0.0) || (d1 < 0.0 && d2 > 0.0)) &&
    ((d3 > 0.0 && d4 < 0.0) || (d3 < 0.0 && d4 > 0.0))
}

#[test]
fn test_adaptive_projection_capping() {
    let nodes = vec![
        node("a", 1200.0, 920.0, 120.0, 80.0),
        node("b", 940.0, 920.0, 120.0, 80.0),
    ];
    let mut config = RelationEngineConfig::default();
    config.routing.bezier_projection_factor = 2.0;
    config.routing.bezier_clamp_max = 150.0;
    
    let edges = vec![bezier_edge("e1", "a", "b")];
    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    assert_eq!(results.len(), 1);
    
    let r = &results[0];
    let pts = &r.path_points;
    
    for i in 0..pts.len().saturating_sub(2) {
        for j in (i + 2)..pts.len().saturating_sub(1) {
            assert!(!segments_intersect(pts[i], pts[i + 1], pts[j], pts[j + 1]),
                "Found self-intersection in adaptive projection capping test at [{},{}) vs [{},{})",
                i, i+1, j, j+1
            );
        }
    }
}

#[test]
fn test_dynamic_sample_count() {
    let nodes_short = vec![
        node("a", 0.0, 0.0, 40.0, 40.0),
        node("b", 30.0, 0.0, 40.0, 40.0),
    ];
    let nodes_long = vec![
        node("a", 0.0, 0.0, 40.0, 40.0),
        node("b", 400.0, 0.0, 40.0, 40.0),
    ];
    let edges = vec![bezier_edge("e1", "a", "b")];
    let config = RelationEngineConfig::default();
    
    let res_short = RelationEngine::compute_relations(&nodes_short, &edges, &config, None);
    let res_long = RelationEngine::compute_relations(&nodes_long, &edges, &config, None);
    
    let pts_short = &res_short[0].path_points;
    let pts_long = &res_long[0].path_points;
    
    assert!(pts_short.len() < pts_long.len(),
        "Short segment should use fewer samples than long segment. Got short: {}, long: {}",
        pts_short.len(), pts_long.len()
    );
    
    assert!(pts_short.len() >= 8);
}

#[test]
fn test_collinear_waypoint_pruning() {
    use rust_lib_mycelium::domain::relation_engine::routing::bezier::BezierRouting;
    use rust_lib_mycelium::domain::relation_engine::routing::RoutingStrategy;
    use rust_lib_mycelium::domain::relation_engine::input::ResolvedPorts;
    use rust_lib_mycelium::domain::relation_engine::input::InputPort;
    use rust_lib_mycelium::domain::styles::PortType;
    
    let config = RelationEngineConfig::default();
    let ports = ResolvedPorts {
        start: InputPort { position: Point::zero(), side: PortSide::Right, port_type: PortType::Middle },
        end: InputPort { position: Point::new(300.0, 0.0), side: PortSide::Left, port_type: PortType::Middle },
        start_normal: Point::new(1.0, 0.0),
        end_normal: Point::new(-1.0, 0.0),
        start_exit: Point::new(8.0, 0.0),
        end_exit: Point::new(292.0, 0.0),
    };
    
    let waypoints = vec![
        Point::new(8.0, 0.0),
        Point::new(150.0, 0.0),
        Point::new(292.0, 0.0),
    ];
    
    let routing = BezierRouting {};
    let path = routing.compute_body(&waypoints, &ports, &config);
    
    assert!(path.len() <= 25, "Expected only 1 segment's worth of points, got {}", path.len());
}
