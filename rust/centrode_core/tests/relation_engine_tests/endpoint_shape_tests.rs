use centrode_core::domain::id::TypedRecordId;
use centrode_core::domain::styles::{EndpointShape, PortSide, RelationStyle};
use centrode_core::domain::traits::TableKind;
use centrode_core::relation_engine::config::{
    EndpointConfig, RelationEngineConfig, RoutingMode,
};
use centrode_core::relation_engine::engine::RelationEngine;
use centrode_core::relation_engine::geometry::Point;
use centrode_core::relation_engine::types::{InputEdge, InputNode};
use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};
use uuid::Uuid;

fn str_to_uuid(s: &str) -> Uuid {
    let mut hasher = DefaultHasher::new();
    s.hash(&mut hasher);
    let hash = hasher.finish();
    Uuid::from_u128(hash as u128)
}

fn tid(table: TableKind, s: &str) -> TypedRecordId {
    TypedRecordId::new(table, str_to_uuid(s))
}

fn create_node(id: &str, x: f64, y: f64, w: f64, h: f64) -> InputNode {
    InputNode {
        id: tid(TableKind::INode, id),
        x,
        y,
        width: w,
        height: h,
        is_obstacle: false,
    }
}

fn make_style(start_shape: Option<EndpointShape>, end_shape: Option<EndpointShape>) -> RelationStyle {
    RelationStyle {
        bg_color: 0,
        stroke_color: 0,
        stroke_width: 2,
        font_family: String::new(),
        font_size: 12.0,
        shape: String::new(),
        arrow_type: String::new(),
        arrow_size: 12.0,
        start_shape,
        end_shape,
        width: 0,
        height: 0,
        text_color: 0,
        shadow_color: 0,
        shadow_blur: 0.0,
        shadow_offset_x: 0.0,
        shadow_offset_y: 0.0,
        strategy_type: String::new(),
        stroke_pattern: String::new(),
        body_strategy: String::new(),
    }
}

fn create_edge(
    id: &str,
    from: &str,
    to: &str,
    start_shape: Option<EndpointShape>,
    end_shape: Option<EndpointShape>,
) -> InputEdge {
    InputEdge {
        id: tid(TableKind::IRelation, id),
        from_node_id: tid(TableKind::INode, from),
        to_node_id: tid(TableKind::INode, to),
        from_side: None,
        to_side: None,
        routing_mode: None,
        bundling_mode: None,
        style: Some(make_style(start_shape, end_shape)),
    }
}

#[allow(dead_code)]
fn create_edge_with_sides(
    id: &str,
    from: &str,
    to: &str,
    from_side: PortSide,
    to_side: PortSide,
    start_shape: Option<EndpointShape>,
    end_shape: Option<EndpointShape>,
) -> InputEdge {
    InputEdge {
        id: tid(TableKind::IRelation, id),
        from_node_id: tid(TableKind::INode, from),
        to_node_id: tid(TableKind::INode, to),
        from_side: Some(from_side),
        to_side: Some(to_side),
        routing_mode: None,
        bundling_mode: None,
        style: Some(make_style(start_shape, end_shape)),
    }
}

fn config_with_shapes(start: EndpointShape, end: EndpointShape) -> RelationEngineConfig {
    let mut config = RelationEngineConfig::default();
    config.endpoint = EndpointConfig {
        default_start_shape: start,
        default_end_shape: end,
        arrow_size: 12.0,
        handle_inset: 20.0,
    };
    config
}

// ---------------------------------------------------------------
// 1. Endpoint shapes follow relation body — direction alignment
// ---------------------------------------------------------------

#[test]
fn test_arrow_direction_follows_straight_body() {
    let config = config_with_shapes(EndpointShape::None, EndpointShape::Arrow);
    let nodes = vec![
        create_node("a", 0.0, 100.0, 80.0, 60.0),
        create_node("b", 400.0, 100.0, 80.0, 60.0),
    ];
    let edges = vec![create_edge(
        "r1",
        "a",
        "b",
        None,
        Some(EndpointShape::Arrow),
    )];

    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    assert_eq!(results.len(), 1);
    let r = &results[0];

    assert!(!r.end_shape_path.is_empty(), "end arrow polygon should exist");
    assert!(r.start_shape_path.is_empty(), "start has None shape");

    let end_dir = r.end_direction;
    let expected_dir = 0.0f64;
    let diff = (end_dir - expected_dir).abs();
    let wrapped = (diff - 2.0 * std::f64::consts::PI).abs();
    let min_diff = diff.min(wrapped);
    assert!(
        min_diff < 0.1,
        "end arrow direction {:.4} should ≈ 0 (pointing right), diff {:.4}",
        end_dir,
        min_diff,
    );
}

