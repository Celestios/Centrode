use centrode_core::domain::base_models::BoundingBox;
use centrode_core::domain::id::TypedRecordId;
use centrode_core::domain::styles::PortSide;
use centrode_core::domain::types::TableKind;
use centrode_core::layout_engine::config::LayoutConfig;
use centrode_core::layout_engine::engine::LayoutEngine;
use centrode_core::layout_engine::port_optimizer;
use centrode_core::layout_engine::types::NodePhysics;

#[test]
fn test_port_optimizer_quadrants() {
    let source = NodePhysics {
        id: TypedRecordId::new_v4(TableKind::INode),
        x: 100.0,
        y: 100.0,
        width: 100.0,
        height: 100.0,
        vx: 0.0,
        vy: 0.0,
    }; // cx = 150, cy = 150

    let target_right = NodePhysics {
        id: TypedRecordId::new_v4(TableKind::INode),
        x: 300.0,
        y: 100.0,
        width: 100.0,
        height: 100.0,
        vx: 0.0,
        vy: 0.0,
    }; // cx = 350, cy = 150

    let (from_s, to_s) = port_optimizer::compute_optimal_ports(&source, &target_right);
    assert_eq!(from_s, PortSide::Right);
    assert_eq!(to_s, PortSide::Left);

    let target_bottom = NodePhysics {
        id: TypedRecordId::new_v4(TableKind::INode),
        x: 100.0,
        y: 300.0,
        width: 100.0,
        height: 100.0,
        vx: 0.0,
        vy: 0.0,
    }; // cx = 150, cy = 350

    let (from_s2, to_s2) = port_optimizer::compute_optimal_ports(&source, &target_bottom);
    assert_eq!(from_s2, PortSide::Bottom);
    assert_eq!(to_s2, PortSide::Top);
}

#[test]
fn test_auto_placement_clamping() {
    let mut engine = LayoutEngine::new(LayoutConfig::default());
    let area = BoundingBox {
        min_x: 0.0,
        min_y: 0.0,
        max_x: 500.0,
        max_y: 500.0,
    };
    engine.state.opt_area = Some(area);

    let source_id = TypedRecordId::new_v4(TableKind::INode);
    let source = NodePhysics {
        id: source_id.clone(),
        x: 100.0,
        y: 100.0,
        width: 160.0,
        height: 80.0,
        vx: 0.0,
        vy: 0.0,
    };
    engine.state.nodes.insert(source_id.clone(), source);

    let (target_x, target_y) = engine
        .compute_auto_placement(source_id, PortSide::Right)
        .expect("Auto placement failed");

    assert!(target_x >= 20.0 && target_x <= 500.0 - 160.0 - 20.0);
    assert!(target_y >= 20.0 && target_y <= 500.0 - 80.0 - 20.0);
}

#[test]
fn test_repulsion_force() {
    use centrode_core::layout_engine::forces::repulsion::repulsion_force;

    let node_a = NodePhysics {
        id: TypedRecordId::new_v4(TableKind::INode),
        x: 0.0,
        y: 0.0,
        width: 50.0,
        height: 50.0,
        vx: 0.0,
        vy: 0.0,
    };
    let node_b = NodePhysics {
        id: TypedRecordId::new_v4(TableKind::INode),
        x: 100.0,
        y: 0.0,
        width: 50.0,
        height: 50.0,
        vx: 0.0,
        vy: 0.0,
    };

    let (fx, fy) = repulsion_force(&node_a, &node_b, 5000.0);
    assert!(fx < 0.0, "Repulsion should push node_a to the left");
    assert_eq!(fy, 0.0);
}

#[test]
fn test_attraction_force() {
    use centrode_core::layout_engine::forces::attraction::link_spring_force;

    let node_a = NodePhysics {
        id: TypedRecordId::new_v4(TableKind::INode),
        x: 0.0,
        y: 0.0,
        width: 50.0,
        height: 50.0,
        vx: 0.0,
        vy: 0.0,
    };
    let node_b = NodePhysics {
        id: TypedRecordId::new_v4(TableKind::INode),
        x: 300.0,
        y: 0.0,
        width: 50.0,
        height: 50.0,
        vx: 0.0,
        vy: 0.0,
    };

    let (fx, fy) = link_spring_force(&node_a, &node_b, 0.05, 200.0);
    assert!(fx > 0.0, "Attraction should pull node_a towards node_b when beyond ideal distance");
    assert_eq!(fy, 0.0);
}

