use centrode_core::domain::id::TypedRecordId;
use centrode_core::domain::styles::PortSide;
use centrode_core::domain::traits::TableKind;
use centrode_core::relation_engine::computed::{ComputedRelation, PathType};
use centrode_core::relation_engine::geometry::{
    distance_to_segment, polyline_length, segments_intersect, Point,
};
use centrode_core::relation_engine::input::InputNode;
use centrode_core::relation_engine::path_finder::grid::Grid;
use centrode_core::relation_engine::path_finder::port::{
    closest_port_to, get_port_dir, normal_for_side, port_position,
};
use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};
use uuid::Uuid;

#[test]
fn test_geometry_distance_and_length() {
    let p1 = Point::new(0.0, 0.0);
    let p2 = Point::new(3.0, 4.0);
    assert_eq!(p1.distance_to(p2), 5.0);

    let path = vec![
        Point::new(0.0, 0.0),
        Point::new(3.0, 0.0),
        Point::new(3.0, 4.0),
    ];
    assert_eq!(polyline_length(&path), 7.0);
}

#[test]
fn test_segments_intersect() {
    // Intersecting
    let a = Point::new(0.0, 0.0);
    let b = Point::new(10.0, 10.0);
    let c = Point::new(0.0, 10.0);
    let d = Point::new(10.0, 0.0);
    assert!(segments_intersect(a, b, c, d));

    // Parallel/non-intersecting
    let e = Point::new(0.0, 0.0);
    let f = Point::new(0.0, 10.0);
    let g = Point::new(2.0, 0.0);
    let h = Point::new(2.0, 10.0);
    assert!(!segments_intersect(e, f, g, h));
}

#[test]
fn test_distance_to_segment() {
    let p = Point::new(2.0, 1.0);
    let a = Point::new(0.0, 0.0);
    let b = Point::new(4.0, 0.0);
    // Closest point on segment ab is (2, 0). Distance should be 1.0
    assert_eq!(distance_to_segment(p, a, b), 1.0);
}

#[test]
fn test_grid_conversion() {
    let grid = Grid::new(10.0, 20.0, 5, 5, 10.0);
    let pt = Point::new(25.0, 35.0);
    let (col, row) = grid.world_to_grid(pt);
    assert_eq!(col, 1);
    assert_eq!(row, 1);

    let back = grid.grid_to_world(1, 1);
    // cell center: 10 + 1.5 * 10 = 25, 20 + 1.5 * 10 = 35
    assert_eq!(back.x, 25.0);
    assert_eq!(back.y, 35.0);

    assert!(grid.in_bounds(0, 0));
    assert!(grid.in_bounds(4, 4));
    assert!(!grid.in_bounds(5, 4));
    assert!(!grid.in_bounds(-1, 0));
}

fn str_to_uuid(s: &str) -> Uuid {
    let mut hasher = DefaultHasher::new();
    s.hash(&mut hasher);
    let hash = hasher.finish();
    Uuid::from_u128(hash as u128)
}

fn tid(table: TableKind, s: &str) -> TypedRecordId {
    TypedRecordId::new(table, str_to_uuid(s))
}

#[test]
fn test_port_side_resolution() {
    let node = InputNode {
        id: tid(TableKind::INode, "test"),
        x: 10.0,
        y: 20.0,
        width: 100.0,
        height: 50.0,
        is_obstacle: false,
    };

    // Test port positions
    let (top_pos, top_angle) = port_position(&node, Some(&PortSide::Top));
    assert_eq!(top_pos.x, 60.0);
    assert_eq!(top_pos.y, 20.0);
    assert_eq!(top_angle, -std::f64::consts::FRAC_PI_2);

    let (bottom_pos, bottom_angle) = port_position(&node, Some(&PortSide::Bottom));
    assert_eq!(bottom_pos.x, 60.0);
    assert_eq!(bottom_pos.y, 70.0);
    assert_eq!(bottom_angle, std::f64::consts::FRAC_PI_2);

    // Test port directions
    assert_eq!(get_port_dir(Some(&PortSide::Top)), Some((0, -1)));
    assert_eq!(get_port_dir(Some(&PortSide::Left)), Some((-1, 0)));
    assert_eq!(get_port_dir(Some(&PortSide::TopRight)), Some((1, -1)));

    // Test normals
    assert_eq!(normal_for_side(&PortSide::Top), Point::new(0.0, -1.0));
    assert_eq!(normal_for_side(&PortSide::Right), Point::new(1.0, 0.0));

    // Test closest port to target
    let target = Point::new(60.0, 10.0); // directly above center
    let (best_side, _) = closest_port_to(&node, target);
    assert_eq!(best_side, PortSide::Top);
}