#[test]
fn test_arrow_direction_follows_body_when_node_moved() {
    let config = config_with_shapes(EndpointShape::None, EndpointShape::Arrow);

    let positions = [
        (400.0, 100.0),
        (400.0, 200.0),
        (400.0, 300.0),
        (300.0, 350.0),
    ];

    let mut prev_dir: Option<f64> = None;
    for (i, (bx, by)) in positions.iter().enumerate() {
        let nodes = vec![
            create_node("a", 0.0, 100.0, 80.0, 60.0),
            create_node("b", *bx, *by, 80.0, 60.0),
        ];
        let edges = vec![create_edge(
            "r1",
            "a",
            "b",
            None,
            Some(EndpointShape::Arrow),
        )];

        let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
        let r = &results[0];
        let dir = r.end_direction;

        if let Some(prev) = prev_dir {
            let diff = (dir - prev).abs();
            let wrapped = (diff - 2.0 * std::f64::consts::PI).abs();
            let min_diff = diff.min(wrapped);
            assert!(
                min_diff < 1.5,
                "step {}: direction jump {:.4} → {:.4} is too large ({:.4} rad)",
                i,
                prev,
                dir,
                min_diff,
            );
        }
        prev_dir = Some(dir);
    }
}

// ---------------------------------------------------------------
// 2. Endpoint shapes change angle smoothly — continuous change
// ---------------------------------------------------------------

#[test]
fn test_endpoint_angle_changes_continuously_with_small_displacement() {
    let config = config_with_shapes(EndpointShape::None, EndpointShape::Arrow);
    let nodes_a = vec![create_node("a", 0.0, 100.0, 80.0, 60.0)];

    let base_by = 100.0;
    let steps = 20;
    let total_dy = 200.0;
    let mut prev_angle: Option<f64> = None;

    for i in 0..=steps {
        let dy = (i as f64 / steps as f64) * total_dy;
        let by = base_by + dy;
        let nodes = vec![
            InputNode {
                id: nodes_a[0].id.clone(),
                ..nodes_a[0]
            },
            create_node("b", 400.0, by, 80.0, 60.0),
        ];
        let edges = vec![create_edge(
            "r1",
            "a",
            "b",
            None,
            Some(EndpointShape::Arrow),
        )];

        let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
        let angle = results[0].end_direction;

        if let Some(prev) = prev_angle {
            let diff = (angle - prev).abs();
            let wrapped = (diff - 2.0 * std::f64::consts::PI).abs();
            let min_diff = diff.min(wrapped);
            assert!(
                min_diff < 0.2,
                "step {}: angle jump {:.4} → {:.4} is quantized (Δ={:.4} rad, > 0.2 threshold)",
                i,
                prev,
                angle,
                min_diff,
            );
        }
        prev_angle = Some(angle);
    }
}

#[test]
fn test_endpoint_angle_continuous_with_node_moved_on_circle() {
    let config = config_with_shapes(EndpointShape::None, EndpointShape::Arrow);
    let center_a = (0.0, 0.0);
    let radius = 300.0;
    let steps = 36;

    let mut prev_angle: Option<f64> = None;
    for i in 0..steps {
        let theta = (i as f64 / steps as f64) * 2.0 * std::f64::consts::PI;
        let bx = center_a.0 + radius * theta.cos();
        let by = center_a.1 + radius * theta.sin();

        let nodes = vec![
            create_node("a", center_a.0 - 40.0, center_a.1 - 30.0, 80.0, 60.0),
            create_node("b", bx - 40.0, by - 30.0, 80.0, 60.0),
        ];
        let edges = vec![create_edge(
            "r1",
            "a",
            "b",
            None,
            Some(EndpointShape::Arrow),
        )];

        let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
        let angle = results[0].end_direction;

        if let Some(prev) = prev_angle {
            let diff = (angle - prev).abs();
            let wrapped = (diff - 2.0 * std::f64::consts::PI).abs();
            let min_diff = diff.min(wrapped);
            assert!(
                min_diff < 0.35,
                "step {}: angle jump {:.4} → {:.4} is quantized (Δ={:.4} rad)",
                i,
                prev,
                angle,
                min_diff,
            );
        }
        prev_angle = Some(angle);
    }
}

// ---------------------------------------------------------------
// 3. Tangent computation — verify it derives from path geometry
// ---------------------------------------------------------------

#[test]
fn test_tangent_matches_last_segment_direction() {
    let config = config_with_shapes(EndpointShape::None, EndpointShape::Arrow);
    let nodes = vec![
        create_node("a", 0.0, 0.0, 80.0, 60.0),
        create_node("b", 500.0, 200.0, 80.0, 60.0),
    ];
    let edges = vec![create_edge(
        "r1",
        "a",
        "b",
        None,
        Some(EndpointShape::Arrow),
    )];

    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    let r = &results[0];
    let n = r.path_points.len();
    assert!(n >= 2);

    let last_seg = (r.path_points[n - 1] - r.path_points[n - 2]).normalize();
    let end_tangent = r.end_tangent.normalize();

    let dot = last_seg.x * end_tangent.x + last_seg.y * end_tangent.y;
    assert!(
        dot > 0.99,
        "end_tangent should align with last path segment, dot={:.4}",
        dot,
    );
}

