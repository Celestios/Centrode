use rust_lib_mycelium::domain::relation_engine::buffers::RelationBuffers;
use rust_lib_mycelium::domain::relation_engine::config::{
    BodyType, EndpointShapeType, RelationEngineConfig,
};
use rust_lib_mycelium::domain::relation_engine::geometry::{Point, Rect};
use rust_lib_mycelium::domain::relation_engine::painting::relation::{
    compute_endpoint_placement, generate_pattern, trim_path,
};
use rust_lib_mycelium::domain::relation_engine::resolvers::{
    color::resolve_relation_color, font::resolve_font_family, icon::resolve_icon_offset,
};
use rust_lib_mycelium::domain::relation_engine::state::cache::RelationCache;
use rust_lib_mycelium::domain::relation_engine::computed::{
    ComputedRelation, LabelAnchor, PathType,
};
use rust_lib_mycelium::domain::relation_engine::sections::endpoint::resolve_start;
use rust_lib_mycelium::domain::relation_engine::sections::body::{BodyResolver, compute_widths};
use rust_lib_mycelium::domain::relation_engine::input::InputNode;

#[test]
fn test_uniform_body_strategy() {
    let path = vec![
        Point::new(0.0, 0.0),
        Point::new(10.0, 0.0),
        Point::new(20.0, 0.0),
    ];
    let config = RelationEngineConfig::default();
    let mut widths_buffer = Vec::new();
    compute_widths(&path, BodyType::Uniform, 3.0, &config, &mut widths_buffer);
    assert_eq!(widths_buffer, vec![3.0, 3.0, 3.0]);
}

#[test]
fn test_taper_body_strategy() {
    let path = vec![
        Point::new(0.0, 0.0),
        Point::new(10.0, 0.0),
        Point::new(20.0, 0.0),
    ];
    let mut config = RelationEngineConfig::default();
    config.body.taper_start_width = 1.0;
    config.body.taper_end_width = 5.0;

    let mut widths_buffer = Vec::new();
    compute_widths(&path, BodyType::Taper, 3.0, &config, &mut widths_buffer);
    assert_eq!(widths_buffer.len(), 3);
    assert_eq!(widths_buffer[0], 1.0);
    assert_eq!(widths_buffer[1], 3.0);
    assert_eq!(widths_buffer[2], 5.0);
}

#[test]
fn test_width_modulate_body_strategy() {
    let path = vec![
        Point::new(0.0, 0.0),
        Point::new(100.0, 0.0),
    ];
    let mut config = RelationEngineConfig::default();
    config.body.width_modulate_amplitude = 1.0;
    config.body.width_modulate_frequency = 1.0;

    let mut widths_buffer = Vec::new();
    compute_widths(&path, BodyType::WidthModulate, 4.0, &config, &mut widths_buffer);
    assert_eq!(widths_buffer.len(), 2);
    assert!((widths_buffer[0] - 4.0).abs() < 1e-5);
    // New formula: base_width + amplitude * sin(len * (frequency / 300.0) * 2*PI)
    let expected_1 = 4.0 + (100.0 * (1.0 / 300.0) * 2.0 * std::f64::consts::PI).sin();
    assert!((widths_buffer[1] - expected_1).abs() < 1e-5);
}

#[test]
fn test_path_trimming() {
    let path = vec![
        Point::new(0.0, 0.0),
        Point::new(10.0, 0.0),
        Point::new(20.0, 0.0),
    ];

    // Trim 2 units from start and 3 units from end
    let trimmed = trim_path(&path, 2.0, 3.0);
    assert_eq!(trimmed.len(), 3);
    assert_eq!(trimmed[0], Point::new(2.0, 0.0));
    assert_eq!(trimmed[1], Point::new(10.0, 0.0));
    assert_eq!(trimmed[2], Point::new(17.0, 0.0));
}