#[test]
fn test_computed_relation_new_basic() {
    let r = ComputedRelation::new_basic(
        tid(TableKind::IRelation, "rel1"),
        vec![Point::new(0.0, 0.0), Point::new(10.0, 10.0)],
        PathType::Straight,
    );
    assert_eq!(r.id, tid(TableKind::IRelation, "rel1"));
    assert_eq!(r.path_points.len(), 2);
    assert_eq!(r.path_type, PathType::Straight);
}

#[test]
fn test_bezier_and_sinewave_perpendicular_exits() {
    use centrode_core::relation_engine::config::BezierConfig;
    use centrode_core::relation_engine::shaper::bezier::BezierShaper;
    use centrode_core::relation_engine::shaper::core::Shaper;
    use centrode_core::relation_engine::shaper::core::ShaperContext;
    use centrode_core::relation_engine::shaper::sinewave::SineWaveShaper;

    let p0 = Point::new(100.0, 100.0);
    let p3 = Point::new(300.0, 300.0);
    // Exit right from p0, enter bottom from p3
    let start_normal = Point::new(1.0, 0.0);
    let end_normal = Point::new(0.0, -1.0);

    let start_size = 50.0;
    let end_size = 50.0;

    let context = ShaperContext {
        start_pt: p0,
        end_pt: p3,
        start_dir: Some((1, 0)),
        end_dir: Some((0, -1)),
        start_normal,
        end_normal,
        start_node_size: (start_size, start_size),
        end_node_size: (end_size, end_size),
        custom_control_point_1: None,
        custom_control_point_2: None,
        start_stub_len: 10.0,
        end_stub_len: 10.0,
        cell_size: 20.0,
    };

    // Test Bezier exits
    let bezier_shaper = BezierShaper::new(BezierConfig {
        num_samples: 10000,
        start_offset_x: 0.0,
        start_offset_y: 0.0,
        end_offset_x: 0.0,
        end_offset_y: 0.0,
    });
    let bezier_res = bezier_shaper.shape(&[], &context);
    assert_eq!(bezier_res.path_points.len(), 10000);
    let t0 = (bezier_res.path_points[1] - bezier_res.path_points[0]).normalize();
    assert!((t0.x - 1.0).abs() < 1e-3);
    assert!(t0.y.abs() < 1e-3);

    let tn = (bezier_res.path_points[9999] - bezier_res.path_points[9998]).normalize();
    assert!(tn.x.abs() < 1e-3);
    assert!((tn.y - 1.0).abs() < 1e-3);

    // Test SineWave exits
    let sinewave_shaper = SineWaveShaper::new(20.0, 3.0, 100);
    let sinewave_res = sinewave_shaper.shape(&[], &context);
    assert_eq!(sinewave_res.path_points.len(), 100);
    assert_eq!(sinewave_res.path_points[0], p0);
    assert_eq!(sinewave_res.path_points[99], p3);

    let t0_sine = (sinewave_res.path_points[1] - sinewave_res.path_points[0]).normalize();
    assert!((t0_sine.x - 1.0).abs() < 0.5);
    assert!(t0_sine.y.abs() < 0.5);

    let tn_sine = (sinewave_res.path_points[99] - sinewave_res.path_points[98]).normalize();
    assert!(tn_sine.x.abs() < 0.5);
    assert!((tn_sine.y - 1.0).abs() < 0.5);
}

#[test]
fn test_bezier_control_points_distance_scaling() {
    use centrode_core::relation_engine::geometry::Point;
    use centrode_core::relation_engine::shaper::core::resolve_control_points;

    let start = Point::new(0.0, 0.0);
    let end_short = Point::new(100.0, 0.0);
    let end_long = Point::new(2000.0, 0.0);

    let start_normal = Point::new(1.0, 0.0);
    let end_normal = Point::new(-1.0, 0.0);
    let size = (50.0, 50.0);

    let (cp1_short, _) = resolve_control_points(
        start, end_short, start_normal, end_normal, size, size, None, None, true,
    );
    let (cp1_long, _) = resolve_control_points(
        start, end_long, start_normal, end_normal, size, size, None, None, true,
    );

    // Short distance (100px): uses base size minimum (50px) projection along normal
    assert!((cp1_short.x - 50.0).abs() < 1e-3);

    // Long distance (2000px): scales proportionally with distance (18% of 2000 = 360px)
    assert!((cp1_long.x - 360.0).abs() < 1e-3);
    assert!(cp1_long.x > cp1_short.x * 5.0);
}
