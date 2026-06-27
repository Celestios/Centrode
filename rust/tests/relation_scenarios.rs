use rust_lib_mycelium::domain::relation_engine::input::{InputEdge, InputNode};
use rust_lib_mycelium::domain::relation_engine::engine::RelationEngine;
use rust_lib_mycelium::domain::relation_engine::config::RelationEngineConfig;
use rust_lib_mycelium::domain::relation_engine::geometry::Point;
use rust_lib_mycelium::domain::styles::PortSide;

fn node(id: &str, x: f64, y: f64, w: f64, h: f64) -> InputNode {
    InputNode { id: id.into(), x, y, width: w, height: h }
}

fn edge(id: &str, from: &str, to: &str, from_side: Option<PortSide>, to_side: Option<PortSide>, strategy: &str) -> InputEdge {
    InputEdge {
        id: id.into(),
        from_node_id: from.into(),
        to_node_id: to.into(),
        from_side,
        to_side,
        routing_mode: Some(rust_lib_mycelium::domain::relation_engine::config::RoutingMode::from_str(strategy)),
        bundling_mode: None,
        style: None,
    }
}

fn dump(name: &str, r: &rust_lib_mycelium::domain::relation_engine::computed::ComputedRelation) {
    println!("\n=== {} ===", name);
    println!("  path_type: {:?}", r.path_type);
    println!("  points ({}):", r.path_points.len());
    for (i, p) in r.path_points.iter().enumerate() {
        println!("    [{:2}] ({:.1}, {:.1})", i, p.x, p.y);
    }
    println!("  start_tangent: ({:.3}, {:.3})", r.start_tangent.x, r.start_tangent.y);
    println!("  end_tangent: ({:.3}, {:.3})", r.end_tangent.x, r.end_tangent.y);
    println!("  body_widths: {:?}", r.body_widths);
    println!("  start_endpoint: {:?}", r.start_endpoint);
    println!("  end_endpoint: {:?}", r.end_endpoint);
}

fn path_intersects_rect(points: &[Point], rect: &rust_lib_mycelium::domain::relation_engine::geometry::Rect) -> bool {
    let margin = 2.0;
    let r = rect.expand(-margin);
    for p in points {
        if p.x > r.left() && p.x < r.right() && p.y > r.top() && p.y < r.bottom() {
            return true;
        }
    }
    false
}

fn port_position(node: &InputNode, side: PortSide) -> Point {
    let r = node.rect();
    match side {
        PortSide::Left => Point::new(r.left(), r.top() + r.height / 2.0),
        PortSide::Right => Point::new(r.right(), r.top() + r.height / 2.0),
        PortSide::Top => Point::new(r.left() + r.width / 2.0, r.top()),
        PortSide::Bottom => Point::new(r.left() + r.width / 2.0, r.bottom()),
        PortSide::TopLeft => Point::new(r.left(), r.top()),
        PortSide::TopRight => Point::new(r.right(), r.top()),
        PortSide::BottomLeft => Point::new(r.left(), r.bottom()),
        PortSide::BottomRight => Point::new(r.right(), r.bottom()),
        _ => Point::new(r.left() + r.width / 2.0, r.top() + r.height / 2.0),
    }
}

fn closest_port_position(node: &InputNode, target: Point) -> Point {
    let r = node.rect();
    let candidates = [
        (Point::new(r.left() + r.width / 2.0, r.top()), "top"),
        (Point::new(r.right(), r.top() + r.height / 2.0), "right"),
        (Point::new(r.left() + r.width / 2.0, r.bottom()), "bottom"),
        (Point::new(r.left(), r.top() + r.height / 2.0), "left"),
    ];
    candidates.iter()
        .min_by(|a, b| {
            let da = (a.0 - target).length();
            let db = (b.0 - target).length();
            da.partial_cmp(&db).unwrap()
        })
        .unwrap().0
}