#[test]
fn test_tangent_changes_smoothly_with_node_position() {
    let config = config_with_shapes(EndpointShape::None, EndpointShape::Arrow);

    let mut prev_tangent: Option<Point> = None;
    for i in 0..=10 {
        let by = 100.0 + (i as f64) * 20.0;
        let nodes = vec![
            create_node("a", 0.0, 100.0, 80.0, 60.0),
            create_node("b", 400.0, by, 80.0, 60.0),
        ];
        let edges = vec![create_edge(
            "r1",
            "a",
            "b",
            None,
            Some(EndpointShape::Arrow),
        )];

        let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
        let tangent = results[0].end_tangent;

        if let Some(prev) = prev_tangent {
            let dot = tangent.x * prev.x + tangent.y * prev.y;
            assert!(
                dot > 0.95,
                "step {}: tangent jump too large, dot={:.4} (prev={:?}, curr={:?})",
                i,
                dot,
                prev,
                tangent,
            );
        }
        prev_tangent = Some(tangent);
    }
}

// ---------------------------------------------------------------
// 4. Endpoint shape polygon properties
// ---------------------------------------------------------------

#[test]
fn test_arrow_polygon_vertices_count() {
    let shape = EndpointShape::Arrow;
    let tip = Point::new(100.0, 50.0);
    let direction = 0.0;
    let size = 12.0;

    let vertices = shape.generate_polygon(tip, direction, size);
    assert_eq!(vertices.len(), 3, "arrow should have 3 vertices (tip + 2 base)");

    assert_eq!(vertices[0], tip, "first vertex should be the tip");
}

#[test]
fn test_diamond_polygon_vertices_count() {
    let shape = EndpointShape::Diamond;
    let tip = Point::new(100.0, 50.0);
    let direction = 0.0;
    let size = 12.0;

    let vertices = shape.generate_polygon(tip, direction, size);
    assert_eq!(
        vertices.len(),
        4,
        "diamond should have 4 vertices (tip + right + back + left)"
    );
}

#[test]
fn test_circle_polygon_vertices_count() {
    let shape = EndpointShape::Circle;
    let tip = Point::new(100.0, 50.0);
    let direction = 0.0;
    let size = 12.0;

    let vertices = shape.generate_polygon(tip, direction, size);
    assert_eq!(vertices.len(), 12, "circle should have 12 segments");
}

#[test]
fn test_arrow_tip_is_always_first_vertex() {
    for dir in [0.0, 0.5, 1.0, 2.0, 3.14] {
        let tip = Point::new(50.0, 50.0);
        let vertices = EndpointShape::Arrow.generate_polygon(tip, dir, 10.0);
        assert!(
            (vertices[0].x - tip.x).abs() < 1e-6 && (vertices[0].y - tip.y).abs() < 1e-6,
            "tip should be first vertex for direction {:.2}",
            dir,
        );
    }
}

#[test]
fn test_arrow_base_is_behind_tip() {
    let tip = Point::new(100.0, 50.0);
    let direction = 0.0;
    let vertices = EndpointShape::Arrow.generate_polygon(tip, direction, 20.0);

    let base_left = vertices[1];
    let base_right = vertices[2];

    assert!(
        base_left.x < tip.x && base_right.x < tip.x,
        "arrow base should be behind (left of) tip when direction=0, base_left.x={:.1}, base_right.x={:.1}",
        base_left.x,
        base_right.x,
    );
}

// ---------------------------------------------------------------
// 5. Both endpoints computed correctly in single relation
// ---------------------------------------------------------------

#[test]
fn test_both_endpoints_have_correct_shapes() {
    let config = config_with_shapes(EndpointShape::Arrow, EndpointShape::Diamond);
    let nodes = vec![
        create_node("a", 0.0, 100.0, 80.0, 60.0),
        create_node("b", 400.0, 100.0, 80.0, 60.0),
    ];
    let edges = vec![create_edge(
        "r1",
        "a",
        "b",
        Some(EndpointShape::Arrow),
        Some(EndpointShape::Diamond),
    )];

    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    let r = &results[0];

    assert_eq!(r.start_endpoint, EndpointShape::Arrow);
    assert_eq!(r.end_endpoint, EndpointShape::Diamond);
    assert!(!r.start_shape_path.is_empty(), "start arrow polygon");
    assert!(!r.end_shape_path.is_empty(), "end diamond polygon");
    assert_eq!(r.start_shape_path.len(), 3, "start arrow = 3 vertices");
    assert_eq!(r.end_shape_path.len(), 4, "end diamond = 4 vertices");
}

// ---------------------------------------------------------------
// 6. Endpoint direction wraps correctly (2π boundary)
// ---------------------------------------------------------------

