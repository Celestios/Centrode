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

    let (fx, fy) = link_spring_force(&node_a, &node_b, 0.05, 200.0, 0.5);
    assert!(fx > 0.0, "Attraction should pull node_a towards node_b when beyond ideal distance");
    assert_eq!(fy, 0.0);
}

#[test]
fn test_force_equilibrium_invariant() {
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
    // Center of node_a is (25.0, 25.0).
    // Place node_b horizontally at ideal distance 200.0 (center: 225.0, 25.0)
    let node_b = NodePhysics {
        id: TypedRecordId::new_v4(TableKind::INode),
        x: 200.0,
        y: 0.0,
        width: 50.0,
        height: 50.0,
        vx: 0.0,
        vy: 0.0,
    };

    let (fx, fy) = link_spring_force(&node_a, &node_b, 0.05, 200.0, 0.5);
    assert!(
        fx.abs() < 1e-6,
        "Horizontal spring force fx must be zero at ideal distance (200.0), got {}",
        fx
    );
    assert!(
        fy.abs() < 1e-6,
        "Horizontal spring force fy must be zero at ideal distance (200.0), got {}",
        fy
    );

    // Diagonal placement at exactly 200.0 distance
    let angle = std::f64::consts::FRAC_PI_4;
    let node_c = NodePhysics {
        id: TypedRecordId::new_v4(TableKind::INode),
        x: 200.0 * angle.cos(),
        y: 200.0 * angle.sin(),
        width: 50.0,
        height: 50.0,
        vx: 0.0,
        vy: 0.0,
    };
    let (fx_diag, fy_diag) = link_spring_force(&node_a, &node_c, 0.05, 200.0, 0.5);
    assert!(
        fx_diag.abs() < 1e-6,
        "Diagonal spring force fx must be zero at ideal distance (200.0), got {}",
        fx_diag
    );
    assert!(
        fy_diag.abs() < 1e-6,
        "Diagonal spring force fy must be zero at ideal distance (200.0), got {}",
        fy_diag
    );
}

#[test]
fn test_multi_node_simulation_stepping() {
    use centrode_core::layout_engine::types::LayoutEdge;

    let mut engine = LayoutEngine::new(LayoutConfig::default());
    let area = BoundingBox {
        min_x: 0.0,
        min_y: 0.0,
        max_x: 1000.0,
        max_y: 1000.0,
    };
    engine.state.opt_area = Some(area.clone());

    let id1 = TypedRecordId::new_v4(TableKind::INode);
    let id2 = TypedRecordId::new_v4(TableKind::INode);
    let id3 = TypedRecordId::new_v4(TableKind::INode);
    let id4 = TypedRecordId::new_v4(TableKind::INode);
    let ids = [id1, id2, id3, id4];

    for (i, &id) in ids.iter().enumerate() {
        engine.state.nodes.insert(
            id,
            NodePhysics {
                id,
                x: 400.0 + (i as f64) * 30.0,
                y: 400.0 + ((i % 2) as f64) * 30.0,
                width: 80.0,
                height: 50.0,
                vx: 0.0,
                vy: 0.0,
            },
        );
    }

    engine.state.edges.push(LayoutEdge {
        id: TypedRecordId::new_v4(TableKind::IRelation),
        from_id: id1,
        to_id: id2,
        from_side: None,
        to_side: None,
    });
    engine.state.edges.push(LayoutEdge {
        id: TypedRecordId::new_v4(TableKind::IRelation),
        from_id: id2,
        to_id: id3,
        from_side: None,
        to_side: None,
    });
    engine.state.edges.push(LayoutEdge {
        id: TypedRecordId::new_v4(TableKind::IRelation),
        from_id: id3,
        to_id: id4,
        from_side: None,
        to_side: None,
    });
    engine.state.edges.push(LayoutEdge {
        id: TypedRecordId::new_v4(TableKind::IRelation),
        from_id: id4,
        to_id: id1,
        from_side: None,
        to_side: None,
    });

    let mut peak_velocity = 0.0f64;
    let mut final_velocity = 0.0f64;

    for iter in 0..50 {
        let tick = engine.step();
        assert_eq!(tick.iteration, (iter + 1) as u32);

        let total_vel: f64 = engine
            .state
            .nodes
            .values()
            .map(|n| (n.vx * n.vx + n.vy * n.vy).sqrt())
            .sum();

        if total_vel > peak_velocity {
            peak_velocity = total_vel;
        }
        final_velocity = total_vel;

        for node in engine.state.nodes.values() {
            assert!(
                node.x.is_finite() && !node.x.is_nan(),
                "Node x position must be valid and finite"
            );
            assert!(
                node.y.is_finite() && !node.y.is_nan(),
                "Node y position must be valid and finite"
            );
            assert!(
                node.x >= area.min_x && node.x + node.width <= area.max_x,
                "Node x must remain within area bounds"
            );
            assert!(
                node.y >= area.min_y && node.y + node.height <= area.max_y,
                "Node y must remain within area bounds"
            );
        }
    }

    assert!(peak_velocity > 0.0, "Cluster must experience initial motion from forces");
    assert!(
        final_velocity < peak_velocity,
        "Total velocity must dampen over time (peak: {}, final: {})",
        peak_velocity,
        final_velocity
    );
}