fn angle_between(a: Point, b: Point) -> f64 {
    let dot = a.x * b.x + a.y * b.y;
    let mag_a = a.length();
    let mag_b = b.length();
    if mag_a < 1e-10 || mag_b < 1e-10 { return 0.0; }
    let cos = (dot / (mag_a * mag_b)).clamp(-1.0, 1.0);
    cos.acos()
}

fn min_turn_angle(points: &[Point]) -> f64 {
    if points.len() < 3 { return std::f64::consts::PI; }
    let mut min_angle = std::f64::consts::PI;
    for i in 1..points.len() - 1 {
        let prev_dir = (points[i] - points[i - 1]).normalized();
        let next_dir = (points[i + 1] - points[i]).normalized();
        let angle = angle_between(prev_dir, next_dir);
        if angle < min_angle {
            min_angle = angle;
        }
    }
    min_angle
}

fn is_smooth(points: &[Point], min_angle_deg: f64) -> bool {
    let min_rad = min_angle_deg.to_radians();
    min_turn_angle(points) >= min_rad
}

fn has_self_intersection(points: &[Point]) -> bool {
    for i in 0..points.len().saturating_sub(1) {
        for j in (i + 2)..points.len().saturating_sub(1) {
            let a1 = points[i];
            let a2 = points[i + 1];
            let b1 = points[j];
            let b2 = points[j + 1];
            if segments_intersect(a1, a2, b1, b2) {
                return true;
            }
        }
    }
    false
}

fn segments_intersect(a: Point, b: Point, c: Point, d: Point) -> bool {
    let cross = |o: Point, a: Point, b: Point| -> f64 {
        (a.x - o.x) * (b.y - o.y) - (a.y - o.y) * (b.x - o.x)
    };
    let d1 = cross(c, d, a);
    let d2 = cross(c, d, b);
    let d3 = cross(a, b, c);
    let d4 = cross(a, b, d);
    if ((d1 > 0.0 && d2 < 0.0) || (d1 < 0.0 && d2 > 0.0)) &&
       ((d3 > 0.0 && d4 < 0.0) || (d3 < 0.0 && d4 > 0.0)) {
        return true;
    }
    false
}

fn all_segments_axis_aligned(points: &[Point], tolerance: f64) -> bool {
    points.windows(2).all(|w| {
        (w[0].x - w[1].x).abs() < tolerance || (w[0].y - w[1].y).abs() < tolerance
    })
}

fn dominant_direction(p: Point) -> (f64, f64) {
    if p.x.abs() >= p.y.abs() {
        (p.x.signum(), 0.0)
    } else {
        (0.0, p.y.signum())
    }
}

struct CheckResult {
    name: String,
    issues: Vec<String>,
    warnings: Vec<String>,
    metrics: Vec<(String, String)>,
}