#[test]
fn test_endpoint_direction_wraps_correctly() {
    let config = config_with_shapes(EndpointShape::None, EndpointShape::Arrow);

    let mut prev_angle: Option<f64> = None;
    for i in 0..36 {
        let theta = (i as f64 / 36.0) * 2.0 * std::f64::consts::PI;
        let bx = 300.0 * theta.cos();
        let by = 300.0 * theta.sin();

        let nodes = vec![
            create_node("a", -40.0, -30.0, 80.0, 60.0),
            create_node("b", bx - 40.0, by - 30.0, 80.0, 60.0),
        ];
        let edges = vec![create_edge(
            "r1",
            "a",
            "b",
            None,
            Some(EndpointShape::Arrow),
        )];

        let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
        let angle = results[0].end_direction;

        if let Some(prev) = prev_angle {
            let raw_diff = (angle - prev).abs();
            let wrapped_diff = (raw_diff - 2.0 * std::f64::consts::PI).abs();
            let min_diff = raw_diff.min(wrapped_diff);

            assert!(
                min_diff < 0.35,
                "step {}: angle jump {:.4} → {:.4} is quantized (Δ={:.4} rad, raw={:.4})",
                i,
                prev,
                angle,
                min_diff,
                raw_diff,
            );
        }
        prev_angle = Some(angle);
    }
}

// ---------------------------------------------------------------
// 7. Endpoint shapes scale with node size
// ---------------------------------------------------------------

#[test]
fn test_endpoint_margin_scales_with_body_width() {
    let config = config_with_shapes(EndpointShape::None, EndpointShape::Arrow);
    let nodes = vec![
        create_node("a", 0.0, 100.0, 80.0, 60.0),
        create_node("b", 400.0, 100.0, 80.0, 60.0),
    ];
    let edges = vec![create_edge(
        "r1",
        "a",
        "b",
        None,
        Some(EndpointShape::Arrow),
    )];

    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    let r = &results[0];

    assert!(
        r.end_margin > 0.0,
        "end margin should be positive for Arrow shape"
    );
    assert!(
        r.start_margin == 0.0,
        "start margin should be 0 for None shape"
    );
}

// ---------------------------------------------------------------
// 8. Endpoint shapes with orthogonal routing
// ---------------------------------------------------------------

#[test]
fn test_endpoint_direction_with_orthogonal_routing() {
    let mut config = config_with_shapes(EndpointShape::None, EndpointShape::Arrow);
    config.routing.routing_mode = RoutingMode::Orthogonal;

    let nodes = vec![
        create_node("a", 0.0, 0.0, 80.0, 60.0),
        create_node("b", 400.0, 200.0, 80.0, 60.0),
    ];
    let edges = vec![InputEdge {
        id: tid(TableKind::IRelation, "r1"),
        from_node_id: tid(TableKind::INode, "a"),
        to_node_id: tid(TableKind::INode, "b"),
        from_side: None,
        to_side: None,
        routing_mode: Some(RoutingMode::Orthogonal),
        bundling_mode: None,
        style: Some(make_style(None, Some(EndpointShape::Arrow))),
    }];

    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    let r = &results[0];

    assert!(!r.end_shape_path.is_empty(), "end arrow should exist");
    assert!(r.end_margin > 0.0, "end margin should be > 0");

    let n = r.path_points.len();
    let last_seg = (r.path_points[n - 1] - r.path_points[n - 2]).normalize();
    let dot = last_seg.x * r.end_tangent.x + last_seg.y * r.end_tangent.y;
    assert!(dot > 0.99, "tangent should align with last segment");
}

// ---------------------------------------------------------------
// 9. Path trimming — body stops at shape back
// ---------------------------------------------------------------

#[test]
fn test_body_trims_at_endpoint_shape_back() {
    let config = config_with_shapes(EndpointShape::None, EndpointShape::Arrow);
    let nodes = vec![
        create_node("a", 0.0, 100.0, 80.0, 60.0),
        create_node("b", 400.0, 100.0, 80.0, 60.0),
    ];
    let edges = vec![create_edge(
        "r1",
        "a",
        "b",
        None,
        Some(EndpointShape::Arrow),
    )];

    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    let r = &results[0];

    if r.end_margin > 0.0 {
        let n = r.path_points.len();
        let last_body_pt = r.path_points[n - 1];
        let end_pt = r.end_point;

        let dist = last_body_pt.distance_to(end_pt);
        assert!(
            dist < 1.0 || (dist - r.end_margin).abs() < 2.0,
            "body end point should be trimmed back by shape margin, dist={:.2}, margin={:.2}",
            dist,
            r.end_margin,
        );
    }
}

// ---------------------------------------------------------------
// 10. Endpoint shape filled vs open
// ---------------------------------------------------------------