#[test]
fn test_dash_pattern_generation() {
    let path = vec![
        Point::new(0.0, 0.0),
        Point::new(100.0, 0.0),
    ];

    // Solid pattern returns whole path
    let solid = generate_pattern(&path, "solid");
    assert_eq!(solid.len(), 1);
    assert_eq!(solid[0].len(), 2);

    // Dashed pattern (dash=8, gap=6)
    let dashed = generate_pattern(&path, "dashed");
    assert!(dashed.len() > 1);
    // First segment should span from 0 to 8
    assert_eq!(dashed[0][0], Point::new(0.0, 0.0));
    assert_eq!(dashed[0][1], Point::new(8.0, 0.0));
}

#[test]
fn test_endpoint_placement() {
    let start = Point::new(10.0, 10.0);
    let center = Point::new(0.0, 10.0); // Start is to the right of center

    let placement = compute_endpoint_placement(start, center, 10.0, 4.0);
    // Offset should be to the right (cos(0)=1) by arrow_size * 0.5 = 5.0
    assert_eq!(placement.position, Point::new(15.0, 10.0));
    // Direction should be PI (outward_dir + PI)
    assert!((placement.direction - std::f64::consts::PI).abs() < 1e-5);
    assert_eq!(placement.scale, 2.0); // 4.0 / 2.0
}

#[test]
fn test_resolvers() {
    // Color resolver
    let color = resolve_relation_color(0xFF000000, true, 0xFFFF0000);
    assert_eq!(color, 0xFFFF0000);

    let color_unselected = resolve_relation_color(0xFF000000, false, 0xFFFF0000);
    assert_eq!(color_unselected, 0xFF000000);

    // Font resolver
    let font = resolve_font_family("Arial", "Roboto");
    assert_eq!(font, "Arial");
    let font_default = resolve_font_family("", "Roboto");
    assert_eq!(font_default, "Roboto");

    // Icon offset resolver
    let pos = Point::new(10.0, 10.0);
    let normal = Point::new(0.0, -1.0); // Upward normal
    let offset = resolve_icon_offset(pos, normal, 16.0, 2.0);
    assert_eq!(offset, Point::new(10.0, 0.0));
}

#[test]
fn test_relation_cache() {
    let mut cache = RelationCache::new();
    assert!(cache.get("e1").is_none());

    let computed = ComputedRelation {
        id: "e1".to_string(),
        path_points: vec![Point::zero(), Point::zero()],
        path_type: PathType::Straight,
        start_tangent: Point::zero(),
        end_tangent: Point::zero(),
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
        depends_on_nodes: vec!["n1".to_string(), "n2".to_string()],
        bbox: Rect::new(0.0, 0.0, 0.0, 0.0),
        start_margin: 0.0,
        end_margin: 0.0,
    };

    cache.insert("e1".to_string(), computed);
    assert!(cache.get("e1").is_some());

    cache.remove("e1");
    assert!(cache.get("e1").is_none());
}

#[test]
fn test_endpoint_resolver_standard() {
    let node = InputNode {
        id: "n1".to_string(),
        x: 0.0,
        y: 0.0,
        width: 100.0,
        height: 100.0,
        is_obstacle: true,
    };
    let port = Point::new(100.0, 50.0);
    let tangent = Point::new(1.0, 0.0);
    let config = RelationEngineConfig::default();

    let result = resolve_start(&node, port, tangent, None, &config, false);

    assert_eq!(result.position, port);
    assert_eq!(result.shape, EndpointShapeType::None);
}

#[test]
fn test_body_uniform_widths() {
    let path = vec![Point::new(0.0, 0.0), Point::new(10.0, 0.0), Point::new(20.0, 0.0)];
    let config = RelationEngineConfig::default();
    let mut widths_buffer = Vec::new();

    let resolver = BodyResolver::Uniform;
    let result = resolver.generate(&path, 3.0, &config, &mut widths_buffer);

    assert_eq!(result.point_count, 3);
    assert_eq!(widths_buffer, vec![3.0, 3.0, 3.0]);
}

#[test]
fn test_buffers_reuse() {
    let mut buffers = RelationBuffers::with_capacity(100);

    buffers.path.push(Point::new(0.0, 0.0));
    buffers.path.push(Point::new(10.0, 0.0));
    assert_eq!(buffers.path.len(), 2);

    buffers.clear();
    assert_eq!(buffers.path.len(), 0);
    assert!(buffers.path.capacity() >= 100);
}