fn check(
    name: &str,
    r: &rust_lib_mycelium::domain::relation_engine::computed::ComputedRelation,
    from_node: &InputNode,
    to_node: &InputNode,
    from_side: Option<PortSide>,
    to_side: Option<PortSide>,
    config: &RelationEngineConfig,
) -> CheckResult {
    let from_rect = from_node.rect();
    let to_rect = to_node.rect();
    let pts = &r.path_points;

    let mut issues = Vec::new();
    let mut warnings = Vec::new();
    let mut metrics = Vec::new();

    let from_hit = path_intersects_rect(&pts[1..], &from_rect);
    let to_hit = path_intersects_rect(&pts[..pts.len().saturating_sub(1)], &to_rect);
    if from_hit { issues.push("PATH_CROSSES_FROM_NODE".to_string()); }
    if to_hit { issues.push("PATH_CROSSES_TO_NODE".to_string()); }

    let start_port = if let Some(ref s) = from_side {
        port_position(from_node, s.clone())
    } else {
        closest_port_position(from_node, to_node.center())
    };
    let end_port = if let Some(ref s) = to_side {
        port_position(to_node, s.clone())
    } else {
        closest_port_position(to_node, from_node.center())
    };
    let start_dist = (pts[0] - start_port).length();
    let end_dist = (*pts.last().unwrap() - end_port).length();
    metrics.push(("start_offset".into(), format!("{:.1}", start_dist)));
    metrics.push(("end_offset".into(), format!("{:.1}", end_dist)));
    if start_dist > 5.0 { warnings.push(format!("START_OFF_PORT({:.1})", start_dist)); }
    if end_dist > 5.0 { warnings.push(format!("END_OFF_PORT({:.1})", end_dist)); }

    if has_self_intersection(pts) { issues.push("SELF_INTERSECTING".to_string()); }

    if r.path_type == rust_lib_mycelium::domain::relation_engine::computed::PathType::Orthogonal {
        let is_ortho = all_segments_axis_aligned(pts, config.routing.corner_radius + 1.0);
        metrics.push(("axis_aligned".into(), format!("{}", is_ortho)));
        if !is_ortho { issues.push("NOT_AXIS_ALIGNED".to_string()); }

        let min_angle = min_turn_angle(pts).to_degrees();
        metrics.push(("min_turn_deg".into(), format!("{:.1}", min_angle)));
    }

    if r.path_type == rust_lib_mycelium::domain::relation_engine::computed::PathType::CubicBezier {
        let min_angle = min_turn_angle(pts).to_degrees();
        metrics.push(("min_turn_deg".into(), format!("{:.1}", min_angle)));
        if min_angle < 45.0 {
            warnings.push(format!("SHARP_TURN({:.0}deg)", min_angle));
        }
    }

    let path_len: f64 = pts.windows(2).map(|w| (w[1] - w[0]).length()).sum();
    let straight_dist = (start_port - end_port).length();
    let ratio = if straight_dist > 1.0 { path_len / straight_dist } else { 1.0 };
    metrics.push(("path_len".into(), format!("{:.1}", path_len)));
    metrics.push(("straight_dist".into(), format!("{:.1}", straight_dist)));
    metrics.push(("length_ratio".into(), format!("{:.2}", ratio)));
    if ratio > 5.0 { warnings.push(format!("PATH_VERY_LONG(ratio={:.1})", ratio)); }

    if let Some(ref s) = from_side {
        let expected_dir = match s {
            PortSide::Left => (-1.0, 0.0),
            PortSide::Right => (1.0, 0.0),
            PortSide::Top => (0.0, -1.0),
            PortSide::Bottom => (0.0, 1.0),
            _ => (0.0, 0.0),
        };
        let actual_dir = (r.start_tangent.x, r.start_tangent.y);
        let dot = expected_dir.0 * actual_dir.0 + expected_dir.1 * actual_dir.1;
        metrics.push(("start_tangent_match".into(), format!("{:.3}", dot)));
        if dot < 0.5 && !(expected_dir.0 == 0.0 && expected_dir.1 == 0.0) {
            warnings.push(format!("START_TANGENT_WRONG(dot={:.2})", dot));
        }
    }
    if let Some(ref s) = to_side {
        let expected_dir = match s {
            PortSide::Left => (-1.0, 0.0),
            PortSide::Right => (1.0, 0.0),
            PortSide::Top => (0.0, -1.0),
            PortSide::Bottom => (0.0, 1.0),
            _ => (0.0, 0.0),
        };
        let actual_dir = (r.end_tangent.x, r.end_tangent.y);
        let dot = expected_dir.0 * actual_dir.0 + expected_dir.1 * actual_dir.1;
        metrics.push(("end_tangent_match".into(), format!("{:.3}", dot)));
        if dot < 0.5 && !(expected_dir.0 == 0.0 && expected_dir.1 == 0.0) {
            warnings.push(format!("END_TANGENT_WRONG(dot={:.2})", dot));
        }
    }

    let x_min = pts.iter().map(|p| p.x).fold(f64::INFINITY, f64::min);
    let x_max = pts.iter().map(|p| p.x).fold(f64::NEG_INFINITY, f64::max);
    let y_min = pts.iter().map(|p| p.y).fold(f64::INFINITY, f64::min);
    let y_max = pts.iter().map(|p| p.y).fold(f64::NEG_INFINITY, f64::max);
    metrics.push(("bbox".into(), format!("({:.0},{:.0})-({:.0},{:.0})", x_min, y_min, x_max, y_max)));
    metrics.push(("point_count".into(), format!("{}", pts.len())));

    CheckResult { name: name.to_string(), issues, warnings, metrics }
}