#[test]
fn test_arrow_is_filled() {
    assert!(EndpointShape::Arrow.is_filled());
    assert!(EndpointShape::Circle.is_filled());
    assert!(EndpointShape::Diamond.is_filled());
    assert!(EndpointShape::Square.is_filled());
    assert!(!EndpointShape::OpenArrow.is_filled());
    assert!(EndpointShape::None.is_filled());
}

// ---------------------------------------------------------------
// 11. Endpoint shape polygon symmetry
// ---------------------------------------------------------------

#[test]
fn test_arrow_polygon_is_symmetric_about_direction() {
    let tip = Point::new(100.0, 0.0);
    let size = 20.0;

    for dir in [0.0, 0.5, 1.0, 2.0, 3.14] {
        let verts = EndpointShape::Arrow.generate_polygon(tip, dir, size);
        assert_eq!(verts.len(), 3);

        let cos = dir.cos();
        let sin = dir.sin();
        let perp = Point::new(-sin, cos);

        let center = (verts[1] + verts[2]) * 0.5;
        let to_center = center - tip;
        let along = to_center.x * cos + to_center.y * sin;
        let perp_component = to_center.x * perp.x + to_center.y * perp.y;

        assert!(
            perp_component.abs() < 0.01,
            "arrow should be symmetric about direction, perp_component={:.4}",
            perp_component,
        );
        assert!(
            (along - (-size)).abs() < 0.5,
            "base center should be ~size behind tip, along={:.4}",
            along,
        );
    }
}

// ---------------------------------------------------------------
// 12. Multiple relations — endpoint shapes independent
// ---------------------------------------------------------------

#[test]
fn test_multiple_relations_endpoint_independence() {
    let config = config_with_shapes(EndpointShape::None, EndpointShape::Arrow);
    let nodes = vec![
        create_node("a", 0.0, 0.0, 80.0, 60.0),
        create_node("b", 400.0, 100.0, 80.0, 60.0),
        create_node("c", 400.0, 400.0, 80.0, 60.0),
    ];
    let edges = vec![
        create_edge("r1", "a", "b", None, Some(EndpointShape::Arrow)),
        create_edge("r2", "a", "c", None, Some(EndpointShape::Diamond)),
    ];

    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    assert_eq!(results.len(), 2);

    let r1 = &results[0];
    let r2 = &results[1];

    assert_eq!(r1.end_endpoint, EndpointShape::Arrow);
    assert_eq!(r2.end_endpoint, EndpointShape::Diamond);

    assert!(!r1.end_shape_path.is_empty());
    assert!(!r2.end_shape_path.is_empty());

    let diff_dir = (r1.end_direction - r2.end_direction).abs();
    let wrapped = (diff_dir - 2.0 * std::f64::consts::PI).abs();
    let min_diff = diff_dir.min(wrapped);
    assert!(
        min_diff > 0.5,
        "different node targets should produce different endpoint angles, diff={:.4}",
        min_diff,
    );
}

// ---------------------------------------------------------------
// 13. Endpoint direction monotonicity on arc
// ---------------------------------------------------------------

#[test]
fn test_endpoint_angle_monotonicity_on_arc() {
    let config = config_with_shapes(EndpointShape::None, EndpointShape::Arrow);
    let radius = 300.0;
    let steps = 18;

    let mut prev_angle: Option<f64> = None;
    for i in 0..steps {
        let theta = (i as f64 / steps as f64) * std::f64::consts::PI;
        let bx = radius * theta.cos();
        let by = radius * theta.sin();

        let nodes = vec![
            create_node("a", -40.0, -30.0, 80.0, 60.0),
            create_node("b", bx - 40.0, by - 30.0, 80.0, 60.0),
        ];
        let edges = vec![create_edge(
            "r1",
            "a",
            "b",
            None,
            Some(EndpointShape::Arrow),
        )];

        let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
        let angle = results[0].end_direction;

        if let Some(prev) = prev_angle {
            let diff = (angle - prev).abs();
            let wrapped = (diff - 2.0 * std::f64::consts::PI).abs();
            let min_diff = diff.min(wrapped);
            assert!(
                min_diff < 0.25,
                "step {}: non-monotonic angle jump {:.4} → {:.4} (Δ={:.4})",
                i,
                prev,
                angle,
                min_diff,
            );
        }
        prev_angle = Some(angle);
    }
}

// ---------------------------------------------------------------
// 14. Handle positions inset from endpoint shapes
// ---------------------------------------------------------------

#[test]
fn test_handle_positions_inset_from_endpoints() {
    let config = config_with_shapes(EndpointShape::None, EndpointShape::Arrow);
    let nodes = vec![
        create_node("a", 0.0, 100.0, 80.0, 60.0),
        create_node("b", 400.0, 100.0, 80.0, 60.0),
    ];
    let edges = vec![create_edge(
        "r1",
        "a",
        "b",
        None,
        Some(EndpointShape::Arrow),
    )];

    let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
    let r = &results[0];

    let start_to_handle = r.start_point.distance_to(r.start_handle_pos);
    let end_to_handle = r.end_point.distance_to(r.end_handle_pos);

    assert!(
        start_to_handle >= 0.0,
        "start handle inset should be non-negative"
    );
    assert!(
        end_to_handle >= 0.0,
        "end handle inset should be non-negative"
    );
}

// ---------------------------------------------------------------
// 15. ENDPOINT ANGLE QUANTIZATION — the bug
// For octilinear routing, A* path segments are grid-aligned, so
// the endpoint tangent (and thus shape angle) is quantized to
// 0°, 45°, 90°, 135°, etc. The body path LOOKS smooth because
// the shaper adds interpolated points, but the endpoint shape
// angle snaps to one of 8 discrete values.
// ---------------------------------------------------------------

const QUANTIZED_ANGLES: [f64; 8] = [
    0.0,
    std::f64::consts::FRAC_PI_4,
    std::f64::consts::FRAC_PI_2,
    3.0 * std::f64::consts::FRAC_PI_4,
    std::f64::consts::PI,
    5.0 * std::f64::consts::FRAC_PI_4,
    3.0 * std::f64::consts::FRAC_PI_2,
    7.0 * std::f64::consts::FRAC_PI_4,
];

fn angle_to_quantized_bucket(angle: f64) -> usize {
    let normalized = ((angle % (2.0 * std::f64::consts::PI))
        + 2.0 * std::f64::consts::PI)
        % (2.0 * std::f64::consts::PI);
    let step = std::f64::consts::PI / 4.0;
    (normalized / step).round() as usize
}

fn angle_distance_to_nearest_45(angle: f64) -> f64 {
    let normalized = ((angle % (2.0 * std::f64::consts::PI))
        + 2.0 * std::f64::consts::PI)
        % (2.0 * std::f64::consts::PI);
    let step = std::f64::consts::PI / 4.0;
    let bucket = (normalized / step).round() as usize % 8;
    (normalized - QUANTIZED_ANGLES[bucket]).abs()
}

fn angle_distance_to_nearest_90(angle: f64) -> f64 {
    let normalized = ((angle % (2.0 * std::f64::consts::PI))
        + 2.0 * std::f64::consts::PI)
        % (2.0 * std::f64::consts::PI);
    let step = std::f64::consts::FRAC_PI_2;
    let bucket = (normalized / step).round() as usize % 4;
    let target = bucket as f64 * step;
    (normalized - target).abs()
}

fn angle_to_90_bucket(angle: f64) -> usize {
    let normalized = ((angle % (2.0 * std::f64::consts::PI))
        + 2.0 * std::f64::consts::PI)
        % (2.0 * std::f64::consts::PI);
    let step = std::f64::consts::FRAC_PI_2;
    (normalized / step).round() as usize % 4
}

const TOLERANCE: f64 = 0.25;

#[test]
fn test_octilinear_endpoint_angle_quantized_to_45deg() {
    let mut config = config_with_shapes(EndpointShape::None, EndpointShape::Arrow);
    config.routing.routing_mode = RoutingMode::Octilinear;

    let total = 36;
    let radius = 300.0;
    let mut unique_buckets = std::collections::HashSet::new();
    let mut quantized_count = 0;

    for i in 0..total {
        let theta = (i as f64 / total as f64) * 2.0 * std::f64::consts::PI;
        let bx = radius * theta.cos();
        let by = radius * theta.sin();

        let nodes = vec![
            create_node("a", -40.0, -30.0, 80.0, 60.0),
            create_node("b", bx - 40.0, by - 30.0, 80.0, 60.0),
        ];
        let edges = vec![InputEdge {
            id: tid(TableKind::IRelation, "r1"),
            from_node_id: tid(TableKind::INode, "a"),
            to_node_id: tid(TableKind::INode, "b"),
            from_side: None,
            to_side: None,
            routing_mode: Some(RoutingMode::Octilinear),
            bundling_mode: None,
            style: Some(make_style(None, Some(EndpointShape::Arrow))),
        }];

        let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
        let angle = results[0].end_direction;
        let bucket = angle_to_quantized_bucket(angle);
        unique_buckets.insert(bucket);
        if angle_distance_to_nearest_45(angle) < TOLERANCE {
            quantized_count += 1;
        }
    }

    eprintln!(
        "octilinear: {}/{} quantized, {} unique buckets",
        quantized_count,
        total,
        unique_buckets.len()
    );
    assert!(
        unique_buckets.len() <= 8,
        "octilinear should hit ≤8 direction buckets, hit {}",
        unique_buckets.len()
    );
    assert!(
        quantized_count > total * 70 / 100,
        "octilinear endpoint direction should be quantized to 45° steps, only {}/{} were",
        quantized_count,
        total,
    );
}