#[test]
fn all_scenarios() {
    let config = RelationEngineConfig::default();
    println!("=== CONFIG ===");
    println!("  routing: {:?}", config.routing.routing_mode);
    println!("  corner_radius: {}", config.routing.corner_radius);
    println!("  bezier_proj: {} clamp:[{},{}]", config.routing.bezier_projection_factor, config.routing.bezier_clamp_min, config.routing.bezier_clamp_max);
    println!("  endpoint: start={:?} end={:?} arrow={}", config.endpoint.default_start_shape, config.endpoint.default_end_shape, config.endpoint.arrow_size);

    let scenarios: Vec<(&str, Vec<InputNode>, Vec<InputEdge>)> = vec![
        ("Bezier: left→left side-by-side",
            vec![node("a", 0.0, 50.0, 40.0, 100.0), node("b", 200.0, 50.0, 40.0, 100.0)],
            vec![edge("e1", "a", "b", Some(PortSide::Left), Some(PortSide::Left), "bezier")]),
        ("Bezier: no sides auto-resolve",
            vec![node("a", 0.0, 50.0, 40.0, 100.0), node("b", 200.0, 50.0, 40.0, 100.0)],
            vec![edge("e1", "a", "b", None, None, "bezier")]),
        ("Bezier: left→left wide node (200px)",
            vec![node("a", 0.0, 50.0, 200.0, 100.0), node("b", 400.0, 50.0, 40.0, 100.0)],
            vec![edge("e1", "a", "b", Some(PortSide::Left), Some(PortSide::Left), "bezier")]),
        ("Bezier: right→left different Y",
            vec![node("a", 0.0, 0.0, 40.0, 40.0), node("b", 200.0, 200.0, 40.0, 40.0)],
            vec![edge("e1", "a", "b", Some(PortSide::Right), Some(PortSide::Left), "bezier")]),
        ("Bezier: right→right side-by-side",
            vec![node("a", 0.0, 50.0, 40.0, 100.0), node("b", 200.0, 50.0, 40.0, 100.0)],
            vec![edge("e1", "a", "b", Some(PortSide::Right), Some(PortSide::Right), "bezier")]),
        ("Bezier: top→top stacked",
            vec![node("a", 50.0, 0.0, 100.0, 40.0), node("b", 50.0, 200.0, 100.0, 40.0)],
            vec![edge("e1", "a", "b", Some(PortSide::Top), Some(PortSide::Top), "bezier")]),
        ("Bezier: bottom→bottom stacked",
            vec![node("a", 50.0, 0.0, 100.0, 40.0), node("b", 50.0, 200.0, 100.0, 40.0)],
            vec![edge("e1", "a", "b", Some(PortSide::Bottom), Some(PortSide::Bottom), "bezier")]),
        ("Bezier: top→bottom facing",
            vec![node("a", 50.0, 0.0, 40.0, 40.0), node("b", 50.0, 200.0, 40.0, 40.0)],
            vec![edge("e1", "a", "b", Some(PortSide::Top), Some(PortSide::Bottom), "bezier")]),
        ("Bezier: right→bottom cross",
            vec![node("a", 0.0, 0.0, 40.0, 40.0), node("b", 200.0, 100.0, 40.0, 40.0)],
            vec![edge("e1", "a", "b", Some(PortSide::Right), Some(PortSide::Bottom), "bezier")]),
        ("Bezier: topLeft→bottomRight corners",
            vec![node("a", 0.0, 50.0, 40.0, 100.0), node("b", 200.0, 50.0, 40.0, 100.0)],
            vec![edge("e1", "a", "b", Some(PortSide::TopLeft), Some(PortSide::BottomRight), "bezier")]),
        ("Ortho: left→left side-by-side",
            vec![node("a", 0.0, 50.0, 40.0, 100.0), node("b", 200.0, 50.0, 40.0, 100.0)],
            vec![edge("e1", "a", "b", Some(PortSide::Left), Some(PortSide::Left), "orthogonal")]),
        ("Ortho: left→left wide node",
            vec![node("a", 0.0, 50.0, 200.0, 100.0), node("b", 400.0, 50.0, 40.0, 100.0)],
            vec![edge("e1", "a", "b", Some(PortSide::Left), Some(PortSide::Left), "orthogonal")]),
        ("Ortho: right→right side-by-side",
            vec![node("a", 0.0, 50.0, 40.0, 100.0), node("b", 200.0, 50.0, 40.0, 100.0)],
            vec![edge("e1", "a", "b", Some(PortSide::Right), Some(PortSide::Right), "orthogonal")]),
        ("Ortho: top→top stacked",
            vec![node("a", 50.0, 0.0, 100.0, 40.0), node("b", 50.0, 200.0, 100.0, 40.0)],
            vec![edge("e1", "a", "b", Some(PortSide::Top), Some(PortSide::Top), "orthogonal")]),
        ("Ortho: bottom→bottom stacked",
            vec![node("a", 50.0, 0.0, 100.0, 40.0), node("b", 50.0, 200.0, 100.0, 40.0)],
            vec![edge("e1", "a", "b", Some(PortSide::Bottom), Some(PortSide::Bottom), "orthogonal")]),
        ("Ortho: left→right facing aligned",
            vec![node("a", 0.0, 50.0, 40.0, 100.0), node("b", 200.0, 50.0, 40.0, 100.0)],
            vec![edge("e1", "a", "b", Some(PortSide::Left), Some(PortSide::Right), "orthogonal")]),
        ("Ortho: left→right facing offset",
            vec![node("a", 0.0, 0.0, 40.0, 40.0), node("b", 200.0, 200.0, 40.0, 40.0)],
            vec![edge("e1", "a", "b", Some(PortSide::Left), Some(PortSide::Right), "orthogonal")]),
        ("Ortho: right→bottom cross",
            vec![node("a", 0.0, 0.0, 40.0, 40.0), node("b", 200.0, 100.0, 40.0, 40.0)],
            vec![edge("e1", "a", "b", Some(PortSide::Right), Some(PortSide::Bottom), "orthogonal")]),
        ("Ortho: topLeft→bottomRight corners",
            vec![node("a", 0.0, 50.0, 40.0, 100.0), node("b", 200.0, 50.0, 40.0, 100.0)],
            vec![edge("e1", "a", "b", Some(PortSide::TopLeft), Some(PortSide::BottomRight), "orthogonal")]),
    ];

    let mut pass = 0;
    let mut fail = 0;
    let mut warn_count = 0;

    for (name, nodes, edges) in &scenarios {
        let results = RelationEngine::compute_relations(nodes, edges, &config, None);
        let r = &results[0];
        dump(name, r);

        let from_node = nodes.iter().find(|n| n.id == edges[0].from_node_id).unwrap();
        let to_node = nodes.iter().find(|n| n.id == edges[0].to_node_id).unwrap();

        let result = check(name, r, from_node, to_node, edges[0].from_side.clone(), edges[0].to_side.clone(), &config);

        for (k, v) in &result.metrics {
            println!("  {} = {}", k, v);
        }

        if !result.warnings.is_empty() {
            println!("  !! WARN: {}", result.warnings.join(", "));
            warn_count += result.warnings.len();
        }

        if result.issues.is_empty() {
            println!("  >> PASS");
            pass += 1;
        } else {
            println!("  >> FAIL: {}", result.issues.join(", "));
            fail += 1;
        }
    }

    println!("\n=== RESULTS: {} pass, {} fail, {} warnings, {} total ===", pass, fail, warn_count, pass + fail);
    assert_eq!(fail, 0, "{} scenarios failed", fail);
}