#[test]
fn test_octilinear_endpoint_angle_snaps_between_only_8_directions() {
    let mut config = config_with_shapes(EndpointShape::None, EndpointShape::Arrow);
    config.routing.routing_mode = RoutingMode::Octilinear;

    let radius = 300.0;
    let steps = 36;
    let mut seen_buckets = std::collections::HashSet::new();

    for i in 0..steps {
        let theta = (i as f64 / steps as f64) * 2.0 * std::f64::consts::PI;
        let bx = radius * theta.cos();
        let by = radius * theta.sin();

        let nodes = vec![
            create_node("a", -40.0, -30.0, 80.0, 60.0),
            create_node("b", bx - 40.0, by - 30.0, 80.0, 60.0),
        ];
        let edges = vec![InputEdge {
            id: tid(TableKind::IRelation, "r1"),
            from_node_id: tid(TableKind::INode, "a"),
            to_node_id: tid(TableKind::INode, "b"),
            from_side: None,
            to_side: None,
            routing_mode: Some(RoutingMode::Octilinear),
            bundling_mode: None,
            style: Some(make_style(None, Some(EndpointShape::Arrow))),
        }];

        let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
        let bucket = angle_to_quantized_bucket(results[0].end_direction);
        seen_buckets.insert(bucket);
    }

    eprintln!(
        "octilinear: endpoint angles hit {}/8 possible 45° buckets",
        seen_buckets.len()
    );
    assert!(
        seen_buckets.len() <= 8,
        "endpoint direction should only come from 8 discrete values, saw {}",
        seen_buckets.len()
    );
}

#[test]
fn test_orthogonal_endpoint_angle_quantized_to_90deg() {
    let mut config = config_with_shapes(EndpointShape::None, EndpointShape::Arrow);
    config.routing.routing_mode = RoutingMode::Orthogonal;

    let total = 36;
    let radius = 300.0;
    let mut unique_buckets = std::collections::HashSet::new();
    let mut quantized_count = 0;

    for i in 0..total {
        let theta = (i as f64 / total as f64) * 2.0 * std::f64::consts::PI;
        let bx = radius * theta.cos();
        let by = radius * theta.sin();

        let nodes = vec![
            create_node("a", -40.0, -30.0, 80.0, 60.0),
            create_node("b", bx - 40.0, by - 30.0, 80.0, 60.0),
        ];
        let edges = vec![InputEdge {
            id: tid(TableKind::IRelation, "r1"),
            from_node_id: tid(TableKind::INode, "a"),
            to_node_id: tid(TableKind::INode, "b"),
            from_side: None,
            to_side: None,
            routing_mode: Some(RoutingMode::Orthogonal),
            bundling_mode: None,
            style: Some(make_style(None, Some(EndpointShape::Arrow))),
        }];

        let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
        let angle = results[0].end_direction;
        let bucket = angle_to_90_bucket(angle);
        unique_buckets.insert(bucket);
        if angle_distance_to_nearest_90(angle) < TOLERANCE {
            quantized_count += 1;
        }
    }

    eprintln!(
        "orthogonal: {}/{} quantized to 90°, {} unique 90° buckets",
        quantized_count,
        total,
        unique_buckets.len()
    );
    assert!(
        unique_buckets.len() <= 4,
        "orthogonal should hit ≤4 direction buckets (cardinal), hit {}",
        unique_buckets.len()
    );
    assert!(
        unique_buckets.len() >= 2,
        "orthogonal should use at least 2 cardinal directions, only used {}",
        unique_buckets.len()
    );
}

#[test]
fn test_body_path_smooth_but_endpoint_quantized() {
    let mut config = config_with_shapes(EndpointShape::None, EndpointShape::Arrow);
    config.routing.routing_mode = RoutingMode::Octilinear;

    let radius = 300.0;
    let mut body_smooth_count = 0;
    let mut endpoint_quantized_count = 0;
    let total = 36;
    let mut prev_body_len: Option<f64> = None;

    for i in 0..total {
        let theta = (i as f64 / total as f64) * 2.0 * std::f64::consts::PI;
        let bx = radius * theta.cos();
        let by = radius * theta.sin();

        let nodes = vec![
            create_node("a", -40.0, -30.0, 80.0, 60.0),
            create_node("b", bx - 40.0, by - 30.0, 80.0, 60.0),
        ];
        let edges = vec![InputEdge {
            id: tid(TableKind::IRelation, "r1"),
            from_node_id: tid(TableKind::INode, "a"),
            to_node_id: tid(TableKind::INode, "b"),
            from_side: None,
            to_side: None,
            routing_mode: Some(RoutingMode::Octilinear),
            bundling_mode: None,
            style: Some(make_style(None, Some(EndpointShape::Arrow))),
        }];

        let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
        let r = &results[0];

        let body_len = centrode_core::relation_engine::geometry::polyline_length(&r.path_points);
        if let Some(prev) = prev_body_len {
            let body_delta = (body_len - prev).abs();
            if body_delta < 50.0 {
                body_smooth_count += 1;
            }
        }
        prev_body_len = Some(body_len);

        let angle = r.end_direction;
        let dist = angle_distance_to_nearest_45(angle);
        if dist < TOLERANCE {
            endpoint_quantized_count += 1;
        }
    }

    eprintln!("body length changes smooth: {}/{}", body_smooth_count, total - 1);
    eprintln!(
        "endpoint angles quantized: {}/{}",
        endpoint_quantized_count, total
    );

    assert!(
        endpoint_quantized_count > total * 70 / 100,
        "endpoint angle should be quantized for octilinear, only {}/{} were",
        endpoint_quantized_count,
        total,
    );
}

#[test]
fn test_polyline_endpoint_angle_is_continuous_not_quantized() {
    let config = config_with_shapes(EndpointShape::None, EndpointShape::Arrow);

    let mut quantized_count = 0;
    let total = 36;
    let radius = 300.0;

    for i in 0..total {
        let theta = (i as f64 / total as f64) * 2.0 * std::f64::consts::PI;
        let bx = radius * theta.cos();
        let by = radius * theta.sin();

        let nodes = vec![
            create_node("a", -40.0, -30.0, 80.0, 60.0),
            create_node("b", bx - 40.0, by - 30.0, 80.0, 60.0),
        ];
        let edges = vec![create_edge(
            "r1",
            "a",
            "b",
            None,
            Some(EndpointShape::Arrow),
        )];

        let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
        let angle = results[0].end_direction;
        let dist = angle_distance_to_nearest_45(angle);

        if dist < 0.05 {
            quantized_count += 1;
        }
    }

    eprintln!(
        "polyline: {}/{} endpoint angles are within 0.05 rad of a 45° multiple",
        quantized_count, total
    );
    assert!(
        quantized_count < total * 50 / 100,
        "polyline endpoint direction should NOT be quantized to 45°, but {}/{} were",
        quantized_count,
        total,
    );
}

#[test]
fn test_endpoint_direction_differs_from_true_node_direction_on_octilinear() {
    let mut config = config_with_shapes(EndpointShape::None, EndpointShape::Arrow);
    config.routing.routing_mode = RoutingMode::Octilinear;

    let radius = 300.0;
    let steps = 36;
    let mut mismatch_count = 0;

    for i in 0..steps {
        let theta = (i as f64 / steps as f64) * 2.0 * std::f64::consts::PI;
        let bx = radius * theta.cos();
        let by = radius * theta.sin();

        let a_center = Point::new(0.0, 0.0);
        let b_center = Point::new(bx, by);

        let nodes = vec![
            create_node("a", a_center.x - 40.0, a_center.y - 30.0, 80.0, 60.0),
            create_node("b", b_center.x - 40.0, b_center.y - 30.0, 80.0, 60.0),
        ];
        let edges = vec![InputEdge {
            id: tid(TableKind::IRelation, "r1"),
            from_node_id: tid(TableKind::INode, "a"),
            to_node_id: tid(TableKind::INode, "b"),
            from_side: None,
            to_side: None,
            routing_mode: Some(RoutingMode::Octilinear),
            bundling_mode: None,
            style: Some(make_style(None, Some(EndpointShape::Arrow))),
        }];

        let results = RelationEngine::compute_relations(&nodes, &edges, &config, None);
        let computed_dir = results[0].end_direction;

        let true_dir = (b_center.y - a_center.y).atan2(b_center.x - a_center.x);

        let raw_diff = (computed_dir - true_dir).abs();
        let wrapped = (raw_diff - 2.0 * std::f64::consts::PI).abs();
        let min_diff = raw_diff.min(wrapped);

        if min_diff > 0.15 {
            mismatch_count += 1;
        }
    }

    eprintln!(
        "octilinear: {}/{} endpoint directions differ from true node-to-node direction by >0.15 rad",
        mismatch_count, steps
    );
    assert!(
        mismatch_count > 0,
        "octilinear endpoint direction should diverge from true node direction due to grid quantization"
    );
}

#[test]
fn test_port_side_normal_is_only_8_directions() {
    let sides = [
        PortSide::Top,
        PortSide::Right,
        PortSide::Bottom,
        PortSide::Left,
        PortSide::TopLeft,
        PortSide::TopRight,
        PortSide::BottomLeft,
        PortSide::BottomRight,
    ];

    let mut unique_normals = std::collections::HashSet::new();
    for side in &sides {
        let normal = centrode_core::relation_engine::path_finder::port::normal_for_side(side);
        let bucket = angle_to_quantized_bucket(normal.y.atan2(normal.x));
        unique_normals.insert(bucket);
    }

    eprintln!("unique normal direction buckets: {}", unique_normals.len());
    assert!(
        unique_normals.len() <= 8,
        "port normals should come from at most 8 directions, got {}",
        unique_normals.len()
    );
}
